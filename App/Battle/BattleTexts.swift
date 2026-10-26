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
        case .abilityNotReady: "Noch nicht bereit"
        case .notOnPath: "Nur auf den Weg"
        case .noAbility: "Hier nicht verfügbar"
        }
    }

    static let build = "Bauen"
    static func ability(_ kind: AbilityKind) -> String {
        switch kind {
        case .stoneRain: "Steinregen"
        case .bulwark: "Bollwerk"
        case .moonMark: "Mondmal"
        }
    }

    /// Für VoiceOver und die Oberflächentests: Der Knopf sagt, was er gerade kann.
    static func abilityState(ready: Bool, aiming: Bool, charge: Double) -> String {
        if aiming { return "Ziel auf den Weg tippen" }
        if ready { return "bereit" }
        return "lädt, \(Int((charge * 100).rounded(.down))) Prozent"
    }
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

    // MARK: Oberfläche UI 01

    /// Eine Zeile Rolle und eine Zeile Zusammenspiel für die Infotafel
    /// (07-ui-ux.md, „Turm antippen“). Rollen aus 02-combat-and-towers.md.
    static func role(_ kind: TowerKind) -> String {
        switch kind {
        case .watch: "Ein Ziel, zuverlässig"
        case .lightning: "Springt durch Gruppen"
        case .spore: "Verlangsamt alles im Kreis"
        }
    }

    static func combo(_ kind: TowerKind) -> String {
        switch kind {
        case .watch: "Schießt länger auf Verlangsamte"
        case .lightning: "Stark, wo Sporen Gruppen stauen"
        case .spore: "Macht Blitze stärker"
        }
    }

    static func missing(_ gold: Int) -> String { "fehlt \(gold)" }
    static let tapAgainToBuild = "Nochmal tippen: bauen"
    static let notEnoughGold = "Zu wenig Gold"
    static let sellArmed = "Sicher?"
    static func confirmSell(refund: Int) -> String { "Nochmal tippen: +\(refund) Gold" }
    static func refundLine(_ refund: Int) -> String { "Verkauf bringt +\(refund) Gold" }

    static let giveUp = "Aufgeben"
    static let menu = "Menü"
    static let wonBanner = "Sieg!"
    static let lostBanner = "Die Festung ist gefallen"
    static let againWon = "Nochmal spielen"
    static let againLost = "Nochmal versuchen"
    static let livesLeft = "Leben übrig"
    static let duration = "Dauer"
    static let towersBuilt = "Türme gebaut"
    static let wavesHeld = "Wellen gehalten"
    static let enemiesDefeated = "Besiegte Gegner"
    static func clock(_ seconds: Int) -> String {
        let rest = seconds % 60
        return "\(seconds / 60):\(rest < 10 ? "0" : "")\(rest)"
    }
    static func nextWaveShort(_ wave: Int) -> String { "Welle \(wave)" }

    static let play = "Spielen"
    static let watch = "Vorführung ansehen"
    static let spike = "Leistungsprobe"
    static let mission = "Mission 1"
    static let offline = "Offline · ohne Konto"
}
