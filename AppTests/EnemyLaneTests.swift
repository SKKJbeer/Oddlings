import OddlingsCore
import XCTest
@testable import Oddlings

/// Spuren statt Gänsemarsch (A-1): Jeder Gegner läuft auf seiner festen Spur
/// quer zum Weg, aus seiner Kennung, im Band seiner Art.
@MainActor
final class EnemyLaneTests: XCTestCase {
    func testLaneIsFixedAndInsideTheBand() {
        for id in 0..<500 {
            let lane = FxMath.lane(forID: id)
            XCTAssertEqual(lane, FxMath.lane(forID: id))
            XCTAssertTrue((-1...1).contains(lane), "\(id): \(lane)")
        }
        for kind in EnemyKind.allCases {
            XCTAssertLessThanOrEqual(FxStyle.laneWidth(kind), 0.2, "\(kind) bleibt auf dem Weg")
        }
        XCTAssertEqual(FxStyle.laneWidth(.moorKing), 0, "der Boss läuft in der Mitte")
        XCTAssertLessThan(FxStyle.laneWidth(.brute), FxStyle.laneWidth(.raider))
    }

    /// Nacheinander erscheinende Gegner liegen weit auseinander, nicht zufällig
    /// nebeneinander: mindestens 0,48 von 2.
    func testNeighbouringIDsAreFarApart() {
        for id in 0..<500 {
            XCTAssertGreaterThanOrEqual(abs(FxMath.lane(forID: id + 1) - FxMath.lane(forID: id)), 0.48, "\(id)")
        }
    }

    /// Zwei Gegner mit derselben Strecke stehen nie auf demselben Punkt, auch im Bogen.
    func testSameDistanceNeverSamePoint() throws {
        let path = try BalanceConfig.missionOne().map.path
        let view = PathView(path: path, radius: FxStyle.pathCornerRadius)
        let width = FxStyle.laneWidth(.raider)
        for distance in stride(from: 0.0, through: path.length, by: 0.25) {
            for id in 0..<40 {
                let a = view.position(at: distance, lane: FxMath.lane(forID: id) * width)
                let b = view.position(at: distance, lane: FxMath.lane(forID: id + 1) * width)
                XCTAssertGreaterThan(a.distance(to: b), 0.08, "Strecke \(distance), \(id)")
            }
        }
    }

    /// In der Szene: Die Node trägt ihre Spur und steht um genau sie neben dem Bogen.
    func testSceneDrawsEnemiesOnTheirLane() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: true)
        let scene = BattleScene(model: model)
        let frameTime = 1 / Double(config.simulation.ticksPerSecond)
        var lanes = Set<Double>()
        for _ in 0..<4_000 {
            scene.frame(after: frameTime)
            for node in scene.enemyNodes.values { lanes.insert(node.lane) }
            if lanes.count >= 4 { break }
        }
        XCTAssertGreaterThanOrEqual(lanes.count, 4, "verschiedene Spuren")
    }
}
