import Foundation

/// Die drei Plätze am Avatar (R-7, D-066). Jeder Platz trägt höchstens ein Stück.
public enum EquipmentSlot: String, Codable, CaseIterable, Sendable {
    /// Wirkt auf Türme.
    case banner
    /// Wirkt auf die Festungsfähigkeit.
    case amulet
    /// Wirkt auf Festung und Gold.
    case seal
}

/// Werte einer Mission, die ein Stück verschieben darf. Faktoren statt fester
/// Zuschläge, damit Stücke sich verrechnen lassen, ohne einander zu kennen.
public enum EquipmentField: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case towerDamage, towerRange, towerCost, startGold, fortressLives, abilityCooldown

    /// Welche Felder auf welchen Platz gehören. Ein Banner am Startgold wäre ein
    /// Siegel unter falschem Namen; die Prüfung der Tabelle hält das fest.
    public var slot: EquipmentSlot {
        switch self {
        case .towerDamage, .towerRange, .towerCost: .banner
        case .abilityCooldown: .amulet
        case .startGold, .fortressLives: .seal
        }
    }
}

/// Woher ein Stück kommt (D-070, R-7a: feste Belohnungen). Genau eine der zwei
/// Formen: beste Sterne einer Mission oder die Sternsumme der Region.
public struct EquipmentSource: Codable, Equatable, Sendable {
    public var mission: String?
    /// Mit `mission`: mindestens so viele Sterne dort. Ohne: Sternsumme.
    public var stars: Int

    public init(mission: String? = nil, stars: Int) {
        self.mission = mission
        self.stars = stars
    }

    public func isMet(by progress: CampaignProgress) -> Bool {
        if let mission { return progress.stars(for: mission) >= stars }
        return progress.totalStars >= stars
    }
}

public struct EquipmentPiece: Codable, Equatable, Sendable {
    public var id: String
    public var slot: EquipmentSlot
    public var source: EquipmentSource
    /// Nur zum Nachschlagen, nie darüber iterieren (Architekturregel 6).
    public var bonus: [EquipmentField: Double]
    /// Nur diese Turmart, wenn gesetzt; sonst alle. Gilt nur für Turmfelder.
    public var tower: TowerKind?

    public init(id: String, slot: EquipmentSlot, source: EquipmentSource,
                bonus: [EquipmentField: Double], tower: TowerKind? = nil) {
        self.id = id
        self.slot = slot
        self.source = source
        self.bonus = bonus
        self.tower = tower
    }
}

/// Welches Stück je Platz angelegt ist. Besitz steht nicht hier: Er folgt aus dem
/// Fortschritt, damit ein veränderter Spielstand nichts erschleichen kann.
public struct EquipmentLoadout: Codable, Equatable, Sendable {
    public var banner: String?
    public var amulet: String?
    public var seal: String?

    public init(banner: String? = nil, amulet: String? = nil, seal: String? = nil) {
        self.banner = banner
        self.amulet = amulet
        self.seal = seal
    }

    public subscript(slot: EquipmentSlot) -> String? {
        get {
            switch slot {
            case .banner: banner
            case .amulet: amulet
            case .seal: seal
            }
        }
        set {
            switch slot {
            case .banner: banner = newValue
            case .amulet: amulet = newValue
            case .seal: seal = newValue
            }
        }
    }

    public var isEmpty: Bool { EquipmentSlot.allCases.allSatisfy { self[$0] == nil } }

    /// Lose lesen: Eine kaputte Kennung kostet nur ihren Platz, nie den Avatar.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        func read(_ key: CodingKeys) -> String? {
            guard let id = (try? container.decodeIfPresent(String.self, forKey: key)) ?? nil else { return nil }
            return EquipmentTable.isValidID(id) ? id : nil
        }
        banner = read(.banner)
        amulet = read(.amulet)
        seal = read(.seal)
    }
}

/// Alle Stücke aus `Balance/equipment.json`. Werte stehen nur dort (Architekturregel 7).
public struct EquipmentTable: Codable, Equatable, Sendable {
    /// Reihenfolge der Datei = Reihenfolge im Avatar-Menü.
    public var pieces: [EquipmentPiece]

    public init(pieces: [EquipmentPiece]) { self.pieces = pieces }

    public static let maxIDLength = 32

    /// Wie Porträtkennungen: Die Kennung kommt aus dem Spielstand, also von außen.
    public static func isValidID(_ id: String) -> Bool { Avatar.isValidPortrait(id) && id.count <= maxIDLength }

    public func piece(_ id: String) -> EquipmentPiece? { pieces.first { $0.id == id } }

    public func pieces(in slot: EquipmentSlot) -> [EquipmentPiece] { pieces.filter { $0.slot == slot } }

    public func owns(_ id: String, progress: CampaignProgress) -> Bool {
        piece(id)?.source.isMet(by: progress) ?? false
    }

