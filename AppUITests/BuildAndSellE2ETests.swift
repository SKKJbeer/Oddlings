import OddlingsCore
import XCTest

/// Bauen und Verkaufen mit echtem Tippen (WP-12).
final class BuildAndSellE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testBuildChargesGoldAndSellRefunds() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        let start = e2e.config.mission.startGold
        XCTAssertEqual(e2e.gold, start)
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)

        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: start - e2e.cost(.watch), "Bauen zieht den Preis ab")

        e2e.tap(cell)
        XCTAssertTrue(e2e.sell.waitForExistence(timeout: 5), "Turm ist gebaut und wählbar")
        e2e.sell.tap()
        e2e.waitFor(e2e.gold, toBe: start - e2e.cost(.watch) + e2e.sim.refund(for: e2e.cost(.watch)),
                    "Verkaufen erstattet den Anteil aus der Missionsdatei")

        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.watch).waitForExistence(timeout: 5), "Zelle nach dem Verkauf wieder frei")
    }

    @MainActor
    func testFirstChoiceOnlyPreviews() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.lightning).waitForExistence(timeout: 5))
        e2e.build(.lightning).tap()
        XCTAssertEqual(e2e.build(.lightning).label.contains("Bauen"), true, "erster Tipp zeigt „Bauen“")
        XCTAssertEqual(e2e.gold, e2e.config.mission.startGold, "Vorschau kostet nichts")
    }

    @MainActor
    func testTapOutsideClosesMenu() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        let cell = try XCTUnwrap(e2e.map.buildableCells.first)
        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.watch).waitForExistence(timeout: 5))
        e2e.tap(cell)
        XCTAssertTrue(e2e.build(.watch).waitForNonExistence(timeout: 5), "zweiter Tipp auf die Zelle schließt")
    }

    @MainActor
    func testUnaffordableTowerIsDisabled() throws {
        let e2e = try E2EApp(["--play"])
        e2e.waitForBoard()
        var cells = e2e.map.buildableCells.makeIterator()
        let cheapest = TowerKind.allCases.min { e2e.cost($0) < e2e.cost($1) }!
        var expected = e2e.config.mission.startGold
        while expected >= e2e.cost(cheapest), let cell = cells.next() {
            e2e.build(cheapest, at: cell)
            expected -= e2e.cost(cheapest)
            e2e.waitFor(e2e.gold, toBe: expected, "Gold nach Bau")
        }
        let free = try XCTUnwrap(cells.next())
        e2e.tap(free)
        XCTAssertTrue(e2e.build(cheapest).waitForExistence(timeout: 5))
        XCTAssertFalse(e2e.build(cheapest).isEnabled, "zu teuer ist ausgegraut")
    }
}
