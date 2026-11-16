import OddlingsCore

/// Die Stücke des Wegs, die ein Turm von seinem Platz aus sieht (A-2, D-156).
/// Die Szene lässt sie beim Bauen und Aufwerten leuchten: Was zählt, ist der
/// Weg im Kreis, nicht die Wiese darum.
///
/// Dieselbe exakte Rechnung wie `PathGeometry.coverage` (Schnitt von Strecke
/// und Kreis), nur dass sie die Stücke liefert statt ihrer Länge. Aneinander
/// grenzende Stücke über eine Ecke hinweg werden zu einem Zug verbunden, damit
/// die Linie an der Ecke nicht abreißt.
enum PathCoverage {
    static func pieces(of path: PathGeometry, around center: Point, radius: Double) -> [[Point]] {
        var pieces: [[Point]] = []
        var open = false
        for index in path.points.indices.dropLast() {
            let a = path.points[index], b = path.points[index + 1]
            let dx = b.x - a.x, dy = b.y - a.y
            let fx = a.x - center.x, fy = a.y - center.y
            let dd = dx * dx + dy * dy
            let half = fx * dx + fy * dy
            let disc = half * half - dd * (fx * fx + fy * fy - radius * radius)
            guard dd > 0, disc > 0 else {
                open = false
                continue
            }
            let root = disc.squareRoot()
            let t1 = max(0, (-half - root) / dd), t2 = min(1, (-half + root) / dd)
            guard t2 > t1 else {
                open = false
                continue
            }
            let from = Point(x: a.x + dx * t1, y: a.y + dy * t1)
            let to = Point(x: a.x + dx * t2, y: a.y + dy * t2)
            if open, t1 == 0 {
                pieces[pieces.count - 1].append(to)
            } else {
                pieces.append([from, to])
            }
            open = t2 == 1
        }
        return pieces
    }

    /// Gesamtlänge der Stücke; gleich `PathGeometry.coverage` (Test).
    static func length(of pieces: [[Point]]) -> Double {
        pieces.reduce(0) { total, piece in
            total + zip(piece, piece.dropFirst()).reduce(0) { $0 + $1.0.distance(to: $1.1) }
        }
    }
}
