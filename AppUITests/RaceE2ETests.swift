import OddlingsCore
import XCTest

/// Völkerwahl (R-4): auf der Missionstafel wählen, die Mission trägt die
/// Fähigkeit des Volks, und die Wahl übersteht den Neustart der App.
final class RaceE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    private func openMap(_ e2e: E2EApp) {
        let play = e2e.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5))
    }

    @MainActor
    func testChosenRaceGivesItsAbilityAndSurvivesRelaunch() throws {
        let e2e = try E2EApp(["--e2e-erste-welle", E2EApp.wavesOnHold], storage: "volk")
        openMap(e2e)
        XCTAssertTrue(e2e.raceDetail.contains("Steinregen"), "ohne Wahl der Steinregen: \(e2e.raceDetail)")
        XCTAssertFalse(e2e.race(.dwarves).isSelected, "keine Vorauswahl")
        XCTAssertFalse(e2e.race(.elves).isSelected, "keine Vorauswahl")

        e2e.race(.elves).tap()
        XCTAssertTrue(e2e.race(.elves).isSelected)
        XCTAssertFalse(e2e.race(.dwarves).isSelected)
        XCTAssertTrue(e2e.raceDetail.contains("Mondmal"), e2e.raceDetail)
        e2e.mapStart.tap()
        e2e.waitForBoard()
        XCTAssertTrue(e2e.ability.waitForExistence(timeout: 5))
        XCTAssertEqual(e2e.ability.label, "Mondmal")

        e2e.app.terminate()
        let again = try E2EApp(["--e2e-erste-welle", E2EApp.wavesOnHold], storage: "volk", fresh: false)
        openMap(again)
        XCTAssertTrue(again.race(.elves).isSelected, "die Wahl steht im Spielstand")
        again.race(.dwarves).tap()
        again.mapStart.tap()
        again.waitForBoard()
        XCTAssertTrue(again.ability.waitForExistence(timeout: 5))
        XCTAssertEqual(again.ability.label, "Bollwerk")
        XCTAssertEqual(again.abilityState, "bereit")
        again.ability.tap()
        again.tap(again.map.path.position(at: again.map.path.length / 3))
        let charging = NSPredicate(format: "value BEGINSWITH %@", "lädt")
        expectation(for: charging, evaluatedWith: again.ability)
        waitForExpectations(timeout: 5)
    }

    /// Die Tafel ist im Querformat knapp; mit der Volkswahl darf nichts
    /// übereinander liegen oder aus dem Bild ragen.
    @MainActor
    func testPanelFitsWithTheRaceChoice() throws {
        let e2e = try E2EApp()
        openMap(e2e)
        let window = e2e.app.windows.firstMatch.frame
        let parts = [e2e.app.staticTexts["map.panel.title"], e2e.race(.dwarves), e2e.race(.elves),
                     e2e.app.staticTexts["map.race.detail"], e2e.app.staticTexts["map.panel.status"], e2e.mapStart]
        for part in parts {
            XCTAssertTrue(part.exists, part.identifier)
            XCTAssertTrue(window.contains(part.frame), "\(part.identifier) liegt im Bild: \(part.frame)")
            XCTAssertTrue(part.isHittable, part.identifier)
        }
        for (index, part) in parts.enumerated() {
            for other in parts[(index + 1)...] {
                XCTAssertFalse(part.frame.intersects(other.frame), "\(part.identifier) und \(other.identifier) überlappen")
            }
        }
    }
}
