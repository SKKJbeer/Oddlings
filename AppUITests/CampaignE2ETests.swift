import OddlingsCore
import XCTest

/// Kampagne und Spielstand wie ein Spieler (Konzept r-spielrahmen.md):
/// gewinnen, Sterne auf der Karte sehen, App beenden, Sterne sind noch da.
final class CampaignE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testWinEarnsStarsThatSurviveRelaunch() throws {
        let e2e = try E2EApp(["--e2e-zeitraffer", E2EApp.fastForward, "--e2e-mitspieler"], storage: "sieg", avatar: .elves)
        let resume = e2e.app.buttons["menu.continue"]
        XCTAssertTrue(resume.waitForExistence(timeout: 15), "Menü bietet die nächste Mission an")
        XCTAssertTrue(resume.label.contains("Mission 1"), resume.label)
        resume.tap()
        e2e.waitForBoard()
        XCTAssertTrue(e2e.result.waitForExistence(timeout: 180), "Mission endet")
        XCTAssertEqual(e2e.result.label, "Sieg")
        let lives = try XCTUnwrap(Int(e2e.resultValue("result.lives")))
        let stars = StarRating.stars(outcome: .won, livesLeft: lives, thresholds: e2e.config.mission.stars)
        let earned = "gewonnen, \(stars) von \(StarRating.maximum) Sternen"

        e2e.app.buttons["result.back"].tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5), "nach dem Ergebnis zur Karte")
        XCTAssertEqual(e2e.nodeState("m1"), earned)
        let total = e2e.app.otherElements["map.stars"].label
        XCTAssertTrue(total.hasPrefix("\(stars) von"), total)
        XCTAssertEqual(e2e.nodeState("m2"), "in Arbeit", "nach M1 ist M2 offen, aber noch nicht gebaut")
        e2e.node("m2").tap()
        XCTAssertEqual(e2e.app.staticTexts["map.panel.title"].label, "Mission 2")
        XCTAssertFalse(e2e.mapStart.isEnabled, "eine Mission ohne Karte startet nicht")

        e2e.app.terminate()
        let again = try E2EApp(storage: "sieg", fresh: false)
        let play = again.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(again.mapStart.waitForExistence(timeout: 5))
        XCTAssertEqual(again.nodeState("m1"), earned, "der Sieg ist nach dem Neustart der App noch da")
    }

    @MainActor
    func testLockedMissionsShowWhyAndDoNotStart() throws {
        let e2e = try E2EApp(avatar: .elves)
        let play = e2e.app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(e2e.mapStart.waitForExistence(timeout: 5))
        XCTAssertEqual(e2e.nodeState("m1"), "offen")
        XCTAssertTrue(e2e.mapStart.isEnabled)
        XCTAssertEqual(e2e.nodeState("m3"), "gesperrt")
        e2e.node("m3").tap()
        XCTAssertEqual(e2e.app.staticTexts["map.panel.status"].label, "Erst nach Mission 2")
        XCTAssertFalse(e2e.mapStart.isEnabled)
        e2e.node("n1").tap()
        XCTAssertEqual(e2e.app.staticTexts["map.panel.status"].label, "Ab 6 Sternen, du hast 0")
        XCTAssertFalse(e2e.mapStart.isEnabled)
        e2e.node("m7").tap()
        XCTAssertEqual(e2e.app.staticTexts["map.panel.title"].label, "Mission 7")
        XCTAssertEqual(e2e.app.staticTexts["map.panel.status"].label, "Erst nach Sumpfpfad II oder Ruinen II")
    }
}
