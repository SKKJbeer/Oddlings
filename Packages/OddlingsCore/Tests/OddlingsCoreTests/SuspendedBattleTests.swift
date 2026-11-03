import Foundation
import Testing
@testable import OddlingsCore

/// P2-2: Eine laufende Mission übersteht das Beenden der App (D-022, D-074).
@Suite("Fortsetzen")
struct SuspendedBattleTests {
    let sim: Simulation
    let campaign: CampaignConfig

    init() throws {
        sim = Simulation(config: try BalanceConfig.bundledMission(named: "mission-02"))
        campaign = try CampaignConfig.regionOne()
    }

    /// Mitten in einer Welle: Türme stehen, Gegner laufen.
    private func midBattle() -> GameState {
        var state = sim.newGame(seed: 7)
        var player = Autoplayer(demoOf: sim.config)
        while !state.isOver && (state.waveIndex < 2 || state.enemies.count < 3) {
            sim.step(&state, commands: player.commands(for: state, in: sim))
        }
        return state
    }

    private func suspended(_ state: GameState) -> SuspendedBattle {
        SuspendedBattle(node: campaign.nodes[1].id, rules: sim.config.fingerprint, seed: 7, state: state)
    }

    private func viaFile(_ battle: SuspendedBattle) throws -> SaveGame? {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("resume-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = SaveStore(directory: directory)
        try store.save(SaveGame(battle: battle))
        return store.load(campaign: campaign).save
    }

    @Test("Gesichert, gelesen und weitergespielt endet genau wie ohne Unterbrechung")
    func resumeIsDeterministic() throws {
        let state = midBattle()
        #expect(!state.isOver && !state.towers.isEmpty && !state.enemies.isEmpty)
        let read = try #require(try viaFile(suspended(state))?.battle)
        #expect(read.state == state)
        #expect(read.problems(for: sim) == [])

        // Ab hier ohne Befehle: Beide Wege bekommen dieselbe Eingabe, also muss
        // jeder Unterschied aus dem Speichern kommen.
        var straight = state, resumed = read.state
        while !straight.isOver { sim.step(&straight) }
        while !resumed.isOver { sim.step(&resumed) }
        #expect(resumed == straight)
        #expect(resumed.checksum == straight.checksum)
    }

    @Test("Ein voller Zustand passt in die Grenze des Spielstands")
    func sizeFitsTheLimit() throws {
        var state = midBattle()
        let template = try #require(state.enemies.first)
        for index in 0..<400 {
            var enemy = template
            enemy.id = state.nextEntityID + index
            state.enemies.append(enemy)
        }
        state.nextEntityID += 400
        let data = try SaveGameCodec.encode(SaveGame(battle: suspended(state)))
        #expect(data.count < SaveStore.maximumBytes)
        #expect(try viaFile(suspended(state))?.battle?.state == state)
    }

    @Test("Schema 2 wird ohne laufende Mission gelesen")
    func migratesSchemaTwo() throws {
        let decoded = try SaveGameCodec.decode(Data(#"{"schemaVersion":2,"progress":{"records":[]}}"#.utf8),
                                               campaign: campaign)
        #expect(decoded.save.battle == nil)
        #expect(decoded.save.schemaVersion == 3)
        #expect(decoded.dropped == [])
    }

    @Test("Ein unlesbarer Zustand kostet die Mission, nicht den Fortschritt")
    func brokenStateKeepsProgress() throws {
        let json = #"{"schemaVersion":3,"progress":{"records":[{"mission":"m1","bestStars":2}]},"battle":{"node":"m1","state":{"tick":"x"}}}"#
        let decoded = try SaveGameCodec.decode(Data(json.utf8), campaign: campaign)
        #expect(decoded.save.battle == nil)
        #expect(decoded.save.progress.stars(for: "m1") == 2)
        #expect(decoded.dropped == [.unreadableBattle])
    }

    @Test("Ein unbekannter Knoten verwirft die Mission")
    func unknownNodeIsDropped() throws {
        var battle = suspended(midBattle())
        battle.node = "zz"
        let decoded = try SaveGameCodec.decode(try SaveGameCodec.encode(SaveGame(battle: battle)), campaign: campaign)
        #expect(decoded.save.battle == nil)
        #expect(decoded.dropped == [.unknownBattleNode("zz")])
    }

    @Test("Der Fingerabdruck ist stabil und ändert sich mit den Regeln")
    func fingerprint() throws {
        let config = sim.config
        #expect(config.fingerprint == config.fingerprint)
        #expect(config.fingerprint.count == 16)
        #expect(Simulation(config: try BalanceConfig.bundledMission(named: "mission-02")).config.fingerprint
            == config.fingerprint)
        var changed = config
        changed.mission.startGold += 1
        #expect(changed.fingerprint != config.fingerprint)
        let races = try RaceTable.bundled()
        let dwarves = try #require(races[.dwarves]), elves = try #require(races[.elves])
        #expect(config.applying(dwarves).fingerprint != config.applying(elves).fingerprint)
        #expect(try BalanceConfig.bundledMission(named: "mission-03").fingerprint != config.fingerprint)
    }

    @Test("Jede Prüfregel weist ihren Fall ab", arguments: Breakage.allCases)
    func rejects(_ breakage: Breakage) throws {
        var state = midBattle()
        breakage.apply(to: &state, sim: sim)
        #expect(!suspended(state).problems(for: sim).isEmpty, "\(breakage)")
    }

    @Test("Ohne Bank in der Mission ist eine Bank im Zustand ungültig")
    func bankWithoutBankConfig() throws {
        let one = Simulation(config: try BalanceConfig.missionOne())
        var state = one.newGame(seed: 1)
        let cell = try #require(one.map.buildableCells.first)
        state.towers.append(Tower(id: 1, kind: .bank, cell: cell, cooldownTicks: 0, spent: 0))
        state.nextEntityID = 2
        let battle = SuspendedBattle(node: "m1", rules: one.config.fingerprint, seed: 1, state: state)
        #expect(!battle.problems(for: one).isEmpty)
        state.towers[0].kind = .watch
        #expect(SuspendedBattle(node: "m1", rules: "", seed: 1, state: state).problems(for: one) == [])
    }

    enum Breakage: CaseIterable, Sendable {
        case decided, negativeGold, noLives, tooManyLives, waveBeyondEnd, towerOnPath, twoTowersOneCell,
             levelTooHigh, enemyBeyondPath, enemyNaN, enemyOverhealed, duplicateID, idNotIssued,
             spawnInPast, negativeTick

        func apply(to state: inout GameState, sim: Simulation) {
            switch self {
            case .decided: state.outcome = .won
            case .negativeGold: state.gold = -1
            case .noLives: state.fortressLives = 0
            case .tooManyLives: state.fortressLives = sim.config.mission.fortressLives + 1
            case .waveBeyondEnd: state.waveIndex = sim.config.waves.count
            case .towerOnPath:
                let onPath = sim.map.path.points[1]
                state.towers[0].cell = Cell(x: Int(onPath.x), y: Int(onPath.y))
            case .twoTowersOneCell:
                var copy = state.towers[0]
                copy.id = state.nextEntityID
                state.nextEntityID += 1
                state.towers.append(copy)
            case .levelTooHigh: state.towers[0].level = 9
            case .enemyBeyondPath: state.enemies[0].distance = sim.map.path.length + 1
            case .enemyNaN: state.enemies[0].hp = .nan
            case .enemyOverhealed: state.enemies[0].hp = state.enemies[0].maxHP * 2
            case .duplicateID: state.enemies[0].id = state.towers[0].id
            case .idNotIssued: state.enemies[0].id = state.nextEntityID + 5
            case .spawnInPast:
                state.pendingSpawns.append(PendingSpawn(tick: state.tick - 1, enemy: .raider, hpScale: 1))
            case .negativeTick: state.tick = -1
            }
        }
    }
}
