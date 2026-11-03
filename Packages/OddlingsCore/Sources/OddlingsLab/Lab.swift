import Foundation
import OddlingsCore

/// Eine Mission der Kampagne, wie ein Spieler sie zum ersten Mal spielt (D-071):
/// mit Rang, Talenten und Ausrüstung aus drei Sternen in allen Missionen davor.
public struct FirstPlay: Sendable {
    public var node: String
    public var mission: BalanceConfig
    public var race: Race
    public var raceConfig: RaceConfig
    public var unlockedRows: Int
    public var progress: CampaignProgress
    public var equipment: EquipmentTable

    /// Alle Knoten der Region mit Missionsdatei, in Kartenreihenfolge.
    public static func all(races: [Race]) throws -> [FirstPlay] {
        let campaign = try CampaignConfig.regionOne()
        let table = try RaceTable.bundled()
        let equipment = try EquipmentTable.bundled(campaign: campaign)
        var result: [FirstPlay] = []
        var progress = CampaignProgress()
        for node in campaign.nodes {
            guard let file = node.mission else { continue }
            let mission = try BalanceConfig.bundledMission(named: file)
            for race in races {
                guard let raceConfig = table.races[race] else { throw LabError.config("Volk \(race.rawValue) fehlt") }
                let rank = table.rank(stars: progress.totalStars)
                result.append(FirstPlay(node: node.id, mission: mission, race: race, raceConfig: raceConfig,
                                        unlockedRows: min(AvatarRank.unlockedRows(rank: rank), raceConfig.talents?.count ?? 0),
                                        progress: progress, equipment: equipment))
            }
            progress = progress.recording(stars: StarRating.maximum, for: node.id)
        }
        return result
    }

    /// Ohne Generator: Seite A in jeder freien Reihe und das erste erhaltene Stück
    /// je Platz. Mit Generator wählt er wie ein Spieler, der sich nicht festlegt.
    public func config(choosing rng: inout SplitMix64?) -> BalanceConfig {
        let sides = (0..<unlockedRows).map { _ -> TalentSide in
            guard rng != nil else { return .a }
            return rng!.next() % 2 == 0 ? .a : .b
        }
        let pieces = EquipmentSlot.allCases.compactMap { slot -> EquipmentPiece? in
            let owned = equipment.pieces(in: slot).filter { equipment.owns($0.id, progress: progress) }
            guard !owned.isEmpty else { return nil }
            guard rng != nil else { return owned[0] }
            return owned[Int(rng!.next() % UInt64(owned.count))]
        }
        return mission.applying(raceConfig, talents: sides, equipment: pieces)
    }

    public var greedyConfig: BalanceConfig {
        var none: SplitMix64?
        return config(choosing: &none)
    }
}

/// Ein Lauf des Labors als Zeile im Bericht.
public struct LabRecord: Equatable, Sendable {
    public enum Bot: String, Sendable { case greedy = "gierig", monoculture = "monokultur", human = "mensch", random = "zufall" }

    public var node: String
    public var race: Race
    public var bot: Bot
    /// Bauweise beim gierigen Bot und der Monokultur, Startwert sonst.
    public var variant: String
    public var won: Bool
    public var livesLeft: Int
    public var leaks: Int
    public var ticks: Int
    public var goldLeft: Int
    /// Nur beim gierigen Bot: Reserve der Bauweise.
    public var reserve: Double?
    public var built: [TowerKind: Int]
    public var violations: [String]

    /// Feste Reihenfolge, unabhängig davon, welcher Kern zuerst fertig war.
    public var sortKey: String {
        [node, race.rawValue, bot.rawValue, variant.count < 4 ? String(repeating: "0", count: 4 - variant.count) + variant : variant]
            .joined(separator: "|")
    }
}

/// Ein Zielwert und ob er hält.
public struct LabFinding: Equatable, Sendable {
    /// `known`: verletzt, aber in `labor.json` als bekannt eingetragen. Er bleibt im
    /// Bericht sichtbar, hält die CI aber nicht auf; neue Verletzungen schon.
    public enum Level: String, Sendable { case ok, warning = "Warnung", known = "bekannt", failure = "rot" }
    public var level: Level
    /// Feste Kennung des Ziels, damit ein bekannter Befund eingetragen werden kann.
    public var id: String
    public var text: String
}

public struct LabResult: Sendable {
    public var stage: String
    public var records: [LabRecord]
    public var findings: [LabFinding]
    public var failed: Bool { findings.contains { $0.level == .failure } }
}

