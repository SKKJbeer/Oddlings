import Testing
@testable import OddlingsCore

@Suite("Sieg, Wellentakt, „Nächste Welle“")
struct VictoryTests {
    /// Zwei Wellen mit je einem Plünderer, 10 s Takt, Aufbauzeit 0.
    private func twoWaves() -> Simulation {
        var config = TestConfig.make()
        config.waves = [config.waves[0], config.waves[0]]
        return Simulation(config: config)
    }

    private func endings(_ events: [Event]) -> [Event] {
        events.filter { if case .missionEnded = $0 { true } else { false } }
    }

    /// Läuft, bis alle Wellen erschienen sind. Gedeckelt gegen Hänger.
    private func runUntilAllSpawned(_ sim: Simulation, _ state: inout GameState) {
        var guardTicks = 0
        while (state.nextWaveTick != nil || !state.pendingSpawns.isEmpty) && guardTicks < 10_000 {
            sim.step(&state)
            guardTicks += 1
        }
    }

    @Test("Sieg erst, wenn der letzte Gegner tot ist")
    func victoryAfterLastKill() {
        let sim = twoWaves()
        var state = sim.newGame(seed: 1)
        runUntilAllSpawned(sim, &state)
        #expect(state.enemies.count == 2)
        state.enemies[1].hp = 0
        #expect(endings(sim.step(&state)).isEmpty)
        #expect(state.outcome == nil)
        state.enemies[0].hp = 0
        let events = sim.step(&state)
        #expect(endings(events) == [.missionEnded(won: true)])
        #expect(state.outcome == .won)
        #expect(sim.step(&state).isEmpty)
    }

    @Test("Kein Sieg, solange noch eine Welle aussteht, auch wenn das Feld leer ist")
    func noVictoryBeforeLastWave() {
        let sim = twoWaves()
        var state = sim.newGame(seed: 1)
        sim.step(&state)
        #expect(state.waveIndex == 0)
        state.enemies[0].hp = 0
        #expect(endings(sim.step(&state)).isEmpty)
        #expect(state.outcome == nil)
    }

    @Test("Letzter Gegner bricht durch, Festung hält: Sieg im selben Tick")
    func lastLeakStillWins() {
        let sim = twoWaves()
        var state = sim.newGame(seed: 1)
        runUntilAllSpawned(sim, &state)
        state.enemies = [TestConfig.enemy(99, at: 39.99)]
        let events = sim.step(&state)
        #expect(events.contains(.enemyLeaked(id: 99, damage: 1)))
        #expect(endings(events) == [.missionEnded(won: true)])
        #expect(state.fortressLives == 9)
    }

    @Test("Letzter Gegner leert die Festung: Niederlage, kein Sieg")
    func lastLeakLoses() {
        let sim = twoWaves()
        var state = sim.newGame(seed: 1)
        runUntilAllSpawned(sim, &state)
        state.fortressLives = 1
        state.enemies = [TestConfig.enemy(99, at: 39.99)]
        let events = sim.step(&state)
        #expect(endings(events) == [.missionEnded(won: false)])
        #expect(state.outcome == .lost)
    }

    @Test("„Nächste Welle“ in der Aufbauzeit startet Welle 1 sofort und verschiebt den Plan")
    func callDuringSetup() throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        var state = sim.newGame(seed: 1)
        for _ in 0..<100 { sim.step(&state) }
        let events = sim.step(&state, commands: [.callNextWave])
        #expect(events.contains(.waveStarted(index: 0)))
        // Welle 1: 8 Plünderer im Abstand 1,6 s, danach 15 s Takt.
        #expect(state.nextWaveTick == 100 + 7 * 48 + 450)
    }

    @Test("„Nächste Welle“ mitten in einer Welle: Wellen überlappen")
    func callOverlaps() throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.callNextWave])
        for _ in 0..<60 { sim.step(&state) }
        let before = state.pendingSpawns.count
        let events = sim.step(&state, commands: [.callNextWave])
        #expect(events.contains(.waveStarted(index: 1)))
        #expect(state.waveIndex == 1)
        #expect(state.pendingSpawns.count > before)
        #expect(!state.enemies.isEmpty)
    }

    @Test("„Nächste Welle“ nach der letzten Welle wird abgelehnt")
    func callAfterLastWave() {
        let sim = twoWaves()
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.callNextWave])
        // Zwei Rufe im selben Tick starten nur eine Welle: Befehle laufen vor dem Wellenstart.
        let events = sim.step(&state, commands: [.callNextWave, .callNextWave])
        #expect(events.filter { if case .waveStarted = $0 { true } else { false } } == [.waveStarted(index: 1)])
        #expect(sim.step(&state, commands: [.callNextWave]).first == .commandRejected(.callNextWave, reason: .noWaveLeft))
    }

    @Test("Mission endet genau einmal mit genau einem Ergebnis", arguments: [UInt64(1), 2, 3, 4, 5])
    func endsExactlyOnce(seed: UInt64) throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        var state = sim.newGame(seed: seed)
        var rng = SplitMix64(seed: seed)
        let cells = sim.map.buildableCells
        var all: [Event] = []
        var guardTicks = 0
        while guardTicks < 50_000 {
            var commands: [Command] = []
            switch rng.next() % 200 {
            case 0: commands = [.build(.watch, cells[Int(rng.next() % UInt64(cells.count))])]
            case 1: commands = [.build(.lightning, cells[Int(rng.next() % UInt64(cells.count))])]
            case 2: commands = [.callNextWave]
            default: break
            }
            all += sim.step(&state, commands: commands)
            guardTicks += 1
            if state.isOver { break }
        }
        for _ in 0..<100 { all += sim.step(&state) }
        #expect(state.isOver)
        #expect(endings(all).count == 1)
        #expect(endings(all) == [.missionEnded(won: state.outcome == .won)])
    }
}
