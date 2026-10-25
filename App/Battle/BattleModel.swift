import Foundation
import OddlingsCore

/// Verbindet Bildtakt und Simulationstakt. Die Szene fragt je Bild nach, wie
/// viele feste Schritte fällig sind; die Simulation weiß von Bildern nichts
/// (Architekturregel 5). 2× heißt doppelt so viele Schritte je Sekunde.
@MainActor
final class BattleModel {
    let sim: Simulation
    private(set) var state: GameState
    /// Zustand vor dem letzten Schritt. Zwischen beiden wird gezeichnet, damit
    /// Gegner bei 60 oder 120 Bildern/s gleiten statt im 30er-Takt zu springen.
    private(set) var previous: GameState
    var speed = 1
    /// Angehalten läuft keine Zeit auf; nach dem Fortsetzen geht es genau dort
    /// weiter, ohne nachzuholen.
    var paused = false
    /// Nur für die End-zu-End-Tests: lässt eine ganze Mission in Sekunden
    /// laufen, damit Sieg und Niederlage im Simulator prüfbar sind. Es sind
    /// weiter dieselben festen Schritte (Regel 5), nur mehr je Bild.
    var timeScale = 1.0
    var autoplay: Bool
    private var player: Autoplayer
    private let seed: UInt64
    private let tickDuration: TimeInterval
    private var accumulator: TimeInterval = 0
    /// Befehle aus der Bedienung, ausgeführt im nächsten Schritt. So kommt
    /// jede Eingabe an einer Taktgrenze an, egal wann der Finger tippt, und
    /// ein Spiel lässt sich aus den Befehlen genau wiederholen.
    private var pending: [Command] = []

    init(config: BalanceConfig, seed: UInt64, autoplay: Bool) {
        sim = Simulation(config: config)
        self.seed = seed
        self.autoplay = autoplay
        player = Autoplayer(demoOf: config)
        state = sim.newGame(seed: seed)
        previous = state
        tickDuration = 1 / Double(config.simulation.ticksPerSecond)
    }

    /// Anteil des nächsten Schritts, der schon vergangen ist, 0 bis 1.
    var interpolation: Double { min(1, accumulator / tickDuration) }

    /// Läuft um die Bildzeit weiter und gibt die Ereignisse aller fälligen
    /// Schritte in ihrer Reihenfolge zurück.
    func advance(by frameTime: TimeInterval) -> [Event] {
        // Nach einer Pause (App im Hintergrund, Haltepunkt) nicht minutenlang
        // nachholen: Das wäre ein Sprung, den niemand sehen will.
        guard !paused else { return [] }
        accumulator += min(frameTime, BattleStyle.maxCatchUp) * Double(speed) * timeScale
        var events: [Event] = []
        while accumulator >= tickDuration && !state.isOver {
            accumulator -= tickDuration
            events += step()
        }
        return events
    }

    func enqueue(_ command: Command) {
        pending.append(command)
    }

    /// Genau ein Schritt, für Tests und für `advance`.
    func step(commands extra: [Command] = []) -> [Event] {
        previous = state
        var commands = pending + extra
        pending = []
        if autoplay { commands += player.commands(for: state, in: sim) }
        return sim.step(&state, commands: commands)
    }

    func restart() {
        player = Autoplayer(demoOf: sim.config)
        state = sim.newGame(seed: seed)
        previous = state
        accumulator = 0
        pending = []
        paused = false
    }
}
