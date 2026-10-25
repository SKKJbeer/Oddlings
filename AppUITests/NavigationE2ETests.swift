import XCTest

/// Wege durch die App und ihr Verhalten beim Wechsel in den Hintergrund.
final class NavigationE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testMenuToMissionAndBack() throws {
        let e2e = try E2EApp()
        let play = e2e.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15), "Startbildschirm")
        play.tap()
        e2e.waitForBoard()
        e2e.app.buttons["hud.back"].tap()
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Zurück führt zum Startbildschirm")
    }

    @MainActor
    func testDemoFromMenuTakesNoInput() throws {
        let e2e = try E2EApp()
        let demo = e2e.app.buttons["menu.watch"]
        XCTAssertTrue(demo.waitForExistence(timeout: 15))
        demo.tap()
        e2e.waitForBoard()
        let cell = try XCTUnwrap(e2e.map.buildableCells.last)
        e2e.tap(cell)
        XCTAssertFalse(e2e.app.otherElements["battle.menu"].waitForExistence(timeout: 2), "kein Baumenü beim Zuschauen")
    }

    @MainActor
    func testBackgroundPausesMission() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        XCUIDevice.shared.press(.home)
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        e2e.app.activate()
        e2e.waitForBoard()
        XCTAssertTrue(e2e.pausedHint.waitForExistence(timeout: 5), "zurück aus dem Hintergrund ist angehalten")
        XCTAssertEqual(e2e.pause.label, "Weiter")
    }
}
