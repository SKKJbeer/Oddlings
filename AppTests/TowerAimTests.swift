import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Türme zielen (A-5 Teil 3, G9, D-185 bis D-189): Schütze dreht zum Ziel,
/// Kristall lädt, Hut hebt sich, Stein atmet nicht.
@MainActor
final class TowerAimTests: XCTestCase {
    private let field: CGFloat = 40
    private let frameTime = 1.0 / 60

    private func tower(_ kind: TowerKind, level: Int = 1, specialization: Specialization? = nil) -> TowerNode {
        TowerNode(tower: Tower(id: 1, kind: kind, cell: Cell(x: 0, y: 0), cooldownTicks: 0, spent: 1,
                               level: level, specialization: specialization), field: field)
    }

    // MARK: Blickrichtung (rein)

    func testSectorsCountCounterclockwiseFromRight() {
        XCTAssertEqual(GuardFacing.nearestSector(0), 0)
        XCTAssertEqual(GuardFacing.nearestSector(.pi / 2), 2)
        XCTAssertEqual(GuardFacing.nearestSector(.pi), 4)
        XCTAssertEqual(GuardFacing.nearestSector(-.pi / 2), 6)
        XCTAssertEqual(GuardFacing.nearestSector(-0.1), 0, "knapp unter rechts bleibt rechts")
        XCTAssertEqual(GuardFacing.nearestSector(2 * .pi - 0.3), 0)
    }

    func testTurnIsLimitedByRate() {
        var facing = GuardFacing(angle: 0)
        facing.turn(toward: .pi / 2, dt: 0.1, rate: 2, hysteresis: 0, snap: false)
        XCTAssertEqual(facing.angle, 0.2, accuracy: 1e-9, "höchstens Tempo × Zeit")
        facing.turn(toward: -0.1, dt: 0.1, rate: 2, hysteresis: 0, snap: false)
        XCTAssertEqual(facing.angle, GuardFacing.normalized(-0.1), accuracy: 1e-9, "nahe Ziele sofort")
        var still = GuardFacing(angle: 0)
        still.turn(toward: .pi, dt: 0.01, rate: 2, hysteresis: 0, snap: true)
        XCTAssertEqual(still.sector, 4, "weniger Bewegung: springt")
    }

    /// An der Grenze zweier Bilder flackert die Figur nicht hin und her.
    func testHysteresisHoldsSectorAtBorder() {
        var facing = GuardFacing(angle: 0)
        let border = GuardFacing.sectorWidth / 2
        var changes = 0, last = facing.sector
        for step in 0..<40 {
            let wobble = border + (step.isMultiple(of: 2) ? 0.05 : -0.05)
            facing.turn(toward: wobble, dt: 1, rate: 100, hysteresis: 10 * .pi / 180, snap: false)
            if facing.sector != last { changes += 1; last = facing.sector }
        }
        XCTAssertEqual(changes, 0)
        facing.turn(toward: border + 0.3, dt: 1, rate: 100, hysteresis: 10 * .pi / 180, snap: false)
        XCTAssertEqual(facing.sector, 1, "deutlich drüben wechselt es")
    }

    // MARK: Turm

    func testCrownTableSkipsBrokenEntries() {
        let data = Data("""
        {"_zweck": "x", "tower_watch": {"schuetzen": [[0.5, 0.8], [2, 0.5]]}, "tower_spore": {"hutLinie": 0.55},
         "tower_bad": {"hutLinie": 4}, "other": {"schuetzen": [[0.5, 0.5]]}}
        """.utf8)
        let table = TowerCrownTable.parse(data)
        XCTAssertEqual(table["tower_watch"]?.shooters, [CGPoint(x: 0.5, y: 0.8)])
        XCTAssertEqual(table["tower_spore"]?.capLine, 0.55)
        XCTAssertNil(table["tower_bad"]?.capLine)
        XCTAssertNil(table["other"])
    }

    /// Wachturm und Salve haben Schützen nach der Tabelle, Salve zwei.
    func testWatchTowersCarryTheirShooters() throws {
        try XCTSkipUnless(ShooterNode.available, "Schützenbilder fehlen im Atlas")
        XCTAssertEqual(tower(.watch).shooters.count, 1)
        XCTAssertEqual(tower(.watch, level: 2).shooters.count, 1)
        XCTAssertEqual(tower(.watch, level: 3, specialization: .volley).shooters.count, 2)
        XCTAssertEqual(tower(.watch, level: 3, specialization: .falconHold).shooters.count, 1)
        XCTAssertTrue(tower(.lightning).shooters.isEmpty)
        // Aufwerten tauscht das Bild und behält die Blickrichtung.
        let node = tower(.watch)
        node.aim(at: [CGPoint(x: -100, y: 0)], dt: 1, still: true)
        node.show(level: 3, specialization: .volley)
        XCTAssertEqual(node.shooters.map(\.facing.sector), [4, 4])
    }

