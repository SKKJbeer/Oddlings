import Foundation
import OddlingsCore

/// Bot des Labors (P2-6b). Der gierige Bot stammt aus dem Phase-0-Prüfskript
/// (WP-10) und lag bis 0.21.0 in den Tests; jetzt gibt es ihn genau einmal, und
/// der Menschenbot ist derselbe Bot mit Zögern, Streuung und später Fähigkeit.
/// Er schickt Befehle wie ein Spieler und ändert den Zustand nie selbst
/// (Architekturregel 2). Zufall nur aus seinem eigenen gesäten Generator (Regel 6).
public struct LabBot: Sendable {
    /// Wie der Bot handelt. `greedy` misst eine Obergrenze, `human` eine Annahme
    /// über Menschen.
    public struct Profile: Equatable, Sendable {
        public var reactionTicks = 0
        public var placementSpread = 1
        public var abilityDelayTicks = 0
        public var castsAbility = false

        public static func greedy(castsAbility: Bool) -> Profile { Profile(castsAbility: castsAbility) }

        public static func human(_ traits: LabConfig.HumanTraits, castsAbility: Bool) -> Profile {
            Profile(reactionTicks: traits.reactionTicks, placementSpread: traits.placementSpread,
                    abilityDelayTicks: traits.abilityDelayTicks, castsAbility: castsAbility)
        }
    }

    public let sim: Simulation
    public private(set) var order: [StrategyStep]
    public let profile: Profile
    private let weights: LabConfig.GreedyWeights
    private var rng: SplitMix64
    private var nextActionTick = 0
    private let candidates: [Cell]
    private let samples: [Point]

    public init(sim: Simulation, order: [StrategyStep], profile: Profile, weights: LabConfig.GreedyWeights,
                seed: UInt64 = 0) {
        self.sim = sim
        self.order = order
        self.profile = profile
        self.weights = weights
        rng = SplitMix64(seed: seed)
        candidates = sim.map.buildableCells.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var points: [Point] = []
        var d = 0.0
        while d < sim.map.path.length {
            points.append(sim.map.path.position(at: d))
            d += weights.sampleStep
        }
        samples = points
    }

    public mutating func commands(for state: GameState) -> [Command] {
        // Ein Mensch handelt nicht in jedem Tick; dazwischen sieht er nur zu.
        guard state.tick >= nextActionTick else { return [] }
        var gold = state.gold
        var placed = state.towers.map { (kind: $0.kind, cell: $0.cell) }
        var commands: [Command] = []
        var upgraded: [Int] = []
        while let step = order.first {
            let kind = step.kind
            if case .upgrade = step {
                // Wie der Mitspieler der App: der älteste Turm der Art auf Stufe 1.
                // Steht er erst im Bau, wartet der Schritt einen Tick.
                guard let tower = state.towers.first(where: {
                    $0.kind == kind && $0.level < sim.config.maxLevel(of: kind) && !upgraded.contains($0.id)
                }), let cost = sim.config.upgradeCost(of: kind) else {
                    if commands.contains(where: { if case .build(kind, _) = $0 { true } else { false } }) { break }
                    order.removeFirst()
                    continue
                }
                guard gold >= cost else { break }
                order.removeFirst()
                gold -= cost
                upgraded.append(tower.id)
                commands.append(.upgrade(towerID: tower.id))
                continue
            }
            guard let cost = sim.config.cost(of: kind), gold >= cost else { break }
            order.removeFirst()
            let ranked = kind == .bank ? quietCells(placed: placed)
                : sim.config.towers[kind].map { rankedCells(for: kind, stats: $0, placed: placed) } ?? []
            guard let cell = pick(ranked) else { break }
            gold -= cost
            placed.append((kind, cell))
            commands.append(.build(kind, cell))
        }
        // Gegen Panzerung richtet der Bot aufgewertete Wachtürme auf die
        // zähesten Ziele (P2-10); ohne gepanzerte Gegner bleibt alles, wie es war.
        if sim.config.hasArmoredEnemies {
            for tower in state.towers where tower.kind == .watch && tower.level == 2 && tower.targetMode != .strongest {
                commands.append(.setTargetMode(towerID: tower.id, .strongest))
            }
        }
        if profile.castsAbility, let target = abilityTarget(in: state) { commands.append(.useAbility(target)) }
        if !commands.isEmpty { nextActionTick = state.tick + profile.reactionTicks }
        return commands
    }

