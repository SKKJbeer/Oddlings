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
}
