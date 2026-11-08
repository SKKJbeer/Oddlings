import OddlingsCore
import XCTest

/// Aufwerten und Zielwahl in Mission 3, mit echtem Tippen (P2-6). Preise aus
/// `mission-03.json`.
final class UpgradeE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testUpgradeCostsItsPriceAndUnlocksTargetMode() throws {
        let e2e = try E2EApp(["--play", "--e2e-knoten", "m3", "--e2e-erste-welle", E2EApp.wavesOnHold],
                             mission: "mission-03")
        e2e.waitForBoard()
        let start = e2e.config.mission.startGold
        let price = try XCTUnwrap(e2e.config.upgradeCost(of: .watch), "Mission 3 bietet Aufwertung an")
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: start - e2e.cost(.watch), "Bauen zieht den Preis ab")

        e2e.tap(cell)
        let upgrade = e2e.app.buttons["upgrade"]
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5), "am Turm steht Aufwerten")
        XCTAssertFalse(e2e.app.buttons["target"].exists, "Zielwahl erst ab Stufe 2")
        let tally = e2e.app.staticTexts["panel.tally"]
        XCTAssertTrue(tally.waitForExistence(timeout: 5), "am Turm steht seine Kampfbilanz (D-130)")
        XCTAssertTrue(tally.label.contains("erledigt"), "gelesen: \(tally.label)")
        let leading = e2e.app.descendants(matching: .any)["stat.damagePerSecond"]
        XCTAssertTrue(leading.exists, "Schaden je Sekunde steht vorn")
        upgrade.tap()
        XCTAssertTrue(e2e.app.staticTexts["upgrade.confirm"].waitForExistence(timeout: 5), "erstes Tippen fragt")
        XCTAssertEqual(e2e.gold, start - e2e.cost(.watch), "noch nichts bezahlt")
        // Vorher-nachher (D-130): dasselbe Plus, das die Konfiguration verspricht.
        let first = TowerSheet(kind: .watch, stats: try XCTUnwrap(e2e.config.stats(of: .watch, level: 1)))
        let second = TowerSheet(kind: .watch, stats: try XCTUnwrap(e2e.config.stats(of: .watch, level: 2)))
        let ratio = try XCTUnwrap(first.changes(to: second).first?.ratio)
        XCTAssertEqual(leading.value as? String, "+\(Int((ratio * 100).rounded())) %")
        XCTAssertEqual(e2e.app.staticTexts["panel.title"].label, "Wachturm → II")
        XCTAssertEqual(e2e.app.descendants(matching: .any)["stat.range"].value as? String, "gleich")
        e2e.screenshot("d-130-vergleich", in: self)
        upgrade.tap()
        e2e.waitFor(e2e.gold, toBe: start - e2e.cost(.watch) - price, "Aufwerten zieht den Preis ab")
        XCTAssertEqual(e2e.app.staticTexts["panel.title"].label, "Wachturm II")
        XCTAssertFalse(upgrade.exists, "Stufe 2 ist die letzte")

        let target = e2e.app.buttons["target"]
        XCTAssertTrue(target.waitForExistence(timeout: 5), "Stufe 2 schaltet die Zielwahl frei")
        XCTAssertEqual(target.value as? String, "Erster")
        target.tap()
        e2e.waitFor(target, label: "Ziel: Letzter")
        target.tap()
        e2e.waitFor(target, label: "Ziel: Stärkster")
        XCTAssertEqual(e2e.gold, start - e2e.cost(.watch) - price, "Zielwahl kostet nichts")
        e2e.screenshot("p2-6-aufgewertet", in: self)
    }
}
