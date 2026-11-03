import Foundation
import Testing
@testable import OddlingsCore
import OddlingsLab

/// Spezialisieren auf Stufe 3 (D-024, D-077, P3-1). Eigene Testwerte, damit eine
/// Balanceänderung an Mission 5a keinen Regeltest bricht.
@Suite("Spezialisieren")
struct SpecializationTests {
    static let specializations: [Specialization: SpecializationConfig] = [
        .volley: SpecializationConfig(cost: 9, scale: [.damage: 0.5], targets: 2),
        .stormCrown: SpecializationConfig(cost: 9, extraJumps: 2, keepsDamageOnSlowed: true),
        .bogHeart: SpecializationConfig(cost: 9, scale: [.range: 2, .slowFactor: 0.5, .slowDuration: 2]),
    ]
    let sim: Simulation
    let cell = Cell(x: 5, y: 2)

    init() {
        var config = TestConfig.make()
        config.upgrades = UpgradeTests.upgrades
        config.specializations = Self.specializations
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    /// Ein Turm der Art steht auf Stufe 2.
    private func levelTwo(_ kind: TowerKind) -> GameState {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(kind, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        return state
    }

    @Test("Spezialisieren kostet den Preis, hebt auf Stufe 3 und zählt zum Bezahlten")
    func specialize() {
        var state = levelTwo(.watch)
        #expect(sim.step(&state, commands: [.specialize(towerID: 1, .volley)]) == [.towerUpgraded(id: 1, level: 3)])
        #expect(state.gold == 1_000 - 10 - 7 - 9)
        #expect(state.towers.first?.level == 3)
        #expect(state.towers.first?.specialization == .volley)
        #expect(state.towers.first?.spent == 26)
        let gold = state.gold
        #expect(sim.step(&state, commands: [.sell(towerID: 1)]) == [.towerSold(id: 1, refund: 13)])
        #expect(state.gold == gold + 13, "26 × 0,5")
    }

    @Test("Nur aus Stufe 2, nur einmal, nur passend zum Turm und nur, wenn die Mission sie anbietet")
    func rejected() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell), .build(.lightning, Cell(x: 8, y: 2))])
        let early = Command.specialize(towerID: 1, .volley)
        #expect(sim.step(&state, commands: [early]) == [.commandRejected(early, reason: .notUpgradable)], "Stufe 1")
        sim.step(&state, commands: [.upgrade(towerID: 1), .upgrade(towerID: 2)])
        let wrong = Command.specialize(towerID: 1, .stormCrown)
        let ghost = Command.specialize(towerID: 99, .volley)
        #expect(sim.step(&state, commands: [wrong, ghost]) == [
            .commandRejected(wrong, reason: .notUpgradable),
            .commandRejected(ghost, reason: .unknownTower),
        ])
        sim.step(&state, commands: [.specialize(towerID: 1, .volley)])
        let again = Command.specialize(towerID: 1, .volley), upgrade = Command.upgrade(towerID: 1)
        let gold = state.gold
        #expect(sim.step(&state, commands: [again, upgrade]) == [
            .commandRejected(again, reason: .notUpgradable),
            .commandRejected(upgrade, reason: .notUpgradable),
        ], "Stufe 3 ist die letzte, Aufwerten bleibt bei 1 → 2")
        #expect(state.gold == gold)

        var config = sim.config
        config.specializations = [.bogHeart: Self.specializations[.bogHeart]!]
        let narrow = Simulation(config: config)
        let offered = Command.specialize(towerID: 2, .stormCrown)
        #expect(narrow.step(&state, commands: [offered]) == [.commandRejected(offered, reason: .notUpgradable)],
                "nicht angeboten")
    }

    @Test("Zu wenig Gold zum Spezialisieren")
    func notEnoughGold() {
        var state = levelTwo(.spore)
        state.gold = 8
        let command = Command.specialize(towerID: 1, .bogHeart)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .notEnoughGold)])
        #expect(state.towers.first?.level == 2 && state.towers.first?.specialization == nil)
    }

    @Test("Werte rechnen von Stufe 2 aus")
    func stats() throws {
        let config = sim.config
        let volley = try #require(config.stats(of: .watch, specialization: .volley))
        #expect(volley.damage == 10 * 1.5 * 0.5)
        #expect(volley.targets == 2)
        let crown = try #require(config.stats(of: .lightning, specialization: .stormCrown))
        #expect(crown.chainJumps == 6 && crown.keepsDamageOnSlowed == true && crown.damage == 36)
        let heart = try #require(config.stats(of: .spore, specialization: .bogHeart))
        #expect(heart.range == 3 * 1.5 * 2)
        #expect(abs((heart.slowFactor ?? 0) - 0.2) < 1e-9 && heart.slowDuration == 3)
        #expect(config.stats(of: .spore, specialization: .volley) == nil, "Salve gehört zum Wachturm")
        #expect(config.specializations(for: .watch) == [.volley])
        #expect(config.specializations(for: .bank).isEmpty)
        var noUpgrade = config
        noUpgrade.upgrades = nil
        #expect(noUpgrade.specializations(for: .watch).isEmpty, "Stufe 3 setzt Stufe 2 voraus")
    }

    @Test("Salve trifft zwei verschiedene Ziele nach der Zielwahl")
    func volleyHitsTwo() {
        var state = levelTwo(.watch)
        sim.step(&state, commands: [.specialize(towerID: 1, .volley)])
        state.enemies = [TestConfig.enemy(7, at: 4), TestConfig.enemy(8, at: 6), TestConfig.enemy(9, at: 5)]
        state.towers[0].cooldownTicks = 0
        let events = sim.step(&state)
        #expect(events.contains(.towerFired(towerID: 1, targets: [8, 9])), "erster, dann zweiter: \(events)")
        #expect(events.contains(.enemyDamaged(id: 8, amount: 7.5)) && events.contains(.enemyDamaged(id: 9, amount: 7.5)))
        #expect(!events.contains { if case .enemyDamaged(7, _) = $0 { true } else { false } })
    }

    @Test("Salve mit einem einzigen Ziel trifft es einmal")
    func volleySingleTarget() {
        var state = levelTwo(.watch)
        sim.step(&state, commands: [.specialize(towerID: 1, .volley)])
        state.enemies = [TestConfig.enemy(7, at: 5)]
        state.towers[0].cooldownTicks = 0
        #expect(sim.step(&state).contains(.towerFired(towerID: 1, targets: [7])))
    }

    @Test("Gewitterkrone springt weiter und verliert auf verlangsamten Zielen keinen Schaden")
    func stormCrown() throws {
        let config = sim.config
        let crown = try #require(config.stats(of: .lightning, specialization: .stormCrown))
        var enemies = (0..<8).map { TestConfig.enemy($0, at: 10 + Double($0)) }
        let plain = sim.chainTargets(in: enemies, from: 0, stats: crown, tick: 100)
        #expect(plain.count == 7, "eins plus sechs Sprünge")
        #expect(abs(plain[1].damage - 36 * 0.8) < 1e-9)
        for index in [1, 2] { enemies[index].slow = SlowEffect(factor: 0.5, untilTick: 200) }
        let slowed = sim.chainTargets(in: enemies, from: 0, stats: crown, tick: 100)
        #expect(slowed[1].damage == 36 && slowed[2].damage == 36, "verlangsamt: kein Abfall")
        #expect(abs(slowed[3].damage - 36 * 0.8) < 1e-9, "danach wieder Abfall")
        enemies[1].slow = SlowEffect(factor: 0.5, untilTick: 100)
        #expect(abs(sim.chainTargets(in: enemies, from: 0, stats: crown, tick: 100)[1].damage - 36 * 0.8) < 1e-9,
                "abgelaufene Verlangsamung zählt nicht")
        let second = try #require(config.stats(of: .lightning, level: 2))
        #expect(abs(sim.chainTargets(in: enemies, from: 0, stats: second, tick: 100)[2].damage - 36 * 0.64) < 1e-9,
                "ohne Gewitterkrone fällt jeder Sprung ab")
    }

    @Test("Bauweisen lesen den Namen einer Spezialisierung und schreiben ihn zurück")
    func strategySteps() throws {
        let steps = try JSONDecoder().decode([StrategyStep].self, from: Data(#"["watch","watch+","volley"]"#.utf8))
        #expect(steps == [.build(.watch), .upgrade(.watch), .specialize(.volley)])
        #expect(steps[2].kind == .watch)
        #expect(try JSONDecoder().decode([StrategyStep].self, from: JSONEncoder().encode(steps)) == steps)
    }

    @Test("Mitspieler und Labor-Bot spezialisieren den ältesten Turm auf Stufe 2")
    func botsSpecialize() {
        var config = sim.config
        config.mission.firstWaveDelay = 60
        let sim = Simulation(config: config)
        let order: [StrategyStep] = [.build(.watch), .upgrade(.watch), .specialize(.volley), .specialize(.bogHeart)]
        var player = Autoplayer(order: order)
        var state = sim.newGame(seed: 1)
        for _ in 0..<10 { sim.step(&state, commands: player.commands(for: state, in: sim)) }
        #expect(state.towers.first?.specialization == .volley)
        #expect(player.order.isEmpty, "Moorherz ohne Sporenturm entfällt, statt die Liste anzuhalten")
        let run = sim.play(order, until: 10)
        #expect(run.state.towers.first?.specialization == .volley)
    }

    @Test("Prüfung der Datei: nur mit Stufe 2, passende Wirkung, positive Werte")
    func validation() {
        var config = sim.config
        config.specializations = [
            .volley: SpecializationConfig(cost: 0, targets: 0),
            .stormCrown: SpecializationConfig(cost: 5),
            .bogHeart: SpecializationConfig(cost: 5, scale: [.chainRadius: 2, .slowFactor: 3], extraJumps: 1),
        ]
        config.simStrategies = ["Salve": [.specialize(.volley)]]
        let rules = config.issues().map { "\($0.field) \($0.rule)" }
        #expect(rules.contains("specializations.volley.cost mustBePositive"))
        #expect(rules.contains("specializations.volley.targets mustBePositive"))
        #expect(rules.contains("specializations.stormCrown emptySpecialization"))
        #expect(rules.contains("specializations.bogHeart.scale.chainRadius statNotInTower"))
        #expect(rules.contains("specializations.bogHeart.extraJumps statNotInTower"))
        #expect(rules.contains("specializations.bogHeart.scale.slowFactor mustBeFraction"))
        config.upgrades = nil
        config.specializations = [.volley: SpecializationConfig(cost: 5, targets: 2)]
        let without = config.issues().map { "\($0.field) \($0.rule)" }
        #expect(without.contains("specializations.volley specializationNeedsUpgrade"))
        config.specializations = nil
        #expect(config.issues().map { "\($0.field) \($0.rule)" }.contains("simStrategies.Salve strategyNeedsSpecialization"))
        #expect(sim.config.issues().isEmpty)
    }

    @Test("Zustände mit und ohne Spezialisierung bleiben lesbar")
    func codable() throws {
        let json = #"{"id":1,"kind":"watch","cell":{"x":1,"y":2},"cooldownTicks":0,"spent":50,"level":2}"#
        #expect(try JSONDecoder().decode(Tower.self, from: Data(json.utf8)).specialization == nil)
        let tower = Tower(id: 1, kind: .watch, cell: cell, cooldownTicks: 0, spent: 5, level: 3, specialization: .volley)
        #expect(try JSONDecoder().decode(Tower.self, from: JSONEncoder().encode(tower)) == tower)
        let plain = String(decoding: try JSONEncoder().encode(Tower(id: 1, kind: .watch, cell: cell, cooldownTicks: 0,
                                                                     spent: 5)), as: UTF8.self)
        #expect(!plain.contains("specialization"), "alte Zustände und Fingerabdrücke ändern sich nicht")
    }

    @Test("Eine gesicherte Mission mit Spezialisierung besteht nur, wenn die Mission sie anbietet")
    func suspended() {
        var state = levelTwo(.watch)
        sim.step(&state, commands: [.specialize(towerID: 1, .volley)])
        let battle = SuspendedBattle(node: "m5a", rules: "x", seed: 1, state: state)
        #expect(battle.problems(for: sim).isEmpty)
        var config = sim.config
        config.specializations = nil
        #expect(!battle.problems(for: Simulation(config: config)).isEmpty)
        var level = state
        level.towers[0].level = 2
        #expect(!SuspendedBattle(node: "m5a", rules: "x", seed: 1, state: level).problems(for: sim).isEmpty)
    }
}
