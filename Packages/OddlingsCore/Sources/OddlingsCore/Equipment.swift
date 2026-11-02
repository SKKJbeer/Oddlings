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
    /// Boni der geschmiedeten Stufen II, III, … (R-7b). `bonus` ist Stufe I.
    public var levels: [[EquipmentField: Double]]?

    public init(id: String, slot: EquipmentSlot, source: EquipmentSource,
                bonus: [EquipmentField: Double], tower: TowerKind? = nil,
                levels: [[EquipmentField: Double]]? = nil) {
        self.id = id
        self.slot = slot
        self.source = source
        self.bonus = bonus
        self.tower = tower
        self.levels = levels
    }

    public var maxLevel: Int { 1 + (levels?.count ?? 0) }

    /// Dasselbe Stück mit den Boni der Stufe; außerhalb des Bereichs die nächste gültige.
    public func at(level: Int) -> EquipmentPiece {
        let level = min(max(level, 1), maxLevel)
        guard level > 1, let levels else { return self }
        var piece = self
        piece.bonus = levels[level - 2]
        return piece
    }
}

extension EquipmentField {
    /// Für Preis und Abklingzeit ist weniger besser; eine höhere Stufe muss
    /// in diese Richtung gehen, sonst wäre Schmieden ein Rückschritt.
    public var lowerIsBetter: Bool { self == .towerCost || self == .abilityCooldown }
}

/// Werte der Schmiede (R-7b). Erz gibt jeder Sieg, neue Sterne geben mehr.
public struct ForgeConfig: Codable, Equatable, Sendable {
    public var winOre: Int
    public var newStarOre: Int
    /// Mehr hält die Truhe nicht; was darüber hinausgeht, verfällt.
    public var maxOre: Int
    /// `levelCosts[0]` kostet Stufe II, `levelCosts[1]` Stufe III, …
    public var levelCosts: [Int]

    public init(winOre: Int, newStarOre: Int, maxOre: Int, levelCosts: [Int]) {
        self.winOre = winOre
        self.newStarOre = newStarOre
        self.maxOre = maxOre
        self.levelCosts = levelCosts
    }

    /// Erz für ein Ergebnis: nichts bei Niederlage, sonst Sieg plus jeder Stern
    /// über dem bisherigen Bestwert. So bringt Wiederholen wenig und neue Sterne viel.
    public func ore(won: Bool, starsBefore: Int, starsAfter: Int) -> Int {
        guard won else { return 0 }
        return winOre + max(0, starsAfter - starsBefore) * newStarOre
    }
}

/// Geschmiedete Stufe eines Stücks. Nur Stufen ab II stehen im Spielstand.
public struct EquipmentLevel: Codable, Equatable, Sendable {
    public var piece: String
    public var level: Int

    public init(piece: String, level: Int) {
        self.piece = piece
        self.level = level
    }
}

/// Erz und Stufen im Spielstand (R-7b). Anders als der Besitz lässt sich der
/// Bestand nicht aus dem Fortschritt ableiten, weil Wiederholen Erz bringt.
/// Das Spiel ist offline und allein: Die Prüfung beim Laden verwirft Unsinn,
/// sie schützt nicht gegen Absicht, die nur dem Spieler selbst schadet.
public struct ForgeState: Codable, Equatable, Sendable {
    /// Formgrenzen der Datei, nicht der Spielwerte (die stehen in `ForgeConfig`).
    public static let maxStoredOre = 99_999
    public static let maxStoredLevel = 9

    public private(set) var ore: Int = 0
    /// Sortiert nach Kennung, je Stück höchstens einmal, nur Stufen ab II.
    public private(set) var levels: [EquipmentLevel] = []

    public init(ore: Int = 0, levels: [EquipmentLevel] = []) {
        self.ore = Self.validOre(ore) ?? 0
        for entry in levels { setLevel(entry.level, of: entry.piece) }
    }

    public var isEmpty: Bool { ore == 0 && levels.isEmpty }

    public func level(of id: String) -> Int { levels.first { $0.piece == id }?.level ?? 1 }

    mutating func setLevel(_ level: Int, of id: String) {
        levels.removeAll { $0.piece == id }
        guard EquipmentTable.isValidID(id), (2...Self.maxStoredLevel).contains(level) else { return }
        levels.append(EquipmentLevel(piece: id, level: level))
        levels.sort { $0.piece < $1.piece }
    }

    mutating func add(_ amount: Int, cap: Int) { ore = min(cap, Self.maxStoredOre, ore + max(0, amount)) }

    mutating func spend(_ amount: Int) -> Bool {
        guard amount >= 0, amount <= ore else { return false }
        ore -= amount
        return true
    }

    static func validOre(_ ore: Int) -> Int? { (0...maxStoredOre).contains(ore) ? ore : nil }

    enum CodingKeys: String, CodingKey { case ore, levels }

