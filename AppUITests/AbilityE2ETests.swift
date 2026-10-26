import OddlingsCore
import XCTest

/// Steinregen (R-3): Knopf unten rechts, Zielen, Wurf auf den Weg, Laden.
final class AbilityE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testCastOnPathChargesAndComesBack() throws {
        // Lange Abklingzeit und keine Welle: „lädt" bleibt stehen, egal wie
        // lange XCTest nach dem Tippen auf Ruhe wartet. Vorher lief der Test im
        // Zeitraffer, „lädt" hielt 3,5 s und war auf langsamen Läufern manchmal
        // schon vorbei.
        let e2e = try E2EApp(["--play", "--e2e-erste-welle", E2EApp.wavesOnHold,
                              "--e2e-abklingzeit", E2EApp.abilityOnHold])
        e2e.waitForBoard()
        XCTAssertTrue(e2e.ability.waitForExistence(timeout: 5), "Knopf unten rechts")
        XCTAssertEqual(e2e.abilityState, "bereit", "bereit ab Beginn")

        e2e.ability.tap()
        XCTAssertEqual(e2e.abilityState, "Ziel auf den Weg tippen")
        // Ein Feld, das man bebauen könnte, liegt weit genug neben dem Weg nicht:
        // daneben gezielt bleibt das Zielen offen und kostet nichts.
        let ability = try XCTUnwrap(e2e.config.ability)
        let off = try XCTUnwrap(e2e.map.buildableCells.first { e2e.map.path.distance(from: $0.center) > ability.snapDistance + 0.5 })
        e2e.tap(off.center)
        XCTAssertEqual(e2e.abilityState, "Ziel auf den Weg tippen", "daneben: Zielen bleibt offen")
        XCTAssertFalse(e2e.app.buttons["build.watch"].exists, "beim Zielen öffnet kein Baumenü")

        e2e.tap(e2e.map.path.position(at: e2e.map.path.length / 3))
        let charging = NSPredicate(format: "value BEGINSWITH %@", "lädt")
        expectation(for: charging, evaluatedWith: e2e.ability)
        waitForExpectations(timeout: 5)
        // Ein zweites Tippen wirkt nicht noch einmal und öffnet kein Zielen.
        e2e.ability.tap()
        XCTAssertTrue(e2e.abilityState.hasPrefix("lädt"), e2e.abilityState)
        // Dass die Fähigkeit nach der Abklingzeit wiederkommt, prüft
        // BattleControllerTests.testCastQueuesCommandAndChargeRunsUp Schritt für Schritt.
    }

    @MainActor
    func testButtonGoesAwayWhenTheMissionEnds() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        XCTAssertTrue(e2e.ability.waitForExistence(timeout: 5))
        e2e.pause.tap()
        XCTAssertTrue(e2e.giveUp.waitForExistence(timeout: 5))
        e2e.giveUp.tap()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 5))
        XCTAssertTrue(e2e.ability.waitForNonExistence(timeout: 5), "nach dem Ende kein Knopf")
    }
}
