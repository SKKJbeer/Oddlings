import Testing
@testable import OddlingsCore

@Suite("Bauen, Verkaufen, Gold")
struct BuildSellTests {
    let sim: Simulation
    let free = Cell(x: 0, y: 0)

    init() throws { sim = Simulation(config: try BalanceConfig.missionOne()) }

    @Test("Bauen zieht die Kosten ab und belegt die Zelle")
    func build() {
        var state = sim.newGame(seed: 1)
        let events = sim.step(&state, commands: [.build(.watch, free)])
        #expect(events == [.towerBuilt(id: 1)])
        #expect(state.gold == 150 - 50)
        #expect(state.towers == [Tower(id: 1, kind: .watch, cell: free, cooldownTicks: 0, spent: 50)])
    }

    @Test("Zu wenig Gold")
    func notEnoughGold() {
        var state = sim.newGame(seed: 1)
        state.gold = 79
        let command = Command.build(.lightning, free)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .notEnoughGold)])
        #expect(state.gold == 79)
        #expect(state.towers.isEmpty)
    }

    @Test("Genau passendes Gold reicht")
    func exactGold() {
        var state = sim.newGame(seed: 1)
        state.gold = 80
        sim.step(&state, commands: [.build(.lightning, free)])
        #expect(state.gold == 0)
        #expect(state.towers.count == 1)
    }

    @Test("Belegte Zelle")
    func occupied() {
        var state = sim.newGame(seed: 1)
        let second = Command.build(.spore, free)
        let events = sim.step(&state, commands: [.build(.watch, free), second])
        #expect(events.last == .commandRejected(second, reason: .cellOccupied))
        #expect(state.towers.count == 1)
        #expect(state.gold == 100)
    }

    @Test("Auf dem Weg und außerhalb der Karte")
    func outsideZone() {
        var state = sim.newGame(seed: 1)
        let onPath = Command.build(.watch, Cell(x: 2, y: 1))
        let outside = Command.build(.watch, Cell(x: 16, y: 4))
        #expect(sim.step(&state, commands: [onPath, outside]) == [
            .commandRejected(onPath, reason: .tooCloseToPath),
            .commandRejected(outside, reason: .outsideMap),
        ])
        #expect(state.gold == 150)
    }

    @Test("Verkaufen erstattet 70 %, abgerundet", arguments: [(50, 35), (80, 56), (33, 23), (1, 0), (90, 63), (350, 245)])
    func sellRefund(cost: Int, refund: Int) {
        #expect(sim.refund(for: cost) == refund)
    }

    @Test("Verkaufen gibt Gold zurück und macht die Zelle frei")
    func sell() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.lightning, free)])
        let events = sim.step(&state, commands: [.sell(towerID: 1), .build(.watch, free)])
        #expect(events == [.towerSold(id: 1, refund: 56), .towerBuilt(id: 2)])
        #expect(state.gold == 150 - 80 + 56 - 50)
        #expect(state.towers.map(\.id) == [2])
    }

    @Test("Unbekannter oder schon verkaufter Turm")
    func sellUnknown() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, free), .sell(towerID: 1)])
        let again = Command.sell(towerID: 1)
        #expect(sim.step(&state, commands: [again]) == [.commandRejected(again, reason: .unknownTower)])
        #expect(state.gold == 135)
    }

    @Test("Turmtyp ohne Werte wird abgelehnt statt abzustürzen")
    func towerWithoutConfig() throws {
        var config = try BalanceConfig.missionOne()
        config.towers[.spore] = nil
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        let command = Command.build(.spore, free)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .unknownTower)])
    }

    @Test("Kein Weg führt zu negativem Gold oder zwei Türmen in einer Zelle")
    func invariants() {
        // Zufällige Befehlsfolgen über alle Bauplätze und Turmtypen; der Generator
        // ist gesät, damit ein Fehlschlag wiederholbar ist.
        var rng = SplitMix64(seed: 2026)
        let cells = sim.map.buildableCells + [Cell(x: 2, y: 1), Cell(x: -1, y: 0)]
        for _ in 0..<200 {
            var state = sim.newGame(seed: 1)
            for _ in 0..<60 {
                var commands: [Command] = []
                for _ in 0..<Int.random(in: 0...3, using: &rng) {
                    if Bool.random(using: &rng), let tower = state.towers.randomElement(using: &rng) {
                        commands.append(.sell(towerID: tower.id))
                    } else {
                        commands.append(.build(TowerKind.allCases.randomElement(using: &rng)!,
                                               cells.randomElement(using: &rng)!))
                    }
                }
                sim.step(&state, commands: commands)
                #expect(state.gold >= 0)
                let occupied = state.towers.map(\.cell)
                #expect(Set(occupied).count == occupied.count)
                #expect(occupied.allSatisfy(sim.map.isBuildable))
                if state.isOver { break }
            }
        }
    }

    @Test("Befehle wirken vor der Welle im selben Tick")
    func commandsBeforeWaves() {
        var state = sim.newGame(seed: 1)
        while state.tick < 600 { sim.step(&state) }
        let events = sim.step(&state, commands: [.build(.watch, free)])
        #expect(events.first == .towerBuilt(id: 1))
        #expect(events.dropFirst().first == .waveStarted(index: 0))
        #expect(events.contains(.enemySpawned(id: 2)))
    }
}
