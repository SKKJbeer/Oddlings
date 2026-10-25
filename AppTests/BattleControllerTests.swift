import OddlingsCore
import XCTest
@testable import Oddlings

/// Bedienung der Mission (WP-12 bis WP-14): Tippen wird zu Befehlen, die
/// Anzeige folgt dem Zustand. Zahlen kommen aus der Missionsdatei, nie aus
/// dem Test, damit eine Balanceänderung keinen Test bricht.
@MainActor
final class BattleControllerTests: XCTestCase {
    // Ohne setUp: Die Klasse ist an den Hauptakteur gebunden, setUp von
    // XCTest nicht, und Swift 6 lässt das Überschreiben dann nicht zu.
    private lazy var config: BalanceConfig = try! BalanceConfig.missionOne()
    private lazy var model = BattleModel(config: config, seed: 1, autoplay: false)
    private lazy var controller = BattleController(model: model, interactive: true)

    private var freeCell: Cell { try! XCTUnwrap(model.sim.map.buildableCells.first) }

    private var pathCell: Cell {
        let map = model.sim.map
        for y in 0..<map.height {
            for x in 0..<map.width where !map.isBuildable(Cell(x: x, y: y)) {
                return Cell(x: x, y: y)
            }
        }
        fatalError("Karte ohne Weg")
    }

    private func stepAndRefresh() {
        _ = model.step()
        controller.afterFrame()
    }

    private func build(_ kind: TowerKind, at cell: Cell) {
        controller.tap(cell)
        controller.choose(kind)
        controller.choose(kind)
        stepAndRefresh()
    }

    func testTapOnFreeCellOpensBuildMenu() {
        controller.tap(freeCell)
        XCTAssertEqual(controller.selection, .cell(freeCell, choice: nil))
        controller.tap(freeCell)
        XCTAssertEqual(controller.selection, .none, "zweiter Tipp schließt")
    }

    func testTapOnPathOpensNothing() {
        controller.tap(pathCell)
        XCTAssertEqual(controller.selection, .none)
        controller.tap(nil)
        XCTAssertEqual(controller.selection, .none)
    }

    func testFirstChoiceShowsRangeSecondBuilds() throws {
        controller.tap(freeCell)
        controller.choose(.watch)
        XCTAssertEqual(controller.selection, .cell(freeCell, choice: .watch))
        let range = try XCTUnwrap(controller.previewRange)
        XCTAssertEqual(range.range, config.towers[.watch]?.range)
        XCTAssertTrue(model.state.towers.isEmpty, "Vorschau baut nicht")

        controller.choose(.watch)
        XCTAssertEqual(controller.selection, .none)
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.map(\.cell), [freeCell])
        XCTAssertEqual(controller.gold, config.mission.startGold - (config.towers[.watch]?.cost ?? 0))
    }

    func testTapOnTowerOffersSellAndRefunds() throws {
        build(.watch, at: freeCell)
        let tower = try XCTUnwrap(model.state.towers.first)
        controller.tap(freeCell)
        XCTAssertEqual(controller.selection, .tower(id: tower.id))
        let refund = controller.refund(for: tower)
        let before = controller.gold
        controller.sell()
        stepAndRefresh()
        XCTAssertTrue(model.state.towers.isEmpty)
        XCTAssertEqual(controller.gold, before + refund)
        XCTAssertEqual(controller.selection, .none)
    }

    func testUnaffordableKindIsMarked() {
        let cheapest = TowerKind.allCases.map(controller.cost(of:)).min() ?? 0
        var cells = model.sim.map.buildableCells.makeIterator()
        while controller.gold >= cheapest, let cell = cells.next() {
            let kind = TowerKind.allCases.first { controller.cost(of: $0) == cheapest }!
            build(kind, at: cell)
        }
        for kind in TowerKind.allCases {
            XCTAssertEqual(controller.canAfford(kind), controller.gold >= controller.cost(of: kind))
        }
        XCTAssertFalse(TowerKind.allCases.allSatisfy(controller.canAfford))
    }

    func testWatchModeIgnoresInput() {
        let watching = BattleController(model: model, interactive: false)
        watching.tap(freeCell)
        XCTAssertEqual(watching.selection, .none)
        XCTAssertFalse(watching.canCallNextWave)
    }

    func testCallNextWaveStartsItNow() {
        XCTAssertEqual(controller.wave, 0)
        XCTAssertNotNil(controller.secondsToNextWave)
        controller.callNextWave()
        stepAndRefresh()
        XCTAssertEqual(controller.wave, 1)
    }

    func testCountdownMatchesMissionFile() {
        XCTAssertEqual(controller.secondsToNextWave, Int(config.mission.firstWaveDelay.rounded(.up)))
    }

    func testPauseStopsTimeAndResumeContinues() {
        controller.togglePause()
        XCTAssertTrue(controller.paused)
        _ = model.advance(by: 1)
        XCTAssertEqual(model.state.tick, 0)
        controller.togglePause()
        _ = model.advance(by: 0.5)
        XCTAssertGreaterThan(model.state.tick, 0)
    }

    func testSpeedTogglesBetweenOneAndTwo() {
        controller.toggleSpeed()
        XCTAssertEqual(model.speed, BattleStyle.fastSpeed)
        controller.toggleSpeed()
        XCTAssertEqual(model.speed, 1)
    }

    /// Ohne Türme läuft alles durch: Die Mission geht verloren, die Tafel
    /// erscheint, Neustart setzt alles zurück.
    func testLossShowsResultAndRestartResets() {
        let scene = BattleScene(model: model)
        scene.controller = controller
        controller.toggleSpeed()
        var frames = 0
        while controller.outcome == nil && frames < 200_000 {
            scene.frame(after: 1 / Double(config.simulation.ticksPerSecond))
            frames += 1
        }
        XCTAssertEqual(controller.outcome, .lost)
        XCTAssertEqual(controller.lives, 0)
        XCTAssertFalse(controller.canCallNextWave)

        scene.restart()
        XCTAssertNil(controller.outcome)
        XCTAssertEqual(controller.lives, config.mission.fortressLives)
        XCTAssertEqual(controller.gold, config.mission.startGold)
        XCTAssertEqual(controller.wave, 0)
        XCTAssertFalse(controller.paused)
    }
}
