import OddlingsCore
import XCTest

/// P2-2: Eine laufende Mission übersteht das Beenden der App (D-074, Karte S12).
/// Wie ein Spieler: bauen, Home drücken, App wird beendet, wieder öffnen.
final class ResumeE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    /// Hält die erste Welle zurück: Gold ändert sich dann nur durch den Bau, und
    /// der Vergleich nach dem Neustart bleibt genau.
    @MainActor private var hold: [String] { ["--e2e-erste-welle", E2EApp.wavesOnHold] }

    @MainActor
    private func startMission(storage: String) throws -> E2EApp {
        let e2e = try E2EApp(hold, storage: storage, avatar: .elves)
        let start = e2e.app.buttons["menu.continue"]
        XCTAssertTrue(start.waitForExistence(timeout: 15), "Menü bietet Mission 1 an")
        start.tap()
        e2e.waitForBoard()
        return e2e
    }

    @MainActor
    func testMissionContinuesPausedAfterTheAppWasClosed() throws {
        let e2e = try startMission(storage: "fortsetzen")
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        let before = e2e.gold
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: before - e2e.cost(.watch), "der Turm ist bezahlt")
        let gold = e2e.gold

        // Home sichert, Beenden aus dem Hintergrund ist, was iOS selbst tut.
        XCUIDevice.shared.press(.home)
        let end = Date().addingTimeInterval(10)
        while e2e.app.state == .runningForeground && Date() < end {
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertNotEqual(e2e.app.state, .runningForeground, "App ist im Hintergrund")
        // Das Sichern läuft beim Wechsel in den Hintergrund; einen Moment Luft.
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        e2e.app.terminate()

        let again = try E2EApp(hold, storage: "fortsetzen", fresh: false)
        again.waitForBoard()
        XCTAssertTrue(again.pauseCard.waitForExistence(timeout: 5), "fortgesetzt wird angehalten")
        XCTAssertEqual(again.app.staticTexts["pause.notice"].label, "Hier warst du stehen geblieben.")
        XCTAssertEqual(again.gold, gold, "Gold wie vor dem Beenden")
        again.screenshot("p2-2-fortgesetzt", in: self)

        again.resume.tap()
        XCTAssertTrue(again.pauseCard.waitForNonExistence(timeout: 5), "Weiter läuft weiter")
        again.tap(cell)
        XCTAssertTrue(again.sell.waitForExistence(timeout: 5), "der Turm steht noch")
    }

    @MainActor
    func testLeavingTheMissionDoesNotResumeIt() throws {
        let e2e = try startMission(storage: "verlassen")
        XCUIDevice.shared.press(.home)
        e2e.app.activate()
        XCTAssertTrue(e2e.app.buttons["hud.back"].waitForExistence(timeout: 10))
        e2e.app.buttons["hud.back"].tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5), "Zurück führt zur Karte")
        e2e.app.terminate()

        let again = try E2EApp(hold, storage: "verlassen", fresh: false)
        XCTAssertTrue(again.app.buttons["menu.continue"].waitForExistence(timeout: 15),
                      "nach Zurück startet die App im Menü")
        XCTAssertFalse(again.board.exists)
    }
}
