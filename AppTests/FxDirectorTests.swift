import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Effekte an Ereignissen (D-050): Jedes Ereignis spielt seinen Effekt,
/// Effekte enden und räumen auf, Pause hält sie an, Neustart räumt ab.
/// Alles ohne Bildschirm, weil der Director auf der eigenen Uhr läuft.
@MainActor
final class FxDirectorTests: XCTestCase {
    private lazy var config: BalanceConfig = try! BalanceConfig.missionOne()
    private let frameTime = 1.0 / 60

    private func scene(autoplay: Bool) -> BattleScene {
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: autoplay))
        // Wie auf dem Gerät mit „Bewegung reduzieren" aus.
        scene.fx.reduceMotion = false
        return scene
    }

    private func run(_ scene: BattleScene, seconds: Double) {
        for _ in 0..<Int(seconds / frameTime) { scene.frame(after: frameTime) }
    }

    private func runMission(_ scene: BattleScene) {
        var frames = 0
        while !scene.model.state.isOver && frames < 200_000 {
            scene.frame(after: frameTime)
            frames += 1
        }
        XCTAssertTrue(scene.model.state.isOver)
    }

    /// Die Zelle, von der ein Wachturm den Weg am besten erreicht.
    private func cellNearPath(_ model: BattleModel) -> Cell {
        let path = model.sim.map.path
        return model.sim.map.buildableCells.min { path.distance(from: $0.center) < path.distance(from: $1.center) }!
    }

    func testWholeMissionPlaysEveryEffect() {
        let scene = scene(autoplay: true)
        runMission(scene)
        // Die Münzen des letzten Treffers kommen erst beim Platzen.
        run(scene, seconds: 1)
        let stats = scene.fx.stats
        XCTAssertEqual(scene.model.state.outcome, .won)
        XCTAssertGreaterThan(stats.arrows, 0, stats.summary)
        XCTAssertGreaterThan(stats.bolts, 0, stats.summary)
        XCTAssertGreaterThan(stats.combos, 0, "Sporenfunke (E2): \(stats.summary)")
        XCTAssertGreaterThan(stats.spores, 0, stats.summary)
        XCTAssertGreaterThan(stats.hits, 0, stats.summary)
        XCTAssertGreaterThan(stats.deaths, 0, stats.summary)
        XCTAssertEqual(stats.coins, stats.deaths * FxStyle.coinsPerKill, "jede Münze kam, keine entfiel: \(stats.summary)")
        XCTAssertEqual(stats.builds, scene.model.state.towers.count, stats.summary)
        XCTAssertGreaterThan(stats.spawns, 0, stats.summary)
    }

    /// Nach dem Ende läuft nichts weiter: kein Tween, kein Sprite außerhalb des
    /// Pools, Effektebene leer, keine sterbenden Gegner mehr.
    func testEffectsEndAndSpritesReturnToPool() {
        let scene = scene(autoplay: true)
        runMission(scene)
        run(scene, seconds: 4)
        XCTAssertEqual(scene.fx.runningTweens, 0)
        XCTAssertEqual(scene.fx.activeSprites, 0)
        XCTAssertGreaterThan(scene.fx.pooledSprites, 0, "Sprites wurden wiederverwendet")
        XCTAssertTrue(scene.effectLayer.children.isEmpty, "\(scene.effectLayer.children)")
        var enemies = 0
        scene.enumerateChildNodes(withName: "//enemy_*") { _, _ in enemies += 1 }
        XCTAssertEqual(enemies, scene.model.state.enemies.count)
    }

    func testLeaksShakeTheFortress() {
        let scene = scene(autoplay: false)
        runMission(scene)
        XCTAssertEqual(scene.model.state.outcome, .lost)
        XCTAssertGreaterThan(scene.fx.stats.leaks, 0)
    }

    func testPauseFreezesEffects() {
        let scene = scene(autoplay: true)
        var frames = 0
        while scene.fx.runningTweens == 0 && frames < 20_000 {
            scene.frame(after: frameTime)
            frames += 1
        }
        XCTAssertGreaterThan(scene.fx.runningTweens, 0)
        scene.model.paused = true
        let time = scene.fx.time, tweens = scene.fx.runningTweens, sprites = scene.fx.activeSprites
        run(scene, seconds: 2)
        XCTAssertEqual(scene.fx.time, time)
        XCTAssertEqual(scene.fx.runningTweens, tweens)
        XCTAssertEqual(scene.fx.activeSprites, sprites)
    }

    func testRestartClearsEffects() {
        let scene = scene(autoplay: true)
        run(scene, seconds: 50)
        XCTAssertGreaterThan(scene.fx.stats.deaths, 0)
        scene.restart()
        XCTAssertEqual(scene.fx.runningTweens, 0)
        XCTAssertEqual(scene.fx.activeSprites, 0)
        XCTAssertTrue(scene.effectLayer.children.isEmpty)
        var enemies = 0
        scene.enumerateChildNodes(withName: "//enemy_*") { _, _ in enemies += 1 }
        XCTAssertEqual(enemies, 0)
    }

    /// Die Simulation trifft sofort, der Pfeil braucht Zeit: Aufblitzen wartet
    /// auf die Ankunft.
    func testArrowDelaysHitFlashUntilArrival() throws {
        let scene = scene(autoplay: false)
        let model = scene.model
        model.enqueue(.build(.watch, cellNearPath(model)))
        model.enqueue(.callNextWave)
        var target: EnemyNode?
        for _ in 0..<20_000 {
            scene.frame(after: frameTime)
            for case .towerFired(_, let targets) in scene.lastEvents { target = targets.first.flatMap { scene.enemyNodes[$0] } }
            if target != nil { break }
        }
        let enemy = try XCTUnwrap(target, "Wachturm hat geschossen")
        let arrival = try XCTUnwrap(scene.fx.arrival(for: enemy.enemyID),
                                    "Pfeil unterwegs: \(scene.fx.stats.summary) Zeit \(scene.fx.time) Ereignisse \(scene.lastEvents)")
        XCTAssertGreaterThan(arrival, scene.fx.time, "Pfeil fliegt noch")
        XCTAssertEqual(enemy.flash?.alpha ?? -1, 0, accuracy: 0.001, "noch kein Aufblitzen")
        var flashed = false
        while scene.fx.time < arrival + 0.1 {
            scene.frame(after: frameTime)
            if (enemy.flash?.alpha ?? 0) > 0.1 { flashed = true }
        }
        XCTAssertTrue(flashed, "blitzt bei Ankunft")
        XCTAssertNil(scene.fx.arrival(for: enemy.enemyID))
    }

    /// Bau fällt von oben und landet genau auf der Zelle; Verkauf versinkt,
    /// danach ist der Turm ganz weg. Die Szene hat dabei immer genau eine
    /// Node je Turm im Zustand.
    func testBuildDropsAndSellSinks() throws {
        let scene = scene(autoplay: false)
        let model = scene.model
        model.enqueue(.build(.watch, cellNearPath(model)))
        scene.frame(after: 1.0 / Double(config.simulation.ticksPerSecond))
        let tower = try XCTUnwrap(scene.towerNodes.values.first)
        XCTAssertGreaterThan(tower.lift.position.y, 0, "startet oben")
        run(scene, seconds: FxStyle.buildLife + 0.1)
        XCTAssertEqual(tower.lift.position.y, 0, accuracy: 0.001)
        XCTAssertEqual(tower.lift.alpha, 1, accuracy: 0.001)
        XCTAssertEqual(tower.lift.yScale, 1, accuracy: 0.01)
        XCTAssertEqual(scene.fx.stats.builds, 1)

        model.enqueue(.sell(towerID: tower.towerID))
        var frames = 0
        while scene.fx.stats.sells == 0 && frames < 100 {
            scene.frame(after: frameTime)
            frames += 1
        }
        XCTAssertTrue(scene.towerNodes.isEmpty)
        XCTAssertNotNil(tower.parent, "versinkt noch")
        run(scene, seconds: FxStyle.sellLife + 0.1)
        XCTAssertNil(tower.parent)
    }

    /// Gegner laufen: Sie heben ab, landen, stauchen und blicken in Laufrichtung.
    func testEnemiesHopAndFaceTheirWay() throws {
        let scene = scene(autoplay: false)
        scene.model.enqueue(.callNextWave)
        var lifts: [CGFloat] = [], scales: [CGFloat] = []
        var enemy: EnemyNode?
        for _ in 0..<3_000 {
            scene.frame(after: frameTime)
            if enemy == nil { enemy = scene.enemyNodes.values.first }
            guard let enemy, enemy.parent != nil else { continue }
            lifts.append(enemy.motion.position.y)
            scales.append(enemy.motion.yScale)
            if lifts.count > 120 { break }
        }
        let node = try XCTUnwrap(enemy)
        XCTAssertGreaterThan(lifts.max() ?? 0, lifts.min() ?? 0, "hüpft")
        XCTAssertLessThan(scales.min() ?? 1, 1, "staucht beim Aufsetzen")
        // Mission 1 beginnt links und läuft nach rechts.
        XCTAssertEqual(node.facing, 1)
        XCTAssertGreaterThan(node.motion.xScale, 0)
    }

    // MARK: Festungsfähigkeit

    /// Szene mit Mitspieler-Steuerung, damit ein Wurf wie auf dem Gerät läuft.
    private func abilityScene(_ race: Race?) throws -> (BattleScene, BattleController) {
        var config = try BalanceConfig.missionOne()
        if let race { config = config.applying(try XCTUnwrap(try RaceTable.bundled()[race])) }
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.fx.reduceMotion = false
        scene.controller = controller
        return (scene, controller)
    }

    /// Wirft auf den vordersten Gegner, sobald einer weit genug gelaufen ist.
    private func castOnFirstEnemy(_ scene: BattleScene, _ controller: BattleController) throws {
        let model = scene.model
        model.enqueue(.callNextWave)
        var frames = 0
        while (model.state.enemies.first?.distance ?? 0) < 3 && frames < 20_000 {
            scene.frame(after: frameTime)
            frames += 1
        }
        let enemy = try XCTUnwrap(model.state.enemies.first, "Gegner läuft")
        controller.toggleAim()
        controller.cast(at: model.sim.map.path.position(at: enemy.distance + 0.8))
    }

    /// Steinregen: erst Warnung mit fallenden Felsen, dann Einschlag mit
    /// Wackeln; Getroffene zeigen Sternchen, solange sie betäubt sind.
    func testStoneRainWarnsStrikesAndStuns() throws {
        let (scene, controller) = try abilityScene(nil)
        XCTAssertEqual(scene.model.sim.config.ability?.kind, .stoneRain)
        try castOnFirstEnemy(scene, controller)
        // Der Wurf geht mit dem nächsten Simulationsschritt raus (30/s).
        for _ in 0..<4 where scene.fx.stats.casts == 0 { scene.frame(after: frameTime) }
        XCTAssertEqual(scene.fx.stats.casts, 1, scene.fx.stats.summary)
        XCTAssertEqual(scene.fx.stats.impacts, 0, "Einschlag erst nach der Warnzeit")
        var shook = false, stunned = false
        for _ in 0..<Int(2 / frameTime) {
            scene.frame(after: frameTime)
            if scene.fx.stats.impacts > 0 && scene.fx.world.position != .zero { shook = true }
            if scene.enemyNodes.values.contains(where: \.showsStun) { stunned = true }
        }
        XCTAssertEqual(scene.fx.stats.impacts, 1, scene.fx.stats.summary)
        XCTAssertTrue(shook, "Einschlag wackelt")
        XCTAssertTrue(stunned, "Getroffene zeigen Sternchen")
        for _ in 0..<Int(2 / frameTime) { scene.frame(after: frameTime) }
        XCTAssertFalse(scene.enemyNodes.values.contains(where: \.showsStun), "Sternchen gehen mit der Betäubung")
    }

    /// Mondmal: Licht statt Felsen, kein Wackeln.
    func testMoonMarkGlowsWithoutShaking() throws {
        let (scene, controller) = try abilityScene(.elves)
        try castOnFirstEnemy(scene, controller)
        var shook = false
        for _ in 0..<Int(1.5 / frameTime) {
            scene.frame(after: frameTime)
            if scene.fx.world.position != .zero { shook = true }
        }
        XCTAssertEqual(scene.fx.stats.casts, 1, scene.fx.stats.summary)
        XCTAssertEqual(scene.fx.stats.impacts, 1, scene.fx.stats.summary)
        XCTAssertFalse(shook)
        XCTAssertTrue(scene.enemyNodes.values.contains(where: \.showsMoonMark), "Mal am Gegner")
    }

    /// Bollwerk: Mauer schießt federnd hoch, steht, versinkt am Ende und ist
    /// danach ganz weg.
    func testBulwarkRisesStandsAndSinks() throws {
        let (scene, controller) = try abilityScene(.dwarves)
        let model = scene.model
        controller.toggleAim()
        controller.cast(at: model.sim.map.path.position(at: model.sim.map.path.length / 3))
        for _ in 0..<4 where scene.fx.stats.walls == 0 { scene.frame(after: frameTime) }
        let wall = try XCTUnwrap(scene.effectLayer.childNode(withName: BattleScene.wallName))
        XCTAssertLessThan(wall.xScale, 0.6, "wächst aus dem Boden")
        XCTAssertEqual(scene.fx.stats.walls, 1)
        var overshoot = false
        for _ in 0..<Int(FxStyle.wallRise / frameTime) + 2 {
            scene.frame(after: frameTime)
            if wall.xScale > 1.01 { overshoot = true }
        }
        XCTAssertTrue(overshoot, "federt nach")
        XCTAssertEqual(wall.xScale, 1, accuracy: 0.001)
        while model.state.ability.barrier != nil && !model.state.isOver { scene.frame(after: frameTime) }
        XCTAssertNotNil(wall.parent, "versinkt noch")
        run(scene, seconds: FxStyle.wallFall + 0.1)
        XCTAssertNil(wall.parent, "danach weg")
    }

}
