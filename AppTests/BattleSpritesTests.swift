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
        // Jede Gegnerart hat ihr eigenes Bild; seit FX 03 auch der Moorkönig.
        for kind in EnemyKind.allCases {
            XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.enemyName(kind)), "\(kind)")
        }
        XCTAssertNotNil(BattleSprites.fortress(field: field))
    }

    /// Stufe 2 hat für jeden Kampfturm ein eigenes Bild (P2-6), Stufe 1 den Grundnamen.
    func testEveryCombatTowerHasALevelTwoPicture() {
        for kind in TowerKind.combat {
            XCTAssertEqual(BattleSprites.towerName(kind, level: 1), BattleSprites.towerName(kind))
            XCTAssertEqual(BattleSprites.towerName(kind, level: 2), "tower_\(kind.rawValue)_2")
            XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.towerName(kind, level: 2)), "\(kind)")
        }
    }

    /// A-5 (G7): Jede Spezialisierung hat eine eigene Gestalt im Katalog, mit
    /// Schatten, und die sechs Bilder sind verschieden. Sonst fiele der Turm still
    /// auf das Bild der Stufe 2 zurück, und die Wahl wäre auf dem Feld unsichtbar.
    func testEverySpecializationHasItsOwnPictureAndShadow() throws {
        var pictures: [Data] = []
        for specialization in Specialization.allCases {
            let kind = specialization.tower
            let name = BattleSprites.towerName(kind, level: 3, specialization: specialization)
            XCTAssertTrue(name.hasPrefix("tower_\(kind.rawValue)_"), name)
            XCTAssertNotNil(BattleSprites.texture(named: name), name)
            XCTAssertNotNil(BattleSprites.texture(named: name + "_shadow"), name)
            XCTAssertEqual(BattleSprites.towerNameAvailable(kind, level: 3, specialization: specialization), name)
            pictures.append(try XCTUnwrap(UIImage(named: name)?.pngData(), name))
        }
        XCTAssertEqual(Set(pictures).count, Specialization.allCases.count, "sechs verschiedene Bilder")
    }

    /// Fehlt ein Bild, steht die nächstgröbere Gestalt da, nie ein Loch.
    func testMissingPictureFallsBackToTheLevelBelow() {
        XCTAssertEqual(BattleSprites.towerNames(.watch, level: 3, specialization: .volley),
                       ["tower_watch_volley", "tower_watch_3", "tower_watch_2", "tower_watch"])
        XCTAssertEqual(BattleSprites.towerNameAvailable(.watch, level: 3), "tower_watch_2")
        XCTAssertEqual(BattleSprites.towerNameAvailable(.bank, level: 1), "tower_bank")
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
        // iPhone 16 Pro Max und SE quer, iPad Pro 13" und mini quer. Seit D-180 bekommt
        // die Szene den ganzen Bildschirm; die Größen ohne Kopfleiste (60 pt weniger)
        // gibt es nicht mehr. Der Rand oben gehört dem Überstand, nicht dem Raster.
        // Im Probelauf vom 26.10.2026 blieben ohne Überstand links und rechts je 1,3 Zellen leer.
        for size in [CGSize(width: 956, height: 440), CGSize(width: 667, height: 375),
                     CGSize(width: 1376, height: 1032), CGSize(width: 1133, height: 744)] {
            let layout = BoardLayout.battle(size: size, map: map)
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
    /// Gemessen am Bild selbst, nicht an seinem Rahmen: Seit Grafik 11 hat die
    /// Torburg einen durchsichtigen Rand (Rahmen 4 Zellen, Bau etwa 2,4), und ihr
    /// Rahmen reicht über die letzte Spalte, das Bild nicht.
    func testFortressCoversNoBuildCell() throws {
        let config = try BalanceConfig.missionOne()
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
        let fortress = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.fortressName)") as? SKSpriteNode)
        let picture = try OpaqueProbe(fortress)
        for cell in scene.model.sim.map.buildableCells {
            XCTAssertFalse(picture.isOpaque(atScene: scene.layout.scenePoint(cell.center), in: scene), "\(cell)")
        }
    }

    /// Prüft am Probenbild, ob die Prüfung überhaupt Deckung sieht: Der Fuß der
    /// Torburg ist deckend, die Rahmenecke nicht. Sonst bliebe der Test oben
    /// grün, auch wenn er nichts misst.
    func testOpaqueProbeSeesTheFortress() throws {
        let config = try BalanceConfig.missionOne()
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
        let fortress = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.fortressName)") as? SKSpriteNode)
        let parent = try XCTUnwrap(fortress.parent)
        let picture = try OpaqueProbe(fortress)
        XCTAssertTrue(picture.isOpaque(atScene: scene.convert(fortress.position, from: parent), in: scene))
        let corner = CGPoint(x: fortress.frame.minX + 1, y: fortress.frame.maxY - 1)
        XCTAssertFalse(picture.isOpaque(atScene: scene.convert(corner, from: parent), in: scene))
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

    /// Grafik 06 und 07: Jede Mission mit Missionsdatei findet ihren eigenen gemalten
    /// Boden; fehlt einer, zeichnete die Szene still die Ersatzlinie. Die
    /// Festung verdeckt auch dort keine Bauzelle.
    func testEveryBundledMissionHasItsPaintedGround() throws {
        for file in ["mvp-mission-01", "mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b", "mission-06a", "mission-06b", "mission-07"] {
            let config = try BalanceConfig.bundledMission(named: file)
            let name = BattleSprites.groundName(missionID: config.mission.id)
            XCTAssertNotNil(BattleSprites.texture(named: name), name)
            let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: false))
            XCTAssertNotNil(scene.childNode(withName: "//\(name)"), name)
            let fortress = try XCTUnwrap(scene.childNode(withName: "//\(BattleSprites.fortressName)") as? SKSpriteNode)
            let picture = try OpaqueProbe(fortress)
            for cell in scene.model.sim.map.buildableCells {
                XCTAssertFalse(picture.isOpaque(atScene: scene.layout.scenePoint(cell.center), in: scene), "\(file) \(cell)")
            }
        }
    }

    /// FX 02/03, A-3: alle vier Gegner haben ihre Bildfolgen,
    /// gleich groß wie ihr Standbild; die anderen Gegner bleiben beim Standbild.
    /// Seit 0.42.0 auch die Moorhexe, seit 0.43.0 Pilzbalg und Sporling.
    func testAnimatedEnemiesHaveFramesOthersKeepTheirPicture() throws {
        let counts: [EnemyKind: [EnemyMotion: Int]] = [
            .raider: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
            .runner: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
            .brute: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
            .moorKing: [.walk: 8, .hit: 3, .die: 8, .shield: 4, .summon: 5, .walkFront: 8, .walkBack: 8],
            .witch: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
            .puffball: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
            .sporeling: [.walk: 8, .hit: 3, .die: 6, .shield: 0, .summon: 0, .walkFront: 8, .walkBack: 8],
        ]
        for (kind, expected) in counts.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let still = try XCTUnwrap(BattleSprites.texture(named: BattleSprites.enemyName(kind)))
            for motion in EnemyMotion.allCases {
                let frames = BattleSprites.frames(kind, motion)
                XCTAssertEqual(frames.count, expected[motion], "\(kind) \(motion)")
                for texture in frames {
                    XCTAssertEqual(texture.size(), still.size(), "\(kind) \(motion)")
                }
            }
        }
        for kind in EnemyKind.allCases where counts[kind] == nil {
            XCTAssertTrue(BattleSprites.frames(kind, .walk).isEmpty, "\(kind)")
        }
    }

    /// Verlangsamt zeigt sich am Boden, nicht nur im Farbton (P2-8); Funke und
    /// Ton lesen es dort.
    func testSlowAuraFollowsTheSlow() {
        var enemy = Enemy(id: 1, kind: .raider, hp: 10, maxHP: 10, distance: 2)
        let node = EnemyNode(enemy: enemy, field: field)
        node.show(enemy, dt: 0.1)
        XCTAssertFalse(node.isSlowed)
        enemy.slow = SlowEffect(factor: 0.5, untilTick: 99)
        node.show(enemy, dt: 0.1)
        XCTAssertTrue(node.isSlowed)
        enemy.slow = nil
        node.show(enemy, dt: 0.1)
        XCTAssertFalse(node.isSlowed)
    }
}

