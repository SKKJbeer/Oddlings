import Foundation
import Testing
@testable import OddlingsCore

@Suite("Wellen, Bewegung, Festung")
struct WaveTests {
    let sim: Simulation

    init() throws { sim = Simulation(config: try BalanceConfig.missionOne()) }

    /// Läuft, bis `stop` zutrifft oder die Mission endet; liefert alle Ereignisse mit Tick.
    /// Jede Schleife hier hat eine Obergrenze: Ein Regelfehler soll rot werden, nicht hängen.
    private func run(_ state: inout GameState, maxTicks: Int = 100_000,
                     until stop: (GameState) -> Bool = { _ in false }) -> [(tick: Int, event: Event)] {
        var log: [(Int, Event)] = []
        while !state.isOver && !stop(state) && state.tick < maxTicks {
            let tick = state.tick
            for event in sim.step(&state) { log.append((tick, event)) }
        }
        return log
    }

    @Test("Neues Spiel hat Startwerte aus der Konfiguration")
    func newGame() {
        let state = sim.newGame(seed: 1)
        #expect(state.gold == 150)
        #expect(state.fortressLives == 20)
        #expect(state.waveIndex == -1)
        #expect(state.nextWaveTick == 600)
    }

    @Test("Aufbauzeit: erste Welle beginnt nach 20 s = Tick 600")
    func firstWaveAfterSetup() {
        var state = sim.newGame(seed: 1)
        let log = run(&state) { $0.waveIndex >= 0 }
        #expect(log.first?.tick == 600)
        #expect(log.first?.event == .waveStarted(index: 0))
        #expect(log.dropFirst().first?.event == .enemySpawned(id: 1))
    }

    @Test("Plünderer braucht 32 s ± 1 Tick")
    func raiderCrossesInThirtyTwoSeconds() {
        var state = sim.newGame(seed: 1)
        let log = run(&state) { state in state.fortressLives < 20 }
        let spawn = log.first { $0.event == .enemySpawned(id: 1) }!.tick
        let leak = log.first { $0.event == .enemyLeaked(id: 1, damage: 1) }!.tick
        #expect(abs((leak - spawn + 1) - 32 * 30) <= 1)
    }

    @Test("Abstand der Gegner in Welle 1 ist 1,6 s = 48 Ticks")
    func spawnInterval() {
        var state = sim.newGame(seed: 1)
        let log = run(&state) { $0.tick > 600 + 8 * 48 }
        let spawns = log.filter { if case .enemySpawned = $0.event { true } else { false } }.map(\.tick)
        #expect(spawns == (0..<8).map { 600 + $0 * 48 })
    }

    @Test("Nächste Welle 15 s nach dem letzten Erscheinen, nicht nach dem letzten Tod")
    func waveCadence() {
        var state = sim.newGame(seed: 1)
        let log = run(&state) { $0.waveIndex >= 1 }
        let second = log.first { $0.event == .waveStarted(index: 1) }!.tick
        #expect(second == 600 + 7 * 48 + 15 * 30)
    }

    @Test("Ohne Türme: Niederlage exakt beim 20. Durchbruch, zur berechenbaren Zeit")
    func defeatWithoutTowers() {
        var state = sim.newGame(seed: 1)
        let log = run(&state)
        let leaks = log.filter { if case .enemyLeaked = $0.event { true } else { false } }
        #expect(leaks.count == 20)
        #expect(state.outcome == .lost)
        #expect(state.fortressLives == 0)
        #expect(log.last?.event == .missionEnded(won: false))
        #expect(log.last?.tick == leaks.last?.tick)
        // Von Hand nachgerechnet: Welle 1 bringt 8 Durchbrüche. Welle 2 beginnt bei
        // Tick 1386, Plünderer alle 39 Ticks, je 960 Ticks unterwegs. Welle 3 beginnt
        // bei 2265, Flitzer alle 30 Ticks, je 437 Ticks unterwegs – sie überholen die
        // letzten Plünderer. Bis Tick 2731: 8 + 10 Plünderer + 2 Flitzer = 20.
        let expected = 2265 + 437 - 1 + 30
        #expect(abs(log.last!.tick - expected) <= 1)
    }

    @Test("Nach dem Ende passiert nichts mehr")
    func nothingAfterEnd() {
        var state = sim.newGame(seed: 1)
        _ = run(&state)
        let frozen = state
        #expect(sim.step(&state).isEmpty)
        #expect(state == frozen)
    }

    @Test("Durchbruch mit mehr Schaden als Leben endet bei 0, nicht darunter")
    func livesNeverNegative() throws {
        var config = try BalanceConfig.missionOne()
        config.mission.fortressLives = 2
        config.waves = [WaveConfig(hpScale: 1, groups: [SpawnGroup(enemy: .brute, count: 1, interval: 1)])]
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        while !state.isOver && state.tick < 100_000 { sim.step(&state) }
        #expect(state.fortressLives == 0)
        #expect(state.outcome == .lost)
    }

    @Test("Gegner im selben Tick wie der Todesstoß zählen nicht mehr")
    func endsImmediately() throws {
        var config = try BalanceConfig.missionOne()
        config.mission.fortressLives = 1
        config.waves = [WaveConfig(hpScale: 1, groups: [
            SpawnGroup(enemy: .raider, count: 1, interval: 1),
            SpawnGroup(enemy: .raider, count: 1, interval: 1),
        ])]
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        var leaks = 0
        while !state.isOver && state.tick < 100_000 {
            leaks += sim.step(&state).filter { if case .enemyLeaked = $0 { true } else { false } }.count
        }
        #expect(leaks == 1)
        #expect(state.enemies.count == 1)
    }

    @Test("hpScale erhöht die Lebenspunkte")
    func hpScale() throws {
        // Genug Leben, damit Welle 4 (hpScale 1,1) erreicht wird; ohne Türme
        // endet Mission 1 sonst schon in Welle 3.
        var config = try BalanceConfig.missionOne()
        config.mission.fortressLives = 1000
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        while (state.enemies.last.map({ $0.id <= 30 }) ?? true) && state.tick < 100_000 { sim.step(&state) }
        let first = try #require(state.enemies.last)
        #expect(first.kind == .raider)
        #expect(first.maxHP == 70 * 1.1)
        #expect(first.hp == first.maxHP)
    }

    @Test("Zustand übersteht Speichern und Laden mitten in der Welle")
    func codableMidWave() throws {
        var state = sim.newGame(seed: 7)
        _ = run(&state) { $0.tick == 700 }
        let data = try JSONEncoder().encode(state)
        var loaded = try JSONDecoder().decode(GameState.self, from: data)
        #expect(loaded == state)
        _ = run(&state)
        _ = run(&loaded)
        #expect(loaded == state)
    }
}

@Suite("Zufall")
struct RandomTests {
    @Test("SplitMix64 ist bitgleich reproduzierbar")
    func reproducible() {
        var a = SplitMix64(seed: 42), b = SplitMix64(seed: 42)
        #expect((0..<5).map { _ in a.next() } == (0..<5).map { _ in b.next() })
    }

    @Test("Bekannter erster Wert für Seed 0")
    func knownValue() {
        // Referenzwert der Originalbeschreibung von SplitMix64.
        var rng = SplitMix64(seed: 0)
        #expect(rng.next() == 0xE220_A839_7B1D_CDAF)
    }
}
