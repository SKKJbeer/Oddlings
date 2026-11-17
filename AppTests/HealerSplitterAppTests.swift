import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Darstellung von Moorhexe und Pilzbalg (D-175, D-176): Heilring mit Hinweis
/// beim ersten Mal, Sporenwolke beim Zerfall, Sporlinge als eigene Nodes.
/// Alles aus Ereignissen der Simulation.
@MainActor
final class HealerSplitterAppTests: XCTestCase {
    /// Eine Mission mit diesen Gegnern auf dem Weg und ohne weitere Wellen.
    private func scene(_ file: String, _ enemies: [Enemy]) throws -> (BattleModel, BattleScene, Double) {
        let config = try BalanceConfig.bundledMission(named: file)
        var state = Simulation(config: config).newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.waveIndex = config.waves.count - 1
        state.enemies = enemies
        state.nextEntityID = 50
        let model = BattleModel(config: config, seed: 1, autoplay: false, resume: state)
        let scene = BattleScene(model: model)
        scene.controller = BattleController(model: model, interactive: true)
        return (model, scene, 1 / Double(config.simulation.ticksPerSecond))
    }

    func testWitchHealsWithRingSoundLimitAndOneHint() throws {
        var witch = Enemy(id: 1, kind: .witch, hp: 100, maxHP: 100, distance: 3)
        witch.healTick = 2
        let hurt = Enemy(id: 2, kind: .raider, hp: 10, maxHP: 70, distance: 3.2)
        let (model, scene, frameTime) = try scene("mission-06a", [witch, hurt])
        XCTAssertNotNil(model.sim.config.enemies[.witch]?.heal, "M6a bringt die Moorhexe")
        for _ in 0..<5 { scene.frame(after: frameTime) }
        XCTAssertGreaterThan(model.state.enemies.first { $0.id == 2 }?.hp ?? 0, 10, "geheilt")
        XCTAssertEqual(scene.fx.stats.heals, 1, scene.fx.stats.summary)
        XCTAssertEqual(scene.fx.stats.healHints, 1)
        // Eine Sekunde weiter heilt sie nicht noch einmal sichtbar, und der Hinweis kommt nie zweimal.
        let interval = model.sim.config.enemies[.witch]?.heal?.interval ?? 0
        for _ in 0..<Int(interval / frameTime + 2) { scene.frame(after: frameTime) }
        XCTAssertEqual(scene.fx.stats.healHints, 1)
        XCTAssertLessThanOrEqual(scene.fx.stats.heals, 2)
    }

    func testPuffballBurstsIntoSporelingsThatGetTheirOwnNodes() throws {
        let puffball = Enemy(id: 1, kind: .puffball, hp: 0.01, maxHP: 170, distance: 4)
        let (model, scene, frameTime) = try scene("mission-06b", [puffball])
        let split = try XCTUnwrap(model.sim.config.enemies[.puffball]?.split)
        // Ein Wachturm in Reichweite des Balgs genügt für den letzten Treffer.
        let map = model.sim.map
        let at = map.path.position(at: puffball.distance)
        let range = try XCTUnwrap(model.sim.config.stats(of: .watch, level: 1)?.range)
        let cell = try XCTUnwrap((0..<model.sim.config.map.height).lazy.flatMap { y in
            (0..<model.sim.config.map.width).lazy.map { Cell(x: $0, y: y) }
        }.first { map.placement(of: $0, occupied: []) == .free && $0.center.distance(to: at) < range - 0.2 })
        model.enqueue(.build(.watch, cell))
        scene.frame(after: frameTime)
        scene.frame(after: frameTime)
        XCTAssertEqual(scene.fx.stats.splits, 1, scene.fx.stats.summary)
        let sporelings = model.state.enemies.filter { $0.kind == .sporeling }
        XCTAssertEqual(sporelings.count, split.count)
        XCTAssertEqual(scene.enemyNodes.count, model.state.enemies.count)
        for sporeling in sporelings {
            XCTAssertEqual(scene.enemyNodes[sporeling.id]?.kind, .sporeling)
        }
    }

    func testNewEnemiesHaveTheirOwnLook() {
        let kinds: [EnemyKind] = [.witch, .puffball, .sporeling]
        XCTAssertEqual(Set(kinds.map { BattleStyle.enemyHeight($0) }).count, 3)
        for kind in kinds {
            XCTAssertNotEqual(FxStyle.enemyColor(kind), FxStyle.enemyColor(.raider), "\(kind)")
        }
    }
}