/// Spielt eine Stufe des Labors (K11, P2-6b) über alle Kerne.
public enum Lab {
    public static func run(stage name: String, nodes: [String]? = nil, races: [Race]? = nil,
                           lab: LabConfig = .standard) async throws -> LabResult {
        guard let stage = lab.stages[name] else { throw LabError.unknownStage(name) }
        let plays = try FirstPlay.all(races: races ?? stage.races).filter { nodes?.contains($0.node) ?? true }
        let records = await withTaskGroup(of: [LabRecord].self) { group in
            for play in plays {
                for (strategy, order) in Strategies.of(play.mission) {
                    group.addTask { [greedy(play, strategy, order, lab)] }
                }
                for kind in [TowerKind.lightning, .spore] where play.mission.towers[kind] != nil {
                    group.addTask { [monoculture(play, kind, lab)] }
                }
                for seed in 0..<stage.seeds {
                    group.addTask { [human(play, seed, lab), random(play, seed, lab)] }
                }
            }
            var all: [LabRecord] = []
            for await part in group { all += part }
            return all.sorted { $0.sortKey < $1.sortKey }
        }
        return LabResult(stage: name, records: records, findings: evaluate(records, plays: plays, lab: lab))
    }

    static func record(_ play: FirstPlay, _ bot: LabRecord.Bot, _ variant: String, _ run: BotRun,
                       reserve: Double? = nil) -> LabRecord {
        LabRecord(node: play.node, race: play.race, bot: bot, variant: variant, won: run.state.outcome == .won,
                  livesLeft: run.state.fortressLives, leaks: run.leaks, ticks: run.state.tick, goldLeft: run.state.gold,
                  reserve: reserve, built: run.built, violations: run.violations)
    }

    static func greedy(_ play: FirstPlay, _ strategy: String, _ order: [StrategyStep], _ lab: LabConfig) -> LabRecord {
        let sim = Simulation(config: play.greedyConfig)
        let run = sim.play(order, castsAbility: true, lab: lab)
        return record(play, .greedy, strategy, run, reserve: sim.reserve(order, castsAbility: true, lab: lab))
    }

    static func monoculture(_ play: FirstPlay, _ kind: TowerKind, _ lab: LabConfig) -> LabRecord {
        let sim = Simulation(config: play.greedyConfig)
        let order = Array(repeating: StrategyStep.build(kind), count: lab.monocultureSteps)
        return record(play, .monoculture, kind.rawValue, sim.play(order, castsAbility: true, lab: lab))
    }

    /// Der Menschenbot nimmt eine der Mischungen seiner Mission, wählt Talente
    /// und Ausrüstung selbst, zögert und streut; manchmal vergisst er die Fähigkeit.
    static func human(_ play: FirstPlay, _ seed: Int, _ lab: LabConfig) -> LabRecord {
        var rng: SplitMix64? = SplitMix64(seed: botSeed(play, "mensch", seed))
        let config = play.config(choosing: &rng)
        let mixes = Strategies.of(play.mission).filter { Set($0.order.map(\.kind)).count > 1 }
        let pool = mixes.isEmpty ? Strategies.of(play.mission) : mixes
        let order = pool.isEmpty ? [] : pool[Int(rng!.next() % UInt64(pool.count))].order
        let casts = Double(rng!.next() % 1000) / 1000 >= lab.human.abilitySkipShare
        let sim = Simulation(config: config)
        var bot = LabBot(sim: sim, order: order, profile: .human(lab.human, castsAbility: casts), weights: lab.greedy,
                         seed: rng!.next())
        return record(play, .human, String(seed), sim.play(&bot))
    }

    /// Zufällige gültige Bauweise mit dem gierigen Platzierer: findet Türme,
    /// die nie zum Sieg beitragen.
    static func random(_ play: FirstPlay, _ seed: Int, _ lab: LabConfig) -> LabRecord {
        var rng = SplitMix64(seed: botSeed(play, "zufall", seed))
        let config = play.greedyConfig
        let kinds = TowerKind.allCases.filter { config.cost(of: $0) != nil }
        let span = UInt64(lab.random.maxSteps - lab.random.minSteps + 1)
        let length = lab.random.minSteps + Int(rng.next() % span)
        let order = (0..<length).map { _ -> StrategyStep in
            let kind = kinds[Int(rng.next() % UInt64(kinds.count))]
            let upgrade = config.upgradeCost(of: kind) != nil
                && Double(rng.next() % 1000) / 1000 < lab.random.upgradeShare
            return upgrade ? .upgrade(kind) : .build(kind)
        }
        let sim = Simulation(config: config)
        return record(play, .random, String(seed), sim.play(order, castsAbility: true, lab: lab))
    }

