import OddlingsCore
import XCTest

/// Oberflächentest (testing-strategy.md): Ein Turm wird mit echtem Tippen
/// gebaut und wieder verkauft. Die Zelle kommt aus der Missionskarte, die
/// Lage auf dem Bildschirm aus derselben Rechnung wie in der App
/// (Seitenverhältnis einpassen, mittig).
final class BuildAndSellUITests: XCTestCase {
    @MainActor
    private func launch() -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments = ["--play"]
        app.launch()
        return app
    }

    @MainActor
    func testBuildThenSellWatchTower() throws {
        let app = launch()

        let board = app.otherElements["battle.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 10), "Karte erscheint")
        let map = try MissionMap(config: BalanceConfig.missionOne().map)
        let cell = try XCTUnwrap(map.buildableCells.first)
        let target = point(of: cell, in: board, map: map)

        target.tap()
        let watch = app.buttons["build.watch"]
        XCTAssertTrue(watch.waitForExistence(timeout: 5), "Baumenü öffnet")
        watch.tap()
        watch.tap()
        XCTAssertTrue(watch.waitForNonExistence(timeout: 5), "Menü schließt nach dem Bau")

        target.tap()
        let sell = app.buttons["sell"]
        XCTAssertTrue(sell.waitForExistence(timeout: 5), "Turm ist gebaut und wählbar")
        sell.tap()

        target.tap()
        XCTAssertTrue(watch.waitForExistence(timeout: 5), "Zelle nach dem Verkauf wieder frei")
    }

    @MainActor
    func testHUDShowsGoldLivesAndWave() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["hud.gold"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["hud.lives"].exists)
        XCTAssertTrue(app.staticTexts["hud.wave"].exists)
        XCTAssertTrue(app.buttons["hud.nextWave"].exists)
        app.buttons["hud.pause"].tap()
        XCTAssertTrue(app.staticTexts["Angehalten"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func point(of cell: Cell, in board: XCUIElement, map: MissionMap) -> XCUICoordinate {
        let size = board.frame.size
        let field = min(size.width / CGFloat(map.width), size.height / CGFloat(map.height))
        let originX = (size.width - field * CGFloat(map.width)) / 2
        let originY = (size.height - field * CGFloat(map.height)) / 2
        let x = originX + (CGFloat(cell.x) + 0.5) * field
        let y = originY + (CGFloat(cell.y) + 0.5) * field
        return board.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: x, dy: y))
    }
}
