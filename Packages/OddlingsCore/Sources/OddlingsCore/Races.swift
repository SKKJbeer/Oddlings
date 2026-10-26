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

    public init(ability: AbilityConfig, rangeFactor: [TowerKind: Double]? = nil,
                costFactor: [TowerKind: Double]? = nil) {
        self.ability = ability
        self.rangeFactor = rangeFactor
        self.costFactor = costFactor
    }
}

/// Alle Völker aus `Balance/races.json`. Werte stehen nur dort (Architekturregel 7).
public struct RaceTable: Codable, Equatable, Sendable {
    public var races: [Race: RaceConfig]

    public init(races: [Race: RaceConfig]) { self.races = races }

    public subscript(race: Race) -> RaceConfig? { races[race] }

    public func issues() -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        for race in Race.allCases {
            let field = "races.\(race.rawValue)"
            guard let config = races[race] else {
                found.append(.init(field: field, rule: .missingRace))
                continue
            }
            found += config.ability.issues(field: "\(field).ability")
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
