import OddlingsCore
import SpriteKit

/// Kampfplatz in der Welt (Grafik 11, D-190 bis D-195): was Gebautes mit dem Boden
/// verbindet. Nur Darstellung; keine Spielregel hängt daran.
extension BattleStyle {
    /// Steinsockel unter jedem Turm (D-190): Quadrat mit dem Bodenmittelpunkt in der
    /// Mitte, wie `tower_plinth` im Asset-Vertrag. Die Platte ist 1,1 Zellen breit,
    /// also breiter als jeder Turmfuß, und 0,1 Zellen hoch.
    static let plinthSide: CGFloat = 1.5
    /// So weit steht der Turm auf dem Sockel höher: Sockelhöhe × cos 40° (Kamera
    /// aus dem Vertrag), in Feldern.
    static let plinthLift: CGFloat = 0.077
    /// Kontaktdunkel unter dem Fuß (D-193), Quadrat mit dem Fuß in der Mitte.
    static let contactSide: CGFloat = 1.4
}

/// Wo die Torburg steht und wohin ihr Tor zeigt, aus dem Wegende (D-191). Eine
/// Rechnung für Szene, Tafel-Ausweichen (`HudLayout`) und Tests; das Werkzeug
/// (`tools/kampfplatz-3d/plan.py`) rechnet mit denselben Vertragswerten.
enum FortressPlacement {
    /// Dieselben Werte wie `festung` im Asset-Vertrag (art-check hält beide gleich):
    /// Das Tor liegt `gateInset` Zellen hinter dem Kartenrand auf dem Weg, der Fuß
    /// `gateDistance` dahinter, gegen die Blickrichtung des Tores; `yaw` dreht die
    /// Burg (0 = Tor zum Betrachter, −45 = nach links unten).
    static let gateInset = 0.4
    static let gateDistance = 0.5
    static let yaw = -45.0

    /// Tor: dort endet der gemalte Weg, und dort laufen Gegner beim Durchbruch hinein.
    static func gate(pathEnd: Point, mapWidth: Int) -> Point {
        Point(x: min(pathEnd.x, Double(mapWidth)) + gateInset, y: pathEnd.y)
    }

    /// Blickrichtung des Tores in Zellen (y nach unten): (0, 1) zum Betrachter,
    /// um `yaw` gedreht.
    static var facing: (x: Double, y: Double) {
        let angle = yaw * .pi / 180
        return (sin(angle), cos(angle))
    }

    /// Fuß der Torburg (Mitte des Grundrisses), auf dem Anker des Bildes.
    static func foot(pathEnd: Point, mapWidth: Int) -> Point {
        let gate = gate(pathEnd: pathEnd, mapWidth: mapWidth)
        let facing = facing
        return Point(x: gate.x - facing.x * gateDistance,
                     y: gate.y - facing.y * gateDistance)
    }
}

extension BattleSprites {
    static let plinthName = "tower_plinth"
    static let contactName = "tower_contact"
    static let fortressShadowName = "fortress_shadow"
}
