import Foundation

/// Startvölker (03). Seit R-4 wirksam, seit R-5 Teil des Avatars; ihre Werte
/// stehen in `races.json` (`RaceTable`).
public enum Race: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case dwarves, elves
}

/// Der Spielstand auf dem Gerät (D-022). Einstellungen gehören nicht hinein (K6).
public struct SaveGame: Codable, Equatable, Sendable {
    /// Schema dieser App-Fassung. Jede Änderung am Aufbau hebt sie und bringt
    /// eine Migration in `SaveGameCodec.migrate` mit.
    /// 1: Fortschritt und Volk (0.7.0). 2: Avatar statt Volk (R-5).
    /// 3: laufende Mission (P2-2).
    public static let currentSchema = 3

    public var schemaVersion: Int
    public var progress: CampaignProgress
    /// Fehlt, bis der Spieler ihn beim ersten „Spielen“ aufbaut.
    public var avatar: Avatar?
    /// Mission, die lief, als die App in den Hintergrund ging (P2-2). Ob sie
    /// fortgesetzt wird, entscheidet die App mit `SuspendedBattle.problems`,
    /// weil erst sie die gespielte Konfiguration kennt.
    public var battle: SuspendedBattle?

    public init(progress: CampaignProgress = CampaignProgress(), avatar: Avatar? = nil,
                battle: SuspendedBattle? = nil) {
        schemaVersion = Self.currentSchema
        self.progress = progress
        self.avatar = avatar
        self.battle = battle
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
        /// Name oder Porträt fehlt oder besteht die Prüfung nicht. Kostet den
        /// Avatar, nicht den Fortschritt: Der Spieler baut ihn neu auf.
        case invalidAvatar
        /// Die gesicherte Mission ist nicht lesbar. Kostet nur sie.
        case unreadableBattle
        /// Die gesicherte Mission gehört zu keinem Knoten der Region.
        case unknownBattleNode(String)
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
        var avatar: Avatar?
        if let rawAvatar = migrated.avatar {
            if let raceName = rawAvatar.race, Race(rawValue: raceName) == nil {
                dropped.append(.unknownRace(raceName))
            } else if let race = rawAvatar.race.flatMap(Race.init(rawValue:)), let name = rawAvatar.name,
                      let portrait = rawAvatar.portrait, var valid = Avatar(race: race, name: name, portrait: portrait) {
                valid.talents = Avatar.validTalents(rawAvatar.talents)
                valid.equipment = rawAvatar.equipment ?? EquipmentLoadout()
                valid.forge = rawAvatar.forge ?? ForgeState()
                avatar = valid
            } else {
                dropped.append(.invalidAvatar)
            }
        }
        var battle: SuspendedBattle?
        switch migrated.battle {
        case .none, .absent: break
        case .unreadable: dropped.append(.unreadableBattle)
        case .read(let read):
            if campaign.node(read.node) == nil { dropped.append(.unknownBattleNode(read.node)) } else { battle = read }
        }
        return Decoded(save: SaveGame(progress: CampaignProgress(records: records), avatar: avatar, battle: battle),
                       dropped: dropped)
    }

    /// Hebt ältere Schemata Schritt für Schritt auf das aktuelle; ein
    /// unbekanntes kleineres Schema (0, negativ) ist kein Spielstand dieser App.
    static func migrate(_ raw: RawSave) throws(Failure) -> RawSave {
        var raw = raw
        switch raw.schemaVersion {
        case 1:
            // Schema 1 kannte nur das Volk, gewählt vor jeder Mission. Ohne Name
            // und Porträt ist das kein Avatar: Der Spieler baut ihn einmal auf
            // und behält seinen Fortschritt (Konzept r-5-avatar.md).
            raw.race = nil
            raw.avatar = nil
            raw.schemaVersion = 2
            return try migrate(raw)
        case 2:
            // Schema 2 kannte keine laufende Mission; es gibt nichts umzubauen.
            raw.battle = .absent
            raw.schemaVersion = 3
            return try migrate(raw)
        case SaveGame.currentSchema: return raw
        default: throw .unknownSchema(raw.schemaVersion)
        }
    }

    /// Lose Form zum Lesen: Ein unbekanntes Volk oder ein fehlendes Feld soll
    /// einen Eintrag kosten, nicht den ganzen Stand.
    struct RawSave: Decodable {
        var schemaVersion: Int
        var progress: RawProgress?
        /// Nur Schema 1.
        var race: String?
        var avatar: RawAvatar?
        var battle: RawBattle?

        enum CodingKeys: String, CodingKey { case schemaVersion, progress, race, avatar, battle }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
            progress = try container.decodeIfPresent(RawProgress.self, forKey: .progress)
            race = try container.decodeIfPresent(String.self, forKey: .race)
            avatar = try container.decodeIfPresent(RawAvatar.self, forKey: .avatar)
            if container.contains(.battle), !((try? container.decodeNil(forKey: .battle)) ?? false) {
                // Ein kaputter Zustand kostet die Mission, nicht Fortschritt und Avatar.
                battle = (try? container.decode(SuspendedBattle.self, forKey: .battle)).map(RawBattle.read) ?? .unreadable
            } else {
                battle = .absent
            }
        }
    }

    enum RawBattle {
        case absent
        case unreadable
        case read(SuspendedBattle)
    }

    struct RawAvatar: Decodable {
        var race: String?
        var name: String?
        var portrait: String?
        var talents: [String]?
        var equipment: EquipmentLoadout?
        var forge: ForgeState?

        enum CodingKeys: String, CodingKey { case race, name, portrait, talents, equipment, forge }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            race = try container.decodeIfPresent(String.self, forKey: .race)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            portrait = try container.decodeIfPresent(String.self, forKey: .portrait)
            // Falscher Typ heißt kaputte Wahl, nicht kaputte Datei.
            talents = (try? container.decodeIfPresent([String].self, forKey: .talents)) ?? nil
            equipment = (try? container.decodeIfPresent(EquipmentLoadout.self, forKey: .equipment)) ?? nil
            forge = (try? container.decodeIfPresent(ForgeState.self, forKey: .forge)) ?? nil
        }
    }

    struct RawProgress: Decodable {
        var records: [MissionRecord]
    }
}
