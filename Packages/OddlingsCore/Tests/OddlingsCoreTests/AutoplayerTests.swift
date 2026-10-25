import Testing
@testable import OddlingsCore

@Suite("Mitspieler und Wegabdeckung")
struct AutoplayerTests {
    @Test("Abdeckung: gerader Weg durch die Kreismitte ergibt den Durchmesser")
    func coverageThroughCenter() {
        let path = PathGeometry(points: [Point(x: 0, y: 0), Point(x: 10, y: 0)])
        #expect(abs(path.coverage(around: Point(x: 5, y: 0), radius: 2) - 4) < 1e-12)
    }

    @Test("Abdeckung: Sehne, Rand, außerhalb und über zwei Abschnitte")
    func coverageCases() {
        let path = PathGeometry(points: [Point(x: 0, y: 0), Point(x: 10, y: 0), Point(x: 10, y: 10)])
        // Abstand 3, Radius 5: Sehne 2 × 4.
        #expect(abs(path.coverage(around: Point(x: 5, y: 3), radius: 5) - 8) < 1e-12)
        #expect(path.coverage(around: Point(x: 5, y: 6), radius: 5) == 0)
        // Ecke: je 2 Felder auf beiden Abschnitten.
        #expect(abs(path.coverage(around: Point(x: 10, y: 0), radius: 2) - 4) < 1e-12)
        // Am Wegende abgeschnitten.
        #expect(abs(path.coverage(around: Point(x: 0, y: 0), radius: 2) - 2) < 1e-12)
    }

    @Test("Abdeckung stimmt mit der Abtastung überein")
    func coverageMatchesSampling() throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        let center = Cell(x: 11, y: 4).center
        var sampled = 0, d = 0.0
        while d < sim.map.path.length {
            if sim.map.path.position(at: d).distance(to: center) <= 2.5 { sampled += 1 }
            d += 0.001
        }
        #expect(abs(sim.map.path.coverage(around: center, radius: 2.5) - Double(sampled) * 0.001) < 0.01)
    }

    @Test("Vorführbauweise kommt aus der Konfiguration und gewinnt Mission 1")
    func demoWins() throws {
        let config = try BalanceConfig.missionOne()
        let sim = Simulation(config: config)
        var player = Autoplayer(demoOf: config)
        #expect(!player.order.isEmpty)
        var state = sim.newGame(seed: 1)
        while !state.isOver && state.tick < 200_000 {
            sim.step(&state, commands: player.commands(for: state, in: sim))
        }
        #expect(state.outcome == .won)
        #expect(state.towers.count > 10)
    }

    @Test("Baut nur, was er bezahlen kann, und nie auf belegte Zellen")
    func respectsGoldAndCells() throws {
        let sim = Simulation(config: try BalanceConfig.missionOne())
        var player = Autoplayer(order: [.watch, .watch, .watch, .watch])
        let state = sim.newGame(seed: 1)
        let commands = player.commands(for: state, in: sim)
        // Startgold 150, Wachturm 50: genau drei.
        #expect(commands.count == 3)
        let cells = commands.compactMap { if case .build(_, let cell) = $0 { cell } else { nil } }
        #expect(Set(cells).count == 3)
        #expect(player.order.count == 1)
    }
}
