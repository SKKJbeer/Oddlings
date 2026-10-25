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

    func testPaintedGroundCoversTheWholeBoard() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let layout = BoardLayout(size: CGSize(width: 844, height: 390), map: model.sim.map)
        let ground = try XCTUnwrap(BattleSprites.ground(missionID: config.mission.id, layout: layout))
        let topLeft = layout.scenePoint(Point(x: 0, y: 0))
        let bottomRight = layout.scenePoint(Point(x: Double(layout.columns), y: Double(layout.rows)))
        XCTAssertEqual(ground.frame.minX, topLeft.x, accuracy: 0.5)
        XCTAssertEqual(ground.frame.maxY, topLeft.y, accuracy: 0.5)
        XCTAssertEqual(ground.frame.maxX, bottomRight.x, accuracy: 0.5)
        XCTAssertEqual(ground.frame.minY, bottomRight.y, accuracy: 0.5)
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
