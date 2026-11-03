import Foundation
import Testing
@testable import OddlingsCore
import OddlingsLab

/// Mission 6a „Sumpfpfad II“ und 6b „Ruinen II“ (P3-3, D-079): Ab hier bietet
/// jede Mission je Turm beide Spezialisierungen. Werte sind Hypothese bis nach
/// dem Spieltest; die Tests halten Beziehungen fest, keine genauen Zahlen.
@Suite("Mission 6")
struct MissionSixTests {
    static let files = ["mission-06a", "mission-06b"]

    private func setup(_ file: String) throws -> (Simulation, [(name: String, order: [StrategyStep])]) {
        let config = try BalanceConfig.bundledMission(named: file)
        return (Simulation(config: config), Strategies.of(config))
    }

    private func order(_ name: String, in strategies: [(name: String, order: [StrategyStep])]) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }, "\(name)").order
    }

    @Test("Jeder Turm bietet zwei Spezialisierungen zur Wahl, die Sumpfpfad-Form zuerst (S14)", arguments: MissionSixTests.files)
    func twoChoicesPerTower(file: String) throws {
        let (sim, _) = try setup(file)
        #expect(sim.config.mission.id == file)
        #expect(sim.config.specializations(for: .watch) == [.volley, .falconHold])
        #expect(sim.config.specializations(for: .lightning) == [.stormCrown, .sparkColumn])
        #expect(sim.config.specializations(for: .spore) == [.bogHeart, .rot])
    }

    /// S16: Die Gewitterkrone verliert ihren Vorteil auf gebremste Ziele; mit
    /// ihm schlug Gewitterkrone plus Sporen in Mission 6 jede andere Bauweise.
    @Test("Die Gewitterkrone schwächt sich an gebremsten Zielen ab wie jeder Blitz (S16)", arguments: MissionSixTests.files)
    func crownWithoutSlowBonus(file: String) throws {
        let (sim, _) = try setup(file)
        #expect(sim.config.specializations?[.stormCrown]?.keepsDamageOnSlowed != true)
        let five = try BalanceConfig.bundledMission(named: "mission-05a")
        #expect(five.specializations?[.stormCrown]?.keepsDamageOnSlowed != true)
    }

    @Test("Der Weg ist der Vorschlag des Grafik-Threads", arguments: MissionSixTests.files)
    func pathMatchesProposal(file: String) throws {
        let (sim, _) = try setup(file)
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("art/karten/wegvorschlaege/\(file).json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    @Test("Die freie Wahl gewinnt, jede Monokultur verliert, auch spezialisiert", arguments: MissionSixTests.files)
    func outcomes(file: String) throws {
        let (sim, strategies) = try setup(file)
        for name in ["Mix mit freier Wahl", "Mix mit Sumpf-Spezialisierungen", "Mix mit Ruinen-Spezialisierungen", "Fäulnis mit Falkenhorsten"] {
            #expect(sim.play(try order(name, in: strategies)).state.outcome == .won, "\(file) \(name)")
        }
        for name in ["Nur Wachtürme", "Salven", "Falkenhorste", "Nur Blitz", "Nur Blitz, Gewitterkronen", "Nur Blitz, Funkensäulen"] {
            #expect(sim.play(try order(name, in: strategies)).state.outcome == .lost, "\(file) \(name)")
        }
    }

    /// Kern der Mission: Die Wahl lohnt. Wer auf dem Sumpfpfad die Formen des
    /// Sumpfpfads nimmt und in den Ruinen die der Ruinen, liegt vorn; wer
    /// immer dieselbe Form nimmt, verliert Reserve.
    @Test("Die passende Wahl schlägt die unpassende, die freie Wahl schlägt beide", arguments: MissionSixTests.files)
    func choiceMatters(file: String) throws {
        let (sim, strategies) = try setup(file)
        let swamp = sim.reserve(try order("Mix mit Sumpf-Spezialisierungen", in: strategies))
        let ruins = sim.reserve(try order("Mix mit Ruinen-Spezialisierungen", in: strategies))
        let free = sim.reserve(try order("Mix mit freier Wahl", in: strategies))
        let (fitting, other) = file == "mission-06a" ? (swamp, ruins) : (ruins, swamp)
        #expect(fitting >= other + 0.05, "\(file): passend \(fitting), unpassend \(other)")
        #expect(free >= other, "\(file): frei \(free), unpassend \(other)")
        let upgraded = sim.reserve(try order("Mix mit Aufwertung", in: strategies))
        #expect(fitting >= upgraded + 0.05, "\(file): passend \(fitting), nur Stufe 2 \(upgraded)")
    }

    /// Gegen die Dominanz aus dem Labor (S16): Eine eingespielte Kombination
    /// darf vor der Mischung liegen (wie in M5a und M5b), aber unter der
    /// Dominanzgrenze des Labors. Mit dem Sporen-Vorteil der Krone lag
    /// Gewitterkronen mit Fäulnis bis 0,68 vorn.
    @Test("Gewitterkronen mit Fäulnis liegt höchstens 0,3 vor der besten Mischung (S16)", arguments: MissionSixTests.files)
    func noDominantCombo(file: String) throws {
        let (sim, strategies) = try setup(file)
        let mixes = try ["Mix mit freier Wahl", "Mix mit Sumpf-Spezialisierungen", "Mix mit Ruinen-Spezialisierungen"]
            .map { sim.reserve(try order($0, in: strategies)) }
        let best = mixes.max() ?? 0
        for name in ["Gewitterkronen mit Fäulnis", "Salven mit Moorherz", "Fäulnis mit Falkenhorsten"] {
            let combo = sim.reserve(try order(name, in: strategies))
            #expect(combo <= best + 0.3, "\(file) \(name): \(combo) gegen beste Mischung \(best)")
        }
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand", arguments: MissionSixTests.files)
    func deterministic(file: String) throws {
        let (sim, strategies) = try setup(file)
        let mix = try order("Mix mit freier Wahl", in: strategies)
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    @Test("Jedes Volk hilft und hebt die Reserve um höchstens 0,3", arguments: MissionSixTests.files)
    func racesBounded(file: String) throws {
        let (sim, strategies) = try setup(file)
        let mix = try order(try #require(sim.config.demoStrategy), in: strategies)
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let with = Simulation(config: sim.config.applying(try #require(table[race]))).reserve(mix, castsAbility: true)
            #expect(with >= without, "\(file) \(race) hilft")
            #expect(with <= without + 0.3, "\(file) \(race): \(with) gegen \(without)")
        }
    }
}
