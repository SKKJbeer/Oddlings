import Foundation
import Testing
@testable import OddlingsCore

@Suite("Weg")
struct PathTests {
    let path: PathGeometry

    init() throws { path = PathGeometry(points: try BalanceConfig.missionOne().map.path) }

    @Test("Weglänge Mission 1 ist 32,0 Felder")
    func length() { #expect(abs(path.length - 32.0) < 1e-9) }

    @Test("Anfang, Knick und Ende")
    func positions() {
        #expect(path.position(at: 0) == Point(x: -1, y: 1.5))
        #expect(path.position(at: 5.5) == Point(x: 4.5, y: 1.5))
        #expect(path.position(at: 7) == Point(x: 4.5, y: 3.0))
        #expect(path.position(at: 32) == Point(x: 17, y: 7.5))
    }

    @Test("Außerhalb der Weglänge wird festgehalten")
    func clamps() {
        #expect(path.position(at: -3) == Point(x: -1, y: 1.5))
        #expect(path.position(at: 40) == Point(x: 17, y: 7.5))
    }

    @Test("Letzter Abschnitt wird gefunden")
    func lastSegment() {
        // 28,5 = Anfang des letzten Abschnitts (13,5 | 7,5) → (17 | 7,5)
        let p = path.position(at: 30)
        #expect(abs(p.x - 15.0) < 1e-9)
        #expect(p.y == 7.5)
    }

    @Test("Abstand zum Weg")
    func distanceFromPath() {
        #expect(path.distance(from: Point(x: 2, y: 1.5)) == 0)
        #expect(abs(path.distance(from: Point(x: 0.5, y: 0.5)) - 1.0) < 1e-9)
    }
}

@Suite("Bauzonen")
struct MapZoneTests {
    let map: MissionMap

    init() throws { map = MissionMap(config: try BalanceConfig.missionOne().map) }

    @Test("Zelle auf dem Weg ist kein Bauplatz")
    func onPath() {
        #expect(map.placement(of: Cell(x: 2, y: 1), occupied: []) == .tooCloseToPath)
        #expect(map.placement(of: Cell(x: 4, y: 4), occupied: []) == .tooCloseToPath)
    }

    @Test("Zelle in einer Insel ist frei")
    func inZone() {
        #expect(map.placement(of: Cell(x: 2, y: 2), occupied: []) == .free)
    }

    @Test("Zelle neben dem Weg, aber außerhalb jeder Insel ist Landschaft")
    func landscape() {
        #expect(map.placement(of: Cell(x: 0, y: 0), occupied: []) == .outsideZone)
    }

    @Test("Belegte Zelle")
    func occupied() {
        #expect(map.placement(of: Cell(x: 2, y: 2), occupied: [Cell(x: 2, y: 2)]) == .occupied)
    }

    @Test("Außerhalb der Karte", arguments: [Cell(x: -1, y: 0), Cell(x: 16, y: 0), Cell(x: 0, y: 9), Cell(x: 3, y: -2)])
    func outside(cell: Cell) {
        #expect(map.placement(of: cell, occupied: []) == .outsideMap)
    }

    @Test("Jede Zelle ist eindeutig klassifiziert")
    func everyCellClassified() {
        var free = 0, blocked = 0, landscape = 0
        for y in 0..<map.height {
            for x in 0..<map.width {
                switch map.placement(of: Cell(x: x, y: y), occupied: []) {
                case .free: free += 1
                case .tooCloseToPath: blocked += 1
                case .outsideZone: landscape += 1
                case .occupied, .outsideMap: Issue.record("Zelle \(x),\(y) innerhalb der Karte falsch eingeordnet")
                }
            }
        }
        #expect(free + blocked + landscape == 16 * 9)
        #expect(free == map.buildableCells.count)
    }

    @Test("Mission 1 hat 4 bis 7 Inseln mit 35 bis 50 Feldern (D-141)")
    func zoneBudget() {
        #expect((4...7).contains(map.zones.count))
        #expect((35...50).contains(map.buildableCells.count))
        // Ohne Inseln waren es 114 (Phase-0-Prüfskript, 25.10.2026); die Inseln sind eine Auswahl daraus.
        #expect(map.buildableCells.count == map.zones.reduce(0) { $0 + $1.cells.count })
    }

    @Test("Jede Insel hat genau ihre Zellen als Bauplätze")
    func everyZoneBuildable() {
        for zone in map.zones {
            for cell in zone.cells {
                #expect(map.zone(of: cell) == zone, "\(zone.id) \(cell)")
                #expect(map.isBuildable(cell), "\(zone.id) \(cell)")
            }
        }
        #expect(map.zone(of: Cell(x: 0, y: 0)) == nil)
        #expect(map.zone(of: Cell(x: -1, y: 0)) == nil)
    }

    @Test("Mission 1 hat beide Arten von starkem Ort: Kehre und lange Seite")
    func zoneKinds() {
        let kinds = map.zones.map(\.kind)
        #expect(kinds.filter { $0 == .turn }.count >= 2)
        #expect(kinds.contains(.longSide))
        #expect(kinds.contains(.lastLine))
    }

