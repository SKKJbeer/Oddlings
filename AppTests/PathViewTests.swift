import OddlingsCore
import XCTest
@testable import Oddlings

/// Der gezeichnete Weg mit Bögen (A-1, docs/konzepte/a-1-laufen.md): Er weicht
/// nur an den Ecken und nur wenig von der Regel ab, und die Laufrichtung
/// springt nirgends. Geprüft an jeder Mission der Region.
@MainActor
final class PathViewTests: XCTestCase {
    private let step = 0.01

    private func paths() throws -> [(String, PathGeometry)] {
        // Nebenmissionen ohne eigene Missionsdatei (P3-5) haben noch keinen Weg.
        try CampaignConfig.regionOne().nodes.compactMap(\.mission).map { name in
            (name, try BalanceConfig.bundledMission(named: name).map.path)
        }
    }

    /// Größte Abweichung von der Simulation: r·(√2 − 1) an einer rechtwinkligen Ecke.
    func testDrawnPathStaysCloseToTheRule() throws {
        let radius = FxStyle.pathCornerRadius
        let limit = radius * (2.0.squareRoot() - 1) + 1e-9
        for (name, path) in try paths() {
            let view = PathView(path: path, radius: radius)
            XCTAssertEqual(view.length, path.length, accuracy: 1e-9, name)
            var worst = 0.0
            for distance in stride(from: 0.0, through: path.length, by: step) {
                worst = max(worst, view.sample(at: distance).position.distance(to: path.position(at: distance)))
            }
            XCTAssertLessThanOrEqual(worst, limit, name)
            XCTAssertGreaterThan(worst, 0.1, "\(name): an den Ecken wird gerundet")
        }
    }

    /// Außerhalb der Ecken (Mitte jeder Strecke) und an beiden Enden sind Bild
    /// und Regel deckungsgleich: Niemand läuft vor oder hinter seiner Position her.
    func testStraightsAndEndsMatchTheRuleExactly() throws {
        for (name, path) in try paths() {
            let view = PathView(path: path, radius: FxStyle.pathCornerRadius)
            var along = 0.0
            for index in path.points.indices.dropLast() {
                let length = path.points[index].distance(to: path.points[index + 1])
                let middle = along + length / 2
                XCTAssertEqual(view.sample(at: middle).position, path.position(at: middle), "\(name) Strecke \(index)")
                along += length
            }
            XCTAssertEqual(view.sample(at: 0).position, path.points[0], name)
            XCTAssertEqual(view.sample(at: path.length).position.distance(to: path.points[path.points.count - 1]), 0,
                           accuracy: 1e-9, name)
            XCTAssertEqual(view.sample(at: -1).position, view.sample(at: 0).position, name)
        }
    }

    /// Kein Knick: Zwischen zwei Proben dreht die Richtung höchstens so weit,
    /// wie der Bogen über diese Strecke erlaubt. Mit Radius 0 (heute bis 0.29.1)
    /// springt sie an jeder Ecke um 90°.
    func testDirectionTurnsSmoothly() throws {
        for (name, path) in try paths() {
            XCTAssertLessThanOrEqual(maxTurn(PathView(path: path, radius: FxStyle.pathCornerRadius)),
                                     step / FxStyle.pathCornerRadius + 1e-6, name)
            XCTAssertGreaterThan(maxTurn(PathView(path: path, radius: 0)), 1.5, "\(name) ohne Bogen")
        }
    }

    private func maxTurn(_ view: PathView) -> Double {
        var worst = 0.0
        var previous = view.sample(at: 0)
        for distance in stride(from: step, through: view.length, by: step) {
            let sample = view.sample(at: distance)
            let dot = max(-1, min(1, sample.dx * previous.dx + sample.dy * previous.dy))
            worst = max(worst, acos(dot))
            XCTAssertEqual(sample.dx * sample.dx + sample.dy * sample.dy, 1, accuracy: 1e-9)
            previous = sample
        }
        return worst
    }

    /// Krümmung nur im Bogen, mit Vorzeichen der Drehung: Mission 1 biegt
    /// zuerst nach unten (Uhrzeigersinn auf dem Bildschirm, positiv).
    func testCurvatureOnlyInBendsWithTurnSign() throws {
        let path = try BalanceConfig.missionOne().map.path
        let view = PathView(path: path, radius: FxStyle.pathCornerRadius)
        let corner = path.points[0].distance(to: path.points[1])
        XCTAssertEqual(view.sample(at: corner - 1).curvature, 0)
        XCTAssertEqual(view.sample(at: corner).curvature, 1 / FxStyle.pathCornerRadius, accuracy: 1e-9)
        // Zweite Ecke biegt zurück nach rechts: gegen den Uhrzeigersinn.
        let second = corner + path.points[1].distance(to: path.points[2])
        XCTAssertLessThan(view.sample(at: second).curvature, 0)
    }

    /// Eine kurze Strecke zwischen zwei Ecken begrenzt beide Bögen auf ihre
    /// Hälfte, damit sie sich nicht überlappen.
    func testShortStretchShrinksTheBends() {
        let points = [Point(x: 0, y: 0), Point(x: 2, y: 0), Point(x: 2, y: 0.4), Point(x: 4, y: 0.4)]
        let view = PathView(points: points, radius: 0.5)
        var previous = view.sample(at: 0)
        for distance in stride(from: 0.0, through: view.length, by: 0.005) {
            let sample = view.sample(at: distance)
            XCTAssertLessThan(sample.position.distance(to: previous.position), 0.02, "bei \(distance)")
            previous = sample
        }
        XCTAssertEqual(view.sample(at: 2.2).dx, 0, accuracy: 1e-9, "in der Mitte der kurzen Strecke senkrecht")
    }
}
