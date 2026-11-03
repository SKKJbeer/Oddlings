import OddlingsCore
import XCTest

/// Einstieg ohne Erklärtext (P2-8, K8) in der echten App: Hand nur beim Zögern,
/// nach dem ersten Turm der Pfeil, nach dem Rufen nichts mehr, und nach einem
/// Neustart der App kommt keins wieder. Hand und Pfeil zeigt der Zähler
/// `guide.state` (Debug-Bau); ob man sie sieht, prüft das Bildschirmfoto.
final class GuideE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testHandThenArrowThenNothingAndNeverAgain() throws {
        let storage = "guide"
        let e2e = try E2EApp(["--play", "--e2e-erste-welle", E2EApp.wavesOnHold], storage: storage)
        e2e.waitForBoard()
        XCTAssertTrue(e2e.guideState.waitForExistence(timeout: 5))
        XCTAssertEqual(e2e.guideState.label, "none", "gleich am Anfang noch keine Hand")
        e2e.waitFor(e2e.guideState, label: "build", timeout: 20)
        e2e.screenshot("einstieg-hand", in: self)

        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.guideState, label: "none")
        e2e.waitFor(e2e.guideState, label: "wave", timeout: 20)
        XCTAssertTrue(e2e.nextWave.exists)
        e2e.screenshot("einstieg-pfeil", in: self)
        e2e.nextWave.tap()
        e2e.waitFor(e2e.guideState, label: "none")
        e2e.app.terminate()

        // Derselbe Stand, keine Mission gewonnen: Gesehen ist gesehen.
        let again = try E2EApp(["--play", "--e2e-erste-welle", E2EApp.wavesOnHold], storage: storage, fresh: false)
        again.waitForBoard()
        XCTAssertTrue(again.guideState.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(BattleStyleTimes.build + 3))
        XCTAssertEqual(again.guideState.label, "none", "keine Hand nach dem ersten Mal")
    }

    @MainActor
    func testSwitchedOffShowsNoHand() throws {
        let e2e = try E2EApp(["--play", "--e2e-erste-welle", E2EApp.wavesOnHold, "--e2e-ohne-hinweise"])
        e2e.waitForBoard()
        XCTAssertTrue(e2e.guideState.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(BattleStyleTimes.build + 3))
        XCTAssertEqual(e2e.guideState.label, "none")
    }

    @MainActor
    func testSettingsHaveTheSwitch() throws {
        let e2e = try E2EApp()
        let button = e2e.app.buttons["menu.settings"]
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        button.tap()
        let toggle = e2e.app.switches["settings.guide"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Schalter „Hinweise“")
        XCTAssertEqual(toggle.value as? String, "1", "neu an")
        XCTAssertTrue(e2e.app.buttons["settings.done"].isHittable, "Tafel passt ganz auf den Schirm")
    }
}

/// Die Wartezeit des Einstiegs. Steht in `BattleStyle` der App, die der
/// Oberflächentest nicht sieht; hier dieselbe Zahl als Obergrenze zum Warten.
private enum BattleStyleTimes {
    static let build: TimeInterval = 6
}
