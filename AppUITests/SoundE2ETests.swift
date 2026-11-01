import XCTest

/// Ton in der echten App (P2-3, D-029). Hören kann XCUITest nicht; der Zähler
/// `audio.stats` (nur Debug-Bau, `--e2e-ton`) zeigt, welche Klänge die App
/// ausgelöst hat und welche Musiklage läuft.
final class SoundE2ETests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    @MainActor
    func testMenuHasMusicAndDemoSoundsLikeABattle() throws {
        let e2e = try E2EApp(["--e2e-ton"])
        let stats = e2e.app.staticTexts["audio.stats"]
        XCTAssertTrue(stats.waitForExistence(timeout: 15), "Tonzähler da")
        XCTAssertTrue(wait(for: stats, until: { _ in stats.label.contains("mood=menu") }),
                      "Menümusik: \(stats.label)")
        e2e.app.terminate()

        let demo = try E2EApp(["--demo", "--e2e-zeitraffer", E2EApp.readableFastForward, "--e2e-ton"])
        demo.waitForBoard()
        let battle = demo.app.staticTexts["audio.stats"]
        XCTAssertTrue(battle.waitForExistence(timeout: 10))
        let wanted = ["watchShot", "boltShot", "sporePuff", "hit", "enemyPop", "coin", "build", "wave"]
        let heard = wait(for: battle) { values in wanted.allSatisfy { (values[$0] ?? 0) > 0 } }
        let values = EffectsE2ETests.parse(battle.label)
        XCTAssertTrue(heard, "alle Klanggruppen: \(battle.label)")
        XCTAssertTrue(battle.label.contains("mood=battle") || battle.label.contains("mood=finalWave")
                      || battle.label.contains("mood=victory") || battle.label.contains("mood=defeat"),
                      "Kampfmusik: \(battle.label)")
        XCTAssertEqual(values["uiTap"] ?? 0, 0, "Zuschauen ohne Bedientöne")
    }

    @MainActor
    func testVolumeSlidersSurviveRelaunch() throws {
        func openSettings(_ e2e: E2EApp) -> (sound: XCUIElement, music: XCUIElement) {
            let button = e2e.app.buttons["menu.settings"]
            XCTAssertTrue(button.waitForExistence(timeout: 15), "Einstellungen im Menü")
            button.tap()
            let sound = e2e.app.sliders["settings.sound"]
            let music = e2e.app.sliders["settings.music"]
            XCTAssertTrue(sound.waitForExistence(timeout: 5), "Klangregler")
            XCTAssertTrue(music.exists, "Musikregler")
            return (sound, music)
        }

        let e2e = try E2EApp()
        let first = openSettings(e2e)
        first.music.adjust(toNormalizedSliderPosition: 0)
        XCTAssertEqual(first.music.value as? String, "0 %")
        e2e.app.buttons["settings.done"].tap()
        e2e.app.terminate()

        let again = try E2EApp()
        let second = openSettings(again)
        XCTAssertEqual(second.music.value as? String, "0 %", "Musik bleibt aus nach dem Neustart")
        // Zurück auf die Vorgabe, damit spätere Läufe Musik haben.
        second.music.adjust(toNormalizedSliderPosition: 0.6)
        XCTAssertNotEqual(second.music.value as? String, "0 %")
    }

    /// Liest den Zähler, bis `done` gilt oder zwei Minuten um sind.
    @MainActor
    private func wait(for stats: XCUIElement, until done: ([String: Int]) -> Bool) -> Bool {
        let end = Date().addingTimeInterval(120)
        repeat {
            if done(EffectsE2ETests.parse(stats.label)) { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < end
        return false
    }
}
