import Foundation

/// Sterne nach einer Mission (05, „Sterne und Herausforderungen"). Rein, damit
/// Ergebnistafel, Speicherstand und Tests dieselbe Rechnung benutzen.
public enum StarRating {
    /// Höchste Wertung. Eine Eigenschaft der Regel (1 bis 3 Sterne), kein Balancewert.
    public static let maximum = 3

    public static func stars(outcome: Outcome, livesLeft: Int, thresholds: StarThresholds?) -> Int {
        guard outcome == .won else { return 0 }
        guard let thresholds else { return 1 }
        if livesLeft >= thresholds.three { return 3 }
        if livesLeft >= thresholds.two { return 2 }
        return 1
    }
}

// MARK: - Region aus der Datei

public enum CampaignNodeKind: String, Codable, Equatable, Sendable {
    case main, side, boss
}

/// Was eine Mission neu bringt (05, Spalte „Neu"). Die Anzeige steht in der App.
public enum CampaignNovelty: String, Codable, Equatable, Sendable {
    case basics, bank, upgrades, ability, specializations, boss, specialRule
}

public struct CampaignNode: Codable, Equatable, Sendable {
    public var id: String
    public var kind: CampaignNodeKind
    /// Name der Missionsdatei ohne Endung. Fehlt, solange die Mission nicht gebaut ist.
    public var mission: String?
    /// Lage als Anteil der Kartenfläche, damit jede Bildschirmgröße dieselbe Karte zeigt.
    public var position: Point
    public var requires: [String]
    /// Reicht einer der Vorgänger statt aller: Beide Wege der Gabelung führen zum Boss.
    public var requiresAny: Bool?
    /// Sternsumme der Region, ab der eine Nebenmission offen ist.
    public var stars: Int?
    public var novelty: CampaignNovelty?

    public init(
        id: String, kind: CampaignNodeKind, mission: String? = nil, position: Point,
        requires: [String] = [], requiresAny: Bool? = nil, stars: Int? = nil, novelty: CampaignNovelty? = nil
    ) {
        self.id = id
        self.kind = kind
        self.mission = mission
        self.position = position
        self.requires = requires
        self.requiresAny = requiresAny
        self.stars = stars
        self.novelty = novelty
    }
}

public struct CampaignConfig: Codable, Equatable, Sendable {
    public var id: String
    /// Reihenfolge der Datei = Reihenfolge auf der Karte und für „Weiter mit".
    public var nodes: [CampaignNode]

    public init(id: String, nodes: [CampaignNode]) {
        self.id = id
        self.nodes = nodes
    }

    public func node(_ id: String) -> CampaignNode? { nodes.first { $0.id == id } }
}

// MARK: - Fortschritt

public struct MissionRecord: Codable, Equatable, Sendable {
    public var mission: String
    public var bestStars: Int

    public init(mission: String, bestStars: Int) {
        self.mission = mission
        self.bestStars = bestStars
    }
}

/// Beste Wertung je Knoten. Eine sortierte Liste statt eines Wörterbuchs, damit
/// die Datei bei gleichem Stand immer gleich aussieht.
public struct CampaignProgress: Codable, Equatable, Sendable {
    public private(set) var records: [MissionRecord]

    public init(records: [MissionRecord] = []) {
        self.records = records.sorted { $0.mission < $1.mission }
    }

    public func stars(for mission: String) -> Int {
        records.first { $0.mission == mission }?.bestStars ?? 0
    }

    public var totalStars: Int { records.reduce(0) { $0 + $1.bestStars } }

    /// Behält die beste Wertung: Eine schwächere Runde nimmt nichts weg, eine
    /// Niederlage (0 Sterne) ändert nichts.
    public func recording(stars: Int, for mission: String) -> CampaignProgress {
        guard stars > self.stars(for: mission) else { return self }
        var next = records.filter { $0.mission != mission }
        next.append(MissionRecord(mission: mission, bestStars: stars))
        return CampaignProgress(records: next)
    }
}

// MARK: - Regeln

public enum LockReason: Equatable, Sendable {
    /// Diese Vorgänger fehlen (bei `requiresAny` reicht einer davon).
    case after([String])
    /// So viele Sterne braucht die Nebenmission insgesamt.
    case stars(Int)
}

public enum CampaignNodeState: Equatable, Sendable {
    case completed(stars: Int)
    case open
    /// Nach den Regeln offen, die Mission ist aber noch nicht gebaut.
    case inPreparation
    case locked(LockReason)

    public var isPlayable: Bool {
        switch self {
        case .completed, .open: true
        case .inPreparation, .locked: false
        }
    }
}

extension CampaignConfig {
    public func state(of node: CampaignNode, progress: CampaignProgress) -> CampaignNodeState {
        let earned = progress.stars(for: node.id)
        if earned > 0, node.mission != nil { return .completed(stars: earned) }

        let missing = node.requires.filter { progress.stars(for: $0) == 0 }
        let reachable = node.requires.isEmpty
            || (node.requiresAny == true ? missing.count < node.requires.count : missing.isEmpty)
        if !reachable { return .locked(.after(missing)) }
        if let needed = node.stars, progress.totalStars < needed { return .locked(.stars(needed)) }
        return node.mission == nil ? .inPreparation : .open
    }

