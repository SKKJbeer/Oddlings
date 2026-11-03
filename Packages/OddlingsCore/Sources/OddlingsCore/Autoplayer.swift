import Foundation

/// Einfacher Mitspieler für Vorführung und Oberflächentests (WP-11, WP-14):
/// baut, sobald das Gold reicht, den nächsten Turm seiner Liste auf die freie
/// Zelle mit der meisten Weglänge in Reichweite. Bewusst schlichter als der
/// Bot der Balancetests, der das Phase-0-Prüfskript nachbildet; dieser hier
/// soll nur zeigen, dass das Spiel läuft. Er schickt Befehle wie ein Mensch
/// und ändert den Zustand nie selbst (Architekturregel 2).
public struct Autoplayer: Sendable {
    public private(set) var order: [StrategyStep]

    public init(order: [StrategyStep]) { self.order = order }

    /// Ein Kampfturm reicht etwa so weit; so weit vom Weg weg steht die Bank
    /// niemandem im Weg. Bedienung des Mitspielers, kein Balancewert.
    static let bankProbe = 2.5

    /// Die Vorführbauweise aus der Konfiguration, leer, wenn keine angegeben ist.
    public init(demoOf config: BalanceConfig) {
        order = config.demoStrategy.flatMap { config.simStrategies?[$0] } ?? []
    }

    public mutating func commands(for state: GameState, in sim: Simulation) -> [Command] {
        guard !state.isOver else { return [] }
        var gold = state.gold
        var occupied = state.towers.map(\.cell)
        var commands: [Command] = []
        var upgraded: [Int] = []
        while let step = order.first {
            let kind = step.kind
            if case .specialize(let specialization) = step {
                // Der älteste Turm der Art auf Stufe 2 ohne Spezialisierung (P3-1);
                // gibt es keinen, wartet der Schritt auf eine Aufwertung im selben
                // Zug oder entfällt.
                guard let tower = state.towers.first(where: {
                    $0.kind == kind && $0.level == 2 && $0.specialization == nil && !upgraded.contains($0.id)
                }), let cost = sim.config.specializations?[specialization]?.cost else {
                    if commands.contains(where: {
                        if case .build(kind, _) = $0 { true } else if case .upgrade = $0 { true } else { false }
                    }) { break }
                    order.removeFirst()
                    continue
                }
                guard gold >= cost else { break }
                order.removeFirst()
                gold -= cost
                upgraded.append(tower.id)
                commands.append(.specialize(towerID: tower.id, specialization))
                continue
            }
            if case .upgrade = step {
                // Der älteste Turm der Art auf Stufe 1. Wird er gerade erst gebaut,
                // wartet der Schritt bis zum nächsten Tick; gibt es keinen, entfällt
                // er, damit die Liste nicht hängen bleibt.
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
            // Eine Bank braucht keinen Weg in Reichweite: Sie kommt dorthin, wo
            // kein Kampfturm hinwill.
            let range = sim.config.towers[kind]?.range ?? 0
            guard let cell = bestCell(range: range, occupied: occupied, sim: sim, least: kind == .bank) else { break }
            order.removeFirst()
            gold -= cost
            occupied.append(cell)
            commands.append(.build(kind, cell))
        }
        // Gegen Panzerung richtet der Mitspieler aufgewertete Wachtürme auf die
        // zähesten Ziele (P2-10), wie der Balance-Bot; sonst bleibt alles beim Alten.
        if sim.config.hasArmoredEnemies {
            for tower in state.towers where tower.kind == .watch && tower.level == 2 && tower.targetMode != .strongest {
                commands.append(.setTargetMode(towerID: tower.id, .strongest))
            }
        }
        return commands
    }

    /// `least` sucht die Zelle, die am wenigsten Weg abdeckt (für die Bank).
    private func bestCell(range: Double, occupied: [Cell], sim: Simulation, least: Bool = false) -> Cell? {
        sim.map.bestCell(radius: least ? Self.bankProbe : range, excluding: occupied, least: least)
    }
}
