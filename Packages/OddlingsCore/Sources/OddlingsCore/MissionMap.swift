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
/// die Karte selbst unterscheidet die übrigen Fälle.
public enum Placement: Equatable, Sendable {
    case free
    case occupied
    case tooCloseToPath
    /// Landschaft zwischen den Bauinseln (D-141): Wald, Wasser, Fels.
    case outsideZone
    case outsideMap
}

/// Geometrie einer Mission: Weg und Bauzonen. Bauplatz ist jede Zelle, deren
/// Mitte mindestens `minDistanceFromPath` vom Weg entfernt liegt (D-005) und,
/// wenn die Mission Bauinseln hat (D-141), in einer Insel liegt. Der Abstand
/// gilt auch innerhalb der Inseln: Ändert sich der Weg, kann eine Insel nie
/// unbemerkt auf ihm liegen.
public struct MissionMap: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let path: PathGeometry
    /// Zeilenweise sortiert (y, dann x), damit jede Iteration dieselbe Reihenfolge hat.
    public let buildableCells: [Cell]
    /// Bauinseln in der Reihenfolge der Datei; leer bei Missionen ohne Inseln.
    public let zones: [BuildZone]
    private let buildable: [Bool]
    private let distanceOK: [Bool]
    /// Index in `zones` je Zelle, -1 außerhalb; ein Feld statt einer Tabelle,
    /// weil die Simulation nie über Tabellen läuft.
    private let zoneIndex: [Int]

    public init(config: MapConfig) {
        width = config.width
        height = config.height
        path = PathGeometry(points: config.path)
        zones = config.zones ?? []
        var index = [Int](repeating: -1, count: max(0, config.width * config.height))
        for (i, zone) in zones.enumerated() {
            for cell in zone.cells where cell.x >= 0 && cell.y >= 0 && cell.x < config.width && cell.y < config.height
                && index[cell.y * config.width + cell.x] < 0 {
                // Erste Insel gewinnt; Überschneidungen weist die Prüfung beim Laden ab.
                index[cell.y * config.width + cell.x] = i
            }
        }
        var flags: [Bool] = [], distance: [Bool] = []
        var cells: [Cell] = []
        for y in 0..<config.height {
            for x in 0..<config.width {
                let cell = Cell(x: x, y: y)
                let far = path.distance(from: cell.center) >= config.minDistanceFromPath
                let ok = far && (config.zones == nil || index[y * config.width + x] >= 0)
                distance.append(far)
                flags.append(ok)
                if ok { cells.append(cell) }
            }
        }
        zoneIndex = index
        distanceOK = distance
        buildable = flags
        buildableCells = cells
    }

    /// Bauinsel, in der die Zelle liegt; nil außerhalb und bei Missionen ohne Inseln.
    public func zone(of cell: Cell) -> BuildZone? {
        guard contains(cell) else { return nil }
        let i = zoneIndex[cell.y * width + cell.x]
        return i >= 0 ? zones[i] : nil
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
        guard distanceOK[cell.y * width + cell.x] else { return .tooCloseToPath }
        guard isBuildable(cell) else { return .outsideZone }
        return occupied.contains(cell) ? .occupied : .free
    }

    /// Freie Bauzelle, von der ein Kreis mit `radius` am meisten Weg abdeckt;
    /// `least` sucht die mit dem wenigsten. Strikt besser ersetzt, also gewinnt
    /// bei Gleichstand die erste Zelle in Kartenreihenfolge. Eine Stelle für
    /// den Mitspieler und die Hand des Einstiegs (P2-8), damit beide dieselbe
    /// Zelle meinen.
    public func bestCell(radius: Double, excluding occupied: [Cell], least: Bool = false) -> Cell? {
        var best: Cell?, bestValue = -Double.infinity
        for cell in buildableCells where !occupied.contains(cell) {
            let cover = path.coverage(around: cell.center, radius: radius)
            let value = least ? -cover : cover
            if value > bestValue {
                best = cell
                bestValue = value
            }
        }
        return best
    }
}