    /// Was in der Mission gilt: je Platz das angelegte Stück, wenn es das Stück
    /// gibt, es auf diesen Platz gehört und schon erhalten ist; sonst leer.
    public func effective(_ loadout: EquipmentLoadout, progress: CampaignProgress) -> [EquipmentPiece] {
        EquipmentSlot.allCases.compactMap { slot in
            guard let id = loadout[slot], let piece = piece(id), piece.slot == slot,
                  piece.source.isMet(by: progress) else { return nil }
            return piece
        }
    }

    /// Jede volle Belegung, eine je Kombination aus einem Stück je Platz.
    /// Für die Balancetests: Die Obergrenze gilt für jede.
    public func fullLoadouts() -> [[EquipmentPiece]] {
        EquipmentSlot.allCases.reduce([[]]) { partial, slot in
            partial.flatMap { prefix in pieces(in: slot).map { prefix + [$0] } }
        }
    }

    public func issues(campaign: CampaignConfig? = nil) -> [ConfigIssue] {
        var found: [ConfigIssue] = []
        for (index, piece) in pieces.enumerated() {
            let field = "pieces.\(index)"
            if !Self.isValidID(piece.id) { found.append(.init(field: "\(field).id", rule: .invalidID)) }
            if pieces[..<index].contains(where: { $0.id == piece.id }) {
                found.append(.init(field: "\(field).id", rule: .duplicateID))
            }
            if !(piece.source.stars > 0) { found.append(.init(field: "\(field).source.stars", rule: .mustBePositive)) }
            if let mission = piece.source.mission {
                if let campaign, campaign.node(mission) == nil {
                    found.append(.init(field: "\(field).source.mission", rule: .unknownMission))
                }
                if piece.source.stars > StarRating.maximum {
                    found.append(.init(field: "\(field).source.stars", rule: .starsAboveMaximum))
                }
            }
            // Mehr Sterne, als die Region vergibt, hieße ein Stück, das niemand bekommt.
            else if let campaign, piece.source.stars > campaign.nodes.count * StarRating.maximum {
                found.append(.init(field: "\(field).source.stars", rule: .starsAboveMaximum))
            }
            var any = false
            for name in EquipmentField.allCases {
                guard let factor = piece.bonus[name] else { continue }
                any = true
                if !(factor > 0) { found.append(.init(field: "\(field).bonus.\(name.rawValue)", rule: .mustBePositive)) }
                if name.slot != piece.slot {
                    found.append(.init(field: "\(field).bonus.\(name.rawValue)", rule: .fieldNotInSlot))
                }
            }
            if !any { found.append(.init(field: "\(field).bonus", rule: .noBonus)) }
        }
        for slot in EquipmentSlot.allCases where pieces(in: slot).isEmpty {
            found.append(.init(field: "pieces[\(slot.rawValue)]", rule: .emptySlot))
        }
        return found
    }

    public static func load(from data: Data, campaign: CampaignConfig? = nil) throws(ConfigError) -> EquipmentTable {
        let table: EquipmentTable
        do { table = try JSONDecoder().decode(EquipmentTable.self, from: data) } catch {
            throw .unreadable(String(describing: error))
        }
        let found = table.issues(campaign: campaign)
        if !found.isEmpty { throw .invalid(found) }
        return table
    }

    public static func bundled(campaign: CampaignConfig? = nil) throws(ConfigError) -> EquipmentTable {
        guard let url = Bundle.module.url(forResource: "equipment", withExtension: "json", subdirectory: "Balance")
        else { throw .resourceMissing("equipment") }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { throw .unreadable(String(describing: error)) }
        return try load(from: data, campaign: campaign)
    }
}

extension BalanceConfig {
    /// Dieselbe Mission mit angelegter Ausrüstung: wie Volk und Talente eine
    /// fertige Konfiguration, damit die Simulation keine Ausrüstung kennt.
    /// Gold und Leben auf ganze Werte gerundet, weil Kasse und Festung nur die kennen.
    public func applying(equipment pieces: [EquipmentPiece]) -> BalanceConfig {
        var config = self
        for piece in pieces {
            for field in EquipmentField.allCases {
                guard let factor = piece.bonus[field] else { continue }
                switch field {
                case .towerDamage, .towerRange, .towerCost:
                    for kind in TowerKind.allCases where piece.tower == nil || piece.tower == kind {
                        guard var tower = config.towers[kind] else { continue }
                        switch field {
                        case .towerDamage: tower.damage *= factor
                        case .towerRange: tower.range *= factor
                        default: tower.cost = Int((Double(tower.cost) * factor).rounded())
                        }
                        config.towers[kind] = tower
                    }
                case .startGold:
                    config.mission.startGold = Int((Double(config.mission.startGold) * factor).rounded())
                case .fortressLives:
                    config.mission.fortressLives = Int((Double(config.mission.fortressLives) * factor).rounded())
                case .abilityCooldown:
                    config.ability?.cooldown *= factor
                }
            }
        }
        return config
    }

    public func applying(_ race: RaceConfig, talents: [TalentSide], equipment: [EquipmentPiece]) -> BalanceConfig {
        applying(race, talents: talents).applying(equipment: equipment)
    }
}
