import Testing
@testable import OddlingsCore

@Suite("Steinregen")
struct AbilityTests {
    /// Eigene Werte statt Mission 1 (testing-strategy.md, Regel 4). Verzögerung
    /// 15 Ticks, Anhalten 30 Ticks, Abklingzeit 300 Ticks.
    static let ability = AbilityConfig(radius: 1, damage: 40, delay: 0.5, stunDuration: 1,
                                       cooldown: 10, snapDistance: 1)
    let sim: Simulation = {
        var config = TestConfig.make()
        config.ability = AbilityTests.ability
        return Simulation(config: config)
    }()

    /// Spiel ohne Wellen, damit nur die gesetzten Gegner laufen. Dazu ein
    /// zäher Nachzügler am Weganfang, weit weg von jedem Wurf: Ohne lebende
    /// Gegner wäre die Mission gewonnen, und der Takt stünde still.
    private func game(enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies + [TestConfig.enemy(99, at: 0, hp: 1_000_000)]
        return state
    }

    private func rejection(in events: [Event]) -> Rejection? {
        for case .commandRejected(_, let reason) in events { return reason }
        return nil
    }

    @Test("Bereit ab Tick 0, danach erst nach der Abklingzeit wieder")
    func readyAndCooldown() {
        var state = game(enemies: [])
        let first = sim.step(&state, commands: [.useAbility(Point(x: 5, y: 0.5))])
        #expect(first.contains(.abilityCast(center: Point(x: 5, y: 0.5), impactTick: 15)))
        #expect(state.ability.readyTick == 300)

        while state.tick < 299 { sim.step(&state) }
        let early = sim.step(&state, commands: [.useAbility(Point(x: 5, y: 0.5))])
        #expect(rejection(in: early) == .abilityNotReady)

        let again = sim.step(&state, commands: [.useAbility(Point(x: 5, y: 0.5))])
        #expect(rejection(in: again) == nil)
        #expect(state.ability.readyTick == 600)
    }

    @Test("Einschlag genau nach der Verzögerung, nur im Kreis, gezählt beim Einschlag")
    func impactHitsWhoIsThereThen() {
        // Gegner 1 läuft in 15 Ticks einen halben Schritt nach vorn, in den
        // Kreis hinein; Gegner 2 steht beim Wurf drin und ist beim Einschlag
        // draußen; Gegner 3 bleibt draußen.
        var state = game(enemies: [
            TestConfig.enemy(1, at: 8.6),
            TestConfig.enemy(2, at: 10.6),
            TestConfig.enemy(3, at: 20),
        ])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        var impact: [Event] = []
        var impactTick = -1
        for _ in 0..<20 {
            let tick = state.tick
            let events = sim.step(&state)
            if events.contains(where: { if case .abilityImpact = $0 { true } else { false } }) {
                impact = events
                impactTick = tick
                break
            }
        }
        #expect(impactTick == 15)
        #expect(impact.contains(.abilityImpact(center: Point(x: 10, y: 0.5), hits: [1])))
        #expect(state.enemies.first { $0.id == 1 }?.hp == 60)
        #expect(state.enemies.first { $0.id == 2 }?.hp == 100)
        #expect(state.enemies.first { $0.id == 3 }?.hp == 100)
        #expect(state.ability.strike == nil)
    }

    @Test("Getroffene halten 30 Ticks an und laufen danach weiter")
    func stunHoldsAndEnds() {
        var state = game(enemies: [TestConfig.enemy(1, at: 10, hp: 1_000)])
        var config = AbilityTests.ability
        config.delay = 0
        let instant = Simulation(config: { var c = sim.config; c.ability = config; return c }())
        instant.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        let stopped = state.enemies[0].distance
        for _ in 1..<30 { instant.step(&state) }
        #expect(state.enemies[0].distance == stopped, "steht bis einschließlich Tick 29")
        instant.step(&state)
        #expect(state.enemies[0].distance > stopped, "läuft ab Tick 30")
        #expect(state.enemies[0].stunUntilTick == nil)
    }

    @Test("Anhalten stapelt nicht: Es gilt das spätere Ende")
    func stunDoesNotStack() {
        var enemy = TestConfig.enemy(1, at: 10, hp: 1_000)
        enemy.stunUntilTick = 100
        var state = game(enemies: [enemy])
        var config = AbilityTests.ability
        config.delay = 0
        let instant = Simulation(config: { var c = sim.config; c.ability = config; return c }())
        instant.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        #expect(state.enemies[0].stunUntilTick == 100, "kürzeres Ende verlängert nicht")

        state.enemies[0].stunUntilTick = 10
        state.ability.readyTick = 0
        instant.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        #expect(state.enemies[0].stunUntilTick == state.tick - 1 + 30, "späteres Ende gilt, nicht die Summe")
    }

    @Test("Neben dem Weg abgelehnt, nahe am Weg eingerastet, kostet nichts")
    func snapsToPath() {
        var state = game(enemies: [])
        let far = sim.step(&state, commands: [.useAbility(Point(x: 5, y: 1.6))])
        #expect(rejection(in: far) == .notOnPath)
        #expect(state.ability == AbilityState(), "ein abgelehnter Wurf kostet nichts")

        let near = sim.step(&state, commands: [.useAbility(Point(x: 5, y: 1.4))])
        #expect(near.contains(.abilityCast(center: Point(x: 5, y: 0.5), impactTick: 16)))
    }

    @Test("Ohne Fähigkeit in der Mission abgelehnt")
    func missingAbility() {
        let plain = Simulation(config: TestConfig.make())
        var state = plain.newGame(seed: 1)
        let events = plain.step(&state, commands: [.useAbility(Point(x: 5, y: 0.5))])
        #expect(rejection(in: events) == .noAbility)
    }

    @Test("Prüfung der Werte: positiv, Verzögerung unter der Abklingzeit")
    func validation() {
        var config = TestConfig.make()
        config.ability = AbilityConfig(radius: 0, damage: -1, delay: 10, stunDuration: 1,
                                       cooldown: 10, snapDistance: 1)
        let fields = config.issues().map(\.field)
        #expect(fields.contains("ability.radius"))
        #expect(fields.contains("ability.damage"))
        #expect(fields.contains("ability.delay"))
        config.ability = AbilityTests.ability
        #expect(config.issues().isEmpty)
    }

    @Test("Mission 1 hat den Steinregen und besteht die Prüfung")
    func missionOne() throws {
        let config = try BalanceConfig.missionOne()
        #expect(config.ability != nil)
        #expect(config.issues().isEmpty)
    }
}
