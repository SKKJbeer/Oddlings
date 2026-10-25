import OddlingsCore

/// Alle Texte der Mission an einer Stelle, damit eine spätere Übersetzung
/// nur hier ansetzt.
enum BattleTexts {
    static func name(_ kind: TowerKind) -> String {
        switch kind {
        case .watch: "Wachturm"
        case .lightning: "Blitzturm"
        case .spore: "Sporenturm"
        }
    }

    static func rejection(_ reason: Rejection) -> String {
        switch reason {
        case .notEnoughGold: "Zu wenig Gold"
        case .cellOccupied: "Feld belegt"
        case .tooCloseToPath: "Zu nah am Weg"
        case .outsideMap: "Außerhalb der Karte"
        case .unknownTower: "Turm nicht gefunden"
        case .noWaveLeft: "Keine Welle mehr"
        }
    }

    static let build = "Bauen"
    static let back = "Zurück"
    static let pause = "Pause"
    static let resume = "Weiter"
    static let again = "Nochmal"
    static let restart = "Neu starten"
    static let won = "Sieg"
    static let lost = "Niederlage"
    static let paused = "Angehalten"
    static func speed(_ factor: Int) -> String { "\(factor)×" }
    static func lives(_ lives: Int) -> String { "\(lives) Leben" }
    static func gold(_ gold: Int) -> String { "\(gold) Gold" }
    static func wave(_ wave: Int, of count: Int) -> String { "Welle \(wave)/\(count)" }
    static func callWave(in seconds: Int) -> String { "Nächste Welle · \(seconds) s" }
    static func result(lives: Int, of total: Int) -> String { "Festung hält mit \(lives) von \(total) Leben" }
    static let resultLost = "Die Festung ist gefallen"
    static func sell(refund: Int) -> String { "Verkaufen +\(refund)" }
    static func price(_ cost: Int) -> String { "\(cost) Gold" }
}
