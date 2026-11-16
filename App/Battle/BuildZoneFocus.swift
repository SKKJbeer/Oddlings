import OddlingsCore

/// Wie deutlich ein Bauplatz beim Bauen zu sehen ist (A-2, D-157). Statt aller
/// Kacheln über der ganzen Karte nur die um den Finger, weich auslaufend: Die
/// Malerei bleibt lesbar, gerade wenn der Spieler sie lesen will (Review P2).
///
/// Reine Rechnung, damit die Szene sie nur bei einem Wechsel der Auswahl
/// anwendet und Tests sie ohne Bildschirm prüfen.
@MainActor
enum BuildZoneFocus {
    /// Deckkraft eines Bauplatzes. `focus` ist die gewählte freie Zelle; ohne
    /// sie (vor der ersten Welle) sind alle gedämpft zu sehen.
    static func alpha(of cell: Cell, focus: Cell?) -> Double {
        guard let focus else { return BattleStyle.buildZoneIdleAlpha }
        let distance = cell.center.distance(to: focus.center)
        let full = BattleStyle.buildZoneFullRadius, reach = BattleStyle.buildZoneReach
        if distance <= full { return 1 }
        if distance >= reach { return 0 }
        // Glatt auslaufend (smoothstep), damit kein Ring als Kante sichtbar wird.
        let t = (reach - distance) / (reach - full)
        return t * t * (3 - 2 * t)
    }
}
