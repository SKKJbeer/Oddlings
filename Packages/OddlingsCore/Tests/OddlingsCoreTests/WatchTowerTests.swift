import Testing
@testable import OddlingsCore

@Suite("Wachturm, Schaden, Belohnung")
struct WatchTowerTests {
    let sim: Simulation

    init() throws { sim = Simulation(config: try BalanceConfig.missionOne()) }

    /// Gegner direkt in den Zustand legen, um Zielwahl ohne Wellen zu prüfen.
    private func enemy(_ id: Int, at distance: Double, hp: Double = 70) -> Enemy {
        Enemy(id: id, kind: .raider, hp: hp, maxHP: hp, distance: distance)
    }

    /// Bauplätze wie im Prüfskript: größte Wegabdeckung in Reichweite, Abtastung
    /// alle 0,25 Felder, bei Gleichstand der erste in x-dann-y-Reihenfolge.
    private func bestCells(range: Double, count: Int) -> [Cell] {
        let candidates = sim.map.buildableCells.sorted { ($0.x, $0.y) < ($1.x, $1.y) }
        var chosen: [Cell] = []
        for _ in 0..<count {
            var best: Cell?, bestValue = -1.0
            for cell in candidates where !chosen.contains(cell) {
                var covered = 0, d = 0.0
                while d < sim.map.path.length {
                    if sim.map.path.position(at: d).distance(to: cell.center) <= range { covered += 1 }
                    d += 0.25
                }
                if Double(covered) * 0.25 > bestValue { best = cell; bestValue = Double(covered) * 0.25 }
            }
            chosen.append(best!)
        }
        return chosen
    }

    private func waveOne(towers: Int) throws -> (leaks: Int, kills: Int, gold: Int) {
        var config = try BalanceConfig.missionOne()
        config.waves = Array(config.waves.prefix(1))
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        let cells = bestCells(range: config.towers[.watch]!.range, count: towers)
        sim.step(&state, commands: cells.map { .build(.watch, $0) })
        var leaks = 0, kills = 0
        while state.tick < 5_000 && !(state.waveIndex == 0 && state.pendingSpawns.isEmpty && state.enemies.isEmpty) {
            for event in sim.step(&state) {
                if case .enemyLeaked = event { leaks += 1 }
                if case .enemyKilled = event { kills += 1 }
            }
        }
        return (leaks, kills, state.gold)
    }

    @Test("Bauplätze wie im Prüfskript")
    func sameCellsAsBalanceSim() {
        #expect(bestCells(range: 2.5, count: 2) == [Cell(x: 11, y: 4), Cell(x: 11, y: 3)])
    }

    @Test("Abnahme: zwei Wachtürme halten Welle 1, einer lässt 6 von 8 durch")
    func acceptance() throws {
        let two = try waveOne(towers: 2)
        #expect(two.leaks == 0)
        #expect(two.kills == 8)
        #expect(two.gold == 150 - 2 * 50 + 8 * 5)
        let one = try waveOne(towers: 1)
        #expect(one.leaks == 6)
        #expect(one.kills == 2)
    }

    @Test("Zielwahl: der weiteste von zwei Gegnern in Reichweite")
    func targetsFirst() {
        let center = sim.map.path.position(at: 10)
        let enemies = [enemy(1, at: 9.5), enemy(2, at: 10.5)]
        #expect(sim.firstTarget(in: enemies, around: center, range: 2) == 1)
    }

    @Test("Zielwahl: bei Gleichstand der ältere, außer Reichweite niemand")
    func tieAndRange() {
        let center = sim.map.path.position(at: 10)
        #expect(sim.firstTarget(in: [enemy(1, at: 10), enemy(2, at: 10)], around: center, range: 2) == 0)
        #expect(sim.firstTarget(in: [enemy(1, at: 20)], around: center, range: 2) == nil)
    }

    @Test("Zielwahl überspringt schon tödlich Getroffene")
    func skipsDead() {
        let center = sim.map.path.position(at: 10)
        let enemies = [enemy(1, at: 9.5), enemy(2, at: 10.5, hp: 0)]
        #expect(sim.firstTarget(in: enemies, around: center, range: 2) == 0)
    }

    @Test("Abklingzeit 0,8 s = 24 Ticks")
    func cooldown() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, Cell(x: 3, y: 3))])
        // Ein zäher Gegner direkt vor dem Turm, damit jeder Schuss trifft.
        state.enemies = [enemy(99, at: 5.5, hp: 10_000)]
        var shots: [Int] = []
        for _ in 0..<100 {
            let tick = state.tick
            let events = sim.step(&state)
            if events.contains(where: { if case .towerFired = $0 { true } else { false } }) { shots.append(tick) }
        }
        #expect(shots.count >= 3)
        #expect(zip(shots, shots.dropFirst()).allSatisfy { $1 - $0 == 24 })
    }

    @Test("Belohnung genau einmal, auch wenn zwei Türme im selben Tick bereit sind")
    func rewardOnce() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, Cell(x: 3, y: 3)), .build(.watch, Cell(x: 3, y: 2))])
        state.enemies = [enemy(99, at: 5.5, hp: 12)]
        let goldBefore = state.gold
        let events = sim.step(&state)
        let kills = events.filter { if case .enemyKilled = $0 { true } else { false } }
        let shots = events.filter { if case .towerFired = $0 { true } else { false } }
        #expect(kills == [.enemyKilled(id: 99, reward: 5)])
        #expect(shots.count == 1)
        #expect(state.gold == goldBefore + 5)
        #expect(state.enemies.isEmpty)
    }

    @Test("Ein bereiter Turm ohne Ziel bleibt bereit")
    func staysReady() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, Cell(x: 3, y: 3))])
        for _ in 0..<50 { sim.step(&state) }
        #expect(state.towers[0].cooldownTicks == 0)
        state.enemies = [enemy(99, at: 5.5, hp: 10_000)]
        let events = sim.step(&state)
        #expect(events.contains(.towerFired(towerID: 1, targets: [99])))
    }
}
