import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Kampfplatz in der Welt (Grafik 11, D-190 bis D-195): Turm auf dem Sockel,
/// Kontaktdunkel unter dem Fuß, Torburg am Wegende mit dem Tor zum Weg.
@MainActor
final class WorldGroundingTests: XCTestCase {
    private let watch = Tower(id: 1, kind: .watch, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1)

    /// Die Bilder liegen im Bündel; ohne sie fiele jeder Turm still aufs alte
    /// Fundament zurück, und niemand sähe es.
    func testPlinthAndContactAreInTheCatalog() {
        XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.plinthName))
        XCTAssertNotNil(BattleSprites.texture(named: BattleSprites.contactName))
    }

    /// D-190: Mit Sockel steht der Turm auf der Platte, das Fundament entfällt.
    func testTowerStandsOnThePlinth() throws {
        let field: CGFloat = 40
        let node = TowerNode(tower: watch, field: field, footing: "footing_mission01", plinth: BattleSprites.plinthName)
        let plinth = try XCTUnwrap(node.plinth)
        XCTAssertNil(node.footing, "der Sockel ersetzt das Fundament")
        XCTAssertEqual(plinth.size.width, BattleStyle.plinthSide * field, accuracy: 0.01)
        XCTAssertEqual(node.raise, BattleStyle.plinthLift * field, accuracy: 0.001)
        XCTAssertEqual(node.stand.position.y, node.raise, accuracy: 0.001)
        XCTAssertTrue(node.lift.parent === node.stand, "Auftritte bleiben unter dem Sockel frei")
        // Sockel und Schatten liegen in der Schattenebene, nicht am Turm: sonst
        // deckte ein Sockel den Turm der Reihe dahinter.
        XCTAssertTrue(plinth.parent === node.shade)
        XCTAssertLessThan(plinth.zPosition, try XCTUnwrap(node.shadow).zPosition)
    }

    /// D-193: Das Kontaktdunkel sitzt genau unter dem Fuß, über dem Schatten.
    func testContactSitsUnderTheFoot() throws {
        let node = TowerNode(tower: watch, field: 40, plinth: BattleSprites.plinthName)
        let contact = try XCTUnwrap(node.contact)
        XCTAssertTrue(contact.parent === node.shade)
        XCTAssertEqual(contact.position.y, node.raise, accuracy: 0.001)
        XCTAssertEqual(contact.position.x, 0)
        XCTAssertGreaterThan(contact.zPosition, try XCTUnwrap(node.shadow).zPosition)
        XCTAssertGreaterThan(contact.zPosition, try XCTUnwrap(node.plinth).zPosition)
    }

    /// Ohne Sockel bleibt alles wie bisher: Fundament, Turm auf dem Boden.
    func testWithoutPlinthTheFootingStays() {
        let node = TowerNode(tower: watch, field: 40, footing: "footing_mission01")
        XCTAssertNil(node.plinth)
        XCTAssertEqual(node.footing?.name, "footing_mission01")
        XCTAssertEqual(node.raise, 0)
        XCTAssertNotNil(node.contact, "auch auf dem Boden braucht der Fuß Kontakt")
    }

    /// Der Sockel trägt das Licht des Ortes wie der Turm (D-120).
    func testPlinthIsLit() throws {
        let light = SKColor(red: 0.8, green: 0.85, blue: 0.9, alpha: 1)
        let node = TowerNode(tower: watch, field: 40, light: light, plinth: BattleSprites.plinthName)
        XCTAssertEqual(try XCTUnwrap(node.plinth).colorBlendFactor, 1)
    }

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

    /// Die Vorschau steht auf dem Sockel wie der echte Turm, sonst sprünge der
    /// Turm beim Bezahlen um die Sockelhöhe.
    func testPreviewStandsOnThePlinth() throws {
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
        let tower = try XCTUnwrap(sprites.first { $0.zPosition >= 0 })
        XCTAssertEqual(tower.position.y, BattleStyle.plinthLift * scene.layout.field, accuracy: 0.01)
        XCTAssertTrue(sprites.contains { $0.zPosition < 0 }, "beim Neubau liegt der Sockel blass mit")
    }

    /// Der gebaute Turm in der Szene steht auf dem Sockel, mit Kontakt.
    func testBuiltTowerInSceneHasPlinthAndContact() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        let scene = BattleScene(model: model)
        for _ in 0..<1_500 { scene.frame(after: 1 / Double(config.simulation.ticksPerSecond)) }
        let node = try XCTUnwrap(scene.towerNodes.values.first)
        XCTAssertNotNil(node.plinth)
        XCTAssertNotNil(node.contact)
        XCTAssertNil(node.footing)
        XCTAssertGreaterThan(node.raise, 0)
    }
}
