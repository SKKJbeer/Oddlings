import Foundation

/// Felder einer Festungsfähigkeit, die ein Talent verschieben darf (R-6, D-064).
/// Andere Felder bleiben, wie das Volk sie setzt.
public enum AbilityField: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case cooldown, snapDistance, radius, duration, damageFactor
}

/// Eine der zwei Seiten einer Talentreihe. A ist vorgewählt, sobald die Reihe frei wird.
public enum TalentSide: String, Codable, CaseIterable, Sendable {
    case a, b
}

/// Eine Spielart der Volksfähigkeit: Faktoren auf einzelne Felder. Faktoren statt
/// fester Werte, damit sich zwei Reihen verrechnen lassen, ohne einander zu kennen.
public struct TalentOption: Codable, Equatable, Sendable {
    public var id: String
    /// Nur zum Nachschlagen, nie darüber iterieren (Architekturregel 6).
    public var scale: [AbilityField: Double]

    public init(id: String, scale: [AbilityField: Double]) {
        self.id = id
        self.scale = scale
    }
}

/// Eine Reihe mit zwei gleich starken Seiten. Gleich stark heißt: Die
/// Balancetests rechnen jede Kombination und halten sie nah an der Grundform.
public struct TalentRow: Codable, Equatable, Sendable {
    public var id: String
    public var a: TalentOption
    public var b: TalentOption

    public init(id: String, a: TalentOption, b: TalentOption) {
        self.id = id
        self.a = a
        self.b = b
    }

    public subscript(side: TalentSide) -> TalentOption { side == .a ? a : b }
}

/// Der Rang des Avatars aus den besten Sternen je Mission. Ein Rang lässt sich
/// nie verlieren, weil die besten Sterne nie sinken.
public enum AvatarRank {
    /// Rang I ohne Sterne; jede erreichte Schwelle hebt um eins.
    public static func rank(stars: Int, thresholds: [Int]) -> Int {
        1 + thresholds.filter { stars >= $0 }.count
    }

    /// Reihe 0 wird mit Rang II frei, Reihe 1 mit Rang III.
    public static func unlockedRows(rank: Int) -> Int { max(0, rank - 1) }

    /// Die Wahl, die gilt: je freier Reihe die gespeicherte Seite, sonst A.
    /// Gesperrte Reihen zählen nicht, auch wenn der Spielstand für sie eine Seite kennt.
    public static func effective(_ chosen: [TalentSide], unlockedRows: Int, rows: Int) -> [TalentSide] {
        (0..<min(unlockedRows, rows)).map { $0 < chosen.count ? chosen[$0] : .a }
    }
}

extension AbilityConfig {
    /// Dieselbe Fähigkeit mit verrechneten Spielarten.
    public func applying(_ options: [TalentOption]) -> AbilityConfig {
        var config = self
        for option in options {
            for field in AbilityField.allCases {
                guard let factor = option.scale[field] else { continue }
                switch field {
                case .cooldown: config.cooldown *= factor
                case .snapDistance: config.snapDistance *= factor
                case .radius: config.radius = config.radius.map { $0 * factor }
                case .duration: config.duration = config.duration.map { $0 * factor }
                case .damageFactor: config.damageFactor = config.damageFactor.map { $0 * factor }
                }
            }
        }
        return config
    }

    func has(_ field: AbilityField) -> Bool {
        switch field {
        case .cooldown, .snapDistance: true
        case .radius: radius != nil
        case .duration: duration != nil
        case .damageFactor: damageFactor != nil
        }
    }
}

extension RaceConfig {
    /// Die Spielarten zu einer wirksamen Wahl (`AvatarRank.effective`).
    public func talentOptions(_ sides: [TalentSide]) -> [TalentOption] {
        let rows = talents ?? []
        return sides.enumerated().compactMap { index, side in index < rows.count ? rows[index][side] : nil }
    }

    /// Das Volk mit seiner Talentwahl, als fertige Konfiguration wie ein eigenes Volk.
    public func with(talents sides: [TalentSide]) -> RaceConfig {
        var config = self
        config.ability = ability.applying(talentOptions(sides))
        return config
    }

    /// Jede Kombination, die ein Spieler spielen kann: Grundform, dann je Rang
    /// alle Seiten der freien Reihen. Für Prüfung und Balancetests.
    public func allTalentChoices() -> [[TalentSide]] {
        var result: [[TalentSide]] = [[]]
        var level: [[TalentSide]] = [[]]
        for _ in talents ?? [] {
            level = level.flatMap { prefix in TalentSide.allCases.map { prefix + [$0] } }
            result += level
        }
        return result
    }
}
