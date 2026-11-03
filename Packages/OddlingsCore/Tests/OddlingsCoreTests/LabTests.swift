import Foundation
import Testing
@testable import OddlingsCore
@testable import OddlingsLab

/// Balance-Labor (P2-6b): Bots, Lauf, Zielwerte, Invarianten.
@Suite("Balance-Labor")
struct LabTests {
    let lab = LabConfig.standard

    @Test("labor.json lädt und nennt für jede gebaute Mission eine Siegquote")
    func bundledConfigCoversCampaign() throws {
        let campaign = try CampaignConfig.regionOne()
        for node in campaign.nodes where node.mission != nil {
            #expect(lab.targets.humanWinRate[node.id] != nil, "\(node.id)")
        }
        #expect(lab.stages["pr"] != nil)
    }

    @Test("Unsinn in labor.json wird beim Laden abgewiesen")
    func rejectsNonsense() throws {
        var broken = lab
        broken.stages["pr"]?.seeds = 0
        broken.human.abilitySkipShare = 1.5
        broken.known.append(.init(id: "x", reason: " "))
        let data = try JSONEncoder().encode(broken)
        #expect(throws: LabError.self) { try LabConfig.load(from: data) }
        #expect(broken.issues().count == 3, "\(broken.issues())")
        #expect(lab.issues().isEmpty)
    }

    @Test("Menschenbot: gleicher Startwert gleiche Befehle, anderer andere, und er zögert")
    func humanBotIsSeededAndSlow() throws {
        let config = try BalanceConfig.missionOne()
        let sim = Simulation(config: config)
        let order = try #require(Strategies.of(config).first { $0.name.hasPrefix("Mix") }).order
        func run(_ seed: UInt64) -> BotRun {
            var bot = LabBot(sim: sim, order: order, profile: .human(lab.human, castsAbility: true),
                             weights: lab.greedy, seed: seed)
            return sim.play(&bot)
        }
        let first = run(3), again = run(3), other = run(4)
        #expect(first.log.map(\.tick) == again.log.map(\.tick))
        #expect(first.log.map(\.commands) == again.log.map(\.commands))
        #expect(first.log.map(\.commands) != other.log.map(\.commands), "andere Plätze bei anderem Startwert")
        let ticks = first.log.map(\.tick)
        for (earlier, later) in zip(ticks, ticks.dropFirst()) {
            #expect(later - earlier >= lab.human.reactionTicks, "zwischen zwei Handlungen liegt die Reaktionszeit")
        }
        // Eine lange Reaktionszeit muss sichtbar werden; kurze Abstände ergeben sich auch so.
        var slow = lab.human
        slow.reactionTicks = 900
        var lazy = LabBot(sim: sim, order: order, profile: .human(slow, castsAbility: true), weights: lab.greedy, seed: 3)
        let lazyTicks = sim.play(&lazy).log.map(\.tick)
        #expect(lazyTicks.count > 1)
        for (earlier, later) in zip(lazyTicks, lazyTicks.dropFirst()) {
            #expect(later - earlier >= slow.reactionTicks, "eine lange Reaktionszeit hält ihn auf")
        }
        let greedy = sim.play(order, castsAbility: true)
        let slower = zip(first.log, greedy.log).filter { $0.tick > $1.tick }.count
        // Andere Plätze ändern die Beute, deshalb kann ein einzelner Schritt früher fallen; im Ganzen zögert er.
        #expect(slower * 2 > min(first.log.count, greedy.log.count), "der Menschenbot handelt meist später als der gierige")
    }

    @Test("Zwei Läufe derselben Stufe liefern denselben Bericht, unabhängig von der Reihenfolge der Kerne")
    func runIsDeterministic() async throws {
        let one = try await Lab.run(stage: "pr", nodes: ["m1"], races: [.dwarves])
        let two = try await Lab.run(stage: "pr", nodes: ["m1"], races: [.dwarves])
        #expect(LabReport.csv(one) == LabReport.csv(two))
        #expect(LabReport.markdown(one) == LabReport.markdown(two))
        let bots = Set(one.records.map(\.bot.rawValue))
        #expect(bots == ["gierig", "monokultur", "mensch", "zufall"])
        #expect(one.records.allSatisfy { $0.violations.isEmpty })
        #expect(!one.failed)
    }

    private func record(_ bot: LabRecord.Bot, _ variant: String, won: Bool, reserve: Double? = nil,
                        built: [TowerKind: Int] = [:]) -> LabRecord {
        LabRecord(node: "m1", race: .dwarves, bot: bot, variant: variant, won: won, livesLeft: 0, leaks: 0, ticks: 0,
                  goldLeft: 0, reserve: reserve, built: built, violations: [])
    }

