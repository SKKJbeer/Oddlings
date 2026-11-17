import OddlingsCore
import XCTest
@testable import Oddlings

/// Darstellungstest (testing-strategy.md): Die Szene hat für jeden Turm und
/// jeden Gegner genau eine Node, über eine ganze Mission hinweg.
@MainActor
final class BattleSceneTests: XCTestCase {
    func testNodeCountFollowsStateOverWholeMission() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        let scene = BattleScene(model: model)
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        var frames = 0, maxEnemies = 0
        while !model.state.isOver && frames < 100_000 {
            scene.frame(after: frameTime)
            XCTAssertEqual(scene.enemyNodes.count, model.state.enemies.count, "Bild \(frames)")
            XCTAssertEqual(scene.towerNodes.count, model.state.towers.count, "Bild \(frames)")
            maxEnemies = max(maxEnemies, model.state.enemies.count)
            frames += 1
        }
        XCTAssertEqual(model.state.outcome, .won)
        XCTAssertGreaterThan(maxEnemies, 5)
    }

    func testRestartClearsEverything() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        let scene = BattleScene(model: model)
        for _ in 0..<1_500 { scene.frame(after: 1 / Double(config.simulation.ticksPerSecond)) }
        XCTAssertFalse(scene.towerNodes.isEmpty)
        scene.restart()
        XCTAssertTrue(scene.towerNodes.isEmpty)
        XCTAssertTrue(scene.enemyNodes.isEmpty)
        XCTAssertEqual(model.state, model.sim.newGame(seed: 1))
    }

    /// 2× heißt doppelt so viele feste Schritte, nicht größere (Architekturregel 5).
    func testDoubleSpeedTakesTwiceTheSteps() throws {
        let config = try BalanceConfig.missionOne()
        var ticks: [Int] = []
        for speed in [1, 2] {
            let model = BattleModel(config: config, seed: 1, autoplay: false)
            model.speed = speed
            for _ in 0..<10 { _ = model.advance(by: 0.05) }
            ticks.append(model.state.tick)
        }
        let perHalfSecond = config.simulation.ticksPerSecond / 2
        XCTAssertTrue((perHalfSecond - 1...perHalfSecond).contains(ticks[0]), "\(ticks)")
        XCTAssertTrue((2 * perHalfSecond - 1...2 * perHalfSecond).contains(ticks[1]), "\(ticks)")
    }

    /// Bollwerk (R-4): Die Mauer erscheint mit dem Ereignis und geht mit ihm.
    func testWallStandsWhileTheBarrierDoes() throws {
        let races = try RaceTable.bundled()
        let config = try BalanceConfig.missionOne().applying(try XCTUnwrap(races[.dwarves]))
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        controller.toggleAim()
        controller.cast(at: model.sim.map.path.position(at: model.sim.map.path.length / 3))
        scene.frame(after: frameTime)
        XCTAssertNotNil(model.state.ability.barrier)
        XCTAssertNotNil(scene.childNode(withName: "//\(BattleScene.wallName)"), "Mauer steht")
        while model.state.ability.barrier != nil && !model.state.isOver { scene.frame(after: frameTime) }
        XCTAssertNil(scene.childNode(withName: "//\(BattleScene.wallName)"), "Mauer ist gefallen")
    }

    /// Mondmal (R-4): Markierte Gegner tragen das Zeichen, solange es gilt.
    func testMarkedEnemyShowsTheMoon() throws {
        let enemy = Enemy(id: 1, kind: .raider, hp: 10, maxHP: 10, distance: 0)
        let node = EnemyNode(enemy: enemy, field: 40)
        node.show(enemy)
        XCTAssertFalse(node.showsMoonMark)
        var marked = enemy
        marked.vulnerable = VulnerableEffect(factor: 2, untilTick: 10)
        node.show(marked)
        XCTAssertTrue(node.showsMoonMark)
    }

    /// P2-10: Nur gepanzerte Gegner tragen das Schild, und zwar von Anfang an.
    func testOnlyArmoredEnemiesWearTheShield() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-04")
        let brute = EnemyNode(enemy: Enemy(id: 1, kind: .brute, hp: 10, maxHP: 10, distance: 1), field: 40,
                              armored: (config.enemies[.brute]?.armor ?? 0) > 0)
        let raider = EnemyNode(enemy: Enemy(id: 2, kind: .raider, hp: 10, maxHP: 10, distance: 2), field: 40,
                               armored: (config.enemies[.raider]?.armor ?? 0) > 0)
        XCTAssertTrue(brute.isArmored)
        XCTAssertNotNil(brute.childNode(withName: "armor.badge"))
        XCTAssertFalse(raider.isArmored)
        XCTAssertNil(raider.childNode(withName: "armor.badge"))
    }

    // MARK: Bauen (A-2)

    private func interactiveScene() throws -> (BattleScene, BattleController, BattleModel) {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        scene.size = CGSize(width: 852, height: 393)
        scene.frame(after: 0)
        return (scene, controller, model)
    }

    /// Vorschau vor dem Kauf (P1, D-155): erstes Tippen auf den Turm zeigt ihn
    /// blass an seinem Platz, Abbrechen nimmt ihn weg, Bauen ersetzt ihn.
    func testPreviewShowsTowerBeforeBuying() throws {
        let (scene, controller, model) = try interactiveScene()
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        scene.frame(after: 0)
        XCTAssertNil(scene.previewNode, "nur die Zelle gewählt, noch kein Turm")
        controller.choose(.watch)
        scene.frame(after: 0)
        let ghost = try XCTUnwrap(scene.previewNode)
        XCTAssertEqual(ghost.alpha, BattleStyle.previewAlpha, accuracy: 0.001)
        XCTAssertNotNil(scene.coverageNode, "der Weg im Kreis leuchtet")

        controller.tap(nil)
        scene.frame(after: 0)
        XCTAssertNil(scene.previewNode, "Abbrechen nimmt die Vorschau weg")
        XCTAssertNil(scene.coverageNode)

        controller.tap(cell)
        controller.choose(.watch)
        controller.choose(.watch)
        scene.frame(after: 1 / Double(model.sim.config.simulation.ticksPerSecond))
        XCTAssertEqual(model.state.towers.count, 1)
        XCTAssertNil(scene.previewNode, "nach dem Bau steht der echte Turm")
    }

    /// Vor einer Spezialisierung zeigt die Vorschau das Bild der neuen Gestalt
    /// (A-2 mit A-5), nicht noch einmal Stufe 2.
    func testPreviewShowsSpecializationPicture() throws {
        var config = try BalanceConfig.bundledMission(named: "mission-05a")
        config.mission.startGold = 1_000
        config.mission.firstWaveDelay = 600
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        scene.size = CGSize(width: 852, height: 393)
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        model.enqueue(.build(.watch, cell))
        scene.frame(after: 1 / Double(model.sim.config.simulation.ticksPerSecond))
        let tower = try XCTUnwrap(model.state.towers.first)
        model.enqueue(.upgrade(towerID: tower.id))
        scene.frame(after: 1 / Double(model.sim.config.simulation.ticksPerSecond))
        XCTAssertEqual(model.state.towers.first?.level, 2)

        controller.tap(cell)
        let special = try XCTUnwrap(controller.armedSpecialization ?? {
            controller.upgrade()
            return controller.armedSpecialization
        }())
        scene.frame(after: 0)
        XCTAssertNotNil(scene.previewNode)
        XCTAssertEqual(scene.previewPicture, BattleSprites.towerName(.watch, level: 3, specialization: special))
    }

    /// Bauplätze nur um den Finger (P2, D-157): nah voll, weit weg unsichtbar.
    func testBuildZonesFadeAwayFromTheFinger() throws {
        let (scene, controller, model) = try interactiveScene()
        let cells = model.sim.map.buildableCells
        let focus = try XCTUnwrap(cells.first)
        let far = try XCTUnwrap(cells.max { $0.center.distance(to: focus.center) < $1.center.distance(to: focus.center) })
        XCTAssertEqual(try XCTUnwrap(scene.zoneAlpha(at: far)), CGFloat(BattleStyle.buildZoneIdleAlpha), accuracy: 0.001,
                       "vor der ersten Welle gedämpft überall")
        controller.tap(focus)
        scene.frame(after: 0)
        XCTAssertEqual(try XCTUnwrap(scene.zoneAlpha(at: focus)), 1, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(scene.zoneAlpha(at: far)), 0, accuracy: 0.001)
    }
}
