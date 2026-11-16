import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Laufen in der Szene (A-1): keine Richtungswechsel in einem Bild, Staub mit
/// Grenze je Figur, „Bewegung reduzieren“ ohne Staub und Neigung, und die
/// Spuren halten Gegner auseinander. Ganze Missionen im Bildtakt von 60/s.
@MainActor
final class WalkSceneTests: XCTestCase {
    private let frameTime = 1.0 / 60

    private func scene(_ mission: String = "mvp-mission-01", reduceMotion: Bool = false) throws -> BattleScene {
        let config = try BalanceConfig.bundledMission(named: mission)
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: true))
        scene.fx.reduceMotion = reduceMotion
        return scene
    }

    /// Bis 0.29.1 knickte jede Figur an jeder Ecke um 90° in einem Bild. Jetzt
    /// dreht die Laufrichtung je Bild höchstens um 20°, in jeder Mission.
    func testNoEnemyTurnsSharplyInOneFrame() throws {
        for mission in try CampaignConfig.regionOne().nodes.compactMap(\.mission) {
            let scene = try scene(mission)
            var last: [Int: (CGPoint, CGFloat?)] = [:]
            var worst: CGFloat = 0, frames = 0
            // Höchstens 200 s je Mission: Alle Ecken sind bis dahin oft durchlaufen.
            while !scene.model.state.isOver && frames < 12_000 {
                scene.frame(after: frameTime)
                frames += 1
                var seen: [Int: (CGPoint, CGFloat?)] = [:]
                for (id, enemy) in scene.enemyNodes {
                    let now = enemy.position
                    guard let (before, heading) = last[id] else { seen[id] = (now, nil); continue }
                    let step = hypot(now.x - before.x, now.y - before.y)
                    // Stehen (Bollwerk, Betäubung) hat keine Richtung.
                    guard step > scene.layout.field * 0.005 else { seen[id] = (now, heading); continue }
                    let angle = atan2(now.y - before.y, now.x - before.x)
                    if let heading {
                        var turn = abs(angle - heading)
                        if turn > .pi { turn = 2 * .pi - turn }
                        worst = max(worst, turn)
                    }
                    seen[id] = (now, angle)
                }
                last = seen
            }
            XCTAssertLessThan(worst, 20 * .pi / 180, "\(mission): \(worst * 180 / .pi)°")
        }
    }

    /// Staub beim Aufsetzen, nie mehr als drei Wölkchen je Figur; mit
    /// „Bewegung reduzieren“ keiner, Neigung 0, Laufbilder wechseln weiter.
    func testDustIsBoundedAndReducedMotionDropsIt() throws {
        let lively = try scene()
        for _ in 0..<3_600 {
            lively.frame(after: frameTime)
            for enemy in lively.enemyNodes.values {
                XCTAssertLessThanOrEqual(enemy.activeDust, FxStyle.dustPerEnemy)
            }
        }
        XCTAssertGreaterThan(lively.fx.stats.footfalls, 10)
        XCTAssertGreaterThan(lively.fx.stats.bends, 3)

        let still = try scene(reduceMotion: true)
        var leaned = false
        var frames = Set<Int>()
        for _ in 0..<3_600 {
            still.frame(after: frameTime)
            for enemy in still.enemyNodes.values {
                leaned = leaned || enemy.bank != 0
                if enemy.kind == .raider { frames.insert(enemy.walkIndex) }
            }
        }
        XCTAssertEqual(still.fx.stats.footfalls, 0)
        XCTAssertFalse(leaned)
        XCTAssertGreaterThan(frames.count, 1, "laufen bleibt")
        XCTAssertGreaterThan(still.fx.stats.bends, 3, "Bögen bleiben")
    }

    /// In der Kurve neigen sich Figuren zur Innenseite und richten sich danach
    /// wieder auf; der Flitzer stärker als der Plünderer.
    func testEnemiesLeanIntoBendsAndStraightenAfter() throws {
        let scene = try scene()
        var most: [EnemyKind: Double] = [:]
        for _ in 0..<3_600 {
            scene.frame(after: frameTime)
            for enemy in scene.enemyNodes.values { most[enemy.kind] = max(most[enemy.kind] ?? 0, abs(enemy.bank)) }
        }
        let raider = try XCTUnwrap(most[.raider])
        XCTAssertGreaterThan(raider, 0.02)
        if let runner = most[.runner] { XCTAssertGreaterThan(runner, raider) }
    }

    /// Mit Spuren stehen zwei Gegner fast nie deckungsgleich, auch wenn ein
    /// Flitzer einen Plünderer überholt (höchstens 1 % der Bilder).
    func testEnemiesRarelyStack() throws {
        let scene = try scene()
        var frames = 0, busy = 0
        while !scene.model.state.isOver && frames < 30_000 {
            scene.frame(after: frameTime)
            frames += 1
            if scene.enemyNodes.count > 1 { busy += 1 }
        }
        XCTAssertGreaterThan(busy, 600)
        XCTAssertLessThanOrEqual(scene.stackedFrames, busy / 100, "\(scene.stackedFrames) von \(busy)")
    }

    /// Bild und Regel bleiben nah beieinander: Bogen plus Spur, nie mehr.
    func testDrawnPositionStaysNearTheRule() throws {
        let scene = try scene()
        let limit = FxStyle.pathCornerRadius * (2.0.squareRoot() - 1) + FxStyle.laneWidth(.raider) + 1e-6
        var worst = 0.0
        for _ in 0..<3_600 {
            scene.frame(after: frameTime)
            worst = max(worst, scene.frameDeviation)
        }
        XCTAssertGreaterThan(worst, 0.1)
        XCTAssertLessThanOrEqual(worst, limit)
    }
}
