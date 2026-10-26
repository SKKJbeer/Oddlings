import Testing
@testable import OddlingsCore

@Suite("Mondmal")
struct MoonMarkTests {
    /// Eigene Werte (testing-strategy.md, Regel 4): Verzögerung 15 Ticks, Mal
    /// 60 Ticks, Faktor 1,5.
    static let ability = AbilityConfig(kind: .moonMark, cooldown: 10, snapDistance: 1, radius: 1,
                                       delay: 0.5, duration: 2, damageFactor: 1.5)
    let sim: Simulation = {
        var config = TestConfig.make()
        config.ability = MoonMarkTests.ability
        return Simulation(config: config)
    }()

    private func game(enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies + [TestConfig.enemy(99, at: 0, hp: 1_000_000)]
        return state
    }

    @Test("Markiert beim Einschlag, wer im Kreis steht, ohne Schaden")
    func marksOnImpact() {
        var state = game(enemies: [TestConfig.enemy(1, at: 9.5), TestConfig.enemy(2, at: 20)])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        var impact: [Event] = []
        while state.tick <= 15 {
            let events = sim.step(&state)
            if events.contains(where: { if case .abilityImpact = $0 { true } else { false } }) { impact = events }
        }
        #expect(impact.contains(.abilityImpact(center: Point(x: 10, y: 0.5), hits: [1])))
        #expect(state.enemies[0].vulnerable == VulnerableEffect(factor: 1.5, untilTick: 75))
        #expect(state.enemies[0].hp == 100, "das Mal allein trifft nicht")
        #expect(state.enemies[1].vulnerable == nil)
    }

    @Test("Jeder Treffer zählt mal Faktor, nach dem Ablauf wieder einfach")
    func multipliesDamage() {
        var enemy = TestConfig.enemy(1, at: 10)
        enemy.vulnerable = VulnerableEffect(factor: 1.5, untilTick: 5)
        #expect(sim.hurt(&enemy, by: 10, tick: 4) == 15)
        #expect(enemy.hp == 85)
        #expect(sim.hurt(&enemy, by: 10, tick: 5) == 10, "untilTick ist der erste Tick ohne Wirkung")
    }

    @Test("Ein Turm trifft ein markiertes Ziel stärker")
    func towerHitsHarder() {
        var marked = TestConfig.enemy(1, at: 10)
        marked.vulnerable = VulnerableEffect(factor: 1.5, untilTick: 100)
        var state = game(enemies: [marked])
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(events.contains(.enemyDamaged(id: 1, amount: 15)))
    }

    @Test("Kein Stapeln: stärkster Faktor, späteres Ende")
    func doesNotStack() {
        var enemy = TestConfig.enemy(1, at: 10)
        enemy.vulnerable = VulnerableEffect(factor: 2, untilTick: 100)
        sim.applyVulnerable(VulnerableEffect(factor: 1.5, untilTick: 50), to: &enemy, tick: 0)
        #expect(enemy.vulnerable == VulnerableEffect(factor: 2, untilTick: 100))
        sim.applyVulnerable(VulnerableEffect(factor: 3, untilTick: 200), to: &enemy, tick: 0)
        #expect(enemy.vulnerable == VulnerableEffect(factor: 3, untilTick: 200))
        sim.applyVulnerable(VulnerableEffect(factor: 1.5, untilTick: 300), to: &enemy, tick: 250)
        #expect(enemy.vulnerable == VulnerableEffect(factor: 1.5, untilTick: 300), "ein abgelaufenes zählt nicht")
    }

    @Test("Läuft ab und verschwindet aus dem Zustand")
    func expires() {
        var marked = TestConfig.enemy(1, at: 10)
        marked.vulnerable = VulnerableEffect(factor: 1.5, untilTick: 2)
        var state = game(enemies: [marked])
        sim.step(&state)
        sim.step(&state)
        #expect(state.enemies[0].vulnerable != nil)
        sim.step(&state)
        #expect(state.enemies[0].vulnerable == nil)
    }

    @Test("Prüfung: Radius, Verzögerung, Dauer und Faktor über 1")
    func validation() {
        var config = TestConfig.make()
        config.ability = AbilityConfig(kind: .moonMark, cooldown: 10, snapDistance: 1, delay: 0.5,
                                       duration: 2, damageFactor: 1)
        #expect(Set(config.issues().map(\.field)) == ["ability.radius", "ability.damageFactor"])
        #expect(config.issues().contains(ConfigIssue(field: "ability.damageFactor", rule: .mustBeAboveOne)))
        config.ability = MoonMarkTests.ability
        #expect(config.issues().isEmpty)
    }
}
