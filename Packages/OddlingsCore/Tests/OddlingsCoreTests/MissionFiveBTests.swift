import Foundation
import Testing
@testable import OddlingsCore
import OddlingsLab

/// Mission 5b „Ruinen“ (P3-2, D-078). Werte sind Hypothese bis nach dem
/// Spieltest; die Tests halten Beziehungen fest, keine genauen Zahlen.
@Suite("Mission 5b")
struct MissionFiveBTests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-05b")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }).order
    }

    @Test("Die Ruinen bieten je Turm genau die andere Spezialisierung (S14)")
    func otherSpecializationPerTower() throws {
        #expect(sim.config.mission.id == "mission-05b")
        #expect(sim.config.specializations(for: .watch) == [.falconHold])
        #expect(sim.config.specializations(for: .lightning) == [.sparkColumn])
        #expect(sim.config.specializations(for: .spore) == [.rot])
    }

    @Test("Panzerbestien prägen die Mission: in jeder Welle, und eine reine Panzerwelle")
    func bruteHeavy() {
        #expect(sim.config.waves.allSatisfy { $0.groups.contains { $0.enemy == .brute } })
        #expect(sim.config.waves.contains { $0.groups.allSatisfy { $0.enemy == .brute } })
        let five = try? BalanceConfig.bundledMission(named: "mission-05a")
        let brutes = { (c: BalanceConfig) in c.waves.flatMap(\.groups).filter { $0.enemy == .brute }.reduce(0) { $0 + $1.count } }
        #expect(brutes(sim.config) > 2 * brutes(five ?? sim.config), "mehr als doppelt so viele wie auf dem Sumpfpfad")
    }

    @Test("Der Weg ist der Vorschlag des Grafik-Threads")
    func pathMatchesProposal() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("art/karten/wegvorschlaege/mission-05b.json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    @Test("Mischungen gewinnen, jede Monokultur verliert, auch spezialisiert")
    func outcomes() throws {
        for name in ["Mix mit Spezialisierung", "Mix mit Aufwertung", "Fäulnis mit Falkenhorsten", "Funkensäulen mit Fäulnis"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        for name in ["Nur Wachtürme", "Falkenhorste", "Nur Blitz", "Nur Blitz, spezialisiert"] {
            #expect(sim.play(try order(name)).state.outcome == .lost, "\(name)")
        }
    }

    @Test("Spezialisieren hebt die Mischung um mindestens 0,1 Reserve")
    func specializingPays() throws {
        let with = sim.reserve(try order("Mix mit Spezialisierung"))
        let without = sim.reserve(try order("Mix mit Aufwertung"))
        #expect(with >= without + 0.1, "mit \(with), ohne \(without)")
    }

    /// Falkenhorst und Fäulnis tragen die Bauweise gegen Panzer. Die
    /// Funkensäule hebt nur den reinen Blitz; in der Mischung kostet sie die
    /// Kette, ihr Wert dort ist offen für den Spieltest (04).
    @Test("Falkenhorst und Fäulnis tragen die Kombination, die Funkensäule hebt den Blitz")
    func eachSpecializationCounts() throws {
        let combo = try order("Fäulnis mit Falkenhorsten")
        let full = sim.reserve(combo)
        let withoutRot = sim.reserve(combo.filter { $0 != .specialize(.rot) })
        let withoutFalcon = sim.reserve(combo.filter { $0 != .specialize(.falconHold) })
        #expect(withoutRot + 0.1 < full, "ohne Fäulnis \(withoutRot) gegen \(full)")
        #expect(withoutFalcon + 0.1 < full, "ohne Falkenhorst \(withoutFalcon) gegen \(full)")
        let falcons = sim.reserve(try order("Falkenhorste"))
        let plain = sim.reserve(try order("Nur Wachtürme"))
        #expect(falcons > plain + 0.2, "Falkenhorste \(falcons), Nur Wachtürme \(plain)")
        let columns = sim.reserve(try order("Nur Blitz, spezialisiert"))
        let bolts = sim.reserve(try order("Nur Blitz"))
        #expect(columns > bolts, "Funkensäulen \(columns), Nur Blitz \(bolts)")
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit Spezialisierung")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    /// Die Elfen reichen mit Sporentürmen weiter, und in den Ruinen trägt
    /// die Fäulnis: Das Volk passt hier besser als anderswo (Labor: +0,16 in
    /// der Mischung, unter der Dominanzgrenze 0,35). Offen für den Spieltest (04).
    @Test("Zwerge heben die Reserve in M5b um höchstens 0,1, Elfen um höchstens 0,2")
    func racesBounded() throws {
        let mix = try order(try #require(sim.config.demoStrategy))
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let with = Simulation(config: sim.config.applying(try #require(table[race]))).reserve(mix, castsAbility: true)
            #expect(with >= without, "\(race) hilft")
            let bound = race == .elves ? 0.2 : 0.1
            #expect(with <= without + bound, "\(race): \(with) gegen \(without)")
        }
    }
}