    /// Lose lesen: Ein kaputter Bestand wird 0, eine kaputte Stufe Stufe I,
    /// jedes für sich; nie geht der Avatar verloren.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ore = ((try? container.decodeIfPresent(Int.self, forKey: .ore)) ?? nil).flatMap(Self.validOre) ?? 0
        let raw = ((try? container.decodeIfPresent([LooseLevel].self, forKey: .levels)) ?? nil) ?? []
        for entry in raw {
            guard let piece = entry.piece, let level = entry.level,
                  !levels.contains(where: { $0.piece == piece }) else { continue }
            setLevel(level, of: piece)
        }
    }

    private struct LooseLevel: Decodable {
        var piece: String?
        var level: Int?
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            piece = (try? container.decodeIfPresent(String.self, forKey: .piece)) ?? nil
            level = (try? container.decodeIfPresent(Int.self, forKey: .level)) ?? nil
        }
        enum CodingKeys: String, CodingKey { case piece, level }
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
    /// Ohne Abschnitt gibt es keine Schmiede, und alle Stücke bleiben auf Stufe I.
    public var forge: ForgeConfig?

    public init(pieces: [EquipmentPiece], forge: ForgeConfig? = nil) {
        self.pieces = pieces
        self.forge = forge
    }

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
    /// Die Stufen kommen aus der Schmiede; ohne Schmiede gilt Stufe I.
    public func effective(_ loadout: EquipmentLoadout, progress: CampaignProgress,
                          forge state: ForgeState = ForgeState()) -> [EquipmentPiece] {
        EquipmentSlot.allCases.compactMap { slot in
            guard let id = loadout[slot], let piece = piece(id), piece.slot == slot,
                  piece.source.isMet(by: progress) else { return nil }
            return piece.at(level: level(of: id, in: state))
        }
    }

    /// Gespeicherte Stufe, begrenzt auf das, was Stück und Schmiede kennen.
    public func level(of id: String, in state: ForgeState) -> Int {
        guard let piece = piece(id), let forge else { return 1 }
        return min(state.level(of: id), piece.maxLevel, forge.levelCosts.count + 1)
    }

    /// Preis der nächsten Stufe; `nil`, wenn es keine gibt.
    public func upgradeCost(of id: String, in state: ForgeState) -> Int? {
        guard let piece = piece(id), let forge else { return nil }
        let level = level(of: id, in: state)
        guard level < piece.maxLevel, level - 1 < forge.levelCosts.count else { return nil }
        return forge.levelCosts[level - 1]
    }

    /// Eine Stufe schmieden: nur für erhaltene Stücke, nur mit genug Erz.
    public func upgrade(_ id: String, in state: inout ForgeState, progress: CampaignProgress) -> Bool {
        guard owns(id, progress: progress), let cost = upgradeCost(of: id, in: state) else { return false }
        let next = level(of: id, in: state) + 1
        guard state.spend(cost) else { return false }
        state.setLevel(next, of: id)
        return true
    }

    /// Erz für ein Missionsergebnis gutschreiben; gibt die Menge zurück, die ankam.
    @discardableResult
    public func credit(won: Bool, starsBefore: Int, starsAfter: Int, to state: inout ForgeState) -> Int {
        guard let forge else { return 0 }
        let before = state.ore
        state.add(forge.ore(won: won, starsBefore: starsBefore, starsAfter: starsAfter), cap: forge.maxOre)
        return state.ore - before
    }

    /// Jede volle Belegung, eine je Kombination aus einem Stück je Platz, auf
    /// Stufe I oder auf der höchsten Stufe. Für die Balancetests: Die Obergrenze gilt für jede.
    public func fullLoadouts(atMaxLevel: Bool = false) -> [[EquipmentPiece]] {
        EquipmentSlot.allCases.reduce([[]]) { partial, slot in
            partial.flatMap { prefix in
                pieces(in: slot).map { prefix + [atMaxLevel ? $0.at(level: $0.maxLevel) : $0] }
            }
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
            var previous = piece.bonus
            for (step, level) in (piece.levels ?? []).enumerated() {
                let place = "\(field).levels.\(step)"
                for name in EquipmentField.allCases {
                    switch (previous[name], level[name]) {
                    case (nil, nil): continue
                    case let (old?, new?):
                        if !(new > 0) { found.append(.init(field: "\(place).\(name.rawValue)", rule: .mustBePositive)) }
                        if name.lowerIsBetter ? !(new < old) : !(new > old) {
                            found.append(.init(field: "\(place).\(name.rawValue)", rule: .levelNotStronger))
                        }
                    default: found.append(.init(field: "\(place).\(name.rawValue)", rule: .levelFieldsDiffer))
                    }
                }
                previous = level
            }
            if let forge, piece.maxLevel - 1 > forge.levelCosts.count {
                found.append(.init(field: "\(field).levels", rule: .levelWithoutCost))
            }
        }
        if let forge {
            if forge.winOre < 0 { found.append(.init(field: "forge.winOre", rule: .mustNotBeNegative)) }
            if !(forge.newStarOre > 0) { found.append(.init(field: "forge.newStarOre", rule: .mustBePositive)) }
            if !(forge.maxOre > 0) || forge.maxOre > ForgeState.maxStoredOre {
                found.append(.init(field: "forge.maxOre", rule: .mustBePositive))
            }
            if forge.levelCosts.count + 1 > ForgeState.maxStoredLevel {
                found.append(.init(field: "forge.levelCosts", rule: .levelWithoutCost))
            }
            for (index, cost) in forge.levelCosts.enumerated() where !(cost > 0) {
                found.append(.init(field: "forge.levelCosts.\(index)", rule: .mustBePositive))
            }
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
