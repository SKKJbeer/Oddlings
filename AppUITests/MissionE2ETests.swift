import XCTest

/// Ganze Missionen im Zeitraffer (WP-14): Niederlage ohne Türme, Sieg mit
/// dem Mitspieler, Nochmal und Zurück.
final class MissionE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testLossWithoutTowersThenRetryResetsEverything() throws {
        let e2e = try E2EApp(["--play", "--e2e-zeitraffer", E2EApp.fastForward])
        e2e.waitForBoard()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 180), "Mission endet")
        XCTAssertEqual(e2e.result.label, "Niederlage")
        XCTAssertFalse(e2e.nextWave.exists, "nach dem Ende keine Welle mehr")
        XCTAssertFalse(e2e.pause.isEnabled, "nach dem Ende keine Pause")

        e2e.app.buttons["result.again"].tap()
        XCTAssertTrue(e2e.result.waitForNonExistence(timeout: 5), "Tafel verschwindet")
        e2e.waitFor(e2e.gold, toBe: e2e.config.mission.startGold, "Gold zurückgesetzt")
        e2e.waitFor(e2e.lives, toBe: e2e.config.mission.fortressLives, "Leben zurückgesetzt")
    }

    @MainActor
    func testDemoWinsAndBackReturnsToMenu() throws {
        let e2e = try E2EApp(["--demo", "--e2e-zeitraffer", E2EApp.fastForward])
        e2e.waitForBoard()
        XCTAssertFalse(e2e.nextWave.exists, "Zuschauen ruft keine Wellen")
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 180), "Mission endet")
        XCTAssertEqual(e2e.result.label, "Sieg")
        e2e.app.buttons["result.back"].tap()
        XCTAssertTrue(e2e.app.buttons["menu.play"].waitForExistence(timeout: 5), "zurück im Startbildschirm")
    }
}
