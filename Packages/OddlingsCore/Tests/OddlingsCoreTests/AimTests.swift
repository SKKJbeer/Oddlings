import Testing
@testable import OddlingsCore

/// Abfragen für die Darstellung zielender Türme (A-5 Teil 3, D-186, D-187):
/// `aim` nennt die Ziele des nächsten Schusses, `charge` die Ladung. Beide
/// ändern nichts am Zustand.
@Suite("Zielen und Laden (Anzeige)")
struct AimTests {
    let sim: Simulation
    let cell = Cell(x: 5, y: 2)

    init() {
        var config = TestConfig.make()
        config.upgrades = UpgradeTests.upgrades
        config.specializations = SpecializationTests.specializations
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    private func standing(_ kind: TowerKind) -> GameState {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(kind, cell)])
        return state
    }

    /// Ziele des nächsten Schusses aus dem Ereignis eines Schritts.
    private func fired(_ state: inout GameState) -> [Int]? {
        for event in sim.step(&state) {
            if case .towerFired(_, let targets) = event { return targets }
        }
        return nil
    }

    @Test("Wachturm zielt auf genau das Ziel seines nächsten Schusses, je Zielwahl",
          arguments: [TargetMode.first, .last, .strongest])
    func watchAimMatchesShot(mode: TargetMode) {
        var state = standing(.watch)
        state.towers[0].targetMode = mode
        state.enemies = [TestConfig.enemy(7, at: 4), TestConfig.enemy(8, at: 6.5, hp: 300),
                         TestConfig.enemy(9, at: 5.2)]
        state.towers[0].cooldownTicks = 0
        let aimed = sim.aim(of: state.towers[0], in: state)
        #expect(aimed.count == 1)
        #expect(fired(&state) == aimed)
    }

    @Test("Salve: zwei Ziele in der Reihenfolge des Schusses")
    func volleyAimsAtTwo() {
        var state = standing(.watch)
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        sim.step(&state, commands: [.specialize(towerID: 1, .volley)])
        state.enemies = [TestConfig.enemy(7, at: 4), TestConfig.enemy(8, at: 6), TestConfig.enemy(9, at: 5)]
        state.towers[0].cooldownTicks = 0
        let aimed = sim.aim(of: state.towers[0], in: state)
        #expect(aimed == [8, 9])
        #expect(fired(&state) == aimed)
    }

    @Test("Ohne Gegner in Reichweite zielt kein Turm, die Bank nie")
    func nothingInRange() {
        var state = standing(.watch)
        state.enemies = [TestConfig.enemy(7, at: 30)]
        #expect(sim.aim(of: state.towers[0], in: state).isEmpty)
        state.towers[0].kind = .bank
        #expect(sim.aim(of: state.towers[0], in: state).isEmpty)
    }

    @Test("Blitzturm zielt auf das erste Glied seiner Kette")
    func lightningAimsAtFirstLink() {
        var state = standing(.lightning)
        state.enemies = [TestConfig.enemy(7, at: 4), TestConfig.enemy(8, at: 6)]
        state.towers[0].cooldownTicks = 0
        let aimed = sim.aim(of: state.towers[0], in: state)
        #expect(aimed == [8])
        #expect(fired(&state)?.first == aimed.first)
    }

    @Test("Ladung: 0 direkt nach dem Schuss, wächst mit dem Takt, 1 bereit")
    func chargeFollowsCooldown() {
        var state = standing(.lightning)
        #expect(sim.charge(of: state.towers[0]) == 1, "frisch gebaut ist er bereit")
        state.enemies = [TestConfig.enemy(7, at: 5)]
        _ = fired(&state)
        let interval = sim.ticks(sim.config.stats(of: state.towers[0])!.attackInterval)
        #expect(state.towers[0].cooldownTicks == interval)
        #expect(sim.charge(of: state.towers[0]) == 0)
        state.towers[0].cooldownTicks = interval / 2
        #expect(abs(sim.charge(of: state.towers[0]) - 0.5) < 0.05)
    }

    @Test("Abfragen ändern den Zustand nicht")
    func queriesArePure() {
        var state = standing(.watch)
        state.enemies = [TestConfig.enemy(7, at: 4), TestConfig.enemy(8, at: 6)]
        let before = state
        _ = sim.aim(of: state.towers[0], in: state)
        _ = sim.charge(of: state.towers[0])
        #expect(state == before)
        #expect(state.checksum == before.checksum)
    }
}
