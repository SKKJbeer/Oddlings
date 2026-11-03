import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Spezialisieren in der Bedienung (P3-1). Werte aus `mission-05a.json`, aber
/// nur als Beziehung, damit eine Balanceänderung keinen Test bricht.
@MainActor
final class SpecializationControllerTests: XCTestCase {
    private lazy var config: BalanceConfig = {
        var copy = try! BalanceConfig.bundledMission(named: "mission-05a")
        copy.mission.startGold = 1_000
        copy.mission.firstWaveDelay = 600
        return copy
    }()
    private lazy var model = BattleModel(config: config, seed: 1, autoplay: false)
    private lazy var controller = BattleController(model: model, interactive: true)

    private func stepAndRefresh() { controller.afterFrame(events: model.step()) }

    private func buildAndUpgrade(_ kind: TowerKind) throws -> Tower {
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        controller.choose(kind)
        controller.choose(kind)
        stepAndRefresh()
        let tower = try XCTUnwrap(model.state.towers.last)
        controller.tap(cell)
        controller.upgrade()
        controller.upgrade()
        stepAndRefresh()
        XCTAssertEqual(model.state.towers.last?.level, 2)
        return try XCTUnwrap(controller.selectedTower ?? model.state.towers.first { $0.id == tower.id })
    }

    func testLevelTwoOffersTheSpecializationOfItsTower() throws {
        let watch = try buildAndUpgrade(.watch)
        XCTAssertEqual(controller.specialization(for: watch), .volley)
        XCTAssertEqual(controller.upgradeCost(for: watch), config.specializations?[.volley]?.cost)
        var levelOne = watch
        levelOne.level = 1
        XCTAssertNil(controller.specialization(for: levelOne), "erst aufwerten")
    }

    func testFirstTapPreviewsSecondSpecializesOnce() throws {
        let spore = try buildAndUpgrade(.spore)
        let cost = try XCTUnwrap(controller.upgradeCost(for: spore))
        let before = try XCTUnwrap(controller.previewRange).range
        controller.upgrade()
        XCTAssertTrue(controller.upgradeArmed)
        let gold = model.state.gold
        stepAndRefresh()
        XCTAssertEqual(model.state.gold, gold, "das erste Tippen kostet nichts")
        let preview = try XCTUnwrap(controller.previewRange).range
        XCTAssertEqual(preview, try XCTUnwrap(config.stats(of: .spore, specialization: .bogHeart)).range)
        XCTAssertGreaterThan(preview, before, "das Moorherz reicht weiter")

        controller.upgrade()
        stepAndRefresh()
        let tower = try XCTUnwrap(model.state.towers.last)
        XCTAssertEqual(tower.level, 3)
        XCTAssertEqual(tower.specialization, .bogHeart)
        XCTAssertEqual(model.state.gold, gold - cost)
        XCTAssertNil(controller.upgradeCost(for: tower), "Stufe 3 ist die letzte")
        XCTAssertNil(controller.specialization(for: tower))
    }

    func testMissionsBeforeTheSwampOfferNoSpecialization() throws {
        let other = BattleController(model: BattleModel(config: try BalanceConfig.bundledMission(named: "mission-04"),
                                                        seed: 1, autoplay: false), interactive: true)
        let tower = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1, level: 2)
        XCTAssertNil(other.specialization(for: tower))
        XCTAssertNil(other.upgradeCost(for: tower))
    }

    /// P3-2: Die Ruinen bieten den anderen Weg je Turm an.
    func testRuinsOfferTheOtherSpecialization() throws {
        let ruins = BattleController(model: BattleModel(config: try BalanceConfig.bundledMission(named: "mission-05b"),
                                                        seed: 1, autoplay: false), interactive: true)
        let expected: [(TowerKind, Specialization)] = [(.watch, .falconHold), (.lightning, .sparkColumn), (.spore, .rot)]
        for (kind, specialization) in expected {
            let tower = Tower(id: 1, kind: kind, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1, level: 2)
            XCTAssertEqual(ruins.specialization(for: tower), specialization, "\(kind)")
            XCTAssertEqual(ruins.upgradeCost(for: tower), ruins.model.sim.config.specializations?[specialization]?.cost)
        }
    }

    func testBadgeAndNameShowLevelThree() {
        XCTAssertEqual(BattleTexts.levelTag(2), "II")
        XCTAssertEqual(BattleTexts.levelTag(3), "III")
        XCTAssertEqual(BattleTexts.name(.watch, level: 3), "\(BattleTexts.name(.watch)) III")
        for specialization in Specialization.allCases {
            XCTAssertFalse(BattleTexts.name(specialization).isEmpty)
            XCTAssertFalse(BattleTexts.effect(specialization).isEmpty)
        }
        XCTAssertEqual(Set(Specialization.allCases.map(BattleTexts.name)).count, Specialization.allCases.count,
                       "jede Spezialisierung hat ihren eigenen Namen")
        let node = TowerNode(tower: Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1), field: 40)
        node.showLevel(3, field: 40)
        let badge = node.childNode(withName: "level.badge")
        XCTAssertEqual((badge?.children.first as? SKLabelNode)?.text, "III")
    }
}