/// Liest die Deckung eines Bildes an einem Punkt der Szene, über seinen Rahmen
/// (ohne Drehung) auf das Pixel der Textur abgebildet.
@MainActor
private struct OpaqueProbe {
    let node: SKSpriteNode
    let image: CGImage

    init(_ node: SKSpriteNode) throws {
        self.node = node
        image = try XCTUnwrap(node.texture?.cgImage())
    }

    func isOpaque(atScene point: CGPoint, in scene: SKScene) -> Bool {
        guard let parent = node.parent else { return false }
        let local = scene.convert(point, to: parent)
        let frame = node.frame
        guard frame.contains(local) else { return false }
        let u = (local.x - frame.minX) / frame.width
        let v = (frame.maxY - local.y) / frame.height
        let x = min(image.width - 1, Int(u * CGFloat(image.width)))
        let y = min(image.height - 1, Int(v * CGFloat(image.height)))
        var pixel = [UInt8](repeating: 0, count: 4)
        let drawn = pixel.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            // Bildzeile y von oben liegt im Kontext (Ursprung unten) bei height - 1 - y.
            context.draw(image, in: CGRect(x: -x, y: -(image.height - 1 - y), width: image.width, height: image.height))
            return true
        }
        return drawn && pixel[3] > 128
    }
}
