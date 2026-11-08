import OddlingsCore
import XCTest

/// Mission 7, der Moorkönig (P3-4). `--e2e-bosswelle` lässt nur die letzte
/// Welle laufen; Kuppel und Ruf sind SpriteKit und in `BossAppTests` geprüft,
/// hier zählt, dass die Leiste mit seinem Auftritt erscheint.
final class BossE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testBossBarAppearsWithTheMoorKing() throws {
        let e2e = try E2EApp(["--play", "--e2e-knoten", "m7", "--e2e-zeitraffer", E2EApp.readableFastForward,
                              "--e2e-bosswelle", "--e2e-fx"],
                             mission: "mission-07")
        e2e.waitForBoard()
        XCTAssertNotNil(e2e.config.enemies[.moorKing]?.boss, "Mission 7 hat den Boss")
        XCTAssertTrue(e2e.waveLabel.hasSuffix("/1"), "nur die Bosswelle: \(e2e.waveLabel)")
        let bar = e2e.app.descendants(matching: .any).matching(identifier: "hud.boss").firstMatch
        if e2e.nextWave.waitForExistence(timeout: 5) { e2e.nextWave.tap() }
        XCTAssertTrue(bar.waitForExistence(timeout: 30), "die Leiste erscheint mit dem Moorkönig")
        XCTAssertEqual(bar.label, "Moorkönig")
        XCTAssertTrue((bar.value as? String ?? "").hasSuffix("Prozent Leben"), "\(String(describing: bar.value))")
        e2e.screenshot("p3-4-moorkoenig", in: self)
    }
}
