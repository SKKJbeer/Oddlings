import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Gemalte Grafik (D-016): Die Bilder im Katalog werden gefunden und nach dem
/// Asset-Vertrag gesetzt. Fehlt eines, fiele die Szene still auf die
/// Platzhalterform zurück, das soll hier rot werden, nicht erst auf dem Gerät.
@MainActor
final class BattleSpritesTests: XCTestCase {
    private let field: CGFloat = 43

    func testGroundNameFollowsMissionID() {
        XCTAssertEqual(BattleSprites.groundName(missionID: "mission-01"), "map_mission01_ground")
    }

    func testEveryTowerAndEnemyHasAPaintedPicture() {
        for kind in TowerKind.allCases {
            XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.towerName(kind)), "\(kind)")
        }
        for kind in EnemyKind.allCases {
            XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.enemyName(kind)), "\(kind)")
        }
        XCTAssertNotNil(BattleSprites.fortress(field: field))
    }

    func testPaintedTowerIsSquareWithFootOnCellCenter() throws {
        for kind in TowerKind.allCases {
            let node = BattleSprites.tower(kind, field: field)
            let sprite = try XCTUnwrap(node.children.first as? SKSpriteNode, "\(kind)")
            let side = BattleStyle.towerSpriteSide * field
            // SpriteKit speichert Größe und Anker als Float, darum mit Toleranz.
            XCTAssertEqual(sprite.size.width, side, accuracy: 0.01, "\(kind)")
            XCTAssertEqual(sprite.size.height, side, accuracy: 0.01, "\(kind)")
            XCTAssertEqual(sprite.anchorPoint.x, 0.5, accuracy: 0.001, "\(kind)")
            XCTAssertEqual(sprite.anchorPoint.y, 0.2, accuracy: 0.001, "\(kind)")
        }
    }

    /// Der gemalte Boden reicht über das Feld hinaus bis an den Bildschirmrand,
    /// auf dem breiten iPhone links und rechts, auf dem iPad oben und unten.
    /// Sonst bleiben Streifen in Hintergrundfarbe neben dem Feld.
    func testPaintedGroundCoversTheWholeScene() throws {
        let config = try BalanceConfig.missionOne()
        let map = BattleModel(config: config, seed: 1, autoplay: false).sim.map
        // iPhone 16 Pro Max und SE quer, iPad Pro 13" und mini quer, je ganz und
        // ohne die Kopfleiste darüber (60 pt): Die Karte bekommt nur, was unter
        // der Leiste bleibt, und wird damit noch breiter als der Bildschirm.
        // Im Probelauf vom 26.10.2026 blieben so links und rechts je 1,3 Zellen leer.
        for size in [CGSize(width: 956, height: 440), CGSize(width: 667, height: 375),
                     CGSize(width: 1376, height: 1032), CGSize(width: 1133, height: 744),
                     CGSize(width: 956, height: 380), CGSize(width: 874, height: 342),
                     CGSize(width: 667, height: 315), CGSize(width: 1376, height: 972)] {
            let layout = BoardLayout(size: size, map: map)
            let ground = try XCTUnwrap(BattleSprites.ground(missionID: config.mission.id, layout: layout))
            XCTAssertLessThanOrEqual(ground.frame.minX, 0.5, "\(size)")
            XCTAssertLessThanOrEqual(ground.frame.minY, 0.5, "\(size)")
            XCTAssertGreaterThanOrEqual(ground.frame.maxX, size.width - 0.5, "\(size)")
            XCTAssertGreaterThanOrEqual(ground.frame.maxY, size.height - 0.5, "\(size)")
            // Das Feld selbst liegt im Bild an der Stelle, die der Rand vorgibt.
            let topLeft = layout.scenePoint(Point(x: 0, y: 0))
            XCTAssertEqual(ground.frame.minX, topLeft.x - BattleStyle.groundMargin.width * layout.field, accuracy: 0.5, "\(size)")
            XCTAssertEqual(ground.frame.maxY, topLeft.y + BattleStyle.groundMargin.height * layout.field, accuracy: 0.5, "\(size)")
        }
    }

    /// `ignoresSiblingOrder` zeichnet Geschwister mit gleicher `zPosition` in
    /// beliebiger Reihenfolge; so lag die Festung bis 0.10.3 unter dem Boden.
    func testFortressIsDrawnAboveGroundAndBuildZones() throws {
        let config = try BalanceConfig.missionOne()
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
        let ground = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.groundName(missionID: config.mission.id))"))
        let fortress = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.fortressName)"))
        let fortressZ = try XCTUnwrap(fortress.parent).zPosition + fortress.zPosition
        let floor = try XCTUnwrap(ground.parent)
        XCTAssertGreaterThan(fortressZ, ground.zPosition)
        for tile in floor.children where tile !== ground && tile !== fortress.parent {
            XCTAssertGreaterThan(fortressZ, tile.zPosition)
        }
    }

    /// Die Festung steht im Rand neben dem Feld und verdeckt keine Bauzelle.
    func testFortressCoversNoBuildCell() throws {
        let config = try BalanceConfig.missionOne()
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
        let fortress = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.fortressName)"))
        let parent = try XCTUnwrap(fortress.parent)
        let frame = CGRect(origin: scene.convert(fortress.frame.origin, from: parent), size: fortress.frame.size)
        let layout = BoardLayout(size: scene.size, map: scene.model.sim.map)
        for cell in scene.model.sim.map.buildableCells {
            XCTAssertFalse(frame.contains(layout.scenePoint(cell.center)), "\(cell)")
        }
    }

    /// Mit gemaltem Boden entfällt die gezeichnete Weglinie, sonst läge sie
    /// über dem gemalten Weg.
    func testSceneUsesPaintedGroundInsteadOfPathLine() throws {
        let config = try BalanceConfig.missionOne()
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
        let name = BattleSprites.groundName(missionID: config.mission.id)
        XCTAssertNotNil(scene.childNode(withName: "//\(name)"))
        var lines = 0
        scene.enumerateChildNodes(withName: "//*") { node, _ in
            if let shape = node as? SKShapeNode, shape.strokeColor == BattleStyle.path { lines += 1 }
        }
        XCTAssertEqual(lines, 0)
    }
}
