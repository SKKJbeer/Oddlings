import OddlingsCore
import XCTest
@testable import Oddlings

/// Reine Rechnungen der Effekte (docs/konzepte/fx-01-bewegung-und-effekte.md):
/// Kurven, Laufhaltung, Blitz, Wurfbahn, Wackeln, Lebensbalken, Messung.
@MainActor
final class FxMathTests: XCTestCase {
    private let curves: [(String, (Double) -> Double)] = [
        ("linear", Ease.linear), ("quadIn", Ease.quadIn), ("quadOut", Ease.quadOut),
        ("cubicOut", Ease.cubicOut), ("sineInOut", Ease.sineInOut), ("backIn", Ease.backIn),
        ("backOut", Ease.backOut), ("elasticOut", Ease.elasticOut),
    ]

    func testCurvesStartAtZeroAndEndAtOne() {
        for (name, curve) in curves {
            XCTAssertEqual(curve(0), 0, accuracy: 1e-9, name)
            XCTAssertEqual(curve(1), 1, accuracy: 1e-9, name)
            // Außerhalb von 0…1 wird geklemmt, kein Ausreißer bei zu langer Bildzeit.
            XCTAssertEqual(curve(1.5), curve(1), accuracy: 1e-9, name)
            XCTAssertEqual(curve(-0.5), curve(0), accuracy: 1e-9, name)
        }
    }

    /// Überschwingen ist gewollt, aber nur bei den federnden Kurven.
    func testOnlySpringyCurvesOvershoot() {
        let samples = stride(from: 0.0, through: 1.0, by: 0.01)
        XCTAssertGreaterThan(samples.map(Ease.backOut).max() ?? 0, 1.05)
        XCTAssertGreaterThan(samples.map(Ease.elasticOut).max() ?? 0, 1.05)
        XCTAssertLessThan(samples.map(Ease.backIn).min() ?? 0, -0.05)
        for (name, curve) in curves where ["linear", "quadIn", "quadOut", "cubicOut", "sineInOut"].contains(name) {
            for t in samples { XCTAssertTrue((-1e-9...1 + 1e-9).contains(curve(t)), "\(name) bei \(t)") }
        }
    }

    func testPoseRepeatsAfterTwoStepsAndHopAfterOne() {
        for kind in EnemyKind.allCases {
            let gait = FxStyle.gait(kind)
            for distance in stride(from: 0.0, through: 3.0, by: 0.13) {
                let pose = FxMath.pose(distance: distance, phase: 0.3, gait: gait)
                let twoSteps = FxMath.pose(distance: distance + 2 * gait.stride, phase: 0.3, gait: gait)
                let oneStep = FxMath.pose(distance: distance + gait.stride, phase: 0.3, gait: gait)
                XCTAssertEqual(pose.tilt, twoSteps.tilt, accuracy: 1e-9, "\(kind)")
                XCTAssertEqual(pose.lift, oneStep.lift, accuracy: 1e-9, "\(kind)")
                XCTAssertEqual(pose.scaleY, oneStep.scaleY, accuracy: 1e-9, "\(kind)")
            }
        }
    }

    /// Beim Aufsetzen am Boden und am stärksten gestaucht, in der Luft gestreckt.
    func testPoseSquashesOnContactAndStaysWithinBounds() {
        for kind in EnemyKind.allCases {
            let gait = FxStyle.gait(kind)
            let contact = FxMath.pose(distance: 0, phase: 0, gait: gait)
            XCTAssertEqual(contact.lift, 0, accuracy: 1e-9)
            XCTAssertEqual(contact.scaleY, 1 - gait.squash, accuracy: 1e-9)
            XCTAssertGreaterThan(contact.scaleX, 1)
            let top = FxMath.pose(distance: gait.stride / 2, phase: 0, gait: gait)
            XCTAssertEqual(top.lift, gait.hop, accuracy: 1e-9)
            XCTAssertGreaterThan(top.scaleY, 1)
            XCTAssertLessThan(top.shadow, 1)
            for distance in stride(from: 0.0, through: 5.0, by: 0.017) {
                let pose = FxMath.pose(distance: distance, phase: 0, gait: gait)
                XCTAssertTrue((0...gait.hop + 1e-9).contains(pose.lift))
                XCTAssertTrue((1 - gait.squash - 1e-9...1 + gait.squash).contains(pose.scaleY))
                XCTAssertLessThanOrEqual(abs(pose.tilt), gait.sway + gait.lean + 1e-9)
                XCTAssertTrue((0.7 - 1e-9...1).contains(pose.shadow))
            }
        }
    }

