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

    /// Was Tafel und Bogen nicht verdecken sollen (A-2, D-158). Feste Ecken
    /// sind hart wie Zelle und Knöpfe; Weg und Festung kosten Strafpunkte,
    /// denn dort spielt sich die Mission ab (Review P4).
    struct Avoid: Equatable {
        /// Wegzellen in Ansichtskoordinaten.
        var path: [CGRect] = []
        /// Bild der Festung in Ansichtskoordinaten.
        var fortress: CGRect?
        /// Feste Bedienelemente auf der Karte (Fähigkeitsknopf, Wellenvorschau).
        var reserved: [CGRect] = []
        var pathPenalty: CGFloat = 0
        var fortressPenalty: CGFloat = 0
    }

    let board: BoardLayout
    let metrics: Metrics
    let avoid: Avoid
    /// Bereich, in dem Knöpfe und Tafel ganz liegen müssen.
    let bounds: CGRect

    init(board: BoardLayout, insets: Insets, metrics: Metrics, avoid: Avoid = Avoid()) {
        self.board = board
        self.metrics = metrics
        self.avoid = avoid
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
    /// weder über der Zelle noch über einem Knopf oder einer festen Ecke.
    /// Unter den freien Lagen gewinnt die, die am wenigsten Weg und keine
    /// Festung verdeckt (D-158). `size` ist größer, wenn die Tafel Turmwerte trägt (D-130).
    func panel(for cell: Cell, avoiding buttons: [CGPoint], size: CGSize? = nil) -> CGRect {
        let size = size ?? metrics.panel
        let spots = candidates(size, for: cell)
        return place(size, for: cell, avoiding: buttons, spots: spots)
            ?? CGRect(origin: spots[0], size: size)
    }

    /// Wie `panel`, aber nil, wenn die Tafel in dieser Größe nirgends frei
    /// liegt. Die Tafel mit Turmwerten (D-130) weicht dann auf die flache Leiste aus.
    func freePanel(for cell: Cell, avoiding buttons: [CGPoint], size: CGSize) -> CGRect? {
        place(size, for: cell, avoiding: buttons, spots: candidates(size, for: cell))
    }

    /// Ist die Lage frei von Zelle, Knöpfen und festen Ecken?
    func isFree(_ rect: CGRect, for cell: Cell, avoiding buttons: [CGPoint]) -> Bool {
        let blocked = [cellRect(cell)] + buttons.map(buttonRect) + avoid.reserved
        return !blocked.contains { $0.intersects(rect) }
    }

    /// Strafpunkte einer Lage: Wegzellen darunter und die Festung.
    func penalty(of rect: CGRect) -> CGFloat {
        // Eine bloß berührte Kante zählt nicht: Die Tafel liegt sonst neben
        // dem Weg und gilt doch als darauf.
        let inner = rect.insetBy(dx: 1, dy: 1)
        let path = CGFloat(avoid.path.filter { $0.intersects(inner) }.count) * avoid.pathPenalty
        let fortress = avoid.fortress.map { $0.intersects(inner) ? avoid.fortressPenalty : 0 } ?? 0
        return path + fortress
    }

    /// Mögliche Lagen in der Reihenfolge, die bei gleicher Strafe gewinnt:
    /// Ecken auf der Seite weg von der Zelle, dann Mitte oben und unten, dann
    /// die Mitte links und rechts.
    func candidates(_ size: CGSize, for cell: Cell) -> [CGPoint] {
        let left = [bounds.minX, bounds.maxX - size.width]
        // Die Mitte zuletzt: Die große Tafel mit Turmwerten (D-130) findet auf
        // dem iPhone SE bei vier Knöpfen in der Kartenmitte sonst keine freie Ecke.
        let xs = (cell.x >= board.columns / 2 ? left : left.reversed()) + [bounds.midX - size.width / 2]
        let ys = cell.y >= board.rows / 2 ? [bounds.minY, bounds.maxY - size.height]
                                          : [bounds.maxY - size.height, bounds.minY]
        var spots = xs.flatMap { x in ys.map { CGPoint(x: x, y: $0) } }
        spots += xs.prefix(2).map { CGPoint(x: $0, y: bounds.midY - size.height / 2) }
        // Dicht neben Festung und festen Ecken: Auf dem iPhone SE ragen sie so
        // weit in die Karte, dass die Ecken und Mitten auf ihnen lägen.
        var edgesX: [CGFloat] = [], edgesY: [CGFloat] = []
        for rect in avoid.reserved + [avoid.fortress].compactMap({ $0 }) {
            edgesX += [rect.minX - size.width, rect.maxX]
            edgesY += [rect.minY - size.height, rect.maxY]
        }
        let fitsX = { (x: CGFloat) in x >= self.bounds.minX && x + size.width <= self.bounds.maxX }
        let fitsY = { (y: CGFloat) in y >= self.bounds.minY && y + size.height <= self.bounds.maxY }
        spots += edgesX.filter(fitsX).flatMap { x in ys.map { CGPoint(x: x, y: $0) } }
        spots += edgesY.filter(fitsY).flatMap { y in xs.map { CGPoint(x: $0, y: y) } }
        return spots
    }

    private func place(_ size: CGSize, for cell: Cell, avoiding buttons: [CGPoint], spots: [CGPoint]) -> CGRect? {
        var best: (rect: CGRect, penalty: CGFloat)?
        for spot in spots {
            let rect = CGRect(origin: spot, size: size)
            guard isFree(rect, for: cell, avoiding: buttons) else { continue }
            let cost = penalty(of: rect)
            if best.map({ cost < $0.penalty }) ?? true { best = (rect, cost) }
        }
        return best?.rect
    }

    /// Lage der Tafel mit Turmwerten: hoch mit vier Kacheln im Quadrat, wo
    /// Platz ist, sonst als flache Leiste mit vier Kacheln nebeneinander. Auf
    /// dem iPhone SE fehlt der hohen Tafel bei vier Knöpfen in der
    /// Kartenmitte die Höhe; die Leiste passt dort überall (HudLayoutTests).
    func statPanel(for cell: Cell, avoiding buttons: [CGPoint], tall: CGSize, wide: CGSize) -> (rect: CGRect, wide: Bool) {
        let high = freePanel(for: cell, avoiding: buttons, size: tall)
        let flat = freePanel(for: cell, avoiding: buttons, size: wide)
        // Die Leiste gewinnt nur, wenn die hohe Tafel auf der Festung läge und
        // sie nicht (D-158): Vier Kacheln im Quadrat liest man schneller, ein
        // paar Wegzellen mehr sind dafür in Ordnung.
        let onFortress = { (rect: CGRect) in self.penalty(of: rect) >= self.avoid.fortressPenalty && self.avoid.fortressPenalty > 0 }
        if let high, !onFortress(high) || flat.map(onFortress) ?? true { return (high, false) }
        return (flat ?? panel(for: cell, avoiding: buttons, size: wide), true)
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
            let rect = buttonRect(a).insetBy(dx: -gap, dy: -gap)
            if rect.intersects(cellRect) { return false }
            // Feste Ecken (Fähigkeitsknopf, Wellenvorschau) bleiben frei (D-158).
            if avoid.reserved.contains(where: { $0.intersects(rect) }) { return false }
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

@MainActor
extension HudLayout.Avoid {
    /// Was die Mission auf der Karte hat: Wegzellen, Festung und feste Ecken.
    /// Dieselbe Rechnung für Ansicht und Tests, damit beide dieselbe Lage sehen.
    init(board: BoardLayout, map: MissionMap, reserved: [CGRect] = []) {
        var path: [CGRect] = []
        for y in 0..<map.height {
            for x in 0..<map.width {
                let cell = Cell(x: x, y: y)
                guard map.path.distance(from: cell.center) < BattleStyle.panelPathReach else { continue }
                let origin = board.viewPoint(Point(x: Double(x), y: Double(y)))
                path.append(CGRect(origin: origin, size: CGSize(width: board.field, height: board.field)))
            }
        }
        // Wie `BattleScene.layoutMap`: Die Festung sitzt, wo der Weg die Karte
        // verlässt, das Bild um `fortressOffset` versetzt, Fuß auf dem Anker.
        let end = map.path.points[map.path.points.count - 1]
        let gate = board.viewPoint(Point(x: min(end.x, Double(map.width)), y: end.y))
        let side = BattleStyle.fortressSpriteSide * board.field
        let foot = CGPoint(x: gate.x + BattleStyle.fortressOffset.x * board.field,
                           y: gate.y + BattleStyle.fortressOffset.y * board.field)
        let fortress = CGRect(x: foot.x - side / 2, y: foot.y - side * (1 - BattleStyle.fortressAnchorY),
                              width: side, height: side)
        self.init(path: path, fortress: fortress, reserved: reserved,
                  pathPenalty: BattleStyle.panelPathPenalty, fortressPenalty: BattleStyle.panelFortressPenalty)
    }
}

@MainActor
extension HudLayout {
    /// Fähigkeitsknopf unten rechts auf der Karte (D-033), wie `BattleView` ihn legt.
    static func abilityRect(board size: CGSize, insets: Insets) -> CGRect {
        let side = BattleStyle.tapTarget, m = BattleStyle.hudMargin
        return CGRect(x: size.width - insets.right - m - side, y: size.height - insets.bottom - m - side,
                      width: side, height: side)
    }

    /// Zettel der Wellenvorschau oben rechts unter „Welle n“ (D-159), wie
    /// `BattleView` ihn legt: rechtsbündig mit dem Knopf, links von Tempo und Pause.
    static func forecastRect(board size: CGSize, insets: Insets, entries: Int) -> CGRect {
        let width = BattleStyle.forecastWidth(entries: entries)
        let right = size.width - insets.right - BattleStyle.forecastTrailing
        return CGRect(x: right - width, y: 0, width: width, height: BattleStyle.forecastHeight)
    }
}
