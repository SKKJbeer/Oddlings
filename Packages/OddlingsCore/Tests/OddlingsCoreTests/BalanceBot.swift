import Foundation
@testable import OddlingsCore

/// Bauweisen aus `simStrategies` der Missionsdatei. Die Simulation kennt das
/// Feld nicht: Es ist Prüfwerkzeug, keine Spielregel.
enum Strategies {
    /// Nach Namen sortiert, weil ein Dictionary keine Reihenfolge hat.
    static func missionOne() throws -> [(name: String, order: [TowerKind])] {
        let strategies = try BalanceConfig.missionOne().simStrategies ?? [:]
        return strategies.keys.sorted().map { ($0, strategies[$0]!) }
    }
}

/// Bot aus dem Phase-0-Prüfskript, nach Swift übertragen (WP-10): baut, sobald
/// das Gold reicht, den nächsten Turm seiner Liste auf den Platz mit der größten
/// Wegabdeckung. Sporen dorthin, wo viele Angriffstürme denselben Weg abdecken,
/// Blitze in die Nähe von Sporen. Die Gewichte sind die des Skripts.
struct BalanceBot {
    let sim: Simulation
    var order: [TowerKind]
    /// Wirft den Steinregen, sobald er bereit ist und mindestens zwei Gegner
    /// zusammenstehen (03: „Bot wirft auf die dichteste Stelle").
    var castsAbility = false
    private let candidates: [Cell]
    private let samples: [Point]

    init(sim: Simulation, order: [TowerKind]) {
        self.sim = sim
        self.order = order
        candidates = sim.map.buildableCells.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var points: [Point] = []
        var d = 0.0
        while d < sim.map.path.length {
            points.append(sim.map.path.position(at: d))
            d += 0.25
        }
        samples = points
    }

    mutating func commands(for state: GameState) -> [Command] {
        var gold = state.gold
        var placed = state.towers.map { (kind: $0.kind, cell: $0.cell) }
        var commands: [Command] = []
        while let kind = order.first, let stats = sim.config.towers[kind], gold >= stats.cost {
            order.removeFirst()
            guard let cell = bestCell(for: kind, stats: stats, placed: placed) else { break }
            gold -= stats.cost
            placed.append((kind, cell))
            commands.append(.build(kind, cell))
        }
        if castsAbility, let target = densestPoint(in: state) { commands.append(.useAbility(target)) }
        return commands
    }

    /// Die Gegnerposition mit den meisten Nachbarn im Wirkkreis, ohne
    /// vorauszuzielen: Der Bot soll eine Untergrenze messen, keinen Meister.
    private func densestPoint(in state: GameState) -> Point? {
        guard let ability = sim.config.ability, state.tick >= state.ability.readyTick else { return nil }
        let points = state.enemies.filter { $0.hp > 0 }.map { sim.map.path.position(at: $0.distance) }
        var best: Point?, bestCount = 1
        for p in points {
            let count = points.filter { $0.distance(to: p) <= ability.radius }.count
            if count > bestCount {
                best = p
                bestCount = count
            }
        }
        return best
    }

    private func bestCell(for kind: TowerKind, stats: TowerConfig, placed: [(kind: TowerKind, cell: Cell)]) -> Cell? {
        var best: Cell?, bestValue = -1.0
        for cell in candidates where !placed.contains(where: { $0.cell == cell }) {
            let p = cell.center
            var value = 0.0
            if kind == .spore {
                for q in samples where q.distance(to: p) <= stats.range + 0.5 {
                    let shooters = placed.filter { other in
                        other.kind != .spore && q.distance(to: other.cell.center) <= sim.config.towers[other.kind]!.range
                    }.count
                    value += 0.25 * Double(1 + shooters)
                }
            } else {
                value = 0.25 * Double(samples.filter { $0.distance(to: p) <= stats.range }.count)
            }
            if kind == .lightning {
                value += 1.5 * Double(placed.filter { $0.kind == .spore && p.distance(to: $0.cell.center) < 2.5 }.count)
            }
            if value > bestValue {
                best = cell
                bestValue = value
            }
        }
        return best
    }
}

struct BotRun {
    var state: GameState
    var leaks = 0
    /// Befehle je Tick, für den Replay-Test.
    var log: [(tick: Int, commands: [Command])] = []
}

extension Simulation {
    /// Spielt eine Mission mit dem Bot zu Ende. Gedeckelt, damit ein Fehler
    /// den Test rot macht statt ihn hängen zu lassen.
    func play(_ order: [TowerKind], seed: UInt64 = 1, until stopTick: Int = 200_000,
              castsAbility: Bool = false) -> BotRun {
        var bot = BalanceBot(sim: self, order: order)
        bot.castsAbility = castsAbility
        var run = BotRun(state: newGame(seed: seed))
        while !run.state.isOver && run.state.tick < stopTick {
            let commands = bot.commands(for: run.state)
            if !commands.isEmpty { run.log.append((run.state.tick, commands)) }
            for event in step(&run.state, commands: commands) {
                if case .enemyLeaked = event { run.leaks += 1 }
            }
        }
        return run
    }

    /// Größter Faktor auf das Leben aller Gegner, bei dem die Bauweise noch
    /// gewinnt. Gleiche Suche wie im Prüfskript: 0,5 bis 4, neun Halbierungen.
    func reserve(_ order: [TowerKind], castsAbility: Bool = false) -> Double {
        func wins(_ factor: Double) -> Bool {
            var scaled = config
            for kind in EnemyKind.allCases { scaled.enemies[kind]?.hp *= factor }
            return Simulation(config: scaled).play(order, castsAbility: castsAbility).state.outcome == .won
        }
        var lo = 0.5, hi = 4.0
        guard wins(lo) else { return 0 }
        for _ in 0..<9 {
            let mid = (lo + hi) / 2
            if wins(mid) { lo = mid } else { hi = mid }
        }
        return lo
    }
}
