import Foundation

/// Einfacher Mitspieler für Vorführung und Oberflächentests (WP-11, WP-14):
/// baut, sobald das Gold reicht, den nächsten Turm seiner Liste auf die freie
/// Zelle mit der meisten Weglänge in Reichweite. Bewusst schlichter als der
/// Bot der Balancetests, der das Phase-0-Prüfskript nachbildet; dieser hier
/// soll nur zeigen, dass das Spiel läuft. Er schickt Befehle wie ein Mensch
/// und ändert den Zustand nie selbst (Architekturregel 2).
public struct Autoplayer: Sendable {
    public private(set) var order: [TowerKind]

    public init(order: [TowerKind]) { self.order = order }

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
        while let kind = order.first, let cost = sim.config.cost(of: kind), gold >= cost {
            // Eine Bank braucht keinen Weg in Reichweite: Sie kommt dorthin, wo
            // kein Kampfturm hinwill.
            let range = sim.config.towers[kind]?.range ?? 0
            guard let cell = bestCell(range: range, occupied: occupied, sim: sim, least: kind == .bank) else { break }
            order.removeFirst()
            gold -= cost
            occupied.append(cell)
            commands.append(.build(kind, cell))
        }
        return commands
    }

    /// Strikt größer: Bei Gleichstand gewinnt die erste Zelle in Kartenreihenfolge.
    /// `least` sucht die Zelle, die am wenigsten Weg abdeckt (für die Bank).
    private func bestCell(range: Double, occupied: [Cell], sim: Simulation, least: Bool = false) -> Cell? {
        var best: Cell?, bestValue = -Double.infinity
        let radius = least ? Self.bankProbe : range
        for cell in sim.map.buildableCells where !occupied.contains(cell) {
            let cover = sim.map.path.coverage(around: cell.center, radius: radius)
            let value = least ? -cover : cover
            if value > bestValue {
                best = cell
                bestValue = value
            }
        }
        return best
    }
}
