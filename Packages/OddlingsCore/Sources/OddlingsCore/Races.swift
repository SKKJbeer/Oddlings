import Foundation

/// Was ein Volk an einer Mission ändert (03, „Wie ein Volk wirkt"; R-4): die
/// Festungsfähigkeit und Faktoren auf Reichweite und Preis einzelner Türme. Die
/// Türme selbst bleiben für alle gleich.
public struct RaceConfig: Codable, Equatable, Sendable {
    public var ability: AbilityConfig
    /// Faktor auf die Reichweite je Turmart; eine fehlende Art bleibt bei 1.
    /// Nur zum Nachschlagen, nie darüber iterieren (Architekturregel 6).
    public var rangeFactor: [TowerKind: Double]?
    /// Faktor auf den Baupreis je Turmart (D-062: Zwerge zahlen für Wachtürme
    /// weniger). Gerundet auf ganzes Gold, weil die Kasse nur ganze Münzen kennt.
    public var costFactor: [TowerKind: Double]?
    /// Talentreihen des Avatarrangs (R-6), Reihe 0 frei ab Rang II.
    public var talents: [TalentRow]?

    public init(ability: AbilityConfig, rangeFactor: [TowerKind: Double]? = nil,
                costFactor: [TowerKind: Double]? = nil, talents: [TalentRow]? = nil) {
        self.ability = ability
        self.rangeFactor = rangeFactor
        self.costFactor = costFactor
        self.talents = talents
    }
}

/// Alle Völker aus `Balance/races.json`. Werte stehen nur dort (Architekturregel 7).
public struct RaceTable: Codable, Equatable, Sendable {
    public var races: [Race: RaceConfig]
    /// Sterne, ab denen Rang II, III, … gilt (R-6). Fehlt sie, bleibt jeder auf Rang I.
    public var rankStars: [Int]?

    public init(races: [Race: RaceConfig], rankStars: [Int]? = nil) {
        self.races = races
        self.rankStars = rankStars
    }

    public func rank(stars: Int) -> Int { AvatarRank.rank(stars: stars, thresholds: rankStars ?? []) }

    public subscript(race: Race) -> RaceConfig? { races[race] }

    public func issues() -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        let thresholds = rankStars ?? []
        if zip([0] + thresholds, thresholds).contains(where: { $0 >= $1 }) {
            found.append(.init(field: "rankStars", rule: .ranksOutOfOrder))
        }
        for race in Race.allCases {
            let field = "races.\(race.rawValue)"
            guard let config = races[race] else {
                found.append(.init(field: field, rule: .missingRace))
                continue
            }
            found += config.ability.issues(field: "\(field).ability")
            let rows = config.talents ?? []
            if rows.count != thresholds.count {
                found.append(.init(field: "\(field).talents", rule: .talentRowsDontMatchRanks))
            }
            for (index, row) in rows.enumerated() {
                for side in TalentSide.allCases {
                    let prefix = "\(field).talents.\(index).\(side.rawValue)"
                    for name in AbilityField.allCases {
                        guard let factor = row[side].scale[name] else { continue }
                        if !(factor > 0) { found.append(.init(field: "\(prefix).\(name.rawValue)", rule: .mustBePositive)) }
                        if !config.ability.has(name) {
                            found.append(.init(field: "\(prefix).\(name.rawValue)", rule: .fieldNotInAbility))
                        }
                    }
                }
            }
            // Jede spielbare Kombination ist eine eigene Fähigkeit und muss
            // dieselben Regeln einhalten wie die Grundform.
            for choice in config.allTalentChoices().dropFirst() {
                let name = choice.map(\.rawValue).joined()
                found += config.with(talents: choice).ability.issues(field: "\(field).talents[\(name)].ability")
            }
            for kind in TowerKind.allCases {
                if let factor = config.rangeFactor?[kind], !(factor > 0) {
                    found.append(.init(field: "\(field).rangeFactor.\(kind.rawValue)", rule: .mustBePositive))
                }
                if let factor = config.costFactor?[kind], !(factor > 0) {
                    found.append(.init(field: "\(field).costFactor.\(kind.rawValue)", rule: .mustBePositive))
                }
            }
        }
        return found
    }

    /// Lesen und prüfen in einem Schritt, wie bei der Missionsdatei.
    public static func load(from data: Data) throws(ConfigError) -> RaceTable {
        let table: RaceTable
        do { table = try JSONDecoder().decode(RaceTable.self, from: data) } catch {
            throw .unreadable(String(describing: error))
        }
        let found = table.issues()
        if !found.isEmpty { throw .invalid(found) }
        return table
    }

    public static func bundled() throws(ConfigError) -> RaceTable {
        guard let url = Bundle.module.url(forResource: "races", withExtension: "json", subdirectory: "Balance")
        else { throw .resourceMissing("races") }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { throw .unreadable(String(describing: error)) }
        return try load(from: data)
    }
}

extension BalanceConfig {
    /// Dieselbe Mission für ein Volk: eine zweite Konfiguration statt eines
    /// Falls je Volk in der Simulation. So rechnen Balance- und
    /// Determinismustests jedes Volk, ohne dass der Kern Völker kennt.
    public func applying(_ race: RaceConfig, talents: [TalentSide]) -> BalanceConfig {
        applying(race.with(talents: talents))
    }

    public func applying(_ race: RaceConfig) -> BalanceConfig {
        var config = self
        config.ability = race.ability
        for kind in TowerKind.allCases {
            if let factor = race.rangeFactor?[kind] { config.towers[kind]?.range *= factor }
            if let factor = race.costFactor?[kind], let cost = config.towers[kind]?.cost {
                config.towers[kind]?.cost = Int((Double(cost) * factor).rounded())
            }
        }
        return config
    }
}
