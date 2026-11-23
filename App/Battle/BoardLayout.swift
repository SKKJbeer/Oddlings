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

    /// `top`: Rand oben, in den das Raster nicht rechnet. Dort liegt der gemalte
    /// Überstand des Kampfplatzes unter den Schildern der Kopfleiste (D-180).
    init(size: CGSize, map: MissionMap, top: CGFloat = 0) {
        self.size = size
        columns = map.width
        rows = map.height
        let width = CGFloat(map.width), height = CGFloat(map.height)
        let free = max(0, size.height - top)
        field = max(0, min(size.width / width, free / height))
        origin = CGPoint(x: (size.width - field * width) / 2, y: top + (free - field * height) / 2)
    }

    /// Die Karte einer Mission: Szene, Kreismenü und Tests rechnen hiermit, damit
    /// der Rand unter der Kopfleiste an genau einer Stelle steht.
    @MainActor
    static func battle(size: CGSize, map: MissionMap) -> BoardLayout {
        BoardLayout(size: size, map: map, top: BattleStyle.boardTop)
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

    /// Feldpunkt unter einem Punkt der Ansicht, auch außerhalb der Karte: Die
    /// Simulation entscheidet, ob er nah genug am Weg liegt.
    func fieldPoint(atView point: CGPoint) -> Point? {
        guard field > 0 else { return nil }
        return Point(x: Double((point.x - origin.x) / field), y: Double((point.y - origin.y) / field))
    }

    func fieldPoint(atScene point: CGPoint) -> Point? {
        fieldPoint(atView: CGPoint(x: point.x, y: size.height - point.y))
    }

    func cell(atScene point: CGPoint) -> Cell? {
        cell(atView: CGPoint(x: point.x, y: size.height - point.y))
    }
}
