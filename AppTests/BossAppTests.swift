import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Darstellung des Moorkönigs (P3-4): Leiste oben statt über dem Kopf, Kuppel
/// während des Schilds, Ruf mit Effekt. Alles aus Zustand und Ereignissen.
@MainActor
final class BossAppTests: XCTestCase {
    private func missionSeven() throws -> BalanceConfig {
        try BalanceConfig.bundledMission(named: "mission-07")
    }

    private func king(hp: Double, shield: Int? = nil) -> Enemy {
        var enemy = Enemy(id: 1, kind: .moorKing, hp: hp, maxHP: 4_000, distance: 5)
        enemy.shieldUntilTick = shield
        return enemy
    }

    func testBossNodeIsBigShowsNoHeadBarAndADomeWhileShielded() {
        let enemy = king(hp: 3_000)
        let node = EnemyNode(enemy: enemy, field: 40, armored: true, boss: true)
        node.show(enemy)
        XCTAssertFalse(node.showsHealth, "Leben steht oben in der Leiste")
        XCTAssertFalse(node.showsShield)
        XCTAssertGreaterThan(node.height, BattleStyle.enemyHeight(.brute) * 40)
        node.show(king(hp: 2_000, shield: 300))
        XCTAssertTrue(node.showsShield)
        node.show(king(hp: 2_000))
        XCTAssertFalse(node.showsShield, "die Kuppel geht mit dem Schild")

        let raider = Enemy(id: 2, kind: .raider, hp: 5, maxHP: 10, distance: 1)
        let other = EnemyNode(enemy: raider, field: 40)
        other.show(raider)
        XCTAssertTrue(other.showsHealth, "andere Gegner behalten die Leiste über dem Kopf")
    }

    func testBossStatusFollowsTheFirstBossOnThePath() throws {
        let config = try missionSeven()
        var state = Simulation(config: config).newGame(seed: 1)
        XCTAssertNil(BossStatus(state: state, config: config), "ohne Boss keine Leiste")
        state.enemies = [Enemy(id: 5, kind: .runner, hp: 1, maxHP: 1, distance: 1), king(hp: 1_001)]
        let status = try XCTUnwrap(BossStatus(state: state, config: config))
        XCTAssertEqual(status.fraction, 0.26, "aufgerundet auf Hundertstel: nie leerer als er ist")
        XCTAssertEqual(status.shieldAt, config.enemies[.moorKing]?.boss?.shieldAt)
        XCTAssertFalse(status.shielded)
        state.enemies[1].shieldUntilTick = 10
        XCTAssertEqual(BossStatus(state: state, config: config)?.shielded, true)
    }

    /// Ein Spiel mit dem Moorkönig auf dem Weg und ohne weitere Wellen.
    private func kingOnThePath(_ config: BalanceConfig, hp: Double) -> GameState {
        var state = Simulation(config: config).newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.waveIndex = config.waves.count - 1
        state.enemies = [king(hp: hp)]
        state.nextEntityID = 2
        return state
    }

    func testControllerShowsTheBarOnlyWhileTheBossIsThere() throws {
        let config = try missionSeven()
        let withKing = BattleController(model: BattleModel(config: config, seed: 1, autoplay: false,
                                                            resume: kingOnThePath(config, hp: 4_000)),
                                        interactive: true)
        XCTAssertEqual(withKing.boss?.fraction, 1)
        let without = BattleController(model: BattleModel(config: config, seed: 1, autoplay: false), interactive: true)
        XCTAssertNil(without.boss)
    }

    func testShieldAndSummonPlayInTheScene() throws {
        let config = try missionSeven()
        let threshold = 4_000 * (config.enemies[.moorKing]?.boss?.shieldAt ?? 0)
        let model = BattleModel(config: config, seed: 1, autoplay: false, resume: kingOnThePath(config, hp: threshold))
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        scene.frame(after: frameTime)
        scene.frame(after: frameTime)
        let node = try XCTUnwrap(scene.enemyNodes[1])
        XCTAssertTrue(node.isBoss)
        XCTAssertNotNil(model.state.enemies.first { $0.id == 1 }?.shieldUntilTick, "an der Schwelle steigt der Schild")
        XCTAssertTrue(node.showsShield)
        XCTAssertEqual(controller.boss?.shielded, true)
        XCTAssertGreaterThan(scene.fx.stats.summons, 0, scene.fx.stats.summary)
        XCTAssertGreaterThan(model.state.enemies.count, 1, "die Gerufenen stehen auf dem Weg")
        XCTAssertEqual(scene.enemyNodes.count, model.state.enemies.count)
    }

    /// Der Moorkönig spielt seine Momente selbst (FX 03): Schild heben hält
    /// die Schildhaltung, der Ruf endet wieder darin, ein Zucken setzt sie
    /// nicht zurück, und mit dem Fallen des Schilds läuft er wieder.
    func testKingHoldsShieldPoseSummonsFromItAndWalksAfterwards() throws {
        let config = try missionSeven()
        let threshold = 4_000 * (config.enemies[.moorKing]?.boss?.shieldAt ?? 0)
        let model = BattleModel(config: config, seed: 1, autoplay: false, resume: kingOnThePath(config, hp: threshold))
        let scene = BattleScene(model: model)
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        scene.frame(after: frameTime)
        scene.frame(after: frameTime)
        let node = try XCTUnwrap(scene.enemyNodes[1])
        XCTAssertEqual(node.shieldFrames.count, 4, "eigene Schildfolge im Atlas")
        XCTAssertEqual(node.summonFrames.count, 5, "eigene Ruffolge im Atlas")
        let body = try XCTUnwrap(node.body as? SKSpriteNode)
        XCTAssertEqual(scene.fx.stats.guards, 1, scene.fx.stats.summary)
        XCTAssertTrue(node.guardFrame === node.shieldFrames.last)

        for _ in 0..<Int((FxStyle.summonFramesLife + 0.2) / frameTime) { scene.frame(after: frameTime) }
        XCTAssertTrue(node.holdsFrame, "hinter dem Schild läuft er nicht")
        XCTAssertTrue(body.texture === node.guardFrame || node.summonFrames.contains { $0 === body.texture })

        scene.fx.hit(node)
        for _ in 0..<Int((FxStyle.hitFramesLife + 0.1) / frameTime) { scene.frame(after: frameTime) }
        XCTAssertNotNil(node.guardFrame, "ein Zucken nimmt die Haltung nicht weg")

        scene.fx.lowerShield(node)
        XCTAssertNil(node.guardFrame)
        XCTAssertEqual(scene.fx.stats.unguards, 1)
        scene.fx.advance(by: FxStyle.shieldFramesLife + 0.1)
        XCTAssertFalse(node.holdsFrame, "nach dem Schild zurück zum Lauf")
        XCTAssertTrue(body.texture === node.walkFrames[node.walkIndex])
    }
}
