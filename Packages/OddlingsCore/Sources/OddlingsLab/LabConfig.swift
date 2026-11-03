import Foundation
import OddlingsCore

/// Eigenschaften der Bots und Zielwerte des Labors aus `labor.json` (P2-6b).
/// Keine Zahl davon steht im Code (Architekturregel 7); geprüft wird beim Laden.
public struct LabConfig: Codable, Equatable, Sendable {
    public var greedy: GreedyWeights
    public var human: HumanTraits
    public var random: RandomTraits
    public var reserve: ReserveSearch
    /// So viele Bauschritte hat eine erzeugte Monokultur; mehr, als je bezahlbar sind.
    public var monocultureSteps: Int
    public var stages: [String: Stage]
    public var targets: Targets
    /// Verletzte Zielwerte, die bewusst offen sind, je mit Grund (P2-6b).
    public var known: [Known]

    public struct Known: Codable, Equatable, Sendable {
        public var id: String
        public var reason: String
    }

    /// Platzierung des gierigen Bots, übernommen aus dem Phase-0-Prüfskript.
    public struct GreedyWeights: Codable, Equatable, Sendable {
        /// Abstand der Wegpunkte, an denen Abdeckung gezählt wird (Felder).
        public var sampleStep: Double
        /// So weit vor einer Mauer zählt der Bot heranlaufende Gegner (Felder).
        public var wallApproach: Double
        /// In dieser Reichweite nähme eine Bank einem Kampfturm Platz (Felder).
        public var bankProbe: Double
        /// Wert je abgedecktem Wegpunkt.
        public var coverWeight: Double
        /// Sporen zählen etwas über ihre Reichweite hinaus (Felder).
        public var sporeReach: Double
        /// Zuschlag je Sporenturm in der Nähe eines Blitzturms.
        public var lightningNearSpore: Double
        /// Was „in der Nähe“ heißt (Felder).
        public var sporeNeighbourhood: Double
    }

    /// Was einen Menschen vom gierigen Bot unterscheidet. Eine Annahme, keine Messung.
    public struct HumanTraits: Codable, Equatable, Sendable {
        /// So viele Ticks vergehen mindestens zwischen zwei Handlungen.
        public var reactionTicks: Int
        /// Aus so vielen besten Plätzen wählt er zufällig.
        public var placementSpread: Int
        /// So lange nach Bereitschaft wirft er die Fähigkeit frühestens.
        public var abilityDelayTicks: Int
        /// Anteil der Läufe, in denen er die Fähigkeit vergisst.
        public var abilitySkipShare: Double
    }

    /// Zufällige gültige Bauweisen, um ungenutzte Türme zu finden.
    public struct RandomTraits: Codable, Equatable, Sendable {
        public var minSteps: Int
        public var maxSteps: Int
        /// Anteil der Schritte, die einen Turm aufwerten, wo die Mission das kennt.
        public var upgradeShare: Double
    }

    /// Suche der Reserve wie im Prüfskript: Halbierungen zwischen zwei Faktoren.
    public struct ReserveSearch: Codable, Equatable, Sendable {
        public var low: Double
        public var high: Double
        public var halvings: Int
    }

    public struct Stage: Codable, Equatable, Sendable {
        /// Startwerte je Bot und Kombination; mehr Startwerte heißt mehr leicht verschiedene Spieler.
        public var seeds: Int
        public var races: [Race]
    }

    public struct Targets: Codable, Equatable, Sendable {
        /// Um höchstens so viel Reserve darf die beste Bauweise vor der zweitbesten liegen.
        public var dominanceMargin: Double
        /// Jeder Kampfturm steht in mindestens diesem Anteil der vom Zufallsbot gewonnenen Läufe.
        public var minBuildShare: Double
        /// Siegquote des Menschenbots beim ersten Spielen je Missionsknoten (Warnung bis zum Spieltest).
        public var humanWinRate: [String: Double]
    }

