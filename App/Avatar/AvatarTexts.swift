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

    /// Vorschläge, damit niemand an der Tastatur hängen bleibt. Höchstens
    /// `Avatar.maxNameLength` Zeichen; `AvatarSetupTests` prüft das.
    static func suggestions(_ race: Race) -> [String] {
        switch race {
        case .dwarves: ["Grimbold", "Thora", "Brokk", "Hilde", "Durin", "Ragna"]
        case .elves: ["Lyra", "Faelan", "Sylvie", "Elandor", "Miriel", "Taelis"]
        }
    }
}
