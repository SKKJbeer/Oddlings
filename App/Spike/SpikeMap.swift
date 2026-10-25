import Foundation

/// Nur der Kartenteil der Balancedatei. Der Spike braucht keine Türme und
/// Gegnerwerte; die vollständige Konfiguration entsteht mit WP-02 in
/// OddlingsCore.
struct SpikeMap: Decodable {
    let width: Double
    let height: Double
    let path: [[Double]]

    private struct File: Decodable { let map: SpikeMap }

    static func loadMissionOne() -> SpikeMap {
        guard let url = Bundle.main.url(forResource: "mvp-mission-01", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data) else {
            // Ein fehlender Kartenstand ist ein Baufehler, kein Laufzeitfall.
            fatalError("mvp-mission-01.json fehlt im App-Paket oder ist unlesbar")
        }
        return file.map
    }

    var points: [CGPoint] { path.map { CGPoint(x: $0[0], y: $0[1]) } }
}

/// Weg als Polylinie in Feldern, abgefragt über die zurückgelegte Strecke –
/// so, wie die Simulation es später auch tun wird (data-models.md).
struct SpikePath {
    let points: [CGPoint]
    let segmentStarts: [Double]
    let length: Double

    init(points: [CGPoint]) {
        self.points = points
        var starts: [Double] = []
        var total = 0.0
        for i in 0..<(points.count - 1) {
            starts.append(total)
            total += Double(hypot(points[i + 1].x - points[i].x, points[i + 1].y - points[i].y))
        }
        segmentStarts = starts
        length = total
    }

    func position(at distance: Double) -> CGPoint {
        let d = min(max(distance, 0), length)
        var i = segmentStarts.count - 1
        while i > 0 && segmentStarts[i] > d { i -= 1 }
        let a = points[i], b = points[i + 1]
        let segLength = Double(hypot(b.x - a.x, b.y - a.y))
        let t = CGFloat(segLength > 0 ? (d - segmentStarts[i]) / segLength : 0)
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}
