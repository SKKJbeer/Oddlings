import CoreGraphics
import OddlingsCore

/// Wo das Kreismenü und die Infotafel zu einer Zelle liegen (07-ui-ux.md,
/// Abschnitt 4). Eine reine Rechnung auf `BoardLayout`, damit Menü, Tests und
/// später die HUD-Ecken (D-030) dieselbe Lage sehen und nichts davon an einer
/// Ansicht hängt.
///
/// Koordinaten wie `BoardLayout`: Ansicht der Karte, Ursprung links oben.
struct HudLayout: Equatable {
    struct Metrics: Equatable {
        /// Seite eines runden Knopfs; größer als Apples 44 pt, weil der
        /// Finger die Zelle daneben nicht treffen soll.
        var button: CGFloat
        /// Freiraum zwischen Knöpfen und zur gewählten Zelle.
        var gap: CGFloat
        /// Abstand zum Rand des sicheren Bereichs.
        var margin: CGFloat
        var panel: CGSize
    }

    /// Ränder, die die Ansicht nicht bedecken darf (Dynamic Island, Home-Leiste).
    struct Insets: Equatable {
        var top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0
    }

    let board: BoardLayout
    let metrics: Metrics
    /// Bereich, in dem Knöpfe und Tafel ganz liegen müssen.
    let bounds: CGRect

    init(board: BoardLayout, insets: Insets, metrics: Metrics) {
        self.board = board
        self.metrics = metrics
        let m = metrics.margin
        bounds = CGRect(x: insets.left + m, y: insets.top + m,
                        width: max(0, board.size.width - insets.left - insets.right - 2 * m),
                        height: max(0, board.size.height - insets.top - insets.bottom - 2 * m))
    }

    func cellRect(_ cell: Cell) -> CGRect {
        let origin = board.viewPoint(Point(x: Double(cell.x), y: Double(cell.y)))
        return CGRect(x: origin.x, y: origin.y, width: board.field, height: board.field)
    }

    /// Mittelpunkte von `count` Knöpfen um die Zelle.
    ///
    /// Bevorzugt über der Zelle, damit der Finger beim Tippen nichts verdeckt;
    /// in den oberen zwei Reihen darunter. Passt der Bogen dort nicht, wird er
    /// schräg und zuletzt seitlich gelegt. Am Rand rückt er als Ganzes, nicht
    /// Knopf für Knopf: So bleiben die Abstände zwischen den Knöpfen erhalten.
    func ring(at cell: Cell, count: Int) -> [CGPoint] {
        guard count > 0 else { return [] }
        let up: [Double] = [-90, -45, -135, 90, 45, 135, 0, 180]
        let down: [Double] = [90, 45, 135, -90, -45, -135, 0, 180]
        var fallback: [CGPoint]?
        for base in cell.y > 1 ? up : down {
            let points = fitted(arc(around: cell, count: count, base: base))
            if fits(points, cell: cell) { return points }
            if fallback == nil { fallback = points }
        }
        return fallback ?? []
    }

    func buttonRect(_ center: CGPoint) -> CGRect {
        let side = metrics.button
        return CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    }

    /// Infotafel auf der Seite der Karte, die von der Zelle weg liegt, und
    /// weder über der Zelle noch über einem Knopf.
    func panel(for cell: Cell, avoiding buttons: [CGPoint]) -> CGRect {
        let size = metrics.panel
        let left = [bounds.minX, bounds.maxX - size.width]
        let xs = cell.x >= board.columns / 2 ? left : left.reversed()
        let ys = cell.y >= board.rows / 2 ? [bounds.minY, bounds.maxY - size.height]
                                          : [bounds.maxY - size.height, bounds.minY]
        let blocked = [cellRect(cell)] + buttons.map(buttonRect)
        for x in xs {
            for y in ys {
                let rect = CGRect(origin: CGPoint(x: x, y: y), size: size)
                if !blocked.contains(where: { $0.intersects(rect) }) { return rect }
            }
        }
        return CGRect(origin: CGPoint(x: xs[0], y: ys[0]), size: size)
    }

    // MARK: Rechnung

    private func spread(_ count: Int) -> [Double] {
        switch count {
        case 1: [0]
        case 2: [-34, 34]
        case 3: [-60, 0, 60]
        default: (0..<count).map { Double($0) * 160 / Double(count - 1) - 80 }
        }
    }

    private func arc(around cell: Cell, count: Int, base: Double) -> [CGPoint] {
        let center = board.viewPoint(cell.center)
        let angles = spread(count).map { (base + $0) * .pi / 180 }
        let place = { (radius: CGFloat) in
            angles.map { CGPoint(x: center.x + radius * CGFloat(cos($0)), y: center.y + radius * CGFloat(sin($0))) }
        }
        // Kleinster Radius, bei dem kein Knopf die Zelle oder einen Nachbarn berührt.
        var radius = (board.field + metrics.button) / 2
        let limit = radius + 4 * metrics.button
        while radius < limit, !clear(place(radius), cell: cell) { radius += 1 }
        return place(radius)
    }

    private func clear(_ points: [CGPoint], cell: Cell) -> Bool {
        let cellRect = cellRect(cell)
        let gap = metrics.gap
        for (i, a) in points.enumerated() {
            if buttonRect(a).insetBy(dx: -gap, dy: -gap).intersects(cellRect) { return false }
            for b in points[(i + 1)...] where hypot(a.x - b.x, a.y - b.y) < metrics.button + gap { return false }
        }
        return true
    }

    private func fitted(_ points: [CGPoint]) -> [CGPoint] {
        let half = metrics.button / 2
        let minX = points.map(\.x).min()! - half, maxX = points.map(\.x).max()! + half
        let minY = points.map(\.y).min()! - half, maxY = points.map(\.y).max()! + half
        let dx = max(0, bounds.minX - minX) - max(0, maxX - bounds.maxX)
        let dy = max(0, bounds.minY - minY) - max(0, maxY - bounds.maxY)
        return points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
    }

    private func fits(_ points: [CGPoint], cell: Cell) -> Bool {
        let inside = points.allSatisfy { bounds.insetBy(dx: -0.5, dy: -0.5).contains(buttonRect($0)) }
        return inside && clear(points, cell: cell)
    }
}