    /// Salve: jeder Schütze nimmt sein eigenes Ziel; mit einem Ziel beide dasselbe.
    func testVolleyShootersAimAtTheirOwnTargets() throws {
        try XCTSkipUnless(ShooterNode.available, "Schützenbilder fehlen im Atlas")
        let node = tower(.watch, level: 3, specialization: .volley)
        node.aim(at: [CGPoint(x: 400, y: 0), CGPoint(x: -400, y: 0)], dt: 1, still: true)
        XCTAssertEqual(node.shooters.map(\.facing.sector), [0, 4])
        XCTAssertTrue(node.shooters.allSatisfy(\.onTarget))
        node.aim(at: [CGPoint(x: 0, y: 400)], dt: 1, still: true)
        XCTAssertEqual(node.shooters.map(\.facing.sector), [2, 2])
        node.aim(at: [], dt: 1, still: true)
        XCTAssertEqual(node.shooters.map(\.facing.sector), [2, 2], "ohne Ziel bleibt er stehen")
        XCTAssertTrue(node.shooters.allSatisfy { $0.goal == nil })
    }

    /// Stein atmet nicht (G9), der Pilz schon.
    func testOnlyTheMushroomBreathes() {
        for kind in [TowerKind.watch, .lightning, .bank] {
            let node = tower(kind)
            for t in stride(from: 0.0, to: 3, by: 0.1) { node.idle(time: t, still: false) }
            XCTAssertEqual(node.art.yScale, 1, "\(kind)")
        }
        let spore = tower(.spore)
        var moved = false
        for t in stride(from: 0.0, to: 3, by: 0.1) {
            spore.idle(time: t, still: false)
            if spore.art.yScale != 1 { moved = true }
        }
        XCTAssertTrue(moved)
    }

    /// Der Kristallschein wächst mit der Ladung (D-187).
    func testCrystalGlowFollowsCharge() throws {
        let node = tower(.lightning)
        let glow = try XCTUnwrap(node.glow)
        node.charge = 0
        node.idle(time: 0, still: true)
        let empty = glow.alpha
        node.charge = 0.5
        node.idle(time: 0, still: true)
        let half = glow.alpha
        node.charge = 1
        node.idle(time: 0, still: true)
        XCTAssertLessThan(empty, half)
        XCTAssertLessThan(half, glow.alpha)
        XCTAssertEqual(empty, FxStyle.chargeGlowEmpty, accuracy: 0.001)
    }

    /// Der Hut hebt sich über das Verzerrungsgitter und setzt wieder auf (D-188).
    func testCapLiftsAndSettles() throws {
        let node = tower(.spore)
        try XCTSkipIf(TowerCrownTable.entry(for: node.pictureName).capLine == nil, "Hutlinie fehlt")
        let sprite = try XCTUnwrap(node.art.children.first as? SKSpriteNode)
        XCTAssertNil(sprite.warpGeometry)
        node.capLift = FxStyle.capLift * field
        let grid = try XCTUnwrap(sprite.warpGeometry as? SKWarpGeometryGrid)
        XCTAssertGreaterThan(grid.destPosition(at: 7).y, grid.sourcePosition(at: 7).y, "Hut oben")
        XCTAssertEqual(grid.destPosition(at: 0).y, grid.sourcePosition(at: 0).y, "Fuß bleibt")
        node.capLift = 0
        XCTAssertNil(sprite.warpGeometry)
    }

    // MARK: Szene

    /// Über Mission 1 im Bildtakt: Jeder Schütze mit Ziel blickt nach höchstens
    /// 0,6 s in dessen Richtung, und Schüsse spielen ihre Folge (D-189).
    func testShootersFaceTheirTargetsThroughMissionOne() throws {
        try XCTSkipUnless(ShooterNode.available, "Schützenbilder fehlen im Atlas")
        let config = try BalanceConfig.bundledMission(named: "mvp-mission-01")
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: true))
        var aimed = 0, frames = 0
        while !scene.model.state.isOver && frames < 12_000 {
            scene.frame(after: frameTime)
            frames += 1
            aimed += scene.towerNodes.values.flatMap(\.shooters).filter { $0.goal != nil }.count
        }
        XCTAssertGreaterThan(aimed, 100, "Wachtürme haben gezielt")
        XCTAssertGreaterThan(scene.fx.stats.shots, 10)
        XCTAssertLessThanOrEqual(scene.longestOffTarget, 0.6)
    }

    /// Weniger Bewegung: kein Abdrücken, kein Hut, aber die Richtung stimmt sofort.
    func testReducedMotionSnapsWithoutShotFrames() throws {
        try XCTSkipUnless(ShooterNode.available, "Schützenbilder fehlen im Atlas")
        let config = try BalanceConfig.bundledMission(named: "mvp-mission-01")
        let scene = BattleScene(model: BattleModel(config: config, seed: 1, autoplay: true))
        scene.fx.reduceMotion = true
        for _ in 0..<3_600 { scene.frame(after: frameTime) }
        XCTAssertEqual(scene.fx.stats.shots, 0)
        XCTAssertEqual(scene.longestOffTarget, 0, accuracy: frameTime * 2)
    }
}