    /// Sterne, die die Region überhaupt hergeben kann: der Nenner neben der Summe.
    public var maximumStars: Int { nodes.count * StarRating.maximum }

    /// Der Knoten für „Weiter mit Mission N": der erste offene, noch nicht
    /// gewonnene; sonst der letzte gewonnene, damit der Knopf nie ins Leere zeigt.
    public func continueNode(progress: CampaignProgress) -> CampaignNode? {
        if let next = nodes.first(where: { state(of: $0, progress: progress) == .open }) { return next }
        return nodes.last { if case .completed = state(of: $0, progress: progress) { true } else { false } }
    }
}

// MARK: - Prüfung und Laden

public struct CampaignIssue: Equatable, Sendable, CustomStringConvertible {
    public var node: String
    public var rule: Rule

    public enum Rule: Equatable, Sendable {
        case duplicateID
        case unknownRequirement(String)
        case cycle
        case noStart
        case positionOutsideMap
        case starsNotPositive
        case missionInvalid(String)
    }

    public init(node: String, rule: Rule) {
        self.node = node
        self.rule = rule
    }

    public var description: String {
        switch rule {
        case .duplicateID: "Knoten \(node) kommt mehrfach vor"
        case .unknownRequirement(let other): "Knoten \(node) verlangt unbekannten Knoten \(other)"
        case .cycle: "Knoten \(node) liegt in einem Kreis von Bedingungen"
        case .noStart: "Die Region hat keinen Knoten ohne Bedingung"
        case .positionOutsideMap: "Knoten \(node) liegt außerhalb der Karte (0 bis 1)"
        case .starsNotPositive: "Knoten \(node): stars muss größer als 0 sein"
        case .missionInvalid(let reason): "Mission von Knoten \(node): \(reason)"
        }
    }
}

public enum CampaignError: Error, Equatable, CustomStringConvertible {
    case resourceMissing(String)
    case unreadable(String)
    case invalid([CampaignIssue])

    public var description: String {
        switch self {
        case .resourceMissing(let name): "Region \(name) nicht gefunden"
        case .unreadable(let reason): "Region nicht lesbar: \(reason)"
        case .invalid(let issues): issues.map(\.description).joined(separator: "\n")
        }
    }
}

extension CampaignConfig {
    /// `loadMission` ist austauschbar, damit die Regeln ohne Paketdateien testbar sind.
    public func issues(
        loadMission: (String) throws(ConfigError) -> BalanceConfig = BalanceConfig.bundledMission(named:)
    ) -> [CampaignIssue] {
        var found: [CampaignIssue] = []
        var seen: [String] = []
        for node in nodes {
            if seen.contains(node.id) { found.append(.init(node: node.id, rule: .duplicateID)) }
            seen.append(node.id)
        }
        for node in nodes {
            for other in node.requires where !seen.contains(other) {
                found.append(.init(node: node.id, rule: .unknownRequirement(other)))
            }
            if !(0...1).contains(node.position.x) || !(0...1).contains(node.position.y) {
                found.append(.init(node: node.id, rule: .positionOutsideMap))
            }
            if let stars = node.stars, stars <= 0 {
                found.append(.init(node: node.id, rule: .starsNotPositive))
            }
            if let mission = node.mission {
                do { _ = try loadMission(mission) } catch {
                    found.append(.init(node: node.id, rule: .missionInvalid(error.description)))
                }
            }
        }
        if !nodes.contains(where: { $0.requires.isEmpty }) {
            found.append(.init(node: id, rule: .noStart))
        }
        for node in nodes where reachesItself(node.id) {
            found.append(.init(node: node.id, rule: .cycle))
        }
        return found
    }

    private func reachesItself(_ start: String) -> Bool {
        var stack = node(start)?.requires ?? []
        var visited: [String] = []
        while let current = stack.popLast() {
            if current == start { return true }
            if visited.contains(current) { continue }
            visited.append(current)
            stack.append(contentsOf: node(current)?.requires ?? [])
        }
        return false
    }

    /// Lesen und prüfen in einem Schritt, wie bei `BalanceConfig.load`.
    public static func load(
        from data: Data,
        loadMission: (String) throws(ConfigError) -> BalanceConfig = BalanceConfig.bundledMission(named:)
    ) throws(CampaignError) -> CampaignConfig {
        let config: CampaignConfig
        do {
            config = try JSONDecoder().decode(CampaignConfig.self, from: data)
        } catch {
            throw .unreadable(String(describing: error))
        }
        let found = config.issues(loadMission: loadMission)
        if !found.isEmpty { throw .invalid(found) }
        return config
    }

    /// Region 1 „Flüsterwald" (D-027) aus den Paket-Ressourcen.
    public static func regionOne() throws(CampaignError) -> CampaignConfig {
        let name = "region-01"
        guard let url = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Campaign")
        else { throw .resourceMissing(name) }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { throw .unreadable(String(describing: error)) }
        return try load(from: data)
    }
}
