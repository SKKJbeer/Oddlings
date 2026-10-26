import Testing
@testable import OddlingsCore

@Suite("Bollwerk")
struct BulwarkTests {
    /// Eigene Werte (testing-strategy.md, Regel 4): Mauer 60 Ticks, Abklingzeit 300.
    static let ability = AbilityConfig(kind: .bulwark, cooldown: 10, snapDistance: 1, duration: 2)
    let sim: Simulation = {
        var config = TestConfig.make()
        config.ability = BulwarkTests.ability
        return Simulation(config: config)
    }()

    /// Wie beim Steinregen: ohne Wellen, mit einem zähen Nachzügler am
    /// Weganfang, damit die Mission nicht gewonnen ist und der Takt weiterläuft.
    private func game(enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies + [TestConfig.enemy(99, at: 0, hp: 1_000_000)]
        return state
    }

    private func enemy(_ id: Int, in state: GameState) -> Enemy? { state.enemies.first { $0.id == id } }

    @Test("Steht sofort an der eingerasteten Stelle, gemessen als Wegstrecke")
    func raisedAtOnce() {
        var state = game(enemies: [])
        let events = sim.step(&state, commands: [.useAbility(Point(x: 10, y: 1.2))])
        #expect(events.contains(.abilityCast(center: Point(x: 10, y: 0.5), impactTick: 0)))
        #expect(events.contains(.barrierRaised(distance: 10, untilTick: 60)))
        #expect(state.ability.barrier == Barrier(distance: 10, untilTick: 60))
        #expect(state.ability.readyTick == 300)
        #expect(state.ability.strike == nil, "kein Einschlag, die Mauer wirkt durch Dastehen")
    }

    @Test("Wer davor ist, staut sich an der Mauer; wer dahinter ist, läuft weiter")
    func holdsThoseBefore() {
        var state = game(enemies: [
            TestConfig.enemy(1, at: 9.0),
            TestConfig.enemy(2, at: 9.5),
            TestConfig.enemy(3, at: 10.5),
        ])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        for _ in 1..<60 { sim.step(&state) }
        #expect(enemy(1, in: state)?.distance == 10, "bis an die Mauer, nicht weiter")
        #expect(enemy(2, in: state)?.distance == 10, "beide stehen an derselben Stelle")
        #expect((enemy(3, in: state)?.distance ?? 0) > 12, "hinter der Mauer ungebremst")
    }

    @Test("Fällt nach der Dauer, dann läuft der Stau weiter")
    func falls() {
        var state = game(enemies: [TestConfig.enemy(1, at: 9.5)])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        for _ in 1..<60 { sim.step(&state) }
        #expect(state.ability.barrier != nil, "steht bis einschließlich Tick 59")
        let events = sim.step(&state)
        #expect(events.contains(.barrierFell))
        #expect(state.ability.barrier == nil)
        #expect((enemy(1, in: state)?.distance ?? 0) > 10, "läuft ab Tick 60")
    }

    @Test("Eine Mauer zur Zeit: Die neue ersetzt die alte")
    func oneAtATime() {
        var state = game(enemies: [])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        state.ability.readyTick = state.tick
        sim.step(&state, commands: [.useAbility(Point(x: 20, y: 0.5))])
        #expect(state.ability.barrier?.distance == 20)
    }

    @Test("Prüfung: Dauer nötig, positiv und nicht länger als die Abklingzeit")
    func validation() {
        var config = TestConfig.make()
        config.ability = AbilityConfig(kind: .bulwark, cooldown: 10, snapDistance: 1)
        #expect(config.issues() == [ConfigIssue(field: "ability.duration", rule: .missingAbilityValue)])
        config.ability?.duration = 11
        #expect(config.issues() == [ConfigIssue(field: "ability.duration", rule: .durationAboveCooldown)])
        config.ability?.duration = 0
        #expect(config.issues() == [ConfigIssue(field: "ability.duration", rule: .mustBePositive)])
        config.ability = BulwarkTests.ability
        #expect(config.issues().isEmpty)
    }
}