    /// Eine Welle hüpft nicht im Gleichschritt.
    func testPhasesOfNeighbouringIDsDiffer() {
        let phases = (1...40).map(FxMath.phase(forID:))
        XCTAssertTrue(phases.allSatisfy { (0..<1).contains($0) })
        for (a, b) in zip(phases, phases.dropFirst()) { XCTAssertGreaterThan(abs(a - b), 0.2) }
    }

    func testBoltStartsAndEndsExactlyOnTargets() {
        var random = FxRandom(seed: 7)
        let a = Vec(x: 10, y: 20), b = Vec(x: 110, y: -30)
        let points = FxMath.boltPoints(from: a, to: b, segments: 7, jitter: 0.16, using: &random)
        XCTAssertEqual(points.count, 8)
        XCTAssertEqual(points.first, a)
        XCTAssertEqual(points.last, b)
        let length = (b - a).length
        let direction = (b - a) * (1 / length)
        for point in points {
            // Abstand zur Geraden: Kreuzprodukt mit der Einheitsrichtung.
            let offset = abs((point - a).x * direction.y - (point - a).y * direction.x)
            XCTAssertLessThanOrEqual(offset, 0.16 * length + 1e-9)
        }
        XCTAssertGreaterThan(points.dropFirst().dropLast().map { abs(($0 - a).x * direction.y - ($0 - a).y * direction.x) }.max() ?? 0, 0)
    }

    func testSameSeedSameBolt() {
        var first = FxRandom(seed: 3), second = FxRandom(seed: 3)
        let a = FxMath.boltPoints(from: .zero, to: Vec(x: 50, y: 0), segments: 5, jitter: 0.2, using: &first)
        let b = FxMath.boltPoints(from: .zero, to: Vec(x: 50, y: 0), segments: 5, jitter: 0.2, using: &second)
        XCTAssertEqual(a, b)
    }

    func testArrowArcLandsOnTargetAndPeaksInTheMiddle() {
        let a = Vec(x: 0, y: 0), b = Vec(x: 100, y: 0)
        XCTAssertEqual(FxMath.arc(from: a, to: b, height: 12, at: 0).point, a)
        let end = FxMath.arc(from: a, to: b, height: 12, at: 1)
        XCTAssertEqual(end.point.x, 100, accuracy: 1e-9)
        XCTAssertEqual(end.point.y, 0, accuracy: 1e-9)
        XCTAssertEqual(FxMath.arc(from: a, to: b, height: 12, at: 0.5).point.y, 12, accuracy: 1e-9)
        // Steigt am Anfang, fällt am Ende: Die Pfeilspitze zeigt erst hoch, dann runter.
        XCTAssertGreaterThan(FxMath.arc(from: a, to: b, height: 12, at: 0).angle, 0)
        XCTAssertLessThan(end.angle, 0)
    }

    func testShakeIsBoundedAndSilentWithoutTrauma() {
        XCTAssertEqual(FxMath.shake(trauma: 0, time: 1.23, amplitude: 5), .zero)
        for time in stride(from: 0.0, through: 2.0, by: 0.01) {
            let offset = FxMath.shake(trauma: 0.5, time: time, amplitude: 4)
            XCTAssertLessThanOrEqual(abs(offset.x), 4 * 0.25 + 1e-9)
            XCTAssertLessThanOrEqual(abs(offset.y), 4 * 0.25 + 1e-9)
        }
    }

    func testHealthLagFollowsDownSlowlyAndJumpsUp() {
        var shown = 1.0
        shown = FxMath.lag(shown, towards: 0.4, dt: 1.0 / 60, rate: FxStyle.healthLagRate)
        XCTAssertGreaterThan(shown, 0.4, "läuft nach")
        XCTAssertLessThan(shown, 1)
        for _ in 0..<60 { shown = FxMath.lag(shown, towards: 0.4, dt: 1.0 / 60, rate: FxStyle.healthLagRate) }
        XCTAssertEqual(shown, 0.4, accuracy: 1e-9, "nach einer Sekunde angekommen")
        XCTAssertEqual(FxMath.lag(0.4, towards: 1, dt: 1.0 / 60, rate: FxStyle.healthLagRate), 1, "Neustart springt")
    }

    func testFrameStats() {
        var stats = FrameStats()
        for _ in 0..<59 { stats.add(1.0 / 60) }
        stats.add(0.05)
        stats.add(0)
        XCTAssertEqual(stats.frames, 60)
        XCTAssertEqual(stats.worstMS, 50, accuracy: 1e-9)
        XCTAssertEqual(stats.averageFPS, 60 / (59.0 / 60 + 0.05), accuracy: 1e-9)
    }
}
