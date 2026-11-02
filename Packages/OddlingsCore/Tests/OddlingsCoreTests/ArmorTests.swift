import Testing
@testable import OddlingsCore

@Suite("Rüstung")
struct ArmorTests {
    /// Eigene Werte (testing-strategy.md, Regel 4): Panzerbestie mit 6 Rüstung
    /// und Mindestanteil 0,25; Wachturm 10, Blitz 18, Sporen 1, Steinregen 40.
    static func config() -> BalanceConfig {
        var config = TestConfig.make()
        config.enemies[.brute]?.armor = 6
        config.enemies[.brute]?.armorMinShare = 0.25
        config.ability = AbilityTests.ability
        return config
    }
    let sim = Simulation(config: ArmorTests.config())

    private func game(enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies + [TestConfig.enemy(99, at: 0, hp: 1_000_000)]
        return state
    }

    private func brute(_ id: Int, at distance: Double) -> Enemy {
        TestConfig.enemy(id, at: distance, hp: 400, kind: .brute)
    }

    @Test("Fester Abzug je Turmtreffer, gemeldet als geschluckt")
    func subtractsPerHit() {
        var state = game(enemies: [brute(1, at: 10)])
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(events.contains(.enemyDamaged(id: 1, amount: 4)))
        #expect(events.contains(.armorAbsorbed(id: 1, amount: 6)))
        #expect(state.enemies[0].hp == 396)
    }

    @Test("Kleine Treffer behalten den Mindestanteil")
    func keepsMinimumShare() {
        var enemy = brute(1, at: 10)
        let hit = sim.strike(&enemy, by: 1, tick: 0)
        #expect(hit == Simulation.Hit(dealt: 0.25, absorbed: 0.75))
        #expect(enemy.hp == 399.75)
    }

    @Test("Der Sporenpuls verliert an der Panzerung bis auf den Mindestanteil")
    func sporePulse() {
        var state = game(enemies: [brute(1, at: 10)])
        let events = sim.step(&state, commands: [.build(.spore, Cell(x: 10, y: 1))])
        #expect(events.contains(.enemyDamaged(id: 1, amount: 0.25)))
        #expect(events.contains(.enemySlowed(id: 1)), "Verlangsamen wirkt unverändert")
    }

    @Test("Jeder Blitzsprung zahlt die Rüstung einzeln")
    func lightningJumps() {
        var state = game(enemies: [brute(1, at: 10), brute(2, at: 9)])
        let events = sim.step(&state, commands: [.build(.lightning, Cell(x: 10, y: 1))])
        #expect(events.contains(.enemyDamaged(id: 1, amount: 12)))
        // Zweiter Sprung 18 × 0,8 = 14,4, minus 6.
        let second = events.compactMap { if case .enemyDamaged(2, let amount) = $0 { amount } else { nil } }
        #expect(second.count == 1)
        #expect(abs(second[0] - 8.4) < 1e-9)
    }

    @Test("Der Steinregen schlägt durch die Panzerung")
    func abilityPierces() {
        var state = game(enemies: [brute(1, at: 10)])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        var all: [Event] = []
        while state.tick <= 15 { all += sim.step(&state) }
        #expect(all.contains(.enemyDamaged(id: 1, amount: 40)))
        #expect(!all.contains { if case .armorAbsorbed = $0 { true } else { false } })
    }

    /// Erst die Rüstung, dann das Mal: Mondmal vervielfacht, was durchkommt.
    /// Davor gerechnet, hob es die Elfen in Mission 4 über die Grenze aus 03.
    @Test("Mondmal vervielfacht, was durch die Rüstung kommt")
    func markAfterArmor() {
        var enemy = brute(1, at: 10)
        enemy.vulnerable = VulnerableEffect(factor: 1.5, untilTick: 100)
        #expect(sim.strike(&enemy, by: 10, tick: 0) == Simulation.Hit(dealt: 6, absorbed: 9))
    }

    @Test("Gegner ohne Rüstung nehmen den vollen Treffer, ohne Meldung")
    func unarmoredUnchanged() {
        var state = game(enemies: [TestConfig.enemy(1, at: 10)])
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(events.contains(.enemyDamaged(id: 1, amount: 10)))
        #expect(!events.contains { if case .armorAbsorbed = $0 { true } else { false } })
    }

    @Test("Rüstung 0 schluckt nichts und meldet nichts")
    func zeroArmor() {
        var config = ArmorTests.config()
        config.enemies[.brute]?.armor = 0
        let plain = Simulation(config: config)
        var enemy = brute(1, at: 10)
        #expect(plain.strike(&enemy, by: 10, tick: 0) == Simulation.Hit(dealt: 10, absorbed: 0))
    }

    @Test("Prüfung beim Laden: beide Werte zusammen, Anteil in (0, 1], Rüstung nicht negativ")
    func validation() {
        var config = ArmorTests.config()
        #expect(config.issues().isEmpty)
        config.enemies[.brute]?.armorMinShare = nil
        #expect(config.issues() == [ConfigIssue(field: "enemies.brute", rule: .armorNeedsBothValues)])
        config.enemies[.brute]?.armorMinShare = 0
        #expect(config.issues() == [ConfigIssue(field: "enemies.brute.armorMinShare", rule: .mustBeFraction)])
        config.enemies[.brute]?.armorMinShare = 0.25
        config.enemies[.brute]?.armor = -1
        #expect(config.issues() == [ConfigIssue(field: "enemies.brute.armor", rule: .mustNotBeNegative)])
    }
}
