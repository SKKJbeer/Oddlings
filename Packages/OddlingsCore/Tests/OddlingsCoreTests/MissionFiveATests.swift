import Foundation
import Testing
@testable import OddlingsCore
import OddlingsLab

/// Mission 5a „Sumpfpfad“ (P3-1, D-077). Werte sind Hypothese bis nach dem
/// Spieltest; die Tests halten Beziehungen fest, keine genauen Zahlen.
@Suite("Mission 5a")
struct MissionFiveATests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-05a")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }).order
    }

    @Test("Der Sumpfpfad bietet je Turm genau eine Spezialisierung (S14)")
    func oneSpecializationPerTower() throws {
        #expect(sim.config.mission.id == "mission-05a")
        #expect(sim.config.specializations(for: .watch) == [.volley])
        #expect(sim.config.specializations(for: .lightning) == [.stormCrown])
        #expect(sim.config.specializations(for: .spore) == [.bogHeart])
        for name in ["mvp-mission-01", "mission-02", "mission-03", "mission-04"] {
            #expect(try BalanceConfig.bundledMission(named: name).specializations == nil, "\(name) bleibt bei Stufe 2")
        }
    }

    @Test("Flitzer sind die Hauptgegner: mehr als die Hälfte aller Gegner, und eine reine Flitzerwelle")
    func runnerHeavy() {
        let groups = sim.config.waves.flatMap(\.groups)
        let runners = groups.filter { $0.enemy == .runner }.reduce(0) { $0 + $1.count }
        let all = groups.reduce(0) { $0 + $1.count }
        #expect(runners * 2 > all, "\(runners) von \(all)")
        #expect(sim.config.waves.contains { $0.groups.allSatisfy { $0.enemy == .runner } })
    }

    @Test("Der Weg ist der Vorschlag des Grafik-Threads")
    func pathMatchesProposal() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("art/karten/wegvorschlaege/mission-05a.json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    @Test("Mischungen gewinnen, jede Monokultur verliert, auch spezialisiert")
    func outcomes() throws {
        for name in ["Mix mit Spezialisierung", "Mix mit Aufwertung", "Gewitterkronen mit Sporen"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        for name in ["Nur Wachtürme", "Salven", "Nur Blitz", "Nur Blitz, spezialisiert"] {
            #expect(sim.play(try order(name)).state.outcome == .lost, "\(name)")
        }
    }

    /// 02, „Prüfung“: Stufe 3 lohnt in einer Mischung, nicht als Ersatz für sie.
    @Test("Spezialisieren hebt die Mischung um mindestens 0,1 Reserve")
    func specializingPays() throws {
        let with = sim.reserve(try order("Mix mit Spezialisierung"))
        let without = sim.reserve(try order("Mix mit Aufwertung"))
        #expect(with >= without + 0.1, "mit \(with), ohne \(without)")
    }

    /// Jede Spezialisierung trägt die Bauweise, für die sie gedacht ist. Das
    /// Moorherz zeigt seinen Wert erst mit der Verlangsamung der Elfen (Labor);
    /// ohne Volk entscheidet in dieser Bauweise die Panzerbestie, nicht die
    /// Verlangsamung. Ob es sich anfühlt, klärt der Spieltest.
    @Test("Gewitterkrone trägt die Kombination, Salve und Gewitterkrone heben ihre Türme")
    func eachSpecializationCounts() throws {
        let combo = try order("Gewitterkronen mit Sporen")
        let full = sim.reserve(combo)
        let withoutCrown = sim.reserve(combo.filter { $0 != .specialize(.stormCrown) })
        #expect(withoutCrown + 0.05 < full, "ohne Gewitterkrone \(withoutCrown) gegen \(full)")
        let volleys = sim.reserve(try order("Salven"))
        let plain = sim.reserve(try order("Nur Wachtürme"))
        #expect(volleys > plain + 0.05, "Salven \(volleys), Nur Wachtürme \(plain)")
        let crowns = sim.reserve(try order("Nur Blitz, spezialisiert"))
        let bolts = sim.reserve(try order("Nur Blitz"))
        #expect(crowns > bolts + 0.05, "Gewitterkronen \(crowns), Nur Blitz \(bolts)")
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit Spezialisierung")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    @Test("Jedes Volk hebt die Reserve auch in M5a um höchstens 0,1")
    func racesBounded() throws {
        let mix = try order(try #require(sim.config.demoStrategy))
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let with = Simulation(config: sim.config.applying(try #require(table[race]))).reserve(mix, castsAbility: true)
            #expect(with >= without, "\(race) hilft")
            #expect(with <= without + 0.1, "\(race): \(with) gegen \(without)")
        }
    }
}
