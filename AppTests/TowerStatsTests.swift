import OddlingsCore
import XCTest
@testable import Oddlings

/// Wertetafel am Turm in der Bedienung (D-130): was die Tafel zeigt, wie die
/// Zahlen geschrieben sind und dass Vorschau und Kauf dieselben Werte haben.
/// Werte aus `mission-03.json`, damit eine Balanceänderung keinen Test bricht.
@MainActor
final class TowerStatsTests: XCTestCase {
    private lazy var config: BalanceConfig = {
        var copy = try! BalanceConfig.bundledMission(named: "mission-03")
        copy.mission.startGold = 1_000
        copy.mission.firstWaveDelay = 600
        return copy
    }()
    private lazy var model = BattleModel(config: config, seed: 1, autoplay: false)
    private lazy var controller = BattleController(model: model, interactive: true)

    private func stepAndRefresh() { controller.afterFrame(events: model.step()) }

    private func build(_ kind: TowerKind) throws -> Tower {
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        controller.choose(kind)
        controller.choose(kind)
        stepAndRefresh()
        controller.tap(cell)
        return try XCTUnwrap(model.state.towers.last)
    }

    func testTowerShowsItsValuesUntilUpgradeIsArmed() throws {
        let tower = try build(.watch)
        let now = controller.statChanges(for: tower)
        XCTAssertEqual(now.map(\.figure), [.damagePerSecond, .damage, .rate, .range])
        XCTAssertTrue(now.allSatisfy(\.isUnchanged), "ohne Vorschau kein Vergleich")

        controller.upgrade()
        let preview = controller.statChanges(for: try XCTUnwrap(controller.selectedTower))
        let second = TowerSheet(kind: .watch, stats: try XCTUnwrap(config.stats(of: .watch, level: 2)))
        XCTAssertEqual(preview.map(\.after), second.readings.map(\.value), "Vorschau = Werte nach dem Kauf")
        XCTAssertFalse(preview[0].isUnchanged)

        controller.upgrade()
        stepAndRefresh()
        let bought = controller.statChanges(for: try XCTUnwrap(controller.selectedTower))
        XCTAssertEqual(bought.map(\.after), preview.map(\.after), "gekauft wird, was die Tafel versprach")
    }

    func testBuildPreviewHasValuesBankHasNone() {
        XCTAssertEqual(controller.statChanges(for: .lightning).first?.figure, .damagePerSecond)
        XCTAssertTrue(controller.statChanges(for: .bank).isEmpty)
    }

    func testTallyCountsSecondsSinceBuilding() throws {
        let tower = try build(.watch)
        for _ in 0..<(config.simulation.ticksPerSecond * 3) { stepAndRefresh() }
        XCTAssertEqual(controller.secondsInBattle(try XCTUnwrap(controller.selectedTower)), 3)
        XCTAssertTrue(TowerStatTexts.tally(tower, seconds: 75).hasSuffix("seit 1:15"))
    }

    func testNumbersAreWrittenInGerman() {
        XCTAssertEqual(TowerStatTexts.value(.damagePerSecond, 22.5), "22,5")
        XCTAssertEqual(TowerStatTexts.value(.damagePerSecond, 151.2), "151")
        XCTAssertEqual(TowerStatTexts.value(.rate, 1.25), "1,25/s")
        XCTAssertEqual(TowerStatTexts.value(.slow, 0.6), "60 %")
        XCTAssertEqual(TowerStatTexts.value(.vulnerable, 0.4), "+40 %")
        XCTAssertEqual(TowerStatTexts.grouped(1_240), "1.240")
        XCTAssertEqual(TowerStatTexts.grouped(1_234_567), "1.234.567")
    }

    func testDeltaChips() {
        func change(_ figure: TowerFigure, _ before: Double?, _ after: Double) -> TowerChange {
            TowerChange(figure: figure, before: before, after: after)
        }
        XCTAssertEqual(TowerStatTexts.delta(change(.damagePerSecond, 15, 22.5)), "+50 %")
        XCTAssertEqual(TowerStatTexts.delta(change(.damage, 12, 18)), "+6")
        XCTAssertEqual(TowerStatTexts.delta(change(.rate, 1.25, 1.25 / 1.5)), "−33 %", "ein Preis mit echtem Minus")
        XCTAssertEqual(TowerStatTexts.delta(change(.slow, 0.5, 0.6)), "+10")
        XCTAssertEqual(TowerStatTexts.delta(change(.targets, 1, 2)), "+1")
        XCTAssertEqual(TowerStatTexts.delta(change(.range, 2.5, 2.5)), TowerStatTexts.same)
        XCTAssertNil(TowerStatTexts.delta(change(.range, nil, 2.5)))
    }

    func testVoiceOverReadsTheComparison() {
        let change = TowerChange(figure: .damage, before: 12, after: 18)
        XCTAssertEqual(TowerStatTexts.spoken(change, kind: .watch, comparing: true), "Schaden: 12 auf 18, +6")
        XCTAssertEqual(TowerStatTexts.spoken(change, kind: .watch, comparing: false), "Schaden: 18")
    }
}