    @Test("Bauplätze stehen zeilenweise sortiert")
    func sortedRowMajor() {
        let sorted = map.buildableCells.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        #expect(map.buildableCells == sorted)
    }
}

@Suite("Bauinseln")
struct BuildZoneTests {
    /// Weg in Zeile 0 bis x = 5; Insel „a“ 2 × 2 unten links, „b“ ein L rechts.
    let config = MapConfig(width: 6, height: 4, minDistanceFromPath: 0.9,
                           path: [Point(x: -1, y: 0.5), Point(x: 7, y: 0.5)],
                           zones: [BuildZone(id: "a", kind: .turn, rects: [CellRect(x: 0, y: 2, width: 2, height: 2)]),
                                   BuildZone(id: "b", kind: .longSide, rects: [CellRect(x: 4, y: 1, width: 2, height: 1),
                                                                               CellRect(x: 5, y: 2, width: 1, height: 2)])])

    @Test("Ohne Inseln ist jede Zelle mit Abstand Bauplatz, wie bis 0.29")
    func withoutZones() {
        var plain = config
        plain.zones = nil
        let map = MissionMap(config: plain)
        #expect(map.buildableCells.count == 18)
        #expect(map.zones.isEmpty)
        #expect(map.zone(of: Cell(x: 2, y: 2)) == nil)
        #expect(map.placement(of: Cell(x: 2, y: 2), occupied: []) == .free)
    }

    @Test("Mit Inseln nur Inselzellen, zeilenweise")
    func onlyZoneCells() {
        let map = MissionMap(config: config)
        #expect(map.buildableCells == [Cell(x: 4, y: 1), Cell(x: 5, y: 1), Cell(x: 0, y: 2), Cell(x: 1, y: 2),
                                       Cell(x: 5, y: 2), Cell(x: 0, y: 3), Cell(x: 1, y: 3), Cell(x: 5, y: 3)])
        #expect(map.zone(of: Cell(x: 5, y: 3))?.id == "b")
        #expect(map.placement(of: Cell(x: 2, y: 2), occupied: []) == .outsideZone)
        #expect(map.placement(of: Cell(x: 2, y: 0), occupied: []) == .tooCloseToPath)
    }

    @Test("Bauen auf Landschaft wird abgewiesen und kostet nichts")
    func buildRejected() throws {
        var balance = try BalanceConfig.missionOne()
        balance.map = config
        let sim = Simulation(config: balance)
        var state = sim.newGame(seed: 1)
        let gold = state.gold
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 2, y: 2))])
        #expect(events.contains(.commandRejected(.build(.watch, Cell(x: 2, y: 2)), reason: .outsideZone)))
        #expect(state.towers.isEmpty)
        #expect(state.gold == gold)
        _ = sim.step(&state, commands: [.build(.watch, Cell(x: 1, y: 3))])
        #expect(state.towers.count == 1)
    }

    @Test("Rechtecke lesen und schreiben sich als [x, y, b, h]")
    func rectCoding() throws {
        let json = #"{"id":"a","kind":"outpost","rects":[[1,2,3,1]]}"#
        let zone = try JSONDecoder().decode(BuildZone.self, from: Data(json.utf8))
        #expect(zone.rects == [CellRect(x: 1, y: 2, width: 3, height: 1)])
        #expect(zone.cells == [Cell(x: 1, y: 2), Cell(x: 2, y: 2), Cell(x: 3, y: 2)])
        let again = try JSONDecoder().decode(BuildZone.self, from: JSONEncoder().encode(zone))
        #expect(again == zone)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(BuildZone.self, from: Data(#"{"id":"a","kind":"turn","rects":[[1,2,3]]}"#.utf8))
        }
    }
}

@Suite("Beste Bauzelle")
struct BestCellTests {
    /// Kurzer Weg in Zeile 0, er endet bei x = 1. Die Zelle (0, 1) deckt davon
    /// etwa 1,16 Felder ab, (1, 1) nur 0,16, alle anderen nichts. Keine
    /// Gleichstände: Gleich lange Sehnen unterscheiden sich in der letzten Stelle.
    let map = MissionMap(config: MapConfig(width: 5, height: 3, minDistanceFromPath: 0.9,
                                           path: [Point(x: -1, y: 0.5), Point(x: 1, y: 0.5)]))

    @Test("Meiste Weglänge gewinnt")
    func most() {
        #expect(map.bestCell(radius: 1.2, excluding: []) == Cell(x: 0, y: 1))
    }

    @Test("Belegte Zellen fallen weg")
    func skipsOccupied() {
        #expect(map.bestCell(radius: 1.2, excluding: [Cell(x: 0, y: 1)]) == Cell(x: 1, y: 1))
    }

    @Test("`least` sucht die Zelle mit dem wenigsten Weg, bei Gleichstand die erste der Karte")
    func least() {
        #expect(map.bestCell(radius: 1.2, excluding: [], least: true) == Cell(x: 2, y: 0))
    }

    @Test("Ohne freie Zelle nil")
    func none() {
        #expect(map.bestCell(radius: 1.2, excluding: map.buildableCells) == nil)
    }
}
