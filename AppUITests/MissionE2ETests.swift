import XCTest

/// Ganze Missionen im Zeitraffer (WP-14): Niederlage ohne Türme, Sieg mit
/// dem Mitspieler, Nochmal und Zurück.
final class MissionE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testLossWithoutTowersThenRetryResetsEverything() throws {
        let e2e = try E2EApp(["--play", "--e2e-zeitraffer", E2EApp.readableFastForward])
        e2e.waitForBoard()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 240), "Mission endet")
        XCTAssertEqual(e2e.result.label, "Niederlage")
        XCTAssertEqual(e2e.lives, 0)
        XCTAssertFalse(e2e.nextWave.exists, "nach dem Ende keine Welle mehr")
        XCTAssertFalse(e2e.pause.isEnabled, "nach dem Ende keine Pause")

        e2e.app.buttons["result.again"].tap()
        XCTAssertTrue(e2e.result.waitForNonExistence(timeout: 5), "Tafel verschwindet")
        // Sofort ablesen, nicht warten: Der Neustart setzt alles im selben Bild
        // zurück, und kurz darauf läuft die Mission wieder.
        XCTAssertEqual(e2e.lives, e2e.config.mission.fortressLives, "Leben zurückgesetzt")
        XCTAssertEqual(e2e.waveLabel, "Welle 0/\(e2e.config.waves.count)", "Welle zurückgesetzt")
        XCTAssertEqual(e2e.gold, e2e.config.mission.startGold, "Gold zurückgesetzt")
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
