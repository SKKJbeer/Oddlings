import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Kampfplatz in der Welt (Grafik 11, D-191, D-196): Torburg am Wegende mit dem
/// Tor zum Weg, Türme ohne Sockel auf dem Boden.
@MainActor
final class WorldGroundingTests: XCTestCase {
    /// D-191: Das Tor liegt auf dem Weg hinter dem Kartenrand, der Fuß dahinter,
    /// gegen die Blickrichtung des Tores.
    func testFortressPlacementFollowsThePath() {
        let end = Point(x: 15.5, y: 4.5)
        let gate = FortressPlacement.gate(pathEnd: end, mapWidth: 14)
        XCTAssertEqual(gate.x, 14 + FortressPlacement.gateInset, accuracy: 1e-9)
        XCTAssertEqual(gate.y, 4.5, accuracy: 1e-9)
        let foot = FortressPlacement.foot(pathEnd: end, mapWidth: 14)
        let facing = FortressPlacement.facing
        XCTAssertEqual(hypot(foot.x - gate.x, foot.y - gate.y), FortressPlacement.gateDistance, accuracy: 1e-9)
        // Gier −45°: Tor nach links unten, also Fuß rechts oben vom Tor.
        XCTAssertLessThan(facing.x, 0)
        XCTAssertGreaterThan(facing.y, 0)
        XCTAssertGreaterThan(foot.x, gate.x)
        XCTAssertLessThan(foot.y, gate.y)
    }

    /// Die Szene stellt den Festungsknoten ins Tor; Durchbrüche laufen dorthin.
    func testSceneFortressStandsInTheGate() throws {
        let model = BattleModel(config: try BalanceConfig.missionOne(), seed: 1, autoplay: false)
        let scene = BattleScene(model: model)
        let map = model.sim.map
        let gate = FortressPlacement.gate(pathEnd: map.path.points[map.path.points.count - 1], mapWidth: map.width)
        let expected = scene.layout.scenePoint(gate)
        XCTAssertEqual(scene.fortress.position.x, expected.x, accuracy: 0.01)
        XCTAssertEqual(scene.fortress.position.y, expected.y, accuracy: 0.01)
        // Bild und Schatten stehen auf demselben Fuß, der Schatten darunter.
        let picture = try XCTUnwrap(scene.fortress.childNode(withName: BattleSprites.fortressName))
        let shadow = try XCTUnwrap(scene.fortress.childNode(withName: BattleSprites.fortressShadowName))
        XCTAssertEqual(shadow.position, picture.position)
        XCTAssertLessThan(shadow.zPosition, picture.zPosition)
        // Der Fuß liegt hinter dem Tor, gegen dessen Blickrichtung (rechts oben im Bild).
        XCTAssertGreaterThan(picture.position.x, 0)
        XCTAssertGreaterThan(picture.position.y, 0)
    }

    /// D-196: Die Vorschau steht wie der echte Turm auf dem Boden, ohne Sockel;
    /// sonst sprünge der Turm beim Bezahlen.
    func testPreviewStandsOnTheGround() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        scene.frame(after: 0)
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        controller.choose(.watch)
        scene.frame(after: 0)
        let ghost = try XCTUnwrap(scene.previewNode)
        let sprites = ghost.children.compactMap { $0 as? SKSpriteNode }
        XCTAssertEqual(sprites.count, 1)
        XCTAssertEqual(try XCTUnwrap(sprites.first).position.y, 0, accuracy: 0.01)
    }
}
