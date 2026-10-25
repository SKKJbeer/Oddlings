import Foundation

/// Der feste Weg als Polylinie. Gegner speichern nur ihre zurückgelegte Strecke
/// (`distance`), die Position wird hier daraus berechnet: So können Fortschritt
/// und Position nie auseinanderlaufen (data-models.md).
public struct PathGeometry: Equatable, Sendable {
    public let points: [Point]
    public let length: Double
    /// Weglänge bis zum Anfang jedes Abschnitts; gleiche Zählung wie `points`.
    private let startDistances: [Double]

    public init(points: [Point]) {
        precondition(points.count >= 2, "Weg braucht zwei Punkte; BalanceConfig.validate prüft das vorher")
        self.points = points
        var starts: [Double] = []
        var total = 0.0
        for index in points.indices.dropLast() {
            starts.append(total)
            total += points[index].distance(to: points[index + 1])
        }
        startDistances = starts
        length = total
    }

    /// Position nach `distance` Feldern. Außerhalb von 0…length wird an Anfang
    /// oder Ende festgehalten, damit ein Gegner im Durchbruchs-Tick nicht ins
    /// Nichts gezeichnet wird.
    public func position(at distance: Double) -> Point {
        if distance <= 0 { return points[0] }
        if distance >= length { return points[points.count - 1] }
        // Lineare Suche: acht Punkte in Mission 1, eine Suche je Gegner und Tick.
        var segment = startDistances.count - 1
        for index in startDistances.indices.dropFirst() where distance < startDistances[index] {
            segment = index - 1
            break
        }
        let a = points[segment], b = points[segment + 1]
        let segmentLength = a.distance(to: b)
        let t = segmentLength > 0 ? (distance - startDistances[segment]) / segmentLength : 0
        return Point(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    /// Kürzester Abstand eines Punkts zum Weg.
    public func distance(from point: Point) -> Double {
        var best = Double.infinity
        for index in points.indices.dropLast() {
            best = min(best, point.distance(toSegment: points[index], points[index + 1]))
        }
        return best
    }
}

extension Point {
    public func distance(to other: Point) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }

    func distance(toSegment a: Point, _ b: Point) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y
        let lengthSquared = dx * dx + dy * dy
        guard lengthSquared > 0 else { return distance(to: a) }
        let t = min(1, max(0, ((x - a.x) * dx + (y - a.y) * dy) / lengthSquared))
        return distance(to: Point(x: a.x + dx * t, y: a.y + dy * t))
    }
}
