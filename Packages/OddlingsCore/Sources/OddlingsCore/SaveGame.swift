import Foundation

/// Startvölker (03). Seit 0.7.0 im Speicherstand, seit R-4 wirksam; ihre Werte
/// stehen in `races.json` (`RaceTable`).
public enum Race: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case dwarves, elves
}

/// Der Spielstand auf dem Gerät (D-022). Einstellungen gehören nicht hinein (K6).
public struct SaveGame: Codable, Equatable, Sendable {
    /// Schema dieser App-Fassung. Jede Änderung am Aufbau hebt sie und bringt
    /// eine Migration in `SaveGameCodec.migrate` mit.
    public static let currentSchema = 1

    public var schemaVersion: Int
    public var progress: CampaignProgress
    public var race: Race?

    public init(progress: CampaignProgress = CampaignProgress(), race: Race? = nil) {
        schemaVersion = Self.currentSchema
        self.progress = progress
        self.race = race
    }
}

/// Lesen ist Prüfen: Der Speicherstand kommt von außen (eine alte App, eine
/// halb geschriebene Datei, jemand mit Dateizugriff) und erreicht den
/// Fortschritt erst, wenn er zur Region passt.
public enum SaveGameCodec {
    public enum Failure: Error, Equatable, CustomStringConvertible {
        case unreadable(String)
        /// Von einer neueren App geschrieben. Nicht lesen und nicht überschreiben.
        case newerSchema(Int)
        case unknownSchema(Int)

        public var description: String {
            switch self {
            case .unreadable(let reason): "Spielstand nicht lesbar: \(reason)"
            case .newerSchema(let version): "Spielstand hat neueres Schema \(version)"
            case .unknownSchema(let version): "Spielstand hat unbekanntes Schema \(version)"
            }
        }
    }

    /// Was beim Prüfen verworfen wurde. Für das Protokoll, nie für den Spieler.
    public enum Dropped: Equatable, Sendable {
        case unknownMission(String)
        case starsOutOfRange(mission: String, stars: Int)
        case duplicateMission(String)
        case unknownRace(String)
    }

    public struct Decoded: Equatable, Sendable {
        public var save: SaveGame
        public var dropped: [Dropped]
    }

    public static func encode(_ save: SaveGame) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return try encoder.encode(save)
    }

    public static func decode(_ data: Data, campaign: CampaignConfig) throws(Failure) -> Decoded {
        let raw: RawSave
        do { raw = try JSONDecoder().decode(RawSave.self, from: data) } catch {
            throw .unreadable(String(describing: error))
        }
        if raw.schemaVersion > SaveGame.currentSchema { throw .newerSchema(raw.schemaVersion) }
        let migrated = try migrate(raw)

        var dropped: [Dropped] = []
        var records: [MissionRecord] = []
        for record in migrated.progress?.records ?? [] {
            if campaign.node(record.mission) == nil {
                dropped.append(.unknownMission(record.mission))
            } else if !(0...StarRating.maximum).contains(record.bestStars) {
                dropped.append(.starsOutOfRange(mission: record.mission, stars: record.bestStars))
            } else if records.contains(where: { $0.mission == record.mission }) {
                dropped.append(.duplicateMission(record.mission))
            } else if record.bestStars > 0 {
                records.append(record)
            }
        }
        var race: Race?
        if let name = migrated.race {
            if let known = Race(rawValue: name) { race = known } else { dropped.append(.unknownRace(name)) }
        }
        return Decoded(save: SaveGame(progress: CampaignProgress(records: records), race: race), dropped: dropped)
    }

    /// Hebt ältere Schemata Schritt für Schritt auf das aktuelle. Schema 1 ist
    /// das erste, also gibt es noch keinen Schritt; ein unbekanntes kleineres
    /// Schema (0, negativ) ist kein Spielstand dieser App.
    static func migrate(_ raw: RawSave) throws(Failure) -> RawSave {
        switch raw.schemaVersion {
        case SaveGame.currentSchema: raw
        default: throw .unknownSchema(raw.schemaVersion)
        }
    }

    /// Lose Form zum Lesen: Ein unbekanntes Volk oder ein fehlendes Feld soll
    /// einen Eintrag kosten, nicht den ganzen Stand.
    struct RawSave: Decodable {
        var schemaVersion: Int
        var progress: RawProgress?
        var race: String?
    }

    struct RawProgress: Decodable {
        var records: [MissionRecord]
    }
}
