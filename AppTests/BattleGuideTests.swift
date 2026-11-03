import OddlingsCore
import XCTest
@testable import Oddlings

/// Stille Zeichen des Einstiegs (P2-8, K8): erscheinen nur beim Zögern, einer
/// zur Zeit, je Gerät einmal, abschaltbar, nie beim Zuschauen. Ohne Bildschirm:
/// Der Guide bekommt die Lage als Wert.
@MainActor
final class BattleGuideTests: XCTestCase {
    /// Eigene Ablage je Aufruf, damit kein Test den Stand des Geräts oder eines
    /// anderen Tests sieht. Ohne `tearDown`: Die Klasse ist an den Hauptakteur
    /// gebunden, und Swift 6 lässt das Überschreiben dann nicht zu.
    private func memory() -> GuideMemory {
        let name = "BattleGuideTests-\(UUID().uuidString)"
        addTeardownBlock { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        return GuideMemory(defaults: UserDefaults(suiteName: name)!)
    }

    private let cell = Cell(x: 3, y: 2)

    private func guide(_ memory: GuideMemory, intro: Bool = true, interactive: Bool = true) -> BattleGuide {
        BattleGuide(memory: memory, intro: intro, interactive: interactive) { [cell] in cell }
    }

    private func situation(dt: Double, towers: Int = 0, started: Bool = false, canCall: Bool = true,
                           halted: Bool = false) -> BattleGuide.Situation {
        BattleGuide.Situation(dt: dt, towers: towers, firstWaveStarted: started, canCallWave: canCall, halted: halted)
    }

    /// Wartet `seconds` in Bildern zu 0,1 s.
    private func wait(_ guide: BattleGuide, _ seconds: Double, towers: Int = 0, started: Bool = false,
                      canCall: Bool = true, halted: Bool = false) {
        for _ in 0..<Int((seconds * 10).rounded()) {
            guide.update(situation(dt: 0.1, towers: towers, started: started, canCall: canCall, halted: halted))
        }
    }

    func testHandOnlyAfterHesitatingThenArrowAfterFirstTower() {
        let memory = memory()
        let guide = guide(memory)
        wait(guide, BattleStyle.guideBuildDelay - 0.5)
        XCTAssertEqual(guide.shown, .none, "wer gleich baut, sieht keine Hand")
        wait(guide, 1)
        XCTAssertEqual(guide.shown, .build(cell))
        XCTAssertTrue(memory.seen(.build), "gesehen, sobald sie stand")
        XCTAssertFalse(memory.seen(.wave))

        // Erster Turm: Hand weg, dann zögert der Spieler am Welle-Knopf.
        wait(guide, 0.1, towers: 1)
        XCTAssertEqual(guide.shown, .none)
        wait(guide, BattleStyle.guideWaveDelay - 0.5, towers: 1)
        XCTAssertEqual(guide.shown, .none)
        wait(guide, 1, towers: 1)
        XCTAssertEqual(guide.shown, .wave)
        XCTAssertTrue(memory.seen(.wave))

        // Die Welle läuft: Pfeil weg, und er kommt nicht wieder.
        wait(guide, 0.1, towers: 1, started: true)
        XCTAssertEqual(guide.shown, .none)
        wait(guide, 30, towers: 1, started: true)
        XCTAssertEqual(guide.shown, .none)
    }

    func testEarlyBuilderAndEarlyCallerNeverSeeAnythingButLearnedIt() {
        let memory = memory()
        let guide = guide(memory)
        wait(guide, 1)
        wait(guide, 1, towers: 1)
        guide.playerCalledWave()
        wait(guide, 0.1, towers: 1)
        wait(guide, 30, towers: 1, started: true)
        XCTAssertEqual(guide.shown, .none)
        XCTAssertTrue(memory.seen(.build), "selbst gebaut heißt gelernt")
        XCTAssertTrue(memory.seen(.wave), "selbst gerufen heißt gelernt")
    }

    func testWaveThatCameByItselfIsNotLearned() {
        let memory = memory()
        let guide = guide(memory)
        wait(guide, 1, towers: 1)
        wait(guide, 0.1, towers: 1, started: true)
        wait(guide, 30, towers: 1, started: true)
        XCTAssertEqual(guide.shown, .none)
        XCTAssertFalse(memory.seen(.wave), "nächster Versuch zeigt den Pfeil, wenn er wieder zögert")
    }

    func testSeenStepsNeverReturn() {
        let memory = memory()
        memory.markSeen(.build)
        memory.markSeen(.wave)
        let guide = guide(memory)
        wait(guide, 60)
        XCTAssertEqual(guide.shown, .none)
    }

    func testOneAtATimeArrowWaitsForTheHand() {
        let guide = guide(memory())
        // Kein Turm, Knopf da, lange gezögert: nur die Hand, nie beides.
        wait(guide, 60)
        XCTAssertEqual(guide.shown, .build(cell))
    }

    func testPauseHidesAndStopsTheWait() {
        let guide = guide(memory())
        wait(guide, 60, halted: true)
        XCTAssertEqual(guide.shown, .none, "angehalten wartet nichts")
        wait(guide, BattleStyle.guideBuildDelay + 0.5)
        XCTAssertEqual(guide.shown, .build(cell))
        wait(guide, 0.1, halted: true)
        XCTAssertEqual(guide.shown, .none, "Pause blendet aus")
        wait(guide, 0.1)
        XCTAssertEqual(guide.shown, .build(cell), "nach der Pause wieder da")
    }

    func testTapSkips() {
        let guide = guide(memory())
        wait(guide, BattleStyle.guideBuildDelay + 0.5)
        XCTAssertEqual(guide.shown, .build(cell))
        guide.skip()
        XCTAssertEqual(guide.shown, .none)
        wait(guide, 10)
        XCTAssertEqual(guide.shown, .none, "übersprungen bleibt weg, auch ohne Turm")
    }

    func testSwitchedOffWatchingOrNotTheFirstMissionShowsNothing() {
        let off = memory()
        AppSettings.setGuide(false, in: off.defaults)
        for guide in [guide(off), guide(memory(), intro: false), guide(memory(), interactive: false)] {
            wait(guide, 60)
            XCTAssertEqual(guide.shown, .none)
        }
        XCTAssertFalse(guide(off).takeSparkSentence(), "ausgeschaltet auch kein Satz")
        XCTAssertFalse(guide(memory(), interactive: false).takeSparkSentence(), "Zuschauen lehrt nicht")
    }

    func testSparkSentenceOnceInEveryMission() {
        let memory = memory()
        XCTAssertTrue(guide(memory, intro: false).takeSparkSentence(), "auch ohne Einstieg, die Synergie gilt überall")
        XCTAssertFalse(guide(memory, intro: false).takeSparkSentence(), "nur einmal je Gerät")
        XCTAssertTrue(memory.seen(.spark))
    }

    func testMemoryIgnoresForeignValuesAndResets() {
        let memory = memory()
        memory.defaults.set("ja", forKey: GuideMemory.key(.build))
        memory.defaults.set(1, forKey: GuideMemory.key(.wave))
        XCTAssertFalse(memory.seen(.build))
        XCTAssertFalse(memory.seen(.wave))
        memory.markSeen(.spark)
        AppSettings.setGuide(false, in: memory.defaults)
        memory.reset()
        XCTAssertFalse(memory.seen(.spark))
        XCTAssertTrue(memory.enabled, "nach dem Zurücksetzen wieder an")
    }

    /// Die Hand zeigt, wo der günstigste Kampfturm am meisten Weg abdeckt, also
    /// dieselbe Zelle, die der Mitspieler für ihn wählen würde.
    func testControllerPointsAtBestCellForCheapestTower() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true, intro: true, memory: memory())
        for _ in 0..<Int((BattleStyle.guideBuildDelay + 0.5) * 60) {
            controller.afterFrame(events: [], dt: 1.0 / 60)
        }
        let cheapest = try XCTUnwrap(config.buildable.min { (config.cost(of: $0) ?? 0) < (config.cost(of: $1) ?? 0) })
        let range = try XCTUnwrap(config.stats(of: cheapest, level: 1)?.range)
        XCTAssertEqual(controller.guide.shown, .build(try XCTUnwrap(model.sim.map.bestCell(radius: range, excluding: []))))
        controller.tap(nil)
        XCTAssertEqual(controller.guide.shown, .none, "Tippen auf die Karte überspringt")
    }
}
