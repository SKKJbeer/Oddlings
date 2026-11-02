import OddlingsCore
import XCTest

/// Mission 4 „Ruinenrand“ mit gepanzerter Panzerbestie (P2-10). Schild, Funke
/// und Hinweis sind SpriteKit und für XCUITest unsichtbar; wie bei den
/// Effekten (FX 01) zählt `fx.stats` im Debug-Bau mit.
final class ArmorE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testArmoredBruteSparksAndShowsTheHint() throws {
        let e2e = try E2EApp(["--play", "--e2e-knoten", "m4", "--e2e-zeitraffer", E2EApp.readableFastForward, "--e2e-fx"],
                             mission: "mission-04")
        e2e.waitForBoard()
        XCTAssertTrue(e2e.config.hasArmoredEnemies, "Mission 4 hat Panzerung")
        XCTAssertEqual(e2e.waveLabel, "Welle 0/\(e2e.config.waves.count)", "Mission 4 läuft")
        // Zwei Wachtürme an den Plätzen, die am meisten Weg sehen: Sie treffen
        // die erste Panzerbestie in Welle 2 sicher.
        let range = try XCTUnwrap(e2e.config.towers[.watch]).range
        let cells = e2e.map.buildableCells.sorted {
            e2e.map.path.coverage(around: $0.center, radius: range) > e2e.map.path.coverage(around: $1.center, radius: range)
        }
        for cell in cells.prefix(2) { e2e.build(.watch, at: cell) }

        let stats = e2e.app.staticTexts["fx.stats"]
        XCTAssertTrue(stats.waitForExistence(timeout: 10), "Effektzähler da")
        let end = Date().addingTimeInterval(120)
        var values: [String: Int] = [:]
        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
            values = EffectsE2ETests.parse(stats.label)
        } while ((values["armorSparks"] ?? 0) == 0 || (values["armorHints"] ?? 0) == 0) && Date() < end
        XCTAssertGreaterThan(values["armorSparks"] ?? 0, 0, "Funke an der Panzerung: \(stats.label)")
        XCTAssertEqual(values["armorHints"], 1, "Hinweis genau einmal: \(stats.label)")
        e2e.screenshot("p2-10-panzerung", in: self)
    }
}
