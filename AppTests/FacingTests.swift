import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Drei Blickrichtungen mit Rückfall (A-1): Auf jeder Strecke jeder Mission die
/// passende Folge; fehlen der Art die Bilder, bleibt die Seitenansicht.
@MainActor
final class FacingTests: XCTestCase {
    func testEveryStretchOfEveryMissionGetsItsView() throws {
        for mission in try CampaignConfig.regionOne().nodes.compactMap(\.mission) {
            let path = try PathGeometry(points: BalanceConfig.bundledMission(named: mission).map.path)
            let view = PathView(path: path, radius: FxStyle.pathCornerRadius)
            var along = 0.0
            for index in path.points.indices.dropLast() {
                let a = path.points[index], b = path.points[index + 1]
                let length = a.distance(to: b)
                let sample = view.sample(at: along + length / 2)
                // Karte zählt y nach unten: größeres y heißt auf den Betrachter zu.
                let expected: EnemyView = abs(b.y - a.y) <= abs(b.x - a.x) ? .side : (b.y > a.y ? .front : .back)
                XCTAssertEqual(FxMath.facing(dx: sample.dx, dy: sample.dy, sideAngle: FxStyle.sideAngle), expected,
                               "\(mission) Strecke \(index)")
                along += length
            }
        }
    }

    func testThirtyFiveDegreesIsTheBorder() {
        let inside = FxStyle.sideAngle - 0.01, outside = FxStyle.sideAngle + 0.01
        XCTAssertEqual(FxMath.facing(dx: cos(inside), dy: sin(inside), sideAngle: FxStyle.sideAngle), .side)
        XCTAssertEqual(FxMath.facing(dx: -cos(outside), dy: sin(outside), sideAngle: FxStyle.sideAngle), .front)
        XCTAssertEqual(FxMath.facing(dx: cos(outside), dy: -sin(outside), sideAngle: FxStyle.sideAngle), .back)
    }

    /// Ohne Vorder- und Rückbilder (heute alle Arten) bleibt die Seitenfolge,
    /// und das Bild wechselt nicht: Kein Überblenden ohne neue Folge.
    func testFallsBackToSideViewWithoutPictures() throws {
        for kind in EnemyKind.allCases {
            let node = EnemyNode(enemy: Enemy(id: 1, kind: kind, hp: 10, maxHP: 10, distance: 0), field: 40)
            for wanted in EnemyView.allCases where !node.hasFrames(for: wanted) {
                node.turn(to: wanted, dt: 1 / 60)
                XCTAssertEqual(node.view, .side, "\(kind) \(wanted)")
                XCTAssertEqual(node.viewFade.alpha, 0, "\(kind) \(wanted)")
            }
        }
    }

    /// Bewegung reduzieren: keine Neigung, Blickrichtung bleibt.
    func testReducedMotionKeepsFacingButDropsLean() {
        let node = EnemyNode(enemy: Enemy(id: 2, kind: .runner, hp: 10, maxHP: 10, distance: 0), field: 40)
        node.lean(towards: 0.2, dt: 1, still: false)
        XCTAssertEqual(node.bank, 0.2, accuracy: 1e-9)
        node.lean(towards: 0.2, dt: 1, still: true)
        XCTAssertEqual(node.bank, 0)
    }
}
