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

    /// Mitgeschriebene Haptik statt echter Vibration.
    private var felt: [Haptic] = []

    private func recordHaptics() {
        controller.haptics = { [unowned self] in felt.append($0) }
    }

    private func stepAndRefresh() {
        controller.afterFrame(events: model.step())
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
        XCTAssertEqual(controller.selection, .tower(id: tower.id, sellArmed: true), "erstes Tippen fragt nur")
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.count, 1, "erstes Tippen verkauft nicht")
        XCTAssertEqual(controller.gold, before)

        controller.sell()
        stepAndRefresh()
        XCTAssertTrue(model.state.towers.isEmpty)
        XCTAssertEqual(controller.gold, before + refund)
        XCTAssertEqual(controller.selection, .none)
    }

    func testTapElsewhereCancelsArmedSell() throws {
        build(.watch, at: freeCell)
        controller.tap(freeCell)
        controller.sell()
        XCTAssertTrue(controller.sellArmed)
        controller.tap(pathCell)
        XCTAssertEqual(controller.selection, .none)
        controller.tap(freeCell)
        XCTAssertFalse(controller.sellArmed, "neu gewählt beginnt ohne Bestätigung")
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.count, 1, "abgebrochen heißt nicht verkauft")
    }

    func testUnaffordableChoiceWarnsAndSendsNothing() throws {
        recordHaptics()
        let priciest = try XCTUnwrap(TowerKind.allCases.max { controller.cost(of: $0) < controller.cost(of: $1) })
        let cheapest = try XCTUnwrap(TowerKind.allCases.min { controller.cost(of: $0) < controller.cost(of: $1) })
        var cells = model.sim.map.buildableCells.makeIterator()
        while controller.canAfford(priciest), let cell = cells.next() { build(cheapest, at: cell) }
        let free = try XCTUnwrap(cells.next())
        let towers = model.state.towers.count
        XCTAssertGreaterThan(controller.missingGold(for: priciest), 0)

        controller.tap(free)
        felt = []
        controller.choose(priciest)
        controller.choose(priciest)
        XCTAssertEqual(controller.selection, .cell(free, choice: nil), "nicht leistbar zeigt keine Vorschau")
        XCTAssertEqual(controller.goldWarnings, 2)
        XCTAssertEqual(felt, [.warning, .warning])
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.count, towers, "kein Befehl an die Simulation")
    }

    func testCountersFollowEvents() {
        controller.afterFrame(events: [.towerBuilt(id: 7), .enemyKilled(id: 1, reward: 3),
                                       .enemyKilled(id: 2, reward: 3), .enemyLeaked(id: 3, damage: 1),
                                       .enemyDamaged(id: 4, amount: 1)])
        XCTAssertEqual(controller.towersBuilt, 1)
        XCTAssertEqual(controller.enemiesDefeated, 2)
        XCTAssertEqual(controller.leaks, 1)
        controller.restart()
        XCTAssertEqual(controller.towersBuilt, 0, "Neustart setzt die Zähler zurück")
        XCTAssertEqual(controller.enemiesDefeated, 0)
    }

    func testBuildIsCountedFromTheSimulation() {
        build(.watch, at: freeCell)
        XCTAssertEqual(controller.towersBuilt, 1)
    }

    func testDurationComesFromTicks() {
        let perSecond = config.simulation.ticksPerSecond
        for _ in 0..<(perSecond * 3 + perSecond / 2) { stepAndRefresh() }
        XCTAssertEqual(controller.elapsedSeconds, 3)
    }

    func testGiveUpShowsLossWithoutTouchingTheSimulation() {
        controller.togglePause()
        controller.giveUp()
        XCTAssertEqual(controller.shownOutcome, .lost)
        XCTAssertNil(controller.outcome, "die Simulation hat kein Ergebnis gerechnet")
        XCTAssertNil(model.state.outcome)
        XCTAssertFalse(controller.paused, "die Pausentafel weicht der Ergebnistafel")
        XCTAssertFalse(controller.canCallNextWave)
        let tick = model.state.tick
        _ = model.advance(by: 1)
        XCTAssertEqual(model.state.tick, tick, "die Mission bleibt stehen")
        controller.tap(freeCell)
        XCTAssertEqual(controller.selection, .none, "nach dem Aufgeben keine Eingaben")
        controller.togglePause()
        XCTAssertFalse(controller.paused, "nach dem Ende keine Pause")

        let scene = BattleScene(model: model)
        scene.controller = controller
        scene.restart()
        XCTAssertNil(controller.shownOutcome)
        _ = model.advance(by: 0.5)
        XCTAssertGreaterThan(model.state.tick, 0, "Neustart läuft wieder")
    }

    func testOwnActionsAreFelt() {
        recordHaptics()
        controller.tap(freeCell)
        controller.choose(.watch)
        controller.choose(.watch)
        stepAndRefresh()
        controller.callNextWave()
        XCTAssertEqual(felt, [.selection, .selection, .medium, .heavy])
    }

    func testWatchingIsNotFelt() {
        let demo = BattleModel(config: config, seed: 1, autoplay: true)
        let watching = BattleController(model: demo, interactive: false)
        var count = 0
        watching.haptics = { _ in count += 1 }
        var built = 0
        for _ in 0..<(config.simulation.ticksPerSecond * 30) {
            let events = demo.step()
            built += events.filter { if case .towerBuilt = $0 { true } else { false } }.count
            watching.afterFrame(events: events)
        }
        XCTAssertGreaterThan(built, 0, "der Mitspieler hat gebaut")
        XCTAssertEqual(count, 0)
        XCTAssertEqual(watching.towersBuilt, built)
    }

    func testCountdownRingStartsFull() throws {
        let total = controller.countdownTotal
        XCTAssertEqual(Optional(total), controller.secondsToNextWave)
        for _ in 0..<(config.simulation.ticksPerSecond * 2) { stepAndRefresh() }
        let left = try XCTUnwrap(controller.secondsToNextWave)
        XCTAssertLessThan(left, total)
        XCTAssertEqual(controller.countdownTotal, total, "der Ring läuft ab, die Länge bleibt")
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
