import Testing
@testable import OddlingsCore

@Suite("Blitzturm")
struct LightningTests {
    let sim = Simulation(config: TestConfig.make())
    var stats: TowerConfig { sim.config.towers[.lightning]! }

    private func ids(_ chain: [(index: Int, damage: Double)], _ enemies: [Enemy]) -> [Int] {
        chain.map { enemies[$0.index].id }
    }

    private func close(_ a: [Double], _ b: [Double]) -> Bool {
        a.count == b.count && zip(a, b).allSatisfy { abs($0 - $1) < 1e-9 }
    }

    @Test("Drei Gegner im Abstand 1,0: drei Treffer nach Nähe, 18 / 14,4 / 11,52")
    func referenceCase() {
        // Fall aus testing-strategy.md, Regel 1.
        let enemies = [TestConfig.enemy(1, at: 10), TestConfig.enemy(2, at: 11), TestConfig.enemy(3, at: 12)]
        let chain = sim.chainTargets(in: enemies, from: 2, stats: stats)
        #expect(ids(chain, enemies) == [3, 2, 1])
        #expect(close(chain.map(\.damage), [18, 14.4, 11.52]))
    }

    @Test("Kette bricht ab, wenn niemand im Radius ist")
    func breaksWhenNobodyInRadius() {
        let enemies = [TestConfig.enemy(1, at: 10), TestConfig.enemy(2, at: 11.2), TestConfig.enemy(3, at: 13)]
        let chain = sim.chainTargets(in: enemies, from: 1, stats: stats)
        #expect(ids(chain, enemies) == [2, 1])
    }

    @Test("Radius wird vom letzten Ziel aus gemessen, nicht vom ersten")
    func radiusFromLastTarget() {
        // 10 → 11,2 → 12,4: der dritte ist 2,4 vom ersten entfernt, aber 1,2 vom zweiten.
        let enemies = [TestConfig.enemy(1, at: 12.4), TestConfig.enemy(2, at: 11.2), TestConfig.enemy(3, at: 10)]
        let chain = sim.chainTargets(in: enemies, from: 2, stats: stats)
        #expect(ids(chain, enemies) == [3, 2, 1])
    }

    @Test("Keine Doppeltreffer, auch wenn zwei Gegner hin und her im Radius liegen")
    func noDoubleHits() {
        let enemies = [TestConfig.enemy(1, at: 10), TestConfig.enemy(2, at: 10.5)]
        let chain = sim.chainTargets(in: enemies, from: 1, stats: stats)
        #expect(ids(chain, enemies) == [2, 1])
    }

    @Test("Höchstens chainJumps Sprünge")
    func jumpLimit() {
        let enemies = (1...8).map { TestConfig.enemy($0, at: 10 + Double($0)) }
        let chain = sim.chainTargets(in: enemies, from: 7, stats: stats)
        #expect(chain.count == 1 + 4)
        #expect(ids(chain, enemies) == [8, 7, 6, 5, 4])
    }

    @Test("Bei gleichem Abstand springt die Kette zum älteren Gegner")
    func tieGoesToOlder() {
        let enemies = [TestConfig.enemy(1, at: 9), TestConfig.enemy(2, at: 10), TestConfig.enemy(3, at: 11)]
        let chain = sim.chainTargets(in: enemies, from: 1, stats: stats)
        #expect(ids(chain, enemies).prefix(2) == [2, 1])
    }

    @Test("Tote werden übersprungen")
    func skipsDead() {
        let enemies = [TestConfig.enemy(1, at: 10), TestConfig.enemy(2, at: 11, hp: 0), TestConfig.enemy(3, at: 11.2)]
        let chain = sim.chainTargets(in: enemies, from: 0, stats: stats)
        #expect(ids(chain, enemies) == [1, 3])
    }

    @Test("Im Spiel: Ereignis nennt die Kette in Trefferreihenfolge, Schaden kommt an")
    func inGame() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.lightning, Cell(x: 11, y: 2))])
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = [TestConfig.enemy(10, at: 10.6), TestConfig.enemy(11, at: 11.6), TestConfig.enemy(12, at: 12.6)]
        let events = sim.step(&state)
        #expect(events.first == .towerFired(towerID: 1, targets: [12, 11, 10]))
        #expect(state.enemies.map(\.hp).map { 100 - $0 }.enumerated().allSatisfy { index, lost in
            abs(lost - [11.52, 14.4, 18][index]) < 1e-6
        })
    }
}
