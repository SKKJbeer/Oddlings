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
        flow.start("m2")
        XCTAssertEqual(flow.screen, .map, "in Arbeit: kein Start")
        flow.start("m1")
        XCTAssertEqual(flow.screen, .battle(node: "m1"))
    }

    @MainActor
    func testContinueStaysOnMissionOneUntilMoreIsBuilt() throws {
        let flow = try makeFlow()
        XCTAssertEqual(flow.continueNode?.id, "m1")
        flow.finish("m1", outcome: .won, livesLeft: 1)
        XCTAssertEqual(flow.continueNode?.id, "m1")
        XCTAssertEqual(flow.selectedNode, "m1")
    }

    /// R-6: Drei Sterne heben auf Rang II. Die erste Reihe wird frei, steht auf
    /// A, lässt sich umstellen, steht in der Datei und prägt die Mission. Die
    /// zweite Reihe bleibt gesperrt.
    @MainActor
    func testRankUnlocksATalentThatShapesTheBattle() throws {
        let flow = try makeFlow()
        flow.showMap()
        XCTAssertTrue(flow.createAvatar(race: .elves, name: "Lyra", portrait: "elf-1"))
        let races = try RaceTable.bundled()
        let elves = try XCTUnwrap(races[.elves])
        let mission = try XCTUnwrap(flow.mission(for: "m1"))
        XCTAssertEqual(flow.rank, 1)
        XCTAssertEqual(flow.talents, [])
        XCTAssertFalse(flow.chooseTalent(row: 0, side: .b), "auf Rang I ist keine Reihe frei")
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves))

        flow.finish("m1", outcome: .won, livesLeft: try fullLives())
        XCTAssertEqual(flow.rank, 2)
        XCTAssertTrue(flow.newTalentWaiting, "das Schild weist auf das neue Talent hin")
        XCTAssertEqual(flow.talents, [.a])
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.a]))
        flow.openAvatarPanel()
        XCTAssertFalse(flow.newTalentWaiting)
        XCTAssertTrue(flow.showsAvatarPanel)

        XCTAssertTrue(flow.chooseTalent(row: 0, side: .b))
        XCTAssertFalse(flow.chooseTalent(row: 1, side: .b), "Reihe 2 braucht Rang III")
        XCTAssertEqual(flow.talents, [.b])
        XCTAssertEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.b]))
        XCTAssertNotEqual(flow.battleMission(for: "m1"), mission.applying(elves, talents: [.a]))
        flow.start("m1")
        XCTAssertFalse(flow.showsAvatarPanel, "die Mission schließt die Tafel")

        let reopened = try makeFlow()
        XCTAssertEqual(reopened.rank, 2)
        XCTAssertEqual(reopened.talents, [.b], "die Wahl steht in der Datei")
        XCTAssertFalse(reopened.newTalentWaiting)
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
}
