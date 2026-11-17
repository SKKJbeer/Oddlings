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

    private func layout(_ device: Device, avoiding: Bool = false) -> HudLayout {
        let bar = BattleStyle.hudHeight + 2 * BattleStyle.hudMargin
        let size = CGSize(width: device.screen.width, height: device.screen.height - bar)
        let board = BoardLayout(size: size, map: map)
        let insets = HudLayout.Insets(left: device.side, bottom: device.bottom, right: device.side)
        let avoid = avoiding ? HudLayout.Avoid(board: board, map: map, reserved: corners(size, insets)) : HudLayout.Avoid()
        return HudLayout(board: board, insets: insets, metrics: BattleStyle.hudMetrics, avoid: avoid)
    }

    /// Fähigkeitsknopf und Wellenvorschau mit drei Arten, wie `RingMenu` sie meidet.
    private func corners(_ size: CGSize, _ insets: HudLayout.Insets) -> [CGRect] {
        [HudLayout.abilityRect(board: size, insets: insets),
         HudLayout.forecastRect(board: size, insets: insets, entries: WaveForecast.maxEntries)]
    }

    private var allMissions: [BalanceConfig] {
        get throws {
            let names = ["mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b",
                         "mission-06a", "mission-06b", "mission-07"]
            return [try BalanceConfig.missionOne()] + (try names.map { try BalanceConfig.bundledMission(named: $0) })
        }
    }

    func testButtonsAreLargeTapTargets() {
        XCTAssertGreaterThanOrEqual(BattleStyle.hudMetrics.button, 44)
    }

    func testRingFitsEveryCellOnEveryDevice() {
        checkRing(counts: 1...3)
    }

    /// Mission 2 bietet die Zwergenbank als vierten Knopf an (P2-5).
    func testFourButtonsFitEveryCellOfMissionTwo() throws {
        map = Simulation(config: try BalanceConfig.bundledMission(named: "mission-02")).map
        checkRing(counts: 4...4)
    }

    /// Mission 3: Kampfplatz mit Haarnadel, vier Knöpfe zum Bauen, am Turm
    /// höchstens drei (Aufwerten, Zielwahl, Verkaufen; P2-6).
    func testRingFitsEveryCellOfMissionThree() throws {
        map = Simulation(config: try BalanceConfig.bundledMission(named: "mission-03")).map
        checkRing(counts: 1...4)
    }

    private func checkRing(counts: ClosedRange<Int>) {
        for device in devices {
            let hud = layout(device)
            for cell in map.buildableCells {
                for count in counts {
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

    /// Am Kartenrand dreht der Bogen schräg und ein äußerer Knopf darf unter
    /// die Waagerechte rutschen; die Richtung des Fächers bleibt dieselbe.
    private func meanY(_ points: [CGPoint]) -> CGFloat {
        points.map(\.y).reduce(0, +) / CGFloat(max(points.count, 1))
    }

    func testRingOpensDownInTopRows() {
        let hud = layout(devices[2])
        for cell in map.buildableCells where cell.y <= 1 {
            let center = hud.board.viewPoint(cell.center)
            XCTAssertGreaterThan(meanY(hud.ring(at: cell, count: 3)), center.y, "Zelle \(cell.x),\(cell.y)")
        }
    }

    func testRingOpensUpWhereThereIsRoom() {
        let hud = layout(devices[2])
        for cell in map.buildableCells where cell.y >= 3 {
            let center = hud.board.viewPoint(cell.center)
            XCTAssertLessThan(meanY(hud.ring(at: cell, count: 3)), center.y, "Zelle \(cell.x),\(cell.y)")
        }
    }

    /// Tafel mit Turmwerten (D-130): In jeder Mission, auf jedem Gerät, bei
    /// bis zu vier Knöpfen liegt sie frei, hoch oder als Leiste.
    func testStatPanelFitsEveryCellOfEveryMission() throws {
        let names = ["mission-02", "mission-03", "mission-04", "mission-05a", "mission-05b",
                     "mission-06a", "mission-06b", "mission-07"]
        let maps = [try BalanceConfig.missionOne()] + (try names.map { try BalanceConfig.bundledMission(named: $0) })
        var strips = 0
        for config in maps {
            map = Simulation(config: config).map
            for device in devices {
                let hud = layout(device)
                for cell in map.buildableCells {
                    for count in 1...4 {
                        let buttons = hud.ring(at: cell, count: count)
                        let place = hud.statPanel(for: cell, avoiding: buttons,
                                                  tall: BattleStyle.statPanel, wide: BattleStyle.statStrip)
                        if place.wide { strips += 1 }
                        let context = "\(config.mission.id), \(device.name), Zelle \(cell.x),\(cell.y), \(count) Knöpfe"
                        XCTAssertTrue(hud.bounds.insetBy(dx: -0.5, dy: -0.5).contains(place.rect), "außerhalb: \(context)")
                        XCTAssertFalse(place.rect.intersects(hud.cellRect(cell)), "verdeckt die Zelle: \(context)")
                        XCTAssertFalse(buttons.map(hud.buttonRect).contains { $0.intersects(place.rect) },
                                       "verdeckt Knopf: \(context)")
                    }
                }
            }
        }
        XCTAssertGreaterThan(strips, 0, "die Leiste wird gebraucht, sonst wäre sie überflüssig")
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

    // MARK: Tafel kennt die Lage (A-2, D-158)

    /// Review P4: Die Tafel lag auf Weg und Festung, genau wo die Gegner
    /// ankommen, und unter dem Fähigkeitsknopf. Jetzt: nie auf einer festen
    /// Ecke, wo es eine freie Lage gibt; auf der Festung nur auf dem iPhone SE,
    /// wenn Zelle und Knöpfe in der Mitte jede andere Lage belegen.
    func testStatPanelKeepsFortressAndCornersFree() throws {
        var onFortress = 0, cases = 0
        for config in try allMissions {
            map = Simulation(config: config).map
            for device in devices {
                let hud = layout(device, avoiding: true)
                let fortress = try XCTUnwrap(hud.avoid.fortress)
                for cell in map.buildableCells {
                    for count in 1...4 {
                        cases += 1
                        let buttons = hud.ring(at: cell, count: count)
                        let place = hud.statPanel(for: cell, avoiding: buttons,
                                                  tall: BattleStyle.statPanel, wide: BattleStyle.statStrip)
                        let context = "\(config.mission.id), \(device.name), Zelle \(cell.x),\(cell.y), \(count) Knöpfe"
                        let free = hud.freePanel(for: cell, avoiding: buttons, size: BattleStyle.statPanel) != nil
                            || hud.freePanel(for: cell, avoiding: buttons, size: BattleStyle.statStrip) != nil
                        if free {
                            XCTAssertFalse(hud.avoid.reserved.contains { $0.intersects(place.rect) }, "auf fester Ecke: \(context)")
                        }
                        if fortress.intersects(place.rect.insetBy(dx: 1, dy: 1)) {
                            onFortress += 1
                            XCTAssertEqual(device.name, "iPhone SE", "auf der Festung: \(context)")
                        }
                    }
                }
            }
        }
        // Gemessen 16.11.2026: 65 von 16 288 Fällen, alle iPhone SE.
        XCTAssertLessThan(Double(onFortress) / Double(cases), 0.01)
    }

    /// Unter den freien Lagen gewinnt die mit der kleinsten Strafe.
    func testPanelTakesTheLeastCoveringFreeSpot() throws {
        for config in try allMissions {
            map = Simulation(config: config).map
            for device in devices {
                let hud = layout(device, avoiding: true)
                for cell in map.buildableCells {
                    let buttons = hud.ring(at: cell, count: 3)
                    let size = BattleStyle.statPanel
                    guard let chosen = hud.freePanel(for: cell, avoiding: buttons, size: size) else { continue }
                    let best = hud.candidates(size, for: cell)
                        .map { CGRect(origin: $0, size: size) }
                        .filter { hud.bounds.insetBy(dx: -0.5, dy: -0.5).contains($0) && hud.isFree($0, for: cell, avoiding: buttons) }
                        .map(hud.penalty(of:)).min()
                    XCTAssertEqual(hud.penalty(of: chosen), best, "\(config.mission.id), \(device.name), Zelle \(cell.x),\(cell.y)")
                }
            }
        }
    }

    /// Weg und Festung zählen: Ohne Strafe läge die Tafel in Mission 1 auf
    /// dem iPhone 15 öfter auf der Festung (Gegenprobe zu D-158).
    func testPenaltyMovesPanelOffTheFortress() throws {
        map = Simulation(config: try BalanceConfig.missionOne()).map
        let hud = layout(devices[2], avoiding: true)
        let blind = HudLayout(board: hud.board, insets: .init(left: devices[2].side, bottom: devices[2].bottom,
                                                               right: devices[2].side),
                              metrics: BattleStyle.hudMetrics,
                              avoid: HudLayout.Avoid(path: hud.avoid.path, fortress: hud.avoid.fortress,
                                                     reserved: hud.avoid.reserved))
        var seeing: CGFloat = 0, notSeeing: CGFloat = 0
        for cell in map.buildableCells {
            let buttons = hud.ring(at: cell, count: 3)
            seeing += hud.penalty(of: hud.statPanel(for: cell, avoiding: buttons, tall: BattleStyle.statPanel,
                                                    wide: BattleStyle.statStrip).rect)
            notSeeing += hud.penalty(of: blind.statPanel(for: cell, avoiding: buttons, tall: BattleStyle.statPanel,
                                                         wide: BattleStyle.statStrip).rect)
        }
        XCTAssertLessThan(seeing, notSeeing / 2)
    }

    /// Der Bogen liegt nie unter dem Fähigkeitsknopf oder dem Zettel, wo er
    /// anderswo Platz hat.
    func testRingKeepsCornersFree() throws {
        var blocked = 0, cases = 0
        for config in try allMissions {
            map = Simulation(config: config).map
            for device in devices {
                let hud = layout(device, avoiding: true)
                for cell in map.buildableCells {
                    for count in 1...4 {
                        cases += 1
                        let rects = hud.ring(at: cell, count: count).map(hud.buttonRect)
                        if rects.contains(where: { r in hud.avoid.reserved.contains { $0.intersects(r) } }) { blocked += 1 }
                    }
                }
            }
        }
        // Gemessen 16.11.2026: 16 Fälle am Rand, in denen kein Bogen frei liegt.
        XCTAssertLessThan(Double(blocked) / Double(cases), 0.002)
    }
}
