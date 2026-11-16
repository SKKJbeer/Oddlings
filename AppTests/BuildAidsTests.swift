import OddlingsCore
import XCTest
@testable import Oddlings

/// Reine Rechnungen hinter dem Bauen (A-2): Wellenvorschau (R2, D-159),
/// Bauplätze um den Finger (P2, D-157) und der Weg im Kreis (D-156).
@MainActor
final class BuildAidsTests: XCTestCase {
    private func wave(_ groups: [(EnemyKind, Int)]) -> WaveConfig {
        WaveConfig(hpScale: 1, groups: groups.map { SpawnGroup(enemy: $0.0, count: $0.1, interval: 1) })
    }

    // MARK: Wellenvorschau

    func testForecastSumsKindsInOrderOfAppearance() throws {
        let waves = [wave([(.raider, 4)]), wave([(.runner, 3), (.raider, 5), (.runner, 2), (.brute, 0)])]
        let forecast = try XCTUnwrap(WaveForecast(waves: waves, index: 1))
        XCTAssertEqual(forecast.wave, 1)
        XCTAssertEqual(forecast.entries.map(\.kind), [.runner, .raider], "Reihenfolge des ersten Auftretens, leere Gruppen fallen weg")
        XCTAssertEqual(forecast.entries.map(\.count), [5, 5])
        XCTAssertEqual(forecast.entries.map(\.isNew), [true, false], "Flitzer kam vorher nicht vor")
        XCTAssertTrue(forecast.hasNew)
    }

    func testFirstWaveMarksNothingNew() throws {
        let forecast = try XCTUnwrap(WaveForecast(waves: [wave([(.raider, 4), (.runner, 2)])], index: 0))
        XCTAssertFalse(forecast.hasNew, "in der ersten Welle ist alles neu, also nichts")
    }

    func testForecastKeepsAtMostThreeKinds() throws {
        let all = wave([(.raider, 1), (.runner, 1), (.brute, 1), (.moorKing, 1)])
        let forecast = try XCTUnwrap(WaveForecast(waves: [all], index: 0))
        XCTAssertEqual(forecast.entries.count, WaveForecast.maxEntries)
    }

    func testForecastIsNilWithoutWave() {
        XCTAssertNil(WaveForecast(waves: [wave([(.raider, 1)])], index: 1))
        XCTAssertNil(WaveForecast(waves: [wave([(.raider, 0)])], index: 0), "leere Welle")
    }

    /// Jede Welle jeder Mission hat eine Vorschau, und sie passt auf den Zettel.
    func testEveryMissionWaveHasAForecast() throws {
        let names = ["mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b",
                     "mission-06a", "mission-06b", "mission-07"]
        for config in [try BalanceConfig.missionOne()] + (try names.map { try BalanceConfig.bundledMission(named: $0) }) {
            for index in config.waves.indices {
                let forecast = try XCTUnwrap(WaveForecast(waves: config.waves, index: index), "\(config.mission.id) \(index)")
                XCTAssertLessThanOrEqual(forecast.entries.count, WaveForecast.maxEntries)
                XCTAssertFalse(BattleTexts.forecast(forecast).isEmpty)
            }
        }
    }

    /// Der Knopf zeigt die nächste Welle: vor der ersten Welle Welle 1.
    func testControllerForecastsTheNextWave() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        controller.afterFrame(events: model.step())
        XCTAssertTrue(controller.canCallNextWave)
        XCTAssertEqual(controller.forecast, WaveForecast(waves: config.waves, index: 0))
    }

    // MARK: Bauplätze um den Finger

    func testBuildZoneFocusFadesSmoothly() {
        let focus = Cell(x: 5, y: 5)
        XCTAssertEqual(BuildZoneFocus.alpha(of: Cell(x: 9, y: 9), focus: nil), BattleStyle.buildZoneIdleAlpha)
        XCTAssertEqual(BuildZoneFocus.alpha(of: focus, focus: focus), 1)
        XCTAssertEqual(BuildZoneFocus.alpha(of: Cell(x: 5, y: 9), focus: focus), 0, "außer Reichweite")
        var last = 1.0
        for x in 5...9 {
            let alpha = BuildZoneFocus.alpha(of: Cell(x: x, y: 5), focus: focus)
            XCTAssertLessThanOrEqual(alpha, last, "fällt nach außen nur ab")
            last = alpha
        }
        let between = BuildZoneFocus.alpha(of: Cell(x: 7, y: 5), focus: focus)
        XCTAssertGreaterThan(between, 0)
        XCTAssertLessThan(between, 1)
    }

    // MARK: Weg im Kreis

    /// Die gezeichneten Stücke sind genau so lang, wie die Simulation die
    /// Abdeckung rechnet: Was leuchtet, ist, was der Turm erreicht.
    func testCoveredPathMatchesSimulation() throws {
        let map = Simulation(config: try BalanceConfig.missionOne()).map
        for cell in map.buildableCells {
            for radius in [1.5, 2.5, 4.0] {
                let pieces = PathCoverage.pieces(of: map.path, around: cell.center, radius: radius)
                XCTAssertEqual(PathCoverage.length(of: pieces), map.path.coverage(around: cell.center, radius: radius),
                               accuracy: 1e-9, "\(cell) r \(radius)")
            }
        }
    }

    func testCoveredPathJoinsAtCorners() {
        let path = PathGeometry(points: [Point(x: 0, y: 0), Point(x: 2, y: 0), Point(x: 2, y: 2)])
        let pieces = PathCoverage.pieces(of: path, around: Point(x: 2, y: 0), radius: 1)
        XCTAssertEqual(pieces.count, 1, "eine Linie um die Ecke, nicht zwei Stücke")
        XCTAssertEqual(PathCoverage.length(of: pieces), 2, accuracy: 1e-9)
        XCTAssertTrue(PathCoverage.pieces(of: path, around: Point(x: 10, y: 10), radius: 1).isEmpty)
    }
}
