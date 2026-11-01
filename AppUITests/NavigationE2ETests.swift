import XCTest

/// Wege durch die App und ihr Verhalten beim Wechsel in den Hintergrund.
final class NavigationE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testMenuToMapToMissionAndBack() throws {
        let e2e = try E2EApp(avatar: .elves)
        let play = e2e.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15), "Startbildschirm")
        play.tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5), "Spielen öffnet die Karte")
        XCTAssertEqual(e2e.app.staticTexts["map.panel.title"].label, "Mission 1", "gewählt ist die nächste Mission")
        e2e.mapStart.tap()
        e2e.waitForBoard()
        e2e.app.buttons["hud.back"].tap()
        XCTAssertTrue(e2e.mapBack.waitForExistence(timeout: 5), "Zurück aus der Mission führt zur Karte")
        e2e.mapBack.tap()
        XCTAssertTrue(play.waitForExistence(timeout: 5), "Menü auf der Karte führt zum Startbildschirm")
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

    @MainActor
    func testVibrationSettingSurvivesRelaunch() throws {
        func openSettings(_ e2e: E2EApp) -> XCUIElement {
            let button = e2e.app.buttons["menu.settings"]
            XCTAssertTrue(button.waitForExistence(timeout: 15), "Einstellungen im Menü")
            button.tap()
            let toggle = e2e.app.switches["settings.vibration"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            return toggle
        }
        func flip(_ toggle: XCUIElement) { toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap() }

        let e2e = try E2EApp()
        let toggle = openSettings(e2e)
        let before = toggle.value as? String
        flip(toggle)
        XCTAssertNotEqual(toggle.value as? String, before, "Schalter schaltet")
        e2e.app.buttons["settings.done"].tap()
        XCTAssertFalse(e2e.app.otherElements["settings"].waitForExistence(timeout: 1), "Fertig schließt die Tafel")
        e2e.app.terminate()

        let again = try E2EApp()
        let reopened = openSettings(again)
        XCTAssertNotEqual(reopened.value as? String, before, "Einstellung bleibt nach dem Neustart")
        flip(reopened)
        XCTAssertEqual(reopened.value as? String, before, "zurück auf den Ausgangswert für spätere Läufe")
    }
}
