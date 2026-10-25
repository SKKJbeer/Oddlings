import Foundation

/// Eine Rasterzelle. (0, 0) ist links oben, wie in der Konfiguration.
public struct Cell: Codable, Hashable, Sendable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    public var center: Point { Point(x: Double(x) + 0.5, y: Double(y) + 0.5) }
}

/// Was an einer Zelle möglich ist. `occupied` kennt nur, wer die Türme kennt;
/// die Karte selbst unterscheidet die drei übrigen Fälle.
public enum Placement: Equatable, Sendable {
    case free
    case occupied
    case tooCloseToPath
    case outsideMap
}

/// Geometrie einer Mission: Weg und Bauzonen. Bauzone ist jede Zelle, deren
/// Mitte mindestens `minDistanceFromPath` vom Weg entfernt liegt (D-005). Die
/// Zonen werden aus Weg und Abstand berechnet statt einzeln gelistet: Ändert
/// sich der Weg, stimmen sie von selbst.
public struct MissionMap: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let path: PathGeometry
    /// Zeilenweise sortiert (y, dann x), damit jede Iteration dieselbe Reihenfolge hat.
    public let buildableCells: [Cell]
    private let buildable: [Bool]

    public init(config: MapConfig) {
        width = config.width
        height = config.height
        path = PathGeometry(points: config.path)
        var flags: [Bool] = []
        var cells: [Cell] = []
        for y in 0..<config.height {
            for x in 0..<config.width {
                let cell = Cell(x: x, y: y)
                let ok = path.distance(from: cell.center) >= config.minDistanceFromPath
                flags.append(ok)
                if ok { cells.append(cell) }
            }
        }
        buildable = flags
        buildableCells = cells
    }

    public func contains(_ cell: Cell) -> Bool {
        cell.x >= 0 && cell.y >= 0 && cell.x < width && cell.y < height
    }

    public func isBuildable(_ cell: Cell) -> Bool {
        contains(cell) && buildable[cell.y * width + cell.x]
    }

    /// `occupied` ist die Liste der belegten Zellen (aus den Türmen des Zustands);
    /// eine Liste statt einer Menge, weil die Simulation nie über Mengen läuft.
    public func placement(of cell: Cell, occupied: [Cell]) -> Placement {
        guard contains(cell) else { return .outsideMap }
        guard isBuildable(cell) else { return .tooCloseToPath }
        return occupied.contains(cell) ? .occupied : .free
    }
}
