import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Aufwerten und Zielwahl in der Bedienung (P2-6). Werte aus `mission-03.json`,
/// damit eine Balanceänderung keinen Test bricht.
@MainActor
final class UpgradeControllerTests: XCTestCase {
    private lazy var config: BalanceConfig = {
        var copy = try! BalanceConfig.bundledMission(named: "mission-03")
        // Gold für Bau und Aufwerten, und keine Welle, die dazwischenkommt.
        copy.mission.startGold = 1_000
        copy.mission.firstWaveDelay = 600
        return copy
    }()
    private lazy var model = BattleModel(config: config, seed: 1, autoplay: false)
    private lazy var controller = BattleController(model: model, interactive: true)
    private var felt: [Haptic] = []

    private func stepAndRefresh() { controller.afterFrame(events: model.step()) }

    private func build(_ kind: TowerKind) throws -> Tower {
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        controller.choose(kind)
        controller.choose(kind)
        stepAndRefresh()
        let tower = try XCTUnwrap(model.state.towers.last)
        controller.tap(cell)
        XCTAssertEqual(controller.selection, .tower(id: tower.id))
        return tower
    }

    func testFirstTapPreviewsSecondBuys() throws {
        controller.haptics = { [unowned self] in felt.append($0) }
        let tower = try build(.watch)
        let cost = try XCTUnwrap(controller.upgradeCost(for: tower))
        XCTAssertEqual(cost, config.upgradeCost(of: .watch))
        let level1 = try XCTUnwrap(controller.previewRange).range
        felt = []
        controller.upgrade()
        XCTAssertTrue(controller.upgradeArmed, "erstes Tippen fragt nur")
        XCTAssertEqual(felt, [.selection])
        let gold = model.state.gold
        stepAndRefresh()
        XCTAssertEqual(model.state.gold, gold, "noch nichts bezahlt")
        let preview = try XCTUnwrap(controller.previewRange).range
        XCTAssertEqual(preview, try XCTUnwrap(config.stats(of: .watch, level: 2)).range)
        XCTAssertGreaterThanOrEqual(preview, level1)

        controller.upgrade()
        stepAndRefresh()
        XCTAssertEqual(model.state.gold, gold - cost)
        XCTAssertEqual(model.state.towers.last?.level, 2)
        XCTAssertEqual(controller.selection, .tower(id: tower.id), "Auswahl bleibt am Turm")
        XCTAssertEqual(controller.towersUpgraded, 1)
        XCTAssertNil(controller.upgradeCost(for: try XCTUnwrap(controller.selectedTower)), "Stufe 2 ist die letzte")
    }

    func testNotEnoughGoldWarnsAndSendsNothing() throws {
        var poor = config
        poor.mission.startGold = try XCTUnwrap(config.cost(of: .watch)) + XCTUnwrap(config.upgradeCost(of: .watch)) - 1
        model = BattleModel(config: poor, seed: 1, autoplay: false)
        controller = BattleController(model: model, interactive: true)
        controller.haptics = { [unowned self] in felt.append($0) }
        _ = try build(.watch)
        felt = []
        controller.upgrade()
        XCTAssertFalse(controller.upgradeArmed)
        XCTAssertEqual(felt, [.warning])
        XCTAssertEqual(controller.goldWarnings, 1)
    }

    func testTargetModeOnlyFromLevelTwoAndNeverForSpores() throws {
        let watch = try build(.watch)
        XCTAssertFalse(controller.hasTargetMode(watch))
        controller.cycleTargetMode()
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.last?.targetMode, .first, "auf Stufe 1 geht kein Befehl hinaus")

        controller.upgrade()
        controller.upgrade()
        stepAndRefresh()
        XCTAssertTrue(controller.hasTargetMode(try XCTUnwrap(controller.selectedTower)))
        for expected in [TargetMode.last, .strongest, .first] {
            controller.cycleTargetMode()
            stepAndRefresh()
            XCTAssertEqual(model.state.towers.last?.targetMode, expected)
        }

        let spore = Tower(id: watch.id, kind: .spore, cell: watch.cell, cooldownTicks: 0, spent: 1, level: 2)
        XCTAssertFalse(controller.hasTargetMode(spore), "der Sporenturm trifft alle im Kreis")
    }

    func testMissionsWithoutUpgradesOfferNone() throws {
        for (name, mission) in [("M1", try BalanceConfig.missionOne()),
                                ("M2", try BalanceConfig.bundledMission(named: "mission-02"))] {
            let other = BattleController(model: BattleModel(config: mission, seed: 1, autoplay: false), interactive: true)
            let tower = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1)
            XCTAssertNil(other.upgradeCost(for: tower), name)
        }
    }

    func testRestartClearsTheCount() throws {
        _ = try build(.watch)
        controller.upgrade()
        controller.upgrade()
        stepAndRefresh()
        XCTAssertEqual(controller.towersUpgraded, 1)
        controller.restart()
        XCTAssertEqual(controller.towersUpgraded, 0)
    }

    func testTowerNodeShowsLevelWithBadgeAndPicture() throws {
        let tower = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1)
        let node = TowerNode(tower: tower, field: 40)
        XCTAssertNil(node.childNode(withName: "level.badge"))
        let before = (node.art.children.first as? SKSpriteNode)?.texture
        node.showLevel(2, field: 40)
        XCTAssertEqual(node.level, 2)
        XCTAssertNotNil(node.childNode(withName: "level.badge"))
        let after = (node.art.children.first as? SKSpriteNode)?.texture
        XCTAssertNotNil(after)
        XCTAssertFalse(before === after, "Stufe 2 hat ein eigenes Bild")
        node.showLevel(2, field: 40)
        XCTAssertEqual(node.children.filter { $0.name == "level.badge" }.count, 1, "nicht doppelt")
    }
}
