import Foundation
import Testing
@testable import OddlingsCore

/// Mission 4 „Ruinenrand“ (P2-10). Werte sind Hypothese bis nach WP-15; die
/// Tests halten Beziehungen fest, keine genauen Zahlen (testing-strategy.md).
@Suite("Mission 4")
struct MissionFourTests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-04")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }).order
    }

    @Test("Nur die Panzerbestie trägt Rüstung, und nur in Mission 4")
    func onlyBruteIsArmored() throws {
        #expect(sim.config.mission.id == "mission-04")
        #expect((sim.config.enemies[.brute]?.armor ?? 0) > 0)
        #expect(sim.config.enemies[.raider]?.armor == nil)
        #expect(sim.config.enemies[.runner]?.armor == nil)
        for name in ["mvp-mission-01", "mission-02", "mission-03"] {
            #expect(try !BalanceConfig.bundledMission(named: name).hasArmoredEnemies, "\(name) bleibt, wie sie abgestimmt ist")
        }
    }

    @Test("Aufwerten, Bank und Bonus wie in Mission 3")
    func keepsMissionThreeTools() {
        for kind in TowerKind.combat { #expect(sim.config.upgrades?[kind] != nil, "\(kind)") }
        #expect(sim.config.buildable.contains(.bank))
        #expect((sim.config.mission.earlyCallBonus ?? 0) > 0)
    }

    /// D-081: Der gemalte Kampfplatz folgt dem Vorschlag; weicht die Datei ab,
    /// muss nachgemalt werden.
    @Test("Der Weg ist der Vorschlag des Grafik-Threads")
    func pathMatchesProposal() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("art/karten/wegvorschlaege/mission-04.json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    @Test("Panzerbestien kommen früh: ab Welle 2 und in jeder Welle danach")
    func brutesEarly() {
        let waves = sim.config.waves.map { $0.groups.contains { $0.enemy == .brute } }
        #expect(waves.first == false, "Welle 1 lässt Zeit zum Aufbauen")
        #expect(waves.dropFirst().allSatisfy { $0 })
    }

    @Test("Mischungen gewinnen, jede Monokultur verliert, auch aufgewertet")
    func outcomes() throws {
        for name in ["Mix mit Aufwertung", "Mix ohne Aufwertung", "Mix mit Bank und Aufwertung"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        for name in ["Nur Wachtürme", "Nur Wachtürme, aufgewertet", "Nur Blitz", "Nur Blitz, aufgewertet"] {
            #expect(sim.play(try order(name)).state.outcome == .lost, "\(name)")
        }
    }

    /// Kennzahl „Panzerung“ (04): Gegen Rüstung ist Aufwerten der klare Weg,
    /// ohne geht es nur knapp. Und die Rüstung selbst ist es, die das macht.
    @Test("Mit Aufwertung mindestens 0,1 Reserve vor ohne; ohne Rüstung wäre ohne Aufwertung deutlich leichter")
    func armorRewardsUpgrading() throws {
        let with = sim.reserve(try order("Mix mit Aufwertung"))
        let without = sim.reserve(try order("Mix ohne Aufwertung"))
        #expect(with >= without + 0.1, "mit \(with), ohne \(without)")
        var bare = sim.config
        bare.enemies[.brute]?.armor = 0
        let unarmored = Simulation(config: bare).reserve(try order("Mix ohne Aufwertung"))
        #expect(unarmored >= without + 0.1, "ohne Rüstung \(unarmored), mit \(without)")
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit Aufwertung")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    /// 03: Völker helfen, ersetzen aber keine Türme; gleiche Grenze wie in M1
    /// bis M3, gemessen an der Vorführbauweise, die alles nutzt.
    @Test("Jedes Volk hebt die Reserve auch in M4 um höchstens 0,1")
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
