import OddlingsCore

/// Alle Texte der Mission an einer Stelle, damit eine spätere Übersetzung
/// nur hier ansetzt.
enum BattleTexts {
    static func name(_ kind: TowerKind) -> String {
        switch kind {
        case .watch: "Wachturm"
        case .lightning: "Blitzturm"
        case .spore: "Sporenturm"
        case .bank: "Zwergenbank"
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
        case .limitReached: "Höchstzahl erreicht"
        case .notUpgradable: "Nicht weiter aufwertbar"
        case .targetModeLocked: "Zielwahl ab Stufe 2"
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
    /// Pausentafel nach einem Neustart der App (P2-2).
    static let resumed = "Hier warst du stehen geblieben."
    static let restartedAfterUpdate = "Die Mission hat sich mit einem Update geändert und beginnt neu."
    static let restartedAfterDamage = "Der gesicherte Stand war beschädigt. Die Mission beginnt neu."
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
        case .bank: "Zahlt Gold, kämpft nicht"
        }
    }

    static func combo(_ kind: TowerKind) -> String {
        switch kind {
        case .watch: "Schießt länger auf Verlangsamte"
        case .lightning: "Stark, wo Sporen Gruppen stauen"
        case .spore: "Macht Blitze stärker"
        case .bank: "Früh gebaut, zahlt sie am meisten"
        }
    }

    // MARK: Zwergenbank und frühes Rufen (P2-5)

    /// Ertrag in einer Zeile, Zahlen aus der Missionsdatei.
    static func bankIncome(_ bank: BankConfig) -> String {
        "Ab \(seconds(bank.delay)) s alle \(seconds(bank.interval)) s +\(bank.payout), bis \(bank.cap) Gold"
    }
    /// Die eigentliche Entscheidung (07, „Zwergenbank“), in Worten beim Kauf.
    static func bankWarning(cost: Int) -> String { "Die \(cost) Gold fehlen dir in den nächsten Wellen." }
    static func bankPaid(_ paid: Int, of cap: Int) -> String { "Ausgezahlt \(paid) von \(cap) Gold" }
    static let bankEmpty = "Leer. Verkaufen gibt den Platz frei."
    static let bankEmptyTag = "leer"
    static func limit(_ standing: Int, of limit: Int) -> String { "\(standing)/\(limit)" }
    static func limitReached(_ limit: Int) -> String { "Höchstens \(limit) Banken" }
    static func gain(_ gold: Int) -> String { "+\(gold)" }
    static func callWave(in seconds: Int, bonus: Int) -> String {
        bonus > 0 ? "\(callWave(in: seconds)) · +\(bonus) Gold" : callWave(in: seconds)
    }
    static func earlyBonus(_ gold: Int) -> String { "Früh gerufen: +\(gold) Gold" }

    /// 20.0 → „20“, 2.5 → „2,5“: Sekunden, wie man sie spricht.
    static func seconds(_ value: Double) -> String {
        let tenths = Int((value * 10).rounded())
        return tenths % 10 == 0 ? "\(tenths / 10)" : "\(tenths / 10),\(abs(tenths % 10))"
    }

    // MARK: Aufwerten und Zielwahl (P2-6)

    /// Name mit Stufe, wie auf dem Schild am Turm: „Wachturm II“.
    static func name(_ kind: TowerKind, level: Int) -> String { level >= 2 ? "\(name(kind)) II" : name(kind) }
    static let levelTag = "II"
    /// Beim ersten gepanzerten Gegner einer Mission (P2-10).
    static let armorHint = "Gepanzert: Steine schlagen durch"
    /// Sporenfunke (E2, P2-8): Blitz trifft ein verlangsamtes Ziel.
    static let sparkWord = "Sporenfunke!"
    /// Einmal je Gerät unter dem ersten Funken (K8). Beschreibt die Regel, verspricht keinen Bonus.
    static let sparkSentence = "Gebremst rücken sie zusammen – der Blitz trifft mehr."
    /// VoiceOver, solange Hand bzw. Pfeil des Einstiegs stehen.
    static let guideBuild = "Tippe auf ein helles Feld neben dem Weg, um einen Turm zu bauen."
    static let guideWave = "Ruft die erste Welle jetzt."
    static let upgrade = "Aufwerten"
    static let upgradeArmed = "Stufe 2: gleiche Rolle, spürbar stärker."
    static let upgradeUnlocks = "Schaltet die Zielwahl frei."
    static let upgradeUnlocksNothing = "Größere Wirkung im selben Kreis."
    static func confirmUpgrade(_ cost: Int) -> String { "Nochmal tippen: aufwerten für \(cost) Gold" }
    static func upgradeLine(_ cost: Int) -> String { "Aufwerten für \(cost) Gold" }
    static func targetMode(_ mode: TargetMode) -> String {
        switch mode {
        case .first: "Erster"
        case .last: "Letzter"
        case .strongest: "Stärkster"
        }
    }
    static func targetLine(_ mode: TargetMode) -> String { "Ziel: \(targetMode(mode))" }
    static func targetHint(_ mode: TargetMode) -> String {
        switch mode {
        case .first: "Ziel: wer am weitesten ist"
        case .last: "Ziel: wer zuletzt kam"
        case .strongest: "Ziel: der Zäheste"
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
