import CoreGraphics
import OddlingsCore

/// Wo die Karte auf dem Bildschirm liegt. Szene und Bedienoberfläche rechnen
/// beide damit: Zwei eigene Rechnungen würden um Pixel auseinanderlaufen, und
/// dann trifft der Finger die Nachbarzelle.
///
/// Koordinaten wie in SwiftUI: Ursprung links oben, y nach unten, wie die
/// Karte selbst. Die Szene dreht y erst beim Zeichnen (`scenePoint`).
struct BoardLayout: Equatable {
    let size: CGSize
    let field: CGFloat
    let origin: CGPoint
    let columns: Int
    let rows: Int

    init(size: CGSize, map: MissionMap) {
        self.size = size
        columns = map.width
        rows = map.height
        let width = CGFloat(map.width), height = CGFloat(map.height)
        field = max(0, min(size.width / width, size.height / height))
        origin = CGPoint(x: (size.width - field * width) / 2, y: (size.height - field * height) / 2)
    }

    func viewPoint(_ point: Point) -> CGPoint {
        CGPoint(x: origin.x + CGFloat(point.x) * field, y: origin.y + CGFloat(point.y) * field)
    }

    func scenePoint(_ point: Point) -> CGPoint {
        let view = viewPoint(point)
        return CGPoint(x: view.x, y: size.height - view.y)
    }

    /// Zelle unter einem Punkt der Ansicht, nil außerhalb der Karte.
    func cell(atView point: CGPoint) -> Cell? {
        guard field > 0 else { return nil }
        let x = Int(((point.x - origin.x) / field).rounded(.down))
        let y = Int(((point.y - origin.y) / field).rounded(.down))
        guard x >= 0, y >= 0, x < columns, y < rows else { return nil }
        return Cell(x: x, y: y)
    }

    func cell(atScene point: CGPoint) -> Cell? {
        cell(atView: CGPoint(x: point.x, y: size.height - point.y))
    }
}