    /// Startwert je Bot und Kombination. FNV-1a statt `hashValue`, das Swift je
    /// Prozess neu würfelt: Zwei Läufe sollen dieselben Spieler sehen.
    static func botSeed(_ play: FirstPlay, _ bot: String, _ seed: Int) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in "\(play.node)|\(play.race.rawValue)|\(bot)|\(seed)".utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100_0000_01b3
        }
        return hash
    }

    static func evaluate(_ records: [LabRecord], plays: [FirstPlay], lab: LabConfig) -> [LabFinding] {
        var findings: [LabFinding] = []
        let targets = lab.targets
        for record in records where !record.violations.isEmpty {
            findings.append(.init(level: .failure, id: "invariante|\(record.node)|\(record.race.rawValue)|\(record.bot.rawValue)|\(record.variant)", text: "\(record.node) \(record.race.rawValue) \(record.bot.rawValue) \(record.variant): \(record.violations.joined(separator: "; "))"))
        }
        var seen: [String] = []
        for play in plays {
            let label = "\(play.node) \(play.race.rawValue)"
            let mine = records.filter { $0.node == play.node && $0.race == play.race }
            let reserves = mine.filter { $0.bot == .greedy }.compactMap { r in r.reserve.map { (r.variant, $0) } }
                .sorted { $0.1 > $1.1 }
            if reserves.count >= 2 {
                let gap = reserves[0].1 - reserves[1].1
                findings.append(.init(level: gap > targets.dominanceMargin ? .failure : .ok, id: "dominanz|\(play.node)|\(play.race.rawValue)",
                                      text: "\(label): „\(reserves[0].0)“ \(format(reserves[0].1)) vor „\(reserves[1].0)“ \(format(reserves[1].1)), Abstand \(format(gap)), erlaubt \(format(targets.dominanceMargin))"))
            }
            for mono in mine where mono.bot == .monoculture {
                findings.append(.init(level: mono.won ? .failure : .ok, id: "monokultur|\(play.node)|\(play.race.rawValue)|\(mono.variant)",
                                      text: "\(label): Monokultur \(mono.variant) \(mono.won ? "gewinnt beim ersten Spielen" : "verliert beim ersten Spielen")"))
            }
            guard !seen.contains(play.node) else { continue }
            seen.append(play.node)
            let node = records.filter { $0.node == play.node }
            let humans = node.filter { $0.bot == .human }
            if let target = targets.humanWinRate[play.node], !humans.isEmpty {
                let rate = Double(humans.filter(\.won).count) / Double(humans.count)
                findings.append(.init(level: rate + 1e-9 < target ? .warning : .ok, id: "mensch|\(play.node)",
                                      text: "\(play.node): Menschenbot gewinnt \(percent(rate)) beim ersten Spielen, Ziel \(percent(target))"))
            }
            let wonRandom = node.filter { $0.bot == .random && $0.won }
            if wonRandom.isEmpty {
                findings.append(.init(level: .warning, id: "zufall|\(play.node)", text: "\(play.node): kein Zufallslauf gewonnen, Nutzung der Türme nicht messbar"))
            } else {
                for kind in TowerKind.allCases where play.mission.towers[kind] != nil {
                    let share = Double(wonRandom.filter { ($0.built[kind] ?? 0) > 0 }.count) / Double(wonRandom.count)
                    findings.append(.init(level: share + 1e-9 < targets.minBuildShare ? .failure : .ok, id: "nutzung|\(play.node)|\(kind.rawValue)",
                                          text: "\(play.node): \(kind.rawValue) steht in \(percent(share)) der gewonnenen Zufallsläufe, mindestens \(percent(targets.minBuildShare))"))
                }
            }
        }
        return applyingKnown(findings, lab.known)
    }

    /// Bekannte Befunde stehen mit Grund in `labor.json`. Ein Eintrag, dessen
    /// Ziel wieder hält, meldet sich, damit die Liste nur schrumpft.
    static func applyingKnown(_ findings: [LabFinding], _ known: [LabConfig.Known]) -> [LabFinding] {
        var result = findings.map { finding -> LabFinding in
            guard finding.level == .failure, let entry = known.first(where: { $0.id == finding.id }) else { return finding }
            var marked = finding
            marked.level = .known
            marked.text += " (bekannt: \(entry.reason))"
            return marked
        }
        for entry in known where !findings.contains(where: { $0.id == entry.id && $0.level == .failure }) {
            if findings.contains(where: { $0.id == entry.id }) {
                result.append(.init(level: .warning, id: entry.id, text: "Bekannter Befund \(entry.id) hält wieder; Eintrag aus labor.json entfernen"))
            }
        }
        return result
    }

    static func format(_ value: Double) -> String { String(format: "%.2f", value) }
    static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded())) %" }
}