    /// Was an der Datei nicht stimmt, je Feld ein Satz.
    public func issues() -> [String] {
        var found: [String] = []
        func positive(_ value: Double, _ field: String) { if !(value > 0 && value.isFinite) { found.append("\(field) muss positiv sein") } }
        func positive(_ value: Int, _ field: String) { if value <= 0 { found.append("\(field) muss positiv sein") } }
        func rate(_ value: Double, _ field: String) { if !(value >= 0 && value <= 1) { found.append("\(field) muss zwischen 0 und 1 liegen") } }
        positive(greedy.sampleStep, "greedy.sampleStep")
        positive(greedy.wallApproach, "greedy.wallApproach")
        positive(greedy.bankProbe, "greedy.bankProbe")
        positive(greedy.coverWeight, "greedy.coverWeight")
        if !(greedy.sporeReach >= 0) { found.append("greedy.sporeReach darf nicht negativ sein") }
        if !(greedy.lightningNearSpore >= 0) { found.append("greedy.lightningNearSpore darf nicht negativ sein") }
        positive(greedy.sporeNeighbourhood, "greedy.sporeNeighbourhood")
        if human.reactionTicks < 0 { found.append("human.reactionTicks darf nicht negativ sein") }
        positive(human.placementSpread, "human.placementSpread")
        if human.abilityDelayTicks < 0 { found.append("human.abilityDelayTicks darf nicht negativ sein") }
        rate(human.abilitySkipShare, "human.abilitySkipShare")
        positive(random.minSteps, "random.minSteps")
        if random.maxSteps < random.minSteps { found.append("random.maxSteps muss mindestens random.minSteps sein") }
        rate(random.upgradeShare, "random.upgradeShare")
        positive(reserve.low, "reserve.low")
        if !(reserve.high > reserve.low) { found.append("reserve.high muss über reserve.low liegen") }
        positive(reserve.halvings, "reserve.halvings")
        positive(monocultureSteps, "monocultureSteps")
        if stages.isEmpty { found.append("stages darf nicht leer sein") }
        for name in stages.keys.sorted() {
            let stage = stages[name]!
            positive(stage.seeds, "stages.\(name).seeds")
            if stage.races.isEmpty { found.append("stages.\(name).races darf nicht leer sein") }
        }
        if !(targets.dominanceMargin >= 0) { found.append("targets.dominanceMargin darf nicht negativ sein") }
        rate(targets.minBuildShare, "targets.minBuildShare")
        for node in targets.humanWinRate.keys.sorted() { rate(targets.humanWinRate[node]!, "targets.humanWinRate.\(node)") }
        for (index, entry) in known.enumerated() {
            if entry.reason.trimmingCharacters(in: .whitespaces).isEmpty { found.append("known.\(entry.id) braucht einen Grund") }
            if known[..<index].contains(where: { $0.id == entry.id }) { found.append("known.\(entry.id) doppelt") }
        }
        return found
    }

    public static func load(from data: Data) throws(LabError) -> LabConfig {
        let config: LabConfig
        do { config = try JSONDecoder().decode(LabConfig.self, from: data) } catch {
            throw .unreadable(String(describing: error))
        }
        let found = config.issues()
        if !found.isEmpty { throw .invalid(found) }
        return config
    }

    public static func bundled() throws(LabError) -> LabConfig {
        guard let url = Bundle.module.url(forResource: "labor", withExtension: "json") else {
            throw .unreadable("labor.json fehlt im Paket")
        }
        let data: Data
        do { data = try Data(contentsOf: url) } catch { throw .unreadable(String(describing: error)) }
        return try load(from: data)
    }
}

public enum LabError: Error, Equatable, CustomStringConvertible {
    case unreadable(String)
    case invalid([String])
    case unknownStage(String)
    case unknownArgument(String)
    case config(String)

    public var description: String {
        switch self {
        case .unreadable(let reason): "Labor nicht lesbar: \(reason)"
        case .invalid(let issues): issues.joined(separator: "\n")
        case .unknownStage(let name): "Unbekannte Stufe \(name)"
        case .unknownArgument(let text): "Unbekanntes Argument \(text)"
        case .config(let reason): "Konfiguration: \(reason)"
        }
    }
}
