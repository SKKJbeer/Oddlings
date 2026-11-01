import OddlingsCore
import XCTest

/// Pausen- und Ergebnistafel (UI 01): Weiter, Neu starten, Aufgeben.
final class TablesE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testPauseCardResumes() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        e2e.pause.tap()
        XCTAssertTrue(e2e.pauseCard.waitForExistence(timeout: 5), "Pausentafel erscheint")
        XCTAssertEqual(e2e.pause.label, "Weiter")
        let frozen = e2e.nextWave.label
        e2e.resume.tap()
        XCTAssertTrue(e2e.pauseCard.waitForNonExistence(timeout: 5), "Weiter schließt die Tafel")
        let moved = NSPredicate(format: "label != %@", frozen)
        expectation(for: moved, evaluatedWith: e2e.nextWave)
        waitForExpectations(timeout: 5)
    }

    @MainActor
    func testPauseCardRestartsMission() throws {
        // Zeitraffer ohne Türme verliert die Mission, bevor gebaut ist; die
        // Welle wartet deshalb.
        let e2e = try E2EApp(["--play", "--e2e-zeitraffer", E2EApp.readableFastForward,
                              "--e2e-erste-welle", E2EApp.wavesOnHold])
        e2e.waitForBoard()
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: e2e.config.mission.startGold - e2e.cost(.watch), "gebaut")
        e2e.pause.tap()
        XCTAssertTrue(e2e.restart.waitForExistence(timeout: 5))
        e2e.restart.tap()
        XCTAssertTrue(e2e.pauseCard.waitForNonExistence(timeout: 5), "Tafel schließt")
        // Sofort ablesen: Kurz nach dem Neustart läuft die Mission wieder.
        XCTAssertEqual(e2e.gold, e2e.config.mission.startGold, "Gold zurückgesetzt")
        XCTAssertEqual(e2e.waveLabel, "Welle 0/\(e2e.config.waves.count)")
        XCTAssertEqual(e2e.pause.label, "Pause", "nach dem Neustart läuft es")
    }

    @MainActor
    func testGiveUpShowsDefeatAndRetry() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        e2e.pause.tap()
        XCTAssertTrue(e2e.giveUp.waitForExistence(timeout: 5))
        e2e.giveUp.tap()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 5), "Aufgeben zeigt die Tafel")
        XCTAssertEqual(e2e.result.label, "Niederlage")
        XCTAssertEqual(e2e.resultValue("result.waves"), "0", "vor der ersten Welle aufgegeben")
        XCTAssertEqual(e2e.resultValue("result.defeated"), "0")
        XCTAssertFalse(e2e.pause.isEnabled, "nach dem Ende keine Pause")
        XCTAssertFalse(e2e.nextWave.exists)

        e2e.app.buttons["result.again"].tap()
        XCTAssertTrue(e2e.result.waitForNonExistence(timeout: 5))
        XCTAssertEqual(e2e.lives, e2e.config.mission.fortressLives)
        XCTAssertTrue(e2e.pause.isEnabled, "neue Mission läuft")
    }

    /// Bilder für den Vergleich mit dem Entwurf: Schlacht mit offenem
    /// Kreismenü, Turm mit Infotafel, Pause, Ergebnis.
    @MainActor
    func testScreensForReview() throws {
        let e2e = try E2EApp(["--play"], avatar: .elves)
        e2e.waitForBoard()
        let cells = e2e.map.buildableCells
        let cell = try XCTUnwrap(cells.dropFirst(cells.count / 2).first)
        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.lightning).waitForExistence(timeout: 5))
        e2e.build(.lightning).tap()
        e2e.screenshot("1-kreismenue", in: self)
        e2e.build(.lightning).tap()
        e2e.tap(cell)
        XCTAssertTrue(e2e.sell.waitForExistence(timeout: 5))
        e2e.sell.tap()
        XCTAssertTrue(e2e.sellConfirm.waitForExistence(timeout: 5))
        e2e.screenshot("2-verkaufen", in: self)
        e2e.tap(cell)
        e2e.pause.tap()
        XCTAssertTrue(e2e.pauseCard.waitForExistence(timeout: 5))
        e2e.screenshot("3-pause", in: self)
        e2e.giveUp.tap()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        e2e.screenshot("4-niederlage", in: self)
        e2e.app.buttons["result.back"].tap()
        XCTAssertTrue(e2e.mapBack.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date().addingTimeInterval(1))
        e2e.screenshot("5-weltkarte", in: self)
        e2e.mapBack.tap()
        XCTAssertTrue(e2e.app.buttons["menu.play"].waitForExistence(timeout: 5))
        e2e.screenshot("0-hauptmenue", in: self)
    }
}
