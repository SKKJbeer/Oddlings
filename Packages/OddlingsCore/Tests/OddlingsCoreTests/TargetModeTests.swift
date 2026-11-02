import Testing
@testable import OddlingsCore

/// Zielwahl ab Stufe 2 (07 „Zielwahl“, P2-6): erster, letzter, stärkster.
@Suite("Zielwahl")
struct TargetModeTests {
    let sim: Simulation
    let center = Point(x: 10, y: 0.5)
    let cell = Cell(x: 10, y: 2)

    init() {
        var config = TestConfig.make()
        config.upgrades = [
            .watch: UpgradeConfig(cost: 5, scale: [.damage: 1.5]),
            .lightning: UpgradeConfig(cost: 5, scale: [.damage: 1.5]),
            .spore: UpgradeConfig(cost: 5, scale: [.range: 1.2]),
        ]
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    private func enemy(_ id: Int, at distance: Double, hp: Double = 100, maxHP: Double? = nil) -> Enemy {
        Enemy(id: id, kind: .raider, hp: hp, maxHP: maxHP ?? hp, distance: distance)
    }

    @Test("Erster: am weitesten vorn; Letzter: am wenigsten weit; bei Gleichstand der ältere")
    func firstAndLast() {
        let enemies = [enemy(1, at: 9), enemy(2, at: 11), enemy(3, at: 8), enemy(4, at: 8)]
        #expect(sim.target(in: enemies, around: center, range: 3, mode: .first) == 1)
        #expect(sim.target(in: enemies, around: center, range: 3, mode: .last) == 2)
        #expect(sim.target(in: [enemy(1, at: 10), enemy(2, at: 10)], around: center, range: 3, mode: .last) == 0)
    }

    @Test("Stärkster nach Höchstleben, nicht nach Restleben; bei Gleichstand der weiter vorn")
    func strongest() {
        let enemies = [enemy(1, at: 11, hp: 90), enemy(2, at: 9, hp: 30, maxHP: 400), enemy(3, at: 10, hp: 100)]
        #expect(sim.target(in: enemies, around: center, range: 3, mode: .strongest) == 1)
        let tie = [enemy(1, at: 9), enemy(2, at: 11), enemy(3, at: 11)]
        #expect(sim.target(in: tie, around: center, range: 3, mode: .strongest) == 1)
    }

    @Test("Keine Wahl außer Reichweite und keine auf schon tödlich Getroffene")
    func skipsDeadAndFar() {
        let enemies = [enemy(1, at: 20, hp: 500), enemy(2, at: 10, hp: 0, maxHP: 400), enemy(3, at: 9)]
        for mode in TargetMode.allCases {
            #expect(sim.target(in: enemies, around: center, range: 3, mode: mode) == 2, "\(mode)")
        }
    }

    @Test("Der Knopf schaltet Erster → Letzter → Stärkster → Erster")
    func cycle() {
        #expect(TargetMode.first.next == .last)
        #expect(TargetMode.last.next == .strongest)
        #expect(TargetMode.strongest.next == .first)
    }

    @Test("Umschalten ab Stufe 2, auf Stufe 1 abgelehnt, gleiche Wahl ohne Ereignis")
    func setMode() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell)])
        let early = Command.setTargetMode(towerID: 1, .last)
        #expect(sim.step(&state, commands: [early]) == [.commandRejected(early, reason: .targetModeLocked)])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        let gold = state.gold
        #expect(sim.step(&state, commands: [.setTargetMode(towerID: 1, .last)]) == [.targetModeChanged(id: 1, mode: .last)])
        #expect(state.towers.first?.targetMode == .last)
        #expect(state.gold == gold, "kostet nichts")
        #expect(sim.step(&state, commands: [.setTargetMode(towerID: 1, .last)]).isEmpty)
    }

    @Test("Der Sporenturm trifft alle und hat keine Zielwahl")
    func sporeLocked() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.spore, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        let command = Command.setTargetMode(towerID: 1, .strongest)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .targetModeLocked)])
    }

    @Test("Ein Wachturm auf „Letzter“ schießt auf den hintersten Gegner")
    func watchUsesMode() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1), .setTargetMode(towerID: 1, .last)])
        state.towers[0].cooldownTicks = 0
        state.enemies = [enemy(20, at: 11), enemy(21, at: 9)]
        #expect(sim.step(&state).contains(.towerFired(towerID: 1, targets: [21])))
    }

    @Test("Die Blitzkette beginnt am gewählten Ziel")
    func lightningStartsAtChoice() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.lightning, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1), .setTargetMode(towerID: 1, .strongest)])
        state.towers[0].cooldownTicks = 0
        state.enemies = [enemy(20, at: 11), Enemy(id: 21, kind: .brute, hp: 400, maxHP: 400, distance: 9.5)]
        let fired = sim.step(&state).compactMap { if case .towerFired(_, let targets) = $0 { targets } else { nil } }
        #expect(fired.first?.first == 21, "\(fired)")
    }
}
