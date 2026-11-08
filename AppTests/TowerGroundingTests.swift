import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Türme in der Welt (D-120, D-121): Licht des Ortes, Schatten, Fundament, und
/// Bauplätze nur beim Bauen.
@MainActor
final class TowerGroundingTests: XCTestCase {
    private let watch = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1)

    func testLightTableSkipsBrokenEntries() {
        let data = Data("""
        {"_zweck": "x", "mission-01": [255, 128, 0], "mission-02": [1, 2], "mission-03": [300, 0, 0], "other": [1, 2, 3]}
        """.utf8)
        let table = BattlefieldLight.parse(data)
        XCTAssertEqual(Array(table.keys), ["mission-01"])
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        table["mission-01"]?.getRed(&r, green: &g, blue: &b, alpha: &a)
        XCTAssertEqual(r, 1, accuracy: 0.001)
        XCTAssertEqual(g, 128 / 255, accuracy: 0.001)
        XCTAssertEqual(b, 0, accuracy: 0.001)
    }

    /// Jede Mission der Kampagne hat ihr Licht und ihr Fundament im Bündel.
    func testEveryCampaignMissionHasLightAndFooting() throws {
        for id in ["mission-01", "mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b",
                   "mission-06a", "mission-06b", "mission-07"] {
            XCTAssertNotNil(BattlefieldLight.color(missionID: id), id)
            XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.footingName(missionID: id)), id)
        }
    }

    func testTowerIsLitLikeItsBattlefield() throws {
        let light = SKColor(red: 0.8, green: 0.85, blue: 0.9, alpha: 1)
        let node = TowerNode(tower: watch, field: 40, light: light)
        let sprite = node.art.children.compactMap { $0 as? SKSpriteNode }.first
        XCTAssertEqual(sprite?.colorBlendFactor, 1)
        // SpriteKit hält die Farbe in einem eigenen Farbraum; gleich aussehende
        // Farben sind dann nicht mehr `==`, also Kanal für Kanal vergleichen.
        assertSameColor(try XCTUnwrap(sprite).color, light)

        let plain = TowerNode(tower: watch, field: 40)
        XCTAssertEqual(plain.art.children.compactMap { $0 as? SKSpriteNode }.first?.colorBlendFactor, 0)
    }

    func testTowerStandsOnFootingWithShadow() throws {
        let node = TowerNode(tower: watch, field: 40, footing: BattleSprites.footingName(missionID: "mission-01"))
        let shadow = try XCTUnwrap(node.shadow)
        XCTAssertEqual(shadow.name, "tower_watch_shadow")
        XCTAssertEqual(shadow.size.width, BattleStyle.towerShadowSide * 40, accuracy: 0.01)
        XCTAssertEqual(node.footing?.name, "footing_mission01")
        // Fundament unter dem Schatten, beides nicht am Turm selbst: Sonst fiele
        // der Schatten über den Nachbarturm.
        XCTAssertLessThan(try XCTUnwrap(node.footing).zPosition, shadow.zPosition)
        XCTAssertNil(node.shade.parent)
        XCTAssertFalse(node.children.contains(node.shade))
    }

    /// Fundament und Schatten erscheinen mit dem Bau, nicht vorher.
    func testShadeFollowsTheBuildDrop() {
        let node = TowerNode(tower: watch, field: 40, footing: "footing_mission01")
        node.lift.alpha = 0.25
        node.idle(time: 0, still: true)
        XCTAssertEqual(node.shade.alpha, 0.25, accuracy: 0.001)
    }

    /// Beim Verkauf gehen Fundament und Schatten mit dem Turm, ausgeblendet.
    func testSellTakesTheShadeAlong() throws {
        let scene = BattleScene(model: BattleModel(config: try BalanceConfig.missionOne(), seed: 1, autoplay: false))
        let node = TowerNode(tower: watch, field: scene.layout.field, footing: "footing_mission01")
        let layer = SKNode()
        layer.addChild(node.shade)
        scene.effectLayer.addChild(node)
        scene.fx.sell(node, refund: 1)
        scene.fx.advance(by: FxStyle.sellLife / 2)
        XCTAssertLessThan(node.shade.alpha, 0.9)
        XCTAssertNotNil(node.shade.parent)
        scene.fx.advance(by: FxStyle.sellLife)
        XCTAssertNil(node.shade.parent)
    }

    func testUpgradeSwapsTheShadow() throws {
        let node = TowerNode(tower: watch, field: 40)
        node.showLevel(2, field: 40)
        let expected = try XCTUnwrap(BattleSprites.texture(named: "tower_watch_2_shadow"))
        XCTAssertEqual(node.shadow?.texture?.size(), expected.size())
        XCTAssertEqual(BattleSprites.shadowName(.watch, level: 2), "tower_watch_2_shadow")
        // Stufe 3 hat kein eigenes Bild: Schatten der Stufe 2, auch wenn der Turm so geladen wird.
        XCTAssertEqual(BattleSprites.shadowNameAvailable(.watch, level: 3), "tower_watch_2_shadow")
        var resumed = watch
        resumed.level = 3
        XCTAssertEqual(TowerNode(tower: resumed, field: 40).shadow?.name, "tower_watch_2_shadow")
    }

    func testSceneTintsAndShadesBuiltTowers() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        let scene = BattleScene(model: model)
        for _ in 0..<1_500 { scene.frame(after: 1 / Double(config.simulation.ticksPerSecond)) }
        let node = try XCTUnwrap(scene.towerNodes.values.first)
        XCTAssertNotNil(node.shade.parent, "Schattenebene")
        XCTAssertEqual(node.shade.position, node.position)
        XCTAssertEqual(node.footing?.name, "footing_mission01")
        XCTAssertEqual(node.light, BattlefieldLight.color(missionID: "mission-01"))
        scene.restart()
        XCTAssertNil(node.shade.parent)
    }

    /// D-121: Vor der ersten Welle und mit gewählter leerer Zelle sind Bauplätze
    /// zu sehen, sonst nicht.
    func testBuildZonesOnlyWhileBuilding() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        let step = 1 / Double(config.simulation.ticksPerSecond)
        scene.frame(after: step)
        XCTAssertTrue(scene.zonesShown, "vor der ersten Welle")

        controller.callNextWave()
        for _ in 0..<5 { scene.frame(after: step) }
        XCTAssertEqual(controller.wave, 1)
        XCTAssertFalse(scene.zonesShown, "Welle läuft, nichts gewählt")

        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        scene.frame(after: step)
        XCTAssertTrue(scene.zonesShown, "leere Zelle gewählt")

        controller.tap(cell)
        scene.frame(after: step)
        XCTAssertFalse(scene.zonesShown, "Auswahl geschlossen")
    }

    func testSpectatorNeverSeesBuildZones() throws {
        let model = BattleModel(config: try BalanceConfig.missionOne(), seed: 1, autoplay: false)
        let scene = BattleScene(model: model)
        scene.controller = BattleController(model: model, interactive: false)
        scene.frame(after: 0.03)
        XCTAssertFalse(scene.zonesShown)
    }

    private func assertSameColor(_ a: SKColor, _ b: SKColor, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(channels(a), channels(b), file: file, line: line)
    }

    /// Kanäle auf drei Stellen gerundet, damit Farbraum-Rauschen nicht zählt.
    private func channels(_ color: SKColor) -> [Int] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(color.getRed(&r, green: &g, blue: &b, alpha: &a))
        return [r, g, b, a].map { Int(($0 * 1000).rounded()) }
    }
}
