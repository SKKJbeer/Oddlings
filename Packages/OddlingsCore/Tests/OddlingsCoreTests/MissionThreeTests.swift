import Foundation
import Testing
@testable import OddlingsCore

/// Mission 3 „Pilzhain“ (P2-6). Werte sind Hypothese bis nach WP-15; die Tests
/// halten Beziehungen fest, keine genauen Zahlen (testing-strategy.md).
@Suite("Mission 3")
struct MissionThreeTests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-03")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }).order
    }

    @Test("Die Datei ist gültig und bietet Aufwertung für jeden Kampfturm, Mission 1 und 2 keine")
    func offersUpgrades() throws {
        #expect(sim.config.mission.id == "mission-03")
        for kind in TowerKind.combat {
            let upgrade = try #require(sim.config.upgrades?[kind], "\(kind)")
            let cost = try #require(sim.config.cost(of: kind))
            // 02: Stufe 2 kostet etwa 70 % des Grundturms.
            #expect(upgrade.cost < cost, "\(kind)")
        }
        #expect(sim.config.upgrades?[.bank] == nil)
        #expect(try BalanceConfig.missionOne().upgrades == nil, "M1 bleibt für den Spieltest unverändert")
        #expect(try BalanceConfig.bundledMission(named: "mission-02").upgrades == nil, "M2 bleibt, wie sie abgestimmt ist")
    }

    @Test("Bank und Bonus fürs frühe Rufen bleiben (Empfehlung der Entscheidungskarte S5)")
    func keepsBankAndBonus() {
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
            .appendingPathComponent("art/karten/wegvorschlaege/mission-03.json")
        struct Proposal: Decodable { var map: MapConfig }
        let proposal = try JSONDecoder().decode(Proposal.self, from: Data(contentsOf: url))
        #expect(sim.config.map == proposal.map)
    }

    /// „Vertiefen statt verbreitern“: Die Haarnadel gibt einzelnen Plätzen mehr
    /// Weg als jeder Platz in Mission 2.
    @Test("Der beste Platz sieht mehr Weg als der beste in Mission 2")
    func deepSpotsExist() throws {
        let range = try #require(sim.config.towers[.watch]).range
        func best(_ sim: Simulation) -> Double {
            sim.map.buildableCells.map { sim.map.path.coverage(around: $0.center, radius: range) }.max() ?? 0
        }
        let two = Simulation(config: try BalanceConfig.bundledMission(named: "mission-02"))
        #expect(best(sim) > best(two), "M3 \(best(sim)), M2 \(best(two))")
    }

    @Test("Mischungen gewinnen mit und ohne Aufwertung, die Monokultur verliert, auch aufgewertet")
    func outcomes() throws {
        for name in ["Mix ohne Aufwertung", "Mix mit Aufwertung", "Wenige Plätze, tief", "Mix mit Bank und Aufwertung"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        #expect(sim.play(try order("Nur Wachtürme")).state.outcome == .lost)
        #expect(sim.play(try order("Nur Wachtürme, aufgewertet")).state.outcome == .lost)
    }

    /// Kennzahl aus 04: Vertiefen lohnt sich, ist aber nie Pflicht.
    @Test("Die beste Bauweise mit Aufwertung liegt vor der ohne, höchstens 0,15 Reserve")
    func upgradingIsAChoice() throws {
        let with = try ["Mix mit Aufwertung", "Wenige Plätze, tief"].map { sim.reserve(try order($0)) }.max() ?? 0
        let without = sim.reserve(try order("Mix ohne Aufwertung"))
        #expect(with >= without, "mit \(with), ohne \(without)")
        #expect(with <= without + 0.15, "mit \(with), ohne \(without)")
    }

    @Test("Die Bauweise mit Aufwertung hebt wirklich Türme auf Stufe 2")
    func upgradesHappen() throws {
        let run = sim.play(try order("Wenige Plätze, tief"))
        #expect(run.state.towers.filter { $0.level == 2 }.count >= 6)
        #expect(run.state.towers.allSatisfy { $0.level <= 2 })
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit Aufwertung")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    /// 03: Völker helfen, ersetzen aber keine Türme; gleiche Grenze wie in M1
    /// und M2, gemessen wie dort an der Vorführbauweise, die alles nutzt.
    @Test("Jedes Volk hebt die Reserve auch in M3 um höchstens 0,1")
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
