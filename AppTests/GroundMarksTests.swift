import OddlingsCore
import SpriteKit
import XCTest
@testable import Oddlings

/// Gemalte Ringe (A-5, G5): Der Streifen liegt im Katalog, der Rand ist bei
/// jeder Reichweite gleich breit, und die Szene zeichnet die Auswahl ohne Linien.
@MainActor
final class GroundMarksTests: XCTestCase {
    func testStripIsInTheCatalogAndTilesAcross() throws {
        let strip = try XCTUnwrap(GroundMarks.strip, "mark_ring fehlt im Katalog")
        XCTAssertGreaterThan(strip.width, strip.height * 8, "ein langer Streifen, kein Ringbild")
        // Waagerecht kachelbar: Der Sprung vom Ende zum Anfang ist nicht größer
        // als ein gewöhnlicher Schritt zwischen Nachbarspalten, sonst stünde im
        // Ring eine Naht. Der Streifen ist fein gemalt, Nachbarn unterscheiden sich immer etwas.
        func columnDifference(_ x0: Int, _ x1: Int) -> Double {
            var sum = 0
            for y in 0..<strip.height {
                for c in 0..<4 {
                    sum += abs(Int(strip.pixels[(y * strip.width + x0) * 4 + c]) - Int(strip.pixels[(y * strip.width + x1) * 4 + c]))
                }
            }
            return Double(sum) / Double(strip.height * 4)
        }
        let neighbours = (0..<(strip.width - 1)).map { columnDifference($0, $0 + 1) }.sorted()
        let typical = neighbours[neighbours.count * 99 / 100]
        XCTAssertLessThanOrEqual(columnDifference(strip.width - 1, 0), typical * 1.5, "Naht zwischen Ende und Anfang")
    }

    /// Ein kleiner und ein großer Ring: Die deckende Randbreite ist dieselbe.
    func testRimWidthDoesNotGrowWithTheRadius() throws {
        let strip = try XCTUnwrap(GroundMarks.strip)
        func rimWidth(radius: CGFloat) throws -> Int {
            let image = try XCTUnwrap(GroundMarks.render(radius: radius, rim: 8, wash: 0, scale: 1, strip: strip))
            let data = try XCTUnwrap(image.dataProvider?.data as Data?)
            let y = image.height / 2
            var count = 0
            for x in 0..<(image.width / 2) where data[(y * image.bytesPerRow) + x * 4 + 3] > 60 { count += 1 }
            return count
        }
        let small = try rimWidth(radius: 50)
        let large = try rimWidth(radius: 190)
        XCTAssertGreaterThan(small, 2)
        XCTAssertLessThanOrEqual(abs(small - large), 3, "Rand \(small) gegen \(large) Punkte")
    }

    func testCenterStaysClearWithoutWash() throws {
        let strip = try XCTUnwrap(GroundMarks.strip)
        let image = try XCTUnwrap(GroundMarks.render(radius: 60, rim: 8, wash: 0, scale: 1, strip: strip))
        let data = try XCTUnwrap(image.dataProvider?.data as Data?)
        let center = (image.height / 2) * image.bytesPerRow + (image.width / 2) * 4
        XCTAssertEqual(data[center + 3], 0)
    }

    func testTexturesAreCachedPerSize() throws {
        let a = try XCTUnwrap(GroundMarks.texture(radius: 100, rim: 6, wash: 0.2))
        let b = try XCTUnwrap(GroundMarks.texture(radius: 100, rim: 6, wash: 0.2))
        XCTAssertTrue(a === b)
    }

    /// Antippen eines Turms: Zelle und Reichweite gemalt, keine SKShapeNode.
    func testSceneDrawsThePaintedSelection() throws {
        let config = try BalanceConfig.missionOne()
        let model = BattleModel(config: config, seed: 1, autoplay: false)
        let controller = BattleController(model: model, interactive: true)
        let scene = BattleScene(model: model)
        scene.controller = controller
        let cell = try XCTUnwrap(model.sim.map.buildableCells.first)
        controller.tap(cell)
        controller.choose(.watch)
        controller.choose(.watch)
        controller.afterFrame(events: model.step())
        scene.frame(after: 1 / 30)
        controller.tap(cell)
        scene.frame(after: 1 / 30)
        XCTAssertEqual(scene.selectionStyle, "gemalt")
        XCTAssertTrue(scene.artSummary.contains("towers=tower_watch"), scene.artSummary)
    }
}
