import CoreGraphics
import OddlingsCore
import XCTest
@testable import Oddlings

/// Lage von Kreismenü und Infotafel (07-ui-ux.md, Abschnitt 4) auf den
/// kleinsten und größten iPhones im Querformat, für jede Bauzelle von
/// Mission 1. Die Kopfleiste liegt über der Karte (D-030 zurückgestellt), die
/// Karte füllt den Rest bis an die Ränder; was die Ansicht nicht bedecken
/// darf, steht in den Insets.
@MainActor
final class HudLayoutTests: XCTestCase {
    private struct Device {
        let name: String
        let screen: CGSize
        let side: CGFloat
        let bottom: CGFloat
    }

    private let devices = [
        Device(name: "iPhone SE", screen: CGSize(width: 667, height: 375), side: 0, bottom: 0),
        Device(name: "iPhone 13 mini", screen: CGSize(width: 812, height: 375), side: 50, bottom: 21),
        Device(name: "iPhone 15", screen: CGSize(width: 852, height: 393), side: 59, bottom: 21),
        Device(name: "iPhone 16 Pro Max", screen: CGSize(width: 956, height: 440), side: 62, bottom: 21),
    ]

    private lazy var map: MissionMap = Simulation(config: try! BalanceConfig.missionOne()).map

    private func layout(_ device: Device) -> HudLayout {
        let bar = BattleStyle.hudHeight + 2 * BattleStyle.hudMargin
        let size = CGSize(width: device.screen.width, height: device.screen.height - bar)
        let board = BoardLayout(size: size, map: map)
        return HudLayout(board: board, insets: .init(left: device.side, bottom: device.bottom, right: device.side),
                         metrics: BattleStyle.hudMetrics)
    }

    func testButtonsAreLargeTapTargets() {
        XCTAssertGreaterThanOrEqual(BattleStyle.hudMetrics.button, 44)
    }

    func testRingFitsEveryCellOnEveryDevice() {
        for device in devices {
            let hud = layout(device)
            for cell in map.buildableCells {
                for count in 1...3 {
                    let points = hud.ring(at: cell, count: count)
                    let context = "\(device.name), Zelle \(cell.x),\(cell.y), \(count) Knöpfe"
                    XCTAssertEqual(points.count, count, context)
                    let rects = points.map(hud.buttonRect)
                    for rect in rects {
                        XCTAssertTrue(hud.bounds.insetBy(dx: -0.5, dy: -0.5).contains(rect), "außerhalb: \(context)")
                        XCTAssertFalse(rect.intersects(hud.cellRect(cell)), "verdeckt die Zelle: \(context)")
                    }
                    for (i, a) in points.enumerated() {
                        for b in points[(i + 1)...] {
                            XCTAssertGreaterThanOrEqual(hypot(a.x - b.x, a.y - b.y), BattleStyle.hudMetrics.button,
                                                        "Knöpfe überlappen: \(context)")
                        }
                    }
                }
            }
        }
    }

    func testRingOpensDownInTopRows() {
        let hud = layout(devices[2])
        for cell in map.buildableCells where cell.y <= 1 {
            let center = hud.board.viewPoint(cell.center)
            XCTAssertTrue(hud.ring(at: cell, count: 3).allSatisfy { $0.y > center.y }, "Zelle \(cell.x),\(cell.y)")
        }
    }

    func testRingOpensUpWhereThereIsRoom() {
        let hud = layout(devices[2])
        for cell in map.buildableCells where cell.y >= 3 {
            let center = hud.board.viewPoint(cell.center)
            XCTAssertTrue(hud.ring(at: cell, count: 3).allSatisfy { $0.y < center.y }, "Zelle \(cell.x),\(cell.y)")
        }
    }

    func testPanelCoversNeitherCellNorButtons() {
        for device in devices {
            let hud = layout(device)
            for cell in map.buildableCells {
                let buttons = hud.ring(at: cell, count: 1)
                let panel = hud.panel(for: cell, avoiding: buttons)
                let context = "\(device.name), Zelle \(cell.x),\(cell.y)"
                XCTAssertTrue(hud.bounds.insetBy(dx: -0.5, dy: -0.5).contains(panel), "außerhalb: \(context)")
                XCTAssertFalse(panel.intersects(hud.cellRect(cell)), "verdeckt die Zelle: \(context)")
                XCTAssertFalse(buttons.map(hud.buttonRect).contains { $0.intersects(panel) }, "verdeckt Knopf: \(context)")
            }
        }
    }
}
