import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Leistung (docs/konzepte/fx-01-bewegung-und-effekte.md, „Leistung"): eine
/// ganze Mission mit allen Effekten, bei 2× und 60 Bildern je Sekunde.
@MainActor
final class FxBudgetTests: XCTestCase {
    func testWholeMissionStaysWithinBudget() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        model.speed = BattleStyle.fastSpeed
        let scene = BattleScene(model: model)
        scene.fx.reduceMotion = false
        let frameTime = 1.0 / 60
        let clock = ContinuousClock()
        var frames = 0, peakSprites = 0, peakNodes = 0
        var elapsed = Duration.zero
        while !model.state.isOver && frames < 200_000 {
            elapsed += clock.measure { scene.frame(after: frameTime) }
            frames += 1
            peakSprites = max(peakSprites, scene.fx.activeSprites)
            if frames % 30 == 0 {
                var nodes = 0, shapes = 0
                scene.enumerateChildNodes(withName: "//*") { node, _ in nodes += 1 }
                scene.effectLayer.enumerateChildNodes(withName: "//*") { node, _ in
                    if node is SKShapeNode { shapes += 1 }
                }
                peakNodes = max(peakNodes, nodes)
                XCTAssertEqual(shapes, 0, "SKShapeNode in der Effektebene (Bild \(frames))")
            }
        }
        let averageMS = Double(elapsed.components.attoseconds) / 1e15 / Double(frames)
            + Double(elapsed.components.seconds) * 1000 / Double(frames)
        print("FX-Budget: \(frames) Bilder, im Mittel \(String(format: "%.2f", averageMS)) ms, "
              + "höchstens \(peakSprites) Effekt-Sprites, \(peakNodes) Nodes, \(scene.fx.stats.summary)")
        XCTAssertEqual(model.state.outcome, .won)
        XCTAssertLessThanOrEqual(peakSprites, FxStyle.maxSprites)
        XCTAssertGreaterThan(peakSprites, 40, "Effekte liefen wirklich")
        XCTAssertLessThan(averageMS, FxStyle.frameBudgetMS)
    }
}
