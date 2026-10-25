import XCTest

/// Kopfleiste (WP-13): Anzeige, Welle rufen, Pause, Tempo.
final class HUDE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testHUDShowsStartValues() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        XCTAssertEqual(e2e.gold, e2e.config.mission.startGold)
        XCTAssertEqual(e2e.lives, e2e.config.mission.fortressLives)
        XCTAssertEqual(e2e.waveLabel, "Welle 0/\(e2e.config.waves.count)")
        XCTAssertTrue(e2e.nextWave.exists)
    }

    @MainActor
    func testCallNextWaveStartsWaveOne() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        e2e.nextWave.tap()
        e2e.waitFor(e2e.app.staticTexts["hud.wave"], label: "Welle 1/\(e2e.config.waves.count)")
    }

    @MainActor
    func testPauseFreezesCountdownAndResumeContinues() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        e2e.pause.tap()
        XCTAssertTrue(e2e.pausedHint.waitForExistence(timeout: 5))
        let frozen = e2e.nextWave.label
        RunLoop.current.run(until: Date().addingTimeInterval(2.5))
        XCTAssertEqual(e2e.nextWave.label, frozen, "angehalten läuft der Countdown nicht")

        e2e.pause.tap()
        XCTAssertTrue(e2e.pausedHint.waitForNonExistence(timeout: 5))
        let moved = NSPredicate(format: "label != %@", frozen)
        expectation(for: moved, evaluatedWith: e2e.nextWave)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testSpeedToggles() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        XCTAssertEqual(e2e.speed.label, "1×")
        e2e.speed.tap()
        e2e.waitFor(e2e.speed, label: "2×")
        e2e.speed.tap()
        e2e.waitFor(e2e.speed, label: "1×")
    }
}
