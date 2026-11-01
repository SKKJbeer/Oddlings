import Foundation

/// Der Avatar des Spielers (R-5, D-063): einmal am Anfang aufgebaut, danach
/// gesetzt. Das Volk bestimmt die Mission über `RaceTable`; Name und Porträt
/// sind nur Identität und erreichen die Simulation nie.
public struct Avatar: Codable, Equatable, Sendable {
    /// Länger passt nicht ins Avatarschild im Querformat des kleinsten iPhones.
    public static let maxNameLength = 16
    public static let maxPortraitLength = 32

    public let race: Race
    public let name: String
    /// Kennung aus dem Porträtkatalog der App. Der Kern prüft nur die Form:
    /// Welche Bilder es gibt, weiß allein die App.
    public let portrait: String
    /// Gewählte Seite je Talentreihe (R-6). Was gilt, entscheidet erst der Rang
    /// (`AvatarRank.effective`); fehlende Reihen stehen auf A.
    public var talents: [TalentSide] = []
    /// Mehr Reihen kennt kein Volk; was länger ist, kommt nicht aus dieser App.
    public static let maxTalentRows = 8

    /// Nur gültige Werte: ein Name, den `validName` annimmt, und eine Kennung,
    /// die `isValidPortrait` annimmt. Sonst `nil`.
    public init?(race: Race, name: String, portrait: String) {
        guard let name = Self.validName(name), Self.isValidPortrait(portrait) else { return nil }
        self.race = race
        self.name = name
        self.portrait = portrait
    }

    /// Getrimmt, 1 bis `maxNameLength` Zeichen, keine Steuerzeichen. Der Name
    /// kommt aus einem Textfeld oder aus einer Datei, beides von außen.
    public static func validName(_ raw: String) -> String? {
        let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.count <= maxNameLength else { return nil }
        let forbidden = CharacterSet.controlCharacters.union(.illegalCharacters).union(.newlines)
        guard name.unicodeScalars.allSatisfy({ !forbidden.contains($0) }) else { return nil }
        return name
    }

    /// Kleinbuchstaben, Ziffern und Bindestrich: Die Kennung wird zum Bildnamen.
    public static func isValidPortrait(_ id: String) -> Bool {
        !id.isEmpty && id.count <= maxPortraitLength
            && id.unicodeScalars.allSatisfy { ("a"..."z").contains($0) || ("0"..."9").contains($0) || $0 == "-" }
    }

    /// Decodieren geht durch dieselbe Prüfung wie das Anlegen.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let race = try container.decode(Race.self, forKey: .race)
        let name = try container.decode(String.self, forKey: .name)
        let portrait = try container.decode(String.self, forKey: .portrait)
        guard var valid = Avatar(race: race, name: name, portrait: portrait) else {
            throw DecodingError.dataCorruptedError(forKey: .name, in: container, debugDescription: "ungültiger Avatar")
        }
        valid.talents = Self.validTalents((try? container.decodeIfPresent([String].self, forKey: .talents)) ?? nil)
        self = valid
    }

    /// Eine kaputte Talentwahl kostet nur die Wahl, nie den Avatar: Sie ist
    /// jederzeit neu zu treffen, Name und Volk nicht.
    static func validTalents(_ raw: [String]?) -> [TalentSide] {
        guard let raw, raw.count <= maxTalentRows else { return [] }
        let sides = raw.compactMap(TalentSide.init(rawValue:))
        return sides.count == raw.count ? sides : []
    }
}
