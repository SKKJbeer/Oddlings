import XCTest

/// Laufen in der echten App (A-1, D-029): In der Vorführung laufen Gegner durch
/// die Eckbögen und setzen mit Staub auf. Die Figuren sind SpriteKit und für
/// XCUITest unsichtbar; der Zähler `fx.stats` (nur Debug-Bau) zeigt, was die Szene getan hat.
final class WalkE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testDemoWalksThroughBendsWithFootfalls() throws {
        let e2e = try E2EApp(["--demo", "--e2e-zeitraffer", E2EApp.readableFastForward, "--e2e-fx"])
        e2e.waitForBoard()
        let stats = e2e.app.staticTexts["fx.stats"]
        XCTAssertTrue(stats.waitForExistence(timeout: 10), "Effektzähler da")
        let end = Date().addingTimeInterval(90)
        var values: [String: Int] = [:]
        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            values = EffectsE2ETests.parse(stats.label)
        } while ((values["bends"] ?? 0) < 5 || (values["footfalls"] ?? 0) < 5) && Date() < end
        XCTAssertGreaterThanOrEqual(values["bends"] ?? 0, 5, stats.label)
        XCTAssertGreaterThanOrEqual(values["footfalls"] ?? 0, 5, stats.label)
    }
}
