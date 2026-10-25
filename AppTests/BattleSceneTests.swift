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
}
