import Foundation
import Testing
@testable import OddlingsCore

/// Aufwerten auf Stufe 2 (D-024, D-084, P2-6). Eigene Testwerte, damit eine
/// Balanceänderung an Mission 3 keinen Regeltest bricht.
@Suite("Aufwerten")
struct UpgradeTests {
    static let upgrades: [TowerKind: UpgradeConfig] = [
        .watch: UpgradeConfig(cost: 7, scale: [.damage: 1.5]),
        .lightning: UpgradeConfig(cost: 7, scale: [.damage: 2, .chainRadius: 1.5]),
        .spore: UpgradeConfig(cost: 7, scale: [.range: 1.5, .slowFactor: 0.8]),
    ]
    let sim: Simulation
    let cell = Cell(x: 5, y: 2)

    init() {
        var config = TestConfig.make()
        config.upgrades = Self.upgrades
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    /// Ein Wachturm steht, der Bau ist gebucht.
    private func withWatch() -> GameState {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell)])
        return state
    }

    @Test("Aufwerten kostet den Preis, hebt die Stufe und zählt zum Bezahlten")
    func upgrade() {
        var state = withWatch()
        #expect(sim.step(&state, commands: [.upgrade(towerID: 1)]) == [.towerUpgraded(id: 1, level: 2)])
        #expect(state.gold == 1_000 - 10 - 7)
        #expect(state.towers.first?.level == 2)
        #expect(state.towers.first?.spent == 17)
    }

    @Test("Verkaufen erstattet den Anteil von allem, was im Turm steckt")
    func refundIncludesUpgrade() {
        var state = withWatch()
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        let gold = state.gold
        #expect(sim.step(&state, commands: [.sell(towerID: 1)]) == [.towerSold(id: 1, refund: 8)])
        #expect(state.gold == gold + 8, "17 × 0,5 abgerundet")
    }

    @Test("Stufe 2 rechnet mit den Faktoren auf die Werte der Stufe 1")
    func stats() throws {
        let config = sim.config
        #expect(config.stats(of: .watch, level: 1) == config.towers[.watch])
        #expect(try #require(config.stats(of: .watch, level: 2)).damage == 15)
        let lightning = try #require(config.stats(of: .lightning, level: 2))
        #expect(lightning.damage == 36)
        #expect(abs((lightning.chainRadius ?? 0) - 1.95) < 1e-9)
        #expect(lightning.chainJumps == 4, "nicht skaliert, bleibt")
        let spore = try #require(config.stats(of: .spore, level: 2))
        #expect(spore.range == 4.5)
        #expect(abs((spore.slowFactor ?? 0) - 0.4) < 1e-9)
        #expect(config.maxLevel(of: .watch) == 2 && config.maxLevel(of: .bank) == 1)
    }

    @Test("Ein Turm auf Stufe 2 trifft mit dem Schaden der Stufe 2")
    func firesWithLevelTwo() {
        var state = withWatch()
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        state.enemies = [TestConfig.enemy(9, at: 5)]
        let events = sim.step(&state)
        #expect(events.contains(.enemyDamaged(id: 9, amount: 15)), "\(events)")
    }

    @Test("Faktoren wirken auf die Werte nach Volk und Ausrüstung, nicht auf die der Datei")
    func scalesAdjustedBase() throws {
        var config = sim.config
        config.towers[.watch]?.damage *= 1.1
        config.towers[.spore]?.range *= 1.2
        #expect(try #require(config.stats(of: .watch, level: 2)).damage == 10 * 1.1 * 1.5)
        #expect(try #require(config.stats(of: .spore, level: 2)).range == 3 * 1.2 * 1.5)
    }

    @Test("Der Takt läuft beim Aufwerten weiter")
    func cooldownKeeps() {
        var state = withWatch()
        state.towers[0].cooldownTicks = 12
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        #expect(state.towers[0].cooldownTicks == 11)
    }

    @Test("Zweites Aufwerten, Bank und unbekannter Turm werden abgelehnt")
    func rejected() {
        var config = sim.config
        config.bank = BankConfig(cost: 10, delay: 1, interval: 1, payout: 1, cap: 5, limit: 1)
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell), .build(.bank, Cell(x: 6, y: 2))])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        let again = Command.upgrade(towerID: 1), bank = Command.upgrade(towerID: 2), ghost = Command.upgrade(towerID: 99)
        let gold = state.gold
        #expect(sim.step(&state, commands: [again, bank, ghost]) == [
            .commandRejected(again, reason: .notUpgradable),
            .commandRejected(bank, reason: .notUpgradable),
            .commandRejected(ghost, reason: .unknownTower),
        ])
        #expect(state.gold == gold)
    }

    @Test("Mission ohne Abschnitt upgrades lehnt Aufwerten ab")
    func missionWithout() {
        let sim = Simulation(config: TestConfig.make())
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell)])
        let command = Command.upgrade(towerID: 1)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .notUpgradable)])
        #expect(state.towers.first?.level == 1)
    }

    @Test("Zu wenig Gold zum Aufwerten")
    func notEnoughGold() {
        var state = withWatch()
        state.gold = 6
        let command = Command.upgrade(towerID: 1)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .notEnoughGold)])
        #expect(state.gold == 6 && state.towers.first?.level == 1)
    }

    @Test("Zustände ohne Stufe und Zielwahl (vor 0.17.0) bleiben lesbar")
    func oldStateReadable() throws {
        let json = #"{"id":1,"kind":"watch","cell":{"x":1,"y":2},"cooldownTicks":0,"spent":50}"#
        let tower = try JSONDecoder().decode(Tower.self, from: Data(json.utf8))
        #expect(tower.level == 1 && tower.targetMode == .first)
        let round = try JSONDecoder().decode(Tower.self, from: JSONEncoder().encode(
            Tower(id: 1, kind: .watch, cell: cell, cooldownTicks: 0, spent: 5, level: 2, targetMode: .strongest)))
        #expect(round.level == 2 && round.targetMode == .strongest)
    }

    @Test("Bauweisen lesen „watch+“ als Aufwerten und schreiben es zurück")
    func strategySteps() throws {
        let steps = try JSONDecoder().decode([StrategyStep].self, from: Data(#"["watch","watch+","bank"]"#.utf8))
        #expect(steps == [.build(.watch), .upgrade(.watch), .build(.bank)])
        #expect(String(decoding: try JSONEncoder().encode(steps), as: UTF8.self) == #"["watch","watch+","bank"]"#)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode([StrategyStep].self, from: Data(#"["tower+"]"#.utf8)) }
    }

    @Test("Der Mitspieler wertet den ältesten Turm auf, wartet auf einen eben gebauten und überspringt fehlende")
    func autoplayerUpgrades() {
        var player = Autoplayer(order: [.upgrade(.spore), .build(.watch), .upgrade(.watch), .build(.watch)])
        var state = sim.newGame(seed: 1)
        let first = player.commands(for: state, in: sim)
        #expect(first.count == 1, "Sporen fehlen: Schritt entfällt; Aufwerten wartet auf den Bau")
        guard case .build(.watch, _) = first.first else { Issue.record("\(first)"); return }
        sim.step(&state, commands: first)
        #expect(player.commands(for: state, in: sim).first == .upgrade(towerID: 1))
    }
}