    /// Der beste Platz, beim Menschen einer der `placementSpread` besten.
    private mutating func pick(_ ranked: [Cell]) -> Cell? {
        guard !ranked.isEmpty else { return nil }
        let spread = min(profile.placementSpread, ranked.count)
        return spread <= 1 ? ranked[0] : ranked[Int(rng.next() % UInt64(spread))]
    }

    private func abilityTarget(in state: GameState) -> Point? {
        guard let ability = sim.config.ability,
              state.tick >= state.ability.readyTick + profile.abilityDelayTicks else { return nil }
        switch ability.kind {
        case .stoneRain, .moonMark: return densestPoint(in: state, radius: ability.radius ?? 0)
        case .bulwark: return wallPoint(in: state)
        }
    }

    /// Der Wegpunkt mit den meisten Türmen in Reichweite, vor dem mindestens
    /// zwei Gegner heranlaufen. Bei Gleichstand der frühere Punkt.
    private func wallPoint(in state: GameState) -> Point? {
        let distances = state.enemies.filter { $0.hp > 0 }.map(\.distance)
        var best: Point?, bestCover = 0
        for (index, p) in samples.enumerated() {
            let d = Double(index) * weights.sampleStep
            guard distances.filter({ $0 <= d && $0 > d - weights.wallApproach }).count >= 2 else { continue }
            let cover = state.towers.filter { tower in
                tower.kind != .spore && tower.kind != .bank && p.distance(to: tower.cell.center) <= sim.config.stats(of: tower)!.range
            }.count
            if cover > bestCover {
                best = p
                bestCover = cover
            }
        }
        return best
    }

    /// Die Gegnerposition mit den meisten Nachbarn im Wirkkreis, ohne
    /// vorauszuzielen: Der Bot soll eine Untergrenze messen, keinen Meister.
    private func densestPoint(in state: GameState, radius: Double) -> Point? {
        let points = state.enemies.filter { $0.hp > 0 }.map { sim.map.path.position(at: $0.distance) }
        var best: Point?, bestCount = 1
        for p in points {
            let count = points.filter { $0.distance(to: p) <= radius }.count
            if count > bestCount {
                best = p
                bestCount = count
            }
        }
        return best
    }

    /// Die Bank dorthin, wo am wenigsten Weg in Reichweite eines Turms läge.
    private func quietCells(placed: [(kind: TowerKind, cell: Cell)]) -> [Cell] {
        let free = candidates.filter { cell in !placed.contains { $0.cell == cell } }
        let values = free.map { cell in -Double(samples.filter { $0.distance(to: cell.center) <= weights.bankProbe }.count) }
        return Self.ranked(free, values)
    }

    private func rankedCells(for kind: TowerKind, stats: TowerConfig, placed: [(kind: TowerKind, cell: Cell)]) -> [Cell] {
        let free = candidates.filter { cell in !placed.contains { $0.cell == cell } }
        let values = free.map { cell -> Double in
            let p = cell.center
            var value = 0.0
            if kind == .spore {
                for q in samples where q.distance(to: p) <= stats.range + weights.sporeReach {
                    let shooters = placed.filter { other in
                        other.kind != .spore && other.kind != .bank && q.distance(to: other.cell.center) <= sim.config.towers[other.kind]!.range
                    }.count
                    value += weights.coverWeight * Double(1 + shooters)
                }
            } else {
                value = weights.coverWeight * Double(samples.filter { $0.distance(to: p) <= stats.range }.count)
            }
            if kind == .lightning {
                value += weights.lightningNearSpore
                    * Double(placed.filter { $0.kind == .spore && p.distance(to: $0.cell.center) < weights.sporeNeighbourhood }.count)
            }
            return value
        }
        return Self.ranked(free, values)
    }

    /// Bester Wert zuerst; bei Gleichstand die frühere Zelle in Kartenreihenfolge,
    /// wie im Prüfskript („strikt größer gewinnt“).
    static func ranked(_ cells: [Cell], _ values: [Double]) -> [Cell] {
        cells.indices.sorted { values[$0] != values[$1] ? values[$0] > values[$1] : $0 < $1 }.map { cells[$0] }
    }
}
