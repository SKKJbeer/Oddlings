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

    @Test("Zelle neben dem Weg ist frei")
    func besidePath() {
        #expect(map.placement(of: Cell(x: 0, y: 0), occupied: []) == .free)
    }

    @Test("Belegte Zelle")
    func occupied() {
        #expect(map.placement(of: Cell(x: 0, y: 0), occupied: [Cell(x: 0, y: 0)]) == .occupied)
    }

    @Test("Außerhalb der Karte", arguments: [Cell(x: -1, y: 0), Cell(x: 16, y: 0), Cell(x: 0, y: 9), Cell(x: 3, y: -2)])
    func outside(cell: Cell) {
        #expect(map.placement(of: cell, occupied: []) == .outsideMap)
    }

    @Test("Jede Zelle ist eindeutig klassifiziert")
    func everyCellClassified() {
        var free = 0, blocked = 0
        for y in 0..<map.height {
            for x in 0..<map.width {
                switch map.placement(of: Cell(x: x, y: y), occupied: []) {
                case .free: free += 1
                case .tooCloseToPath: blocked += 1
                case .occupied, .outsideMap: Issue.record("Zelle \(x),\(y) innerhalb der Karte falsch eingeordnet")
                }
            }
        }
        #expect(free + blocked == 16 * 9)
        #expect(free == map.buildableCells.count)
    }

    @Test("Gleiche Bauplätze wie das Prüfskript")
    func matchesBalanceSim() {
        // tools/balance-sim/sim.py zählt 114 Kandidaten (25.10.2026). Weicht das ab,
        // rechnen Prüfskript und Simulation auf verschiedenen Karten.
        #expect(map.buildableCells.count == 114)
    }

    @Test("Bauplätze stehen zeilenweise sortiert")
    func sortedRowMajor() {
        let sorted = map.buildableCells.sorted { ($0.y, $0.x) < ($1.y, $1.x) }
        #expect(map.buildableCells == sorted)
    }
}
