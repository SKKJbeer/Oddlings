import OddlingsCore
import XCTest

/// Türme zielen in der echten App (A-5 Teil 3, D-189): Ein Wachturm bekommt
/// seinen Schützen, der dreht sich zum Gegner und drückt ab; verkauft, ist er
/// weg. Die Figur selbst ist SpriteKit und für XCUITest unsichtbar; die Szene
/// meldet sie im Debug-Bau über `scene.art` (`schuetzen= zielen= treffen=`).
final class TowerAimE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testWatchTowerShooterFacesItsTarget() throws {
        try shooterFacesItsTarget(elves: false)
    }

    /// Bei Elfen steht der Bogenschütze auf dem Turm (D-185); verkauft, ist er weg.
    @MainActor
    func testElvenShooterStandsOnTheTower() throws {
        try shooterFacesItsTarget(elves: true)
    }

    @MainActor
    private func shooterFacesItsTarget(elves: Bool) throws {
        let e2e = try E2EApp(["--play", "--e2e-zeitraffer", E2EApp.readableFastForward,
                              "--e2e-erste-welle", E2EApp.wavesOnHold, "--e2e-fx"]
                             + (elves ? ["--e2e-elfen"] : []))
        e2e.waitForBoard()
        // Der Platz, der am meisten Weg sieht. Erst bauen, dann rufen: Im Zeitraffer
        // liefen sonst schon Plünderer über die Zellen am Weg, und der Tipp träfe den
        // Gegner statt der Zelle (wie in `ArmorE2ETests`).
        let range = try XCTUnwrap(e2e.config.towers[.watch]).range
        let cell = try XCTUnwrap(e2e.map.buildableCells.max {
            e2e.map.path.coverage(around: $0.center, radius: range) < e2e.map.path.coverage(around: $1.center, radius: range)
        })
        e2e.build(.watch, at: cell)
        e2e.waitFor(e2e.gold, toBe: e2e.config.mission.startGold - e2e.cost(.watch), "gebaut")

        let art = e2e.app.staticTexts["scene.art"]
        XCTAssertTrue(art.waitForExistence(timeout: 10), "Bildzähler da")
        XCTAssertEqual(Self.parse(art.label)["schuetzen"], 1, art.label)
        // Solange die Elfenbilder fehlen, steht der Zwerg da (Rückfall, D-185).
        let elvenFrames = Self.parse(art.label)["elfenbilder"] == 1
        XCTAssertEqual(Self.parse(art.label)["elfen"], elves && elvenFrames ? 1 : 0, art.label)

        if elves {
            // Verkaufen prüft der kurze Elfenlauf, vor der ersten Welle: Danach laufen
            // Gegner über den Turm, und das Tippen trifft sie statt seiner Tafel.
            e2e.tap(cell)
            XCTAssertTrue(e2e.sell.waitForExistence(timeout: 5), "Tafel des Turms öffnet")
            e2e.sell.tap()
            XCTAssertTrue(e2e.sellConfirm.waitForExistence(timeout: 5))
            e2e.sell.tap()
            let gone = Date().addingTimeInterval(5)
            while Self.parse(art.label)["schuetzen"] != 0, Date() < gone {
                RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            }
            XCTAssertEqual(Self.parse(art.label)["schuetzen"], 0, "verkauft, kein Schütze mehr: \(art.label)")
            return
        }

        // Zielen prüft der Zwerg: Welle rufen, warten, bis er ein Ziel hat und
        // darauf blickt, und bis er geschossen hat.
        e2e.nextWave.tap()
        let stats = e2e.app.staticTexts["fx.stats"]
        let end = Date().addingTimeInterval(120)
        var aimed = false
        repeat {
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
            let values = Self.parse(art.label)
            if let aiming = values["zielen"], aiming > 0, values["treffen"] == aiming { aimed = true }
        } while !(aimed && (Self.parse(stats.label)["shots"] ?? 0) > 0) && Date() < end
        XCTAssertTrue(aimed, "der Schütze blickt auf sein Ziel: \(art.label)")
        XCTAssertGreaterThan(Self.parse(stats.label)["shots"] ?? 0, 0, "er drückt ab: \(stats.label)")
        e2e.screenshot("a-5-schuetze-zielt", in: self)
    }

    /// `towers=… schuetzen=1 zielen=1 treffen=1` → Tabelle der Zahlen.
    static func parse(_ summary: String) -> [String: Int] { EffectsE2ETests.parse(summary) }
}
