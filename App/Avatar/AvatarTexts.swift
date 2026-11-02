import OddlingsCore

/// Texte des Avatar-Aufbaus (r-5-avatar.md).
enum AvatarTexts {
    static let title = "Dein Avatar"
    static let intro = "Wähle dein Volk. Es begleitet dich durch die ganze Kampagne."
    static let portrait = "Porträt"
    static let name = "Name"
    static let suggest = "Anderer Name"
    static let confirm = "Los geht's"
    static let yourAvatar = "Dein Avatar"

    static func badge(_ avatar: Avatar, rank: Int) -> String {
        "\(avatar.name), \(CampaignTexts.race(avatar.race)), \(self.rank(rank))"
    }

    // MARK: Rang und Talente (R-6)

    static let talents = "Talente"
    static let newTalent = "Neues Talent"
    static let back = "Zurück"
    static let switchHint = "Umstellen kostet nichts und gilt ab der nächsten Mission."

    static func roman(_ number: Int) -> String {
        let numerals = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
        return number >= 1 && number <= numerals.count ? numerals[number - 1] : String(number)
    }

    static func rank(_ number: Int) -> String { "Rang \(roman(number))" }

    static func progress(stars: Int, next: Int?, rank: Int) -> String {
        guard let next else { return "Höchster Rang erreicht" }
        return "\(stars) von \(next) Sternen bis \(self.rank(rank + 1))"
    }

    static func locked(rank: Int) -> String { "Frei ab \(self.rank(rank))" }

    static func row(_ id: String) -> String {
        switch id {
        case "reachOrForce": "Reichweite oder Wucht"
        case "pace": "Takt oder Dauer"
        case "throwOrBeat": "Wurf oder Takt"
        case "mightOrSpeed": "Festung oder Feld"
        case "fireOrVeil": "Glut oder Schleier"
        case "widthOrBeat": "Weite oder Takt"
        default: id
        }
    }

    static func option(_ id: String) -> String {
        switch id {
        case "farThrow": "Fernwurf"
        case "granite": "Granit"
        case "quickMason": "Schnell gemauert"
        case "mountainFirm": "Bergfest"
        case "wideGlow": "Weiter Schein"
        case "sharpMark": "Scharfes Mal"
        case "fleeting": "Flüchtig"
        case "deep": "Tief"
        case "longArm": "Langer Arm"
        case "steadyHand": "Ruhige Hand"
        case "fortressWall": "Festungswall"
        case "fieldWall": "Feldmauer"
        case "ember": "Glut"
        case "veil": "Schleier"
        case "moonWide": "Mondweite"
        case "crescent": "Mondsichel"
        default: id
        }
    }

    /// Die Änderung in Zahlen, aus derselben Datei wie die Simulation: Eine Wahl
    /// ohne Zahlen wäre geraten (Säule „fair“).
    static func effect(_ option: TalentOption) -> String {
        AbilityField.allCases.compactMap { field in
            option.scale[field].map { "\(self.field(field)) ×\(factor($0))" }
        }.joined(separator: " · ")
    }

    /// Deutsch geschrieben, unabhängig von der Sprache des Geräts: Die ganze
    /// Oberfläche ist deutsch.
    static func factor(_ value: Double) -> String {
        var text = String(format: "%.2f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text.replacingOccurrences(of: ".", with: ",")
    }

    static func field(_ field: AbilityField) -> String {
        switch field {
        case .cooldown: "Abklingzeit"
        case .snapDistance: "Wurfweite"
        case .radius: "Radius"
        case .duration: "Dauer"
        case .damageFactor: "Schaden"
        }
    }

    // MARK: Ausrüstung (R-7a)

    static let equipment = "Ausrüstung"
    static let newEquipment = "Neue Ausrüstung"
    static let equipHint = "Tippen legt an oder ab und gilt ab der nächsten Mission."
    static let equipped = "angelegt"

    static func slot(_ slot: EquipmentSlot) -> String {
        switch slot {
        case .banner: "Banner"
        case .amulet: "Amulett"
        case .seal: "Siegel"
        }
    }

    static func slotRole(_ slot: EquipmentSlot) -> String {
        switch slot {
        case .banner: "stärkt Türme"
        case .amulet: "stärkt die Festungsfähigkeit"
        case .seal: "stärkt Festung und Kasse"
        }
    }

    static func piece(_ id: String) -> String {
        switch id {
        case "watch-banner": "Wachbanner"
        case "storm-banner": "Sturmbanner"
        case "purse-seal": "Beutelsiegel"
        case "treasure-seal": "Schatzsiegel"
        case "swift-amulet": "Flinkes Amulett"
        case "moon-amulet": "Mondamulett"
        default: id
        }
    }

    /// Der Bonus in Prozent, aus derselben Datei wie die Simulation (Säule „fair“).
    static func bonus(_ piece: EquipmentPiece) -> String {
        EquipmentField.allCases.compactMap { field in
            piece.bonus[field].map { factor in
                let target: String
                switch field {
                case .towerDamage: target = "\(towers(piece)): Schaden"
                case .towerRange: target = "\(towers(piece)): Reichweite"
                case .towerCost: target = "\(towers(piece)): Preis"
                case .startGold: target = "Startgold"
                case .fortressLives: target = "Festungsleben"
                case .abilityCooldown: target = "Abklingzeit"
                }
                return "\(target) \(percent(factor))"
            }
        }.joined(separator: " · ")
    }

    private static func towers(_ piece: EquipmentPiece) -> String {
        piece.tower.map(BattleTexts.name) ?? "Alle Türme"
    }

    /// +3 % oder −5 %, gerundet auf ganze Prozent; das Minus als echtes Minuszeichen.
    static func percent(_ factor: Double) -> String {
        let value = Int(((factor - 1) * 100).rounded())
        return value < 0 ? "−\(-value)\u{00A0}%" : "+\(value)\u{00A0}%"
    }

    static func source(_ source: EquipmentSource) -> String {
        if let mission = source.mission {
            return "\(CampaignTexts.name(mission)) mit \(source.stars) ★"
        }
        return "\(source.stars) ★ in der Region"
    }

    static func locked(_ source: EquipmentSource) -> String { "Frei: \(self.source(source))" }

    /// Vorschläge, damit niemand an der Tastatur hängen bleibt. Höchstens
    /// `Avatar.maxNameLength` Zeichen; `AvatarSetupTests` prüft das.
    static func suggestions(_ race: Race) -> [String] {
        switch race {
        case .dwarves: ["Grimbold", "Thora", "Brokk", "Hilde", "Durin", "Ragna"]
        case .elves: ["Lyra", "Faelan", "Sylvie", "Elandor", "Miriel", "Taelis"]
        }
    }
}
