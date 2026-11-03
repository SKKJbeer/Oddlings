import OddlingsCore
import XCTest

/// Spezialisieren auf dem Sumpfpfad, mit echtem Tippen (P3-1). Preise aus
/// `mission-05a.json`. Das Schild „III“ ist SpriteKit; geprüft werden Tafel,
/// Knopf und Gold.
final class SpecializationE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testUpgradeThenSpecializeIntoAVolley() throws {
        let e2e = try E2EApp(["--play", "--e2e-knoten", "m5a", "--e2e-erste-welle", E2EApp.wavesOnHold],
                             mission: "mission-05a")
        e2e.waitForBoard()
        let start = e2e.config.mission.startGold
        let upgradePrice = try XCTUnwrap(e2e.config.upgradeCost(of: .watch))
        let volleyPrice = try XCTUnwrap(e2e.config.specializations?[.volley]?.cost, "der Sumpfpfad bietet die Salve an")
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: start - e2e.cost(.watch), "Bauen zieht den Preis ab")

        e2e.tap(cell)
        let upgrade = e2e.app.buttons["upgrade"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5), "erst aufwerten")
        XCTAssertFalse(e2e.app.buttons["specialize"].exists, "Spezialisieren erst auf Stufe 2")
        upgrade.tap()
        upgrade.tap()
        let afterUpgrade = start - e2e.cost(.watch) - upgradePrice
        e2e.waitFor(e2e.gold, toBe: afterUpgrade, "Aufwerten zieht den Preis ab")

        let specialize = e2e.app.buttons["specialize"]
        XCTAssertTrue(specialize.waitForExistence(timeout: 5), "auf Stufe 2 steht die Spezialisierung")
        XCTAssertFalse(upgrade.exists, "an der Stelle von Aufwerten")
        specialize.tap()
        XCTAssertTrue(e2e.app.staticTexts["specialize.confirm"].waitForExistence(timeout: 5), "erstes Tippen fragt")
        XCTAssertEqual(e2e.gold, afterUpgrade, "noch nichts bezahlt")
        specialize.tap()
        e2e.waitFor(e2e.gold, toBe: afterUpgrade - volleyPrice, "Spezialisieren zieht den Preis ab")
        XCTAssertEqual(e2e.app.staticTexts["panel.title"].label, "Salve")
        XCTAssertFalse(specialize.exists, "Stufe 3 ist die letzte")
        XCTAssertTrue(e2e.app.buttons["target"].exists, "die Zielwahl bleibt")
        e2e.screenshot("p3-1-salve", in: self)
    }
}
