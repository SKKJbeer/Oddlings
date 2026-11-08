import Foundation
import Testing
@testable import OddlingsCore
import OddlingsLab

/// Mission 7 „Bosslichtung“, der Boss von Region 1 (P3-4, K7). Werte sind
/// Hypothese bis nach dem Spieltest; die Tests halten Beziehungen fest.
@Suite("Mission 7")
struct MissionSevenTests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-07")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }, "\(name)").order
    }

    /// Wie weit der Boss beim Spielen einer Bauweise kam: kleinster Lebensanteil
    /// und ob er den Schild gehoben hat.
    private func bossRun(_ name: String) throws -> (outcome: Outcome?, lowest: Double, shield: Bool) {
        var bot = LabBot(sim: sim, order: try order(name), profile: .greedy(castsAbility: false),
                         weights: LabConfig.standard.greedy)
        var state = sim.newGame(seed: 1)
        var lowest = 1.0, shield = false
        while !state.isOver {
            for event in sim.step(&state, commands: bot.commands(for: state)) {
                if case .bossShieldRaised = event { shield = true }
            }
            for enemy in state.enemies where enemy.kind == .moorKing { lowest = min(lowest, enemy.hp / enemy.maxHP) }
        }
        return (state.outcome, lowest, shield)
    }

    @Test("Der Moorkönig kommt einmal, in der letzten Welle, und kostet beim Durchbruch alle Leben")
    func bossInLastWave() throws {
        #expect(sim.config.mission.id == "mission-07")
        let king = try #require(sim.config.enemies[.moorKing])
        #expect(king.boss != nil)
        #expect(king.leakDamage >= sim.config.mission.fortressLives)
        #expect((king.slowScale ?? 1) < 1, "Verlangsamung wirkt nur teilweise (K7)")
        let counts = sim.config.waves.map { $0.groups.filter { $0.enemy == .moorKing }.reduce(0) { $0 + $1.count } }
        #expect(counts.last == 1)
        #expect(counts.dropLast().allSatisfy { $0 == 0 })
        #expect(sim.config.specializations(for: .watch).count == 2, "die Wahl aus M6 bleibt")
    }

    @Test("Der Weg ist der Vorschlag des Grafik-Threads")
    func pathMatchesProposal() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("art/karten/wegvorschlaege/mission-07.json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    @Test("Mischungen mit beiden Seiten gewinnen, jede Monokultur verliert")
    func outcomes() throws {
        for name in ["Mix mit freier Wahl", "Mix mit Ruinen-Spezialisierungen", "Fäulnis mit Falkenhorsten"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        for name in ["Nur Wachtürme", "Salven", "Falkenhorste", "Nur Blitz", "Nur Blitz, Gewitterkronen", "Nur Blitz, Funkensäulen"] {
            #expect(sim.play(try order(name)).state.outcome == .lost, "\(name)")
        }
    }

    /// Kern des Bosses (S17): Wer nur Gruppen- oder nur Einzelschaden baut,
    /// bringt ihn an den Schild, verliert aber dort oder danach.
    @Test("Reine Gruppen- und reine Einzelziel-Bauweise erreichen den Boss und verlieren an ihm")
    func bossNeedsBothKinds() throws {
        for name in ["Nur Gruppenschaden", "Nur Einzelschaden"] {
            let run = try bossRun(name)
            #expect(run.outcome == .lost, "\(name)")
            #expect(run.lowest < 1, "\(name) erreicht den Boss")
        }
        let mix = try bossRun("Mix mit freier Wahl")
        #expect(mix.outcome == .won)
        #expect(mix.shield, "der Sieg führt durch den Schild")
    }

    @Test("Keine Kombination liegt mehr als 0,3 vor der besten Mischung")
    func noDominantCombo() throws {
        let best = try ["Mix mit freier Wahl", "Mix mit Ruinen-Spezialisierungen"].map { sim.reserve(try order($0)) }.max() ?? 0
        for name in ["Gewitterkronen mit Fäulnis", "Fäulnis mit Falkenhorsten", "Salven mit Moorherz"] {
            let combo = sim.reserve(try order(name))
            #expect(combo <= best + 0.3, "\(name): \(combo) gegen \(best)")
        }
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit freier Wahl")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    @Test("Jedes Volk hilft und hebt die Reserve um höchstens 0,3")
    func racesBounded() throws {
        let mix = try order(try #require(sim.config.demoStrategy))
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let with = Simulation(config: sim.config.applying(try #require(table[race]))).reserve(mix, castsAbility: true)
            #expect(with >= without, "\(race) hilft")
            #expect(with <= without + 0.3, "\(race): \(with) gegen \(without)")
        }
    }
}
