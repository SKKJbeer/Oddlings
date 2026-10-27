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

    static func badge(_ avatar: Avatar) -> String { "\(avatar.name), \(CampaignTexts.race(avatar.race))" }

    /// Vorschläge, damit niemand an der Tastatur hängen bleibt. Höchstens
    /// `Avatar.maxNameLength` Zeichen; `AvatarSetupTests` prüft das.
    static func suggestions(_ race: Race) -> [String] {
        switch race {
        case .dwarves: ["Grimbold", "Thora", "Brokk", "Hilde", "Durin", "Ragna"]
        case .elves: ["Lyra", "Faelan", "Sylvie", "Elandor", "Miriel", "Taelis"]
        }
    }
}
