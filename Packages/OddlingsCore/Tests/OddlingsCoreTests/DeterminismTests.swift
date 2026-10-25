import Foundation
import Testing
@testable import OddlingsCore

@Suite("Determinismus")
struct DeterminismTests {
    let sim: Simulation

    init() throws { sim = Simulation(config: try BalanceConfig.missionOne()) }

    /// Spielt ein Protokoll nach, bis die Mission endet oder `stop` erreicht ist.
    private func replay(_ log: [(tick: Int, commands: [Command])], on state: inout GameState,
                        with sim: Simulation, until stop: Int = 200_000) {
        var next = log.firstIndex { $0.tick >= state.tick } ?? log.count
        while !state.isOver && state.tick < stop {
            var commands: [Command] = []
            if next < log.count && log[next].tick == state.tick {
                commands = log[next].commands
                next += 1
            }
            sim.step(&state, commands: commands)
        }
    }

    @Test("Replay einer ganzen Mission ergibt denselben Endzustand und dieselbe Prüfsumme")
    func replayMatches() throws {
        let order = try #require(Strategies.missionOne().first { $0.name.hasPrefix("Mix") }).order
        let original = sim.play(order)
        #expect(original.state.outcome == .won)
        var copy = sim.newGame(seed: 1)
        replay(original.log, on: &copy, with: sim)
        #expect(copy == original.state)
        #expect(copy.checksum == original.state.checksum)
    }

    @Test("Speichern und Laden mitten in der Welle, mit Türmen und Verlangsamung")
    func saveLoadMidWave() throws {
        let order = try #require(Strategies.missionOne().first { $0.name.hasPrefix("Mix") }).order
        let original = sim.play(order)
        var state = sim.newGame(seed: 1)
        replay(original.log, on: &state, with: sim, until: 5_000)
        #expect(state.enemies.contains { $0.slow != nil })
        #expect(state.towers.count > 5)
        var loaded = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        #expect(loaded == state)
        replay(original.log, on: &loaded, with: sim)
        #expect(loaded == original.state)
    }

    @Test("1× = 2×: zwei Schritte je Bild ergeben dasselbe wie einer")
    func doubleSpeed() throws {
        let order = try #require(Strategies.missionOne().first { $0.name.hasPrefix("Mix") }).order
        let log = sim.play(order).log
        var single = sim.newGame(seed: 1)
        replay(log, on: &single, with: sim)
        // Die Darstellung bei 2× ruft `step` zweimal je Bild; Befehle hängen am
        // Tick, an dem sie ankommen, nicht am Bild.
        var double = sim.newGame(seed: 1)
        var next = 0
        while !double.isOver && double.tick < 200_000 {
            for _ in 0..<2 where !double.isOver {
                var commands: [Command] = []
                if next < log.count && log[next].tick == double.tick {
                    commands = log[next].commands
                    next += 1
                }
                sim.step(&double, commands: commands)
            }
        }
        #expect(double == single)
    }

    @Test("Prüfsumme ändert sich mit jedem Feld")
    func checksumSensitive() {
        let state = sim.newGame(seed: 1)
        var changed = state
        changed.gold += 1
        #expect(changed.checksum != state.checksum)
        changed = state
        changed.rng = SplitMix64(seed: 2)
        #expect(changed.checksum != state.checksum)
        changed = state
        changed.nextWaveTick = nil
        #expect(changed.checksum != state.checksum)
    }

    @Test("Feste Prüfsumme einer kleinen Mission, gleich auf Linux und macOS")
    func goldenChecksum() {
        var config = TestConfig.make()
        let wave = WaveConfig(hpScale: 1.2, groups: [
            SpawnGroup(enemy: .raider, count: 6, interval: 0.7),
            SpawnGroup(enemy: .runner, count: 4, interval: 0.5, delay: 1),
        ])
        config.waves = [wave, wave, wave]
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 42)
        sim.step(&state, commands: [
            .build(.watch, Cell(x: 8, y: 2)), .build(.lightning, Cell(x: 14, y: 2)),
            .build(.spore, Cell(x: 11, y: 2)), .build(.watch, Cell(x: 20, y: 2)),
        ])
        var guardTicks = 0
        while !state.isOver && guardTicks < 100_000 {
            sim.step(&state, commands: state.tick == 400 ? [.callNextWave] : [])
            guardTicks += 1
        }
        #expect(state.isOver)
        // Ändert sich dieser Wert, hat sich eine Regel geändert oder die Simulation
        // ist nicht mehr bitgleich. Beides ist ein Befund, kein Grund zum Anpassen.
        #expect(state.checksum == 4_506_832_313_563_992_051)
    }
}
