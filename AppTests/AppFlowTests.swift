import OddlingsCore
import XCTest
@testable import Oddlings

/// Schirmfolge und Speichern beim Ergebnis (Konzept r-spielrahmen.md).
final class AppFlowTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("AppFlowTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    @MainActor
    private func makeFlow() throws -> AppFlow {
        AppFlow(campaign: try CampaignConfig.regionOne(), store: SaveStore(directory: directory))
    }

    @MainActor
    private func fullLives() throws -> Int { try BalanceConfig.missionOne().mission.fortressLives }

    @MainActor
    func testWinIsSavedAndReadBackByANewFlow() throws {
        let flow = try makeFlow()
        XCTAssertEqual(flow.finish("m1", outcome: .won, livesLeft: try fullLives()), 3)
        XCTAssertEqual(flow.progress.stars(for: "m1"), 3)
        XCTAssertEqual(flow.justImproved, "m1")
        let reopened = try makeFlow()
        XCTAssertEqual(reopened.progress.stars(for: "m1"), 3, "der Sieg steht in der Datei")
    }

    /// R-5: Ohne Avatar führt „Spielen" in den Aufbau. Einmal angelegt, ist das
    /// Volk gesetzt, steht in der Datei und prägt jede Mission.
    @MainActor
    func testAvatarIsBuiltOnceAndShapesTheBattle() throws {
        let flow = try makeFlow()
        let mission = try XCTUnwrap(flow.mission(for: "m1"))
        XCTAssertNil(flow.avatar)
        flow.showMap()
        XCTAssertEqual(flow.screen, .setup, "ohne Avatar erst der Aufbau")
        flow.start("m1")
        XCTAssertEqual(flow.screen, .setup, "auch Weiter mit Mission 1 führt nicht vorbei")

        XCTAssertFalse(flow.createAvatar(race: .elves, name: "   ", portrait: "elf-2"), "leerer Name")
        XCTAssertNil(flow.avatar)
        XCTAssertTrue(flow.createAvatar(race: .elves, name: " Lyra ", portrait: "elf-2"))
        XCTAssertEqual(flow.screen, .map, "nach dem Aufbau die Karte")
        XCTAssertEqual(flow.avatar?.name, "Lyra")
        XCTAssertEqual(flow.race, .elves)
        let elves = try XCTUnwrap(RaceTable.bundled()[.elves])
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves))
        XCTAssertEqual(flow.battleMission(for: "m1")?.ability?.kind, .moonMark)

        XCTAssertFalse(flow.createAvatar(race: .dwarves, name: "Brokk", portrait: "dwarf-1"), "nur einmal")
        XCTAssertEqual(flow.race, .elves)

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.avatar, flow.avatar, "der Avatar steht in der Datei")
        reopened.showMap()
        XCTAssertEqual(reopened.screen, .map, "kein zweiter Aufbau")
        reopened.start("m1")
        XCTAssertEqual(reopened.screen, .battle(node: "m1"))
    }

    @MainActor
    func testWithoutAvatarTheMissionFileDecides() throws {
        let flow = try makeFlow()
        XCTAssertEqual(flow.battleMission(for: "m1"), try XCTUnwrap(flow.mission(for: "m1")))
    }

    @MainActor
    func testLossAndWeakerWinChangeNothing() throws {
        let flow = try makeFlow()
        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        flow.showMap()
        XCTAssertEqual(flow.finish("m1", outcome: .lost, livesLeft: 0), 0)
        XCTAssertEqual(flow.finish("m1", outcome: .won, livesLeft: 1), 1)
        XCTAssertEqual(flow.progress.stars(for: "m1"), 3)
        XCTAssertNil(flow.justImproved, "nichts wurde besser")
    }

    @MainActor
    func testStartOnlyOpensPlayableMissions() throws {
        let flow = try makeFlow()
        flow.createAvatar(race: .dwarves, name: "Brokk", portrait: "dwarf-1")
        flow.showMap()
        flow.start("m2")
        XCTAssertEqual(flow.screen, .map, "gesperrt: kein Start")
        flow.finish("m1", outcome: .won, livesLeft: 1)
        flow.finish("m2", outcome: .won, livesLeft: 1)
        flow.finish("m3", outcome: .won, livesLeft: 1)
        flow.finish("m4", outcome: .won, livesLeft: 1)
        flow.start("m5b")
        XCTAssertEqual(flow.screen, .map, "in Arbeit: kein Start")
        flow.start("m5a")
        XCTAssertEqual(flow.screen, .battle(node: "m5a"), "der Sumpfpfad hat eine Karte (P3-1)")
    }

    /// Weiter führt zur nächsten spielbaren Mission und bleibt auf der letzten,
    /// solange danach nichts gebaut ist.
    @MainActor
    func testContinueStopsAtTheLastBuiltMission() throws {
        let flow = try makeFlow()
        XCTAssertEqual(flow.continueNode?.id, "m1")
        flow.finish("m1", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m2")
        flow.finish("m2", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m3", "Mission 3 ist gebaut (P2-6)")
        flow.finish("m3", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m4", "Mission 4 ist gebaut (P2-10)")
        flow.finish("m4", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m5a", "der Sumpfpfad ist gebaut (P3-1)")
        flow.finish("m5a", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m5a", "Mission 6 ist noch in Arbeit")
    }

    /// R-6: Alle sechs Sterne ein Rang. Ein Sieg, der die Summe auf sechs hebt,
    /// gibt Rang II und damit die erste Reihe; die zweite bleibt gesperrt.
    @MainActor
    func testRankUnlocksATalentThatShapesTheBattle() throws {
        // Drei Sterne aus einer Mission, die es noch nicht zu spielen gibt.
        try SaveStore(directory: directory).save(
            SaveGame(progress: CampaignProgress(records: [MissionRecord(mission: "m2", bestStars: 3)])), allowed: true)
        let flow = try makeFlow()
        flow.showMap()
        XCTAssertTrue(flow.createAvatar(race: .elves, name: "Lyra", portrait: "elf-1"))
        let races = try RaceTable.bundled()
        let elves = try XCTUnwrap(races[.elves])
        let mission = try XCTUnwrap(flow.mission(for: "m1"))
        XCTAssertEqual(flow.rank, 1)
        XCTAssertEqual(flow.nextRankStars, 6)
        XCTAssertEqual(flow.talents, [])
        XCTAssertFalse(flow.chooseTalent(row: 0, side: .b), "auf Rang I ist keine Reihe frei")
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves))

        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        XCTAssertEqual(flow.rank, 2)
        XCTAssertEqual(flow.rankFloorStars, 6)
        XCTAssertEqual(flow.nextRankStars, 12)
        XCTAssertTrue(flow.newTalentWaiting, "das Schild weist auf das neue Talent hin")
        XCTAssertEqual(flow.talents, [.a])
        // Der Sieg bringt auch Ausrüstung (R-7a); sie gilt mit, die Talentwahl ist hier die Frage.
        let gear = flow.equippedPieces
        XCTAssertFalse(gear.isEmpty, "drei Sterne in Mission 1 geben ein Stück")
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.a], equipment: gear))
        flow.openAvatar()
        XCTAssertEqual(flow.screen, .avatar)
        XCTAssertFalse(flow.newTalentWaiting)

        XCTAssertTrue(flow.chooseTalent(row: 0, side: .b))
        XCTAssertFalse(flow.chooseTalent(row: 1, side: .b), "Reihe 2 braucht Rang III")
        XCTAssertEqual(flow.talents, [.b])
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.b], equipment: gear))
        XCTAssertNotEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.a], equipment: gear))
        flow.closeAvatar()
        XCTAssertEqual(flow.screen, .map, "zurück dorthin, wo das Menü geöffnet wurde")

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.rank, 2)
        XCTAssertEqual(reopened.talents, [.b], "die Wahl steht in der Datei")
        XCTAssertFalse(reopened.newTalentWaiting)
        reopened.openAvatar()
        XCTAssertEqual(reopened.screen, .avatar)
        reopened.closeAvatar()
        XCTAssertEqual(reopened.screen, .menu)
    }

    /// R-7a, D-070: Drei Sterne in Mission 1 geben drei Grundstücke. Sie wandern
    /// auf freie Plätze und prägen die nächste Mission; Gesperrtes lässt sich
    /// nicht anlegen, Ablegen geht, und die Belegung steht in der Datei.
    @MainActor
    func testEquipmentComesFromStarsAndShapesTheBattle() throws {
        let flow = try makeFlow()
        flow.showMap()
        XCTAssertTrue(flow.createAvatar(race: .dwarves, name: "Brokk", portrait: "dwarf-1"))
        let dwarves = try XCTUnwrap(try RaceTable.bundled()[.dwarves])
        let table = try EquipmentTable.bundled()
        let mission = try XCTUnwrap(flow.mission(for: "m1"))
        XCTAssertFalse(flow.equip("watch-banner", in: .banner), "vor dem ersten Sieg gibt es nichts")
        XCTAssertEqual(flow.equippedPieces, [])
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(dwarves, talents: []))
        XCTAssertNil(flow.avatarNews)

        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        XCTAssertEqual(flow.equippedPieces.map(\.id), ["watch-banner", "swift-amulet", "purse-seal"])
        XCTAssertEqual(flow.avatarNews, AvatarTexts.newEquipment)
        let pieces = try ["watch-banner", "swift-amulet", "purse-seal"].map { try XCTUnwrap(table.piece($0)) }
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(dwarves, talents: [], equipment: pieces))
        XCTAssertNotEqual(flow.battleMission(for: "m1"), mission.applying(dwarves, talents: []))
        XCTAssertFalse(flow.equip("storm-banner", in: .banner), "das Sturmbanner braucht 9 Sterne")
        XCTAssertFalse(flow.equip("watch-banner", in: .seal), "ein Banner gehört nicht aufs Siegel")
        XCTAssertTrue(flow.equip(nil, in: .banner))
        XCTAssertEqual(flow.equippedPieces.map(\.id), ["swift-amulet", "purse-seal"])

        flow.openAvatar()
        XCTAssertEqual(flow.avatarSection, .equipment, "die neue Ausrüstung liegt vorn")
        XCTAssertNil(flow.avatarNews)
        flow.closeAvatar()

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.equippedPieces.map(\.id), ["swift-amulet", "purse-seal"], "die Belegung steht in der Datei")
        XCTAssertTrue(reopened.owns("watch-banner"))
        XCTAssertTrue(reopened.equip("watch-banner", in: .banner))
        reopened.finish("m1", outcome: .won, livesLeft: try fullLives())
        XCTAssertNil(reopened.avatarNews, "ein zweiter Sieg bringt nichts Neues")
    }

    @MainActor
    func testEquipmentTextsNameEveryPieceAndItsNumbers() throws {
        let table = try EquipmentTable.bundled()
        for piece in table.pieces {
            XCTAssertNotEqual(AvatarTexts.piece(piece.id), piece.id, "\(piece.id) hat einen Namen")
            XCTAssertTrue(AvatarTexts.bonus(piece).contains("%"), AvatarTexts.bonus(piece))
            XCTAssertTrue(AvatarTexts.locked(piece.source).contains("★"))
        }
        XCTAssertEqual(AvatarTexts.percent(1.03), "+3\u{00A0}%")
        XCTAssertEqual(AvatarTexts.percent(0.95), "−5\u{00A0}%")
        XCTAssertEqual(AvatarTexts.source(EquipmentSource(mission: "m1", stars: 2)), "Mission 1 mit 2 ★")
        XCTAssertEqual(AvatarTexts.source(EquipmentSource(stars: 9)), "9 ★ in der Region")
        let banner = try XCTUnwrap(table.piece("watch-banner"))
        XCTAssertEqual(AvatarTexts.bonus(banner), "Wachturm: Reichweite +2\u{00A0}%")
        XCTAssertEqual(AvatarTexts.percent(1.015), "+1,5\u{00A0}%", "Stufen liegen halbe Prozent auseinander")
        XCTAssertEqual(AvatarTexts.percent(0.955), "−4,5\u{00A0}%")
        for piece in table.pieces where piece.maxLevel > 1 {
            let texts = (1...piece.maxLevel).map { AvatarTexts.bonus(piece.at(level: $0)) }
            XCTAssertEqual(Set(texts).count, texts.count, "\(piece.id): jede Stufe liest sich anders, \(texts)")
        }
    }

    /// R-7b: Jeder Sieg gibt Erz, neue Sterne mehr, eine Niederlage nichts. Die
    /// Ergebnistafel nennt den Ertrag. Schmieden zieht ab, steht in der Datei
    /// und prägt die nächste Mission; ohne genug Erz geht es nicht.
    @MainActor
    func testForgeTurnsWinsIntoLevelsThatShapeTheBattle() throws {
        let table = try EquipmentTable.bundled()
        let forge = try XCTUnwrap(table.forge)
        let flow = try makeFlow()
        flow.showMap()
        XCTAssertTrue(flow.createAvatar(race: .dwarves, name: "Brokk", portrait: "dwarf-1"))
        XCTAssertTrue(flow.hasForge)
        XCTAssertEqual(flow.ore, 0)

        flow.finish("m1", outcome: .lost, livesLeft: 0)
        XCTAssertEqual(flow.ore, 0, "eine Niederlage gibt nichts")
        XCTAssertNil(flow.lastReward)

        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        let first = forge.winOre + StarRating.maximum * forge.newStarOre
        XCTAssertEqual(flow.ore, first)
        XCTAssertEqual(flow.lastReward, AvatarTexts.oreGain(first))
        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        XCTAssertEqual(flow.ore, first + forge.winOre, "Wiederholen gibt nur den Sieg")
        XCTAssertEqual(flow.lastReward, AvatarTexts.oreGain(forge.winOre))
        XCTAssertEqual(try makeFlow().ore, flow.ore, "auch der wiederholte Sieg steht in der Datei")

        let cost = try XCTUnwrap(flow.upgradeCost(of: "watch-banner"))
        XCTAssertEqual(cost, forge.levelCosts[0])
        XCTAssertFalse(flow.forge("storm-banner"), "nicht erhalten, nicht schmiedbar")
        let before = try XCTUnwrap(flow.battleMission(for: "m1"))
        let oreBefore = flow.ore
        XCTAssertTrue(flow.forge("watch-banner"))
        XCTAssertEqual(flow.level(of: "watch-banner"), 2)
        XCTAssertEqual(flow.ore, oreBefore - cost)
        XCTAssertNotEqual(flow.battleMission(for: "m1"), before, "die Stufe wirkt in der Mission")
        let dwarves = try XCTUnwrap(try RaceTable.bundled()[.dwarves])
        let pieces = try ["watch-banner", "swift-amulet", "purse-seal"].map { try XCTUnwrap(table.piece($0)) }
        let leveled = [pieces[0].at(level: 2)] + pieces.dropFirst()
        let mission = try XCTUnwrap(flow.mission(for: "m1"))
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(dwarves, talents: [], equipment: leveled))

        let poor = flow.ore
        XCTAssertLessThan(poor, try XCTUnwrap(flow.upgradeCost(of: "watch-banner")))
        XCTAssertFalse(flow.forge("watch-banner"), "zu wenig Erz")
        XCTAssertEqual(flow.ore, poor)

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.level(of: "watch-banner"), 2, "die Stufe steht in der Datei")
        XCTAssertEqual(reopened.ore, poor)
    }

    @MainActor
    func testTalentTextsNameEveryOptionAndItsNumbers() throws {
        let races = try RaceTable.bundled()
        for race in Race.allCases {
            for row in try XCTUnwrap(races[race]?.talents) {
                XCTAssertNotEqual(AvatarTexts.row(row.id), row.id, "Reihe \(row.id) hat einen Namen")
                for side in TalentSide.allCases {
                    let option = row[side]
                    XCTAssertNotEqual(AvatarTexts.option(option.id), option.id, "\(option.id) hat einen Namen")
                    XCTAssertFalse(AvatarTexts.effect(option).isEmpty)
                    XCTAssertFalse(AvatarTexts.effect(option).contains("."), "deutsche Kommazahlen: \(AvatarTexts.effect(option))")
                }
            }
        }
        XCTAssertEqual(AvatarTexts.factor(1.3), "1,3")
        XCTAssertEqual(AvatarTexts.factor(0.875), "0,88")
        XCTAssertEqual(AvatarTexts.factor(2), "2")
        XCTAssertEqual(AvatarTexts.progress(stars: 3, next: 12, rank: 2), "3 von 12 Sternen bis Rang III")
        XCTAssertEqual(AvatarTexts.progress(stars: 30, next: nil, rank: 3), "Höchster Rang erreicht")
    }

    // MARK: Fortsetzen (P2-2)

    /// Mission 1 mit Avatar, ein paar Sekunden gespielt, mit einem Turm.
    @MainActor
    private func runningBattle(_ flow: AppFlow) throws -> GameState {
        if flow.avatar == nil { XCTAssertTrue(flow.createAvatar(race: .dwarves, name: "Brokk", portrait: "dwarf-1")) }
        flow.start("m1")
        let sim = Simulation(config: try XCTUnwrap(flow.battleMission(for: "m1")))
        var state = sim.newGame(seed: 1)
        let cell = try XCTUnwrap(sim.map.buildableCells.first)
        sim.step(&state, commands: [.build(.watch, cell)])
        for _ in 0..<90 { sim.step(&state) }
        XCTAssertEqual(state.towers.count, 1)
        return state
    }

    @MainActor
    func testSuspendedBattleOpensPausedAfterRestart() throws {
        let flow = try makeFlow()
        let state = try runningBattle(flow)
        flow.suspend("m1", seed: 1, state: state)

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.screen, .battle(node: "m1"), "direkt in die Mission (S12)")
        XCTAssertEqual(reopened.resume?.state, state)
        XCTAssertEqual(reopened.resume?.notice, BattleTexts.resumed)

        let model = BattleModel(config: try XCTUnwrap(reopened.battleMission(for: "m1")), seed: 1, autoplay: false,
                                resume: reopened.resume?.state)
        let controller = BattleController(model: model, interactive: true)
        controller.startPaused(notice: BattleTexts.resumed)
        XCTAssertTrue(controller.paused)
        XCTAssertEqual(model.advance(by: 1), [], "angehalten läuft nichts")
        XCTAssertEqual(controller.gold, state.gold)
        controller.togglePause()
        XCTAssertNil(controller.notice, "der Hinweis geht mit dem ersten Weiter")
    }

    @MainActor
    func testChangedRulesRestartTheMissionWithANotice() throws {
        let flow = try makeFlow()
        let state = try runningBattle(flow)
        flow.suspend("m1", seed: 1, state: state)
        // Ein Update ändert die Mission: Der gesicherte Abdruck passt nicht mehr.
        var save = SaveStore(directory: directory).load(campaign: flow.campaign).save
        save.battle?.rules = "0000000000000000"
        try SaveStore(directory: directory).save(save)

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.screen, .battle(node: "m1"))
        XCTAssertNil(reopened.resume?.state, "neu, nicht unter fremden Regeln")
        XCTAssertEqual(reopened.resume?.notice, BattleTexts.restartedAfterUpdate)
        XCTAssertNil(SaveStore(directory: directory).load(campaign: flow.campaign).save.battle, "verworfen")
    }

    @MainActor
    func testDamagedStateRestartsAndKeepsProgress() throws {
        let flow = try makeFlow()
        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        var state = try runningBattle(flow)
        state.gold = -5
        flow.suspend("m1", seed: 1, state: state)

        let reopened = try makeFlow()
        XCTAssertNil(reopened.resume?.state)
        XCTAssertEqual(reopened.resume?.notice, BattleTexts.restartedAfterDamage)
        XCTAssertEqual(reopened.progress.stars(for: "m1"), 3, "der Fortschritt bleibt")
    }

    @MainActor
    func testFinishingOrLeavingDiscardsTheSuspendedBattle() throws {
        let flow = try makeFlow()
        let state = try runningBattle(flow)
        flow.suspend("m1", seed: 1, state: state)
        flow.finish("m1", outcome: .lost, livesLeft: 0)
        XCTAssertEqual(try makeFlow().screen, .menu, "nach dem Ergebnis gibt es nichts fortzusetzen")

        flow.suspend("m1", seed: 1, state: state)
        flow.leaveBattle()
        XCTAssertEqual(flow.screen, .map)
        XCTAssertEqual(try makeFlow().screen, .menu, "Zurück beendet die Mission")
    }

    @MainActor
    func testFinishedStateIsNeverSuspended() throws {
        let flow = try makeFlow()
        var state = try runningBattle(flow)
        state.outcome = .won
        flow.suspend("m1", seed: 1, state: state)
        XCTAssertEqual(try makeFlow().screen, .menu)
    }
}
