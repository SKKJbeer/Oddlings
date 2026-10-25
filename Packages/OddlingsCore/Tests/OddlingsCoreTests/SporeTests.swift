import Testing
@testable import OddlingsCore

@Suite("Sporenturm")
struct SporeTests {
    let sim = Simulation(config: TestConfig.make())
    var stats: TowerConfig { sim.config.towers[.spore]! }

    /// Leeres Spiel ohne Wellen, damit nur die gesetzten Gegner laufen.
    private func game(towers: [Cell], enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: towers.map { .build(.spore, $0) })
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies
        return state
    }

    /// Ticks, bis der Gegner von `start` aus `end` erreicht. Gedeckelt, damit
    /// ein Fehler den Test rot macht statt ihn hängen zu lassen.
    private func ticksThrough(towers: [Cell], from start: Double, to end: Double) -> Int {
        var state = game(towers: towers, enemies: [TestConfig.enemy(1, at: start, hp: 1_000_000)])
        var count = 0
        while state.enemies[0].distance < end && count < 10_000 {
            sim.step(&state)
            count += 1
        }
        return count
    }

    @Test("Plünderer unter Dauerverlangsamung braucht doppelt so lang durch die Zone")
    func twiceAsLong() {
        // Turm bei x = 10,5, zwei Felder neben dem Weg: Zone etwa 8,3 bis 12,7.
        let free = ticksThrough(towers: [], from: 9, to: 12)
        let slowed = ticksThrough(towers: [Cell(x: 10, y: 2)], from: 9, to: 12)
        // ± 1 Tick, weil sich 1/30 in Double nicht exakt aufsummiert.
        #expect((90...91).contains(free))
        #expect((179...182).contains(slowed))
    }

    @Test("Zwei Sporentürme verlangsamen nicht stärker als einer")
    func noStacking() {
        let one = ticksThrough(towers: [Cell(x: 10, y: 2)], from: 9, to: 12)
        let two = ticksThrough(towers: [Cell(x: 10, y: 2), Cell(x: 11, y: 2)], from: 9, to: 12)
        #expect(one == two)
    }

    @Test("Verlangsamung endet nach 1,5 s = 45 Ticks")
    func expires() {
        var state = game(towers: [Cell(x: 10, y: 2)], enemies: [TestConfig.enemy(1, at: 9, hp: 1_000_000)])
        sim.step(&state)
        sim.step(&state, commands: [.sell(towerID: 1)])
        for _ in 2..<45 { sim.step(&state) }
        let slowSpeed = 0.5 / 30
        #expect(abs(state.enemies[0].distance - (9 + 45 * slowSpeed)) < 1e-9)
        #expect(state.enemies[0].slow != nil)
        sim.step(&state)
        #expect(abs(state.enemies[0].distance - (9 + 45 * slowSpeed + 1.0 / 30)) < 1e-9)
        #expect(state.enemies[0].slow == nil)
    }

    @Test("Ein neuer Puls erneuert die Dauer")
    func renews() {
        var enemy = TestConfig.enemy(1, at: 0)
        sim.applySlow(to: &enemy, stats: stats, tick: 0)
        sim.applySlow(to: &enemy, stats: stats, tick: 30)
        #expect(enemy.slow == SlowEffect(factor: 0.5, untilTick: 75))
    }

    @Test("Die stärkste aktive Verlangsamung gilt, eine schwächere ersetzt sie nicht")
    func strongestWins() {
        var weak = stats
        weak.slowFactor = 0.8
        var enemy = TestConfig.enemy(1, at: 0)
        sim.applySlow(to: &enemy, stats: stats, tick: 0)
        sim.applySlow(to: &enemy, stats: weak, tick: 10)
        #expect(enemy.slow?.factor == 0.5)
        // Abgelaufen zählt nicht mehr: dann gilt der neue, schwächere Wert.
        sim.applySlow(to: &enemy, stats: weak, tick: 200)
        #expect(enemy.slow == SlowEffect(factor: 0.8, untilTick: 245))
    }

    @Test("Puls trifft alle Lebenden in Reichweite, sonst niemanden")
    func pulseHitsAllInRange() {
        var state = game(towers: [Cell(x: 10, y: 2)], enemies: [
            TestConfig.enemy(1, at: 9), TestConfig.enemy(2, at: 12),
            TestConfig.enemy(3, at: 20), TestConfig.enemy(4, at: 10, hp: 0),
        ])
        let events = sim.step(&state)
        #expect(events.first == .towerFired(towerID: 1, targets: [1, 2]))
        #expect(events.filter { if case .enemySlowed = $0 { true } else { false } }
                == [.enemySlowed(id: 1), .enemySlowed(id: 2)])
        #expect(state.enemies.map(\.hp) == [99, 99, 100])
        #expect(state.enemies.map { $0.slow != nil } == [true, true, false])
    }

    @Test("Ohne Gegner in Reichweite bleibt der Sporenturm bereit")
    func staysReady() {
        var state = game(towers: [Cell(x: 10, y: 2)], enemies: [TestConfig.enemy(1, at: 30)])
        for _ in 0..<5 { sim.step(&state) }
        #expect(state.towers[0].cooldownTicks == 0)
    }
}
