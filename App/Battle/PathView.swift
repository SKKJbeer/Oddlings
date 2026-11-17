import Foundation
import OddlingsCore

/// Ein Punkt des gezeichneten Wegs: wo, in welche Richtung, wie stark gekrümmt.
/// Längen in Feldern, y nach unten wie in der Karte.
struct PathSample: Equatable {
    var position: Point
    /// Laufrichtung als Einheitsvektor.
    var dx: Double
    var dy: Double
    /// Vorzeichenbehaftet, 1/Radius im Bogen, 0 auf der Geraden. Positiv heißt
    /// Drehung von +x nach +y, auf dem Bildschirm also im Uhrzeigersinn.
    var curvature: Double

    /// Seitlich versetzt um `lane` Felder (positiv nach links der Laufrichtung
    /// in Kartenkoordinaten). Im Bogen liegt der Versatz auf dem Radius, die
    /// Innenspur ist dadurch kürzer, wie bei echten Läufern.
    func offset(by lane: Double) -> Point {
        Point(x: position.x - dy * lane, y: position.y + dx * lane)
    }
}

/// Der Weg, wie er gezeichnet wird (A-1, D-144): Über jede Ecke legt er einen
/// Kreisbogen. Die Simulation rechnet weiter auf der Linie aus Strecken
/// (`PathGeometry`); hier wird ihre Strecke nur auf den Bogen abgebildet.
///
/// Gleiche Strecke: Das Fenster `[D − t, D + t]` um eine Ecke bei Strecke D wird
/// anteilig auf den Bogen gelegt, außerhalb sind Bild und Regel deckungsgleich.
/// Eine Figur läuft so nie vor oder hinter ihrer Regelposition her und stirbt
/// an derselben Stelle (docs/konzepte/a-1-laufen.md).
struct PathView {
    private struct Corner {
        /// Simulationsstrecke bis zur Ecke und halbe Fensterbreite.
        let distance: Double
        let half: Double
        let center: Point
        /// Vom Mittelpunkt zum Anfang des Bogens.
        let startX: Double, startY: Double
        /// Richtung vor der Ecke.
        let inX: Double, inY: Double
        /// Gesamtdrehung, vorzeichenbehaftet.
        let sweep: Double
        let curvature: Double
    }

    let points: [Point]
    let length: Double
    let radius: Double
    private let starts: [Double]
    private let corners: [Corner]

    /// Ecken, die schärfer als fast eine Umkehr sind, bleiben Knick: Dort gäbe
    /// es keinen Bogen, der zwischen beide Strecken passt.
    private static let largestTurn = Double.pi * 0.99

    init(points: [Point], radius: Double) {
        precondition(points.count >= 2, "Weg braucht zwei Punkte; BalanceConfig.validate prüft das vorher")
        self.points = points
        self.radius = radius
        var starts: [Double] = []
        var total = 0.0
        for index in points.indices.dropLast() {
            starts.append(total)
            total += points[index].distance(to: points[index + 1])
        }
        self.starts = starts
        length = total

        var corners: [Corner] = []
        if radius > 0 {
            for index in points.indices.dropFirst().dropLast() {
                let a = points[index - 1], p = points[index], b = points[index + 1]
                let lengthIn = a.distance(to: p), lengthOut = p.distance(to: b)
                guard lengthIn > 0, lengthOut > 0 else { continue }
                let ux = (p.x - a.x) / lengthIn, uy = (p.y - a.y) / lengthIn
                let vx = (b.x - p.x) / lengthOut, vy = (b.y - p.y) / lengthOut
                let cross = ux * vy - uy * vx
                let turn = acos(max(-1, min(1, ux * vx + uy * vy)))
                guard turn > 1e-6, turn < Self.largestTurn else { continue }
                let side: Double = cross >= 0 ? 1 : -1
                // Halbe Strecke als Grenze, damit sich zwei Bögen nie überlappen.
                let tangent = min(radius * tan(turn / 2), lengthIn / 2, lengthOut / 2)
                let bend = tangent / tan(turn / 2)
                let startPoint = Point(x: p.x - ux * tangent, y: p.y - uy * tangent)
                // Mittelpunkt liegt auf der Seite, zu der sich der Weg dreht.
                let center = Point(x: startPoint.x - uy * bend * side, y: startPoint.y + ux * bend * side)
                corners.append(Corner(
                    distance: starts[index], half: tangent, center: center,
                    startX: startPoint.x - center.x, startY: startPoint.y - center.y,
                    inX: ux, inY: uy, sweep: turn * side, curvature: side / bend))
            }
        }
        self.corners = corners
    }

    init(path: PathGeometry, radius: Double) {
        self.init(points: path.points, radius: radius)
    }

    /// Ort, Richtung und Krümmung nach `distance` Feldern Simulationsstrecke.
    func sample(at distance: Double) -> PathSample {
        let d = min(max(distance, 0), length)
        for corner in corners where abs(d - corner.distance) < corner.half {
            let fraction = (d - (corner.distance - corner.half)) / (2 * corner.half)
            let angle = corner.sweep * fraction
            let c = cos(angle), s = sin(angle)
            let position = Point(x: corner.center.x + corner.startX * c - corner.startY * s,
                                 y: corner.center.y + corner.startX * s + corner.startY * c)
            return PathSample(position: position, dx: corner.inX * c - corner.inY * s,
                              dy: corner.inX * s + corner.inY * c, curvature: corner.curvature)
        }
        // Gerade: wie die Simulation, damit Bild und Regel dort genau übereinstimmen.
        var segment = starts.count - 1
        for index in starts.indices.dropFirst() where d < starts[index] {
            segment = index - 1
            break
        }
        let a = points[segment], b = points[segment + 1]
        let segmentLength = a.distance(to: b)
        guard segmentLength > 0 else { return PathSample(position: a, dx: 1, dy: 0, curvature: 0) }
        let t = (d - starts[segment]) / segmentLength
        return PathSample(position: Point(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t),
                          dx: (b.x - a.x) / segmentLength, dy: (b.y - a.y) / segmentLength, curvature: 0)
    }

    /// Wie `sample`, mit seitlicher Spur.
    func position(at distance: Double, lane: Double) -> Point {
        sample(at: distance).offset(by: lane)
    }
}
