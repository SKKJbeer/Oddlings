import XCTest

/// Bewegung und Effekte in der echten App (FX 01, D-029): Die Vorführung im
/// Zeitraffer spielt Pfeil, Blitz, Sporen, Bau, Tod und Münzen. Die Effekte
/// sind SpriteKit und für XCUITest unsichtbar; der Zähler `fx.stats` gibt
/// es nur im Debug-Bau.
final class EffectsE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testDemoPlaysEveryKindOfEffect() throws {
        let e2e = try E2EApp(["--demo", "--e2e-zeitraffer", E2EApp.readableFastForward, "--e2e-fx"])
        e2e.waitForBoard()
        let stats = e2e.app.staticTexts["fx.stats"]
        XCTAssertTrue(stats.waitForExistence(timeout: 10), "Effektzähler da")
        let wanted = ["arrows", "bolts", "spores", "hits", "deaths", "coins", "builds", "spawns"]
        let end = Date().addingTimeInterval(120)
        var values: [String: Int] = [:]
        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            values = Self.parse(stats.label)
        } while wanted.contains(where: { (values[$0] ?? 0) == 0 }) && Date() < end
        for key in wanted { XCTAssertGreaterThan(values[key] ?? 0, 0, "\(key) in \(stats.label)") }
    }

    /// `arrows=3 bolts=1 …` → Tabelle.
    static func parse(_ summary: String) -> [String: Int] {
        var values: [String: Int] = [:]
        for pair in summary.split(separator: " ") {
            let parts = pair.split(separator: "=")
            if parts.count == 2, let value = Int(parts[1]) { values[String(parts[0])] = value }
        }
        return values
    }
}