    @Test("Eine dominante Bauweise, eine siegreiche Monokultur und ein ungenutzter Turm werden rot")
    func brokenBalanceIsRed() throws {
        let play = try #require(try FirstPlay.all(races: [.dwarves]).first)
        let records = [
            record(.greedy, "Blitz übermächtig", won: true, reserve: 3.0),
            record(.greedy, "Mix", won: true, reserve: 1.4),
            record(.monoculture, "lightning", won: true),
            record(.random, "0", won: true, built: [.watch: 3, .lightning: 2]),
        ]
        var targets = lab
        targets.known = []
        let findings = Lab.evaluate(records, plays: [play], lab: targets)
        let red = findings.filter { $0.level == .failure }.map(\.id)
        #expect(red.contains("dominanz|m1|dwarves"))
        #expect(red.contains("monokultur|m1|dwarves|lightning"))
        #expect(red.contains("nutzung|m1|spore"), "der Sporenturm stand in keinem gewonnenen Lauf")
        #expect(!red.contains("nutzung|m1|watch"))
    }

    @Test("Ein bekannter Befund hält die CI nicht auf, meldet sich aber, sobald er behoben ist")
    func knownFindingsOnlyShrink() {
        let failing = LabFinding(level: .failure, id: "monokultur|m2|elves|lightning", text: "gewinnt")
        let holding = LabFinding(level: .ok, id: "dominanz|m1|elves", text: "hält")
        let known = [LabConfig.Known(id: failing.id, reason: "wartet"), LabConfig.Known(id: holding.id, reason: "wartet")]
        let result = Lab.applyingKnown([failing, holding], known)
        #expect(result.first { $0.id == failing.id }?.level == .known)
        #expect(result.contains { $0.id == holding.id && $0.level == .warning }, "Eintrag entfernen")
        #expect(!result.contains { $0.level == .failure })
        #expect(Lab.applyingKnown([failing], []).first?.level == .failure, "neue Verletzung bleibt rot")
    }

    @Test("Invarianten: kaputter Zustand fällt auf")
    func invariantsCatchBrokenState() throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        var state = sim.newGame(seed: 1)
        #expect(Simulation.invariantViolations(in: state).isEmpty)
        state.gold = -1
        state.fortressLives = -2
        let cell = try #require(sim.map.buildableCells.first)
        state.towers = [Tower(id: 1, kind: .watch, cell: cell, cooldownTicks: 0, spent: 0), Tower(id: 2, kind: .spore, cell: cell, cooldownTicks: 0, spent: 0)]
        #expect(Simulation.invariantViolations(in: state).count == 3)
    }

    @Test("Zufällige, auch ungültige Befehle verletzen keine Invariante", arguments: [1, 2, 3] as [UInt64])
    func randomCommandsKeepInvariants(seed: UInt64) throws {
        for name in ["mvp-mission-01", "mission-02", "mission-03", "mission-04"] {
            let sim = Simulation(config: try BalanceConfig.bundledMission(named: name))
            var rng = SplitMix64(seed: seed)
            var state = sim.newGame(seed: seed)
            var ended = 0
            let width = sim.map.width, height = sim.map.height
            while !state.isOver && state.tick < 60_000 {
                var commands: [Command] = []
                if rng.next() % 20 == 0 {
                    let cell = Cell(x: Int(rng.next() % UInt64(width + 2)) - 1, y: Int(rng.next() % UInt64(height + 2)) - 1)
                    let kind = TowerKind.allCases[Int(rng.next() % UInt64(TowerKind.allCases.count))]
                    let id = Int(rng.next() % 40)
                    switch rng.next() % 6 {
                    case 0, 1: commands.append(.build(kind, cell))
                    case 2: commands.append(.sell(towerID: id))
                    case 3: commands.append(.upgrade(towerID: id))
                    case 4: commands.append(.useAbility(cell.center))
                    default: commands.append(.callNextWave)
                    }
                }
                for event in sim.step(&state, commands: commands) { if case .missionEnded = event { ended += 1 } }
                let broken = Simulation.invariantViolations(in: state)
                #expect(broken.isEmpty, "\(name): \(broken)")
                if !broken.isEmpty { return }
            }
            #expect(state.isOver, "\(name) endet")
            #expect(ended == 1, "\(name) endet genau einmal")
        }
    }
}
