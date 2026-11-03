import Foundation
import OddlingsCore

extension LabConfig {
    /// Die Datei aus dem Paket. Ist sie kaputt, gibt es kein Labor: Ein Lauf mit
    /// erfundenen Ersatzwerten sähe gültig aus und wäre es nicht.
    public static let standard: LabConfig = {
        do { return try bundled() } catch { fatalError("labor.json: \(error)") }
    }()
}

/// Bauweisen aus `simStrategies` der Missionsdatei. Die Simulation kennt das
/// Feld nicht: Es ist Prüfwerkzeug, keine Spielregel.
public enum Strategies {
    /// Nach Namen sortiert, weil ein Dictionary keine Reihenfolge hat.
    public static func missionOne() throws -> [(name: String, order: [StrategyStep])] {
        try of(BalanceConfig.missionOne())
    }

    public static func of(_ config: BalanceConfig) -> [(name: String, order: [StrategyStep])] {
        let strategies = config.simStrategies ?? [:]
        return strategies.keys.sorted().map { ($0, strategies[$0]!) }
    }
}

/// Eine zu Ende gespielte Mission mit dem, was das Labor misst.
public struct BotRun: Sendable {
    public var state: GameState
    public var leaks = 0
    /// Durchbrüche je Welle, ab Welle 1 gezählt.
    public var leaksPerWave: [Int] = []
    /// Befehle je Tick, für den Replay-Test.
    public var log: [(tick: Int, commands: [Command])] = []
    /// Verletzte Invarianten, je eine Zeile; leer, wenn alles hielt.
    public var violations: [String] = []
    /// Je Turmart, wie oft sie gebaut wurde.
    public var built: [TowerKind: Int] = [:]
}

extension Simulation {
    /// Spielt eine Mission mit dem gierigen Bot zu Ende. Gedeckelt, damit ein
    /// Fehler den Test rot macht statt ihn hängen zu lassen.
    public func play(_ order: [StrategyStep], seed: UInt64 = 1, until stopTick: Int = 200_000,
                     castsAbility: Bool = false, lab: LabConfig = .standard) -> BotRun {
        var bot = LabBot(sim: self, order: order, profile: .greedy(castsAbility: castsAbility), weights: lab.greedy)
        return play(&bot, seed: seed, until: stopTick)
    }

    /// Spielt mit einem beliebigen Bot und prüft nach jedem Tick die Invarianten.
    public func play(_ bot: inout LabBot, seed: UInt64 = 1, until stopTick: Int = 200_000) -> BotRun {
        var run = BotRun(state: newGame(seed: seed))
        var ended = 0
        while !run.state.isOver && run.state.tick < stopTick {
            let commands = bot.commands(for: run.state)
            if !commands.isEmpty { run.log.append((run.state.tick, commands)) }
            let wave = max(0, run.state.waveIndex)
            for event in step(&run.state, commands: commands) {
                switch event {
                case .enemyLeaked:
                    run.leaks += 1
                    while run.leaksPerWave.count <= wave { run.leaksPerWave.append(0) }
                    run.leaksPerWave[wave] += 1
                case .towerBuilt(let id):
                    if let kind = run.state.towers.first(where: { $0.id == id })?.kind { run.built[kind, default: 0] += 1 }
                case .missionEnded:
                    ended += 1
                default: break
                }
            }
            run.violations += Self.invariantViolations(in: run.state)
            if !run.violations.isEmpty { break }
        }
        if run.state.isOver && ended != 1 { run.violations.append("Mission endete \(ended)-mal") }
        return run
    }

    /// Was in keinem Zustand vorkommen darf (K11, Stresstests).
    static func invariantViolations(in state: GameState) -> [String] {
        var found: [String] = []
        if state.gold < 0 { found.append("Tick \(state.tick): Gold \(state.gold)") }
        if state.fortressLives < 0 { found.append("Tick \(state.tick): Leben \(state.fortressLives)") }
        let cells = state.towers.map(\.cell)
        for (index, cell) in cells.enumerated() where cells[..<index].contains(cell) {
            found.append("Tick \(state.tick): zwei Türme auf \(cell.x),\(cell.y)")
        }
        return found
    }

    /// Größter Faktor auf das Leben aller Gegner, bei dem die Bauweise noch
    /// gewinnt. Gleiche Suche wie im Prüfskript, Grenzen aus `labor.json`.
    public func reserve(_ order: [StrategyStep], castsAbility: Bool = false, lab: LabConfig = .standard) -> Double {
        func wins(_ factor: Double) -> Bool {
            var scaled = config
            for kind in EnemyKind.allCases { scaled.enemies[kind]?.hp *= factor }
            return Simulation(config: scaled).play(order, castsAbility: castsAbility, lab: lab).state.outcome == .won
        }
        var lo = lab.reserve.low, hi = lab.reserve.high
        guard wins(lo) else { return 0 }
        for _ in 0..<lab.reserve.halvings {
            let mid = (lo + hi) / 2
            if wins(mid) { lo = mid } else { hi = mid }
        }
        return lo
    }
}
