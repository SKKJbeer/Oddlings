import Testing
@testable import OddlingsCore

/// Balancetests (testing-strategy.md, Regel 3): Beziehungen zwischen Bauweisen,
/// keine genauen Zahlen. Grundlage sind die Bauweisen aus `simStrategies`.
@Suite("Balance Mission 1")
struct BalanceTests {
    let sim: Simulation
    let strategies: [(name: String, order: [TowerKind])]

    init() throws {
        sim = Simulation(config: try BalanceConfig.missionOne())
        strategies = try Strategies.missionOne()
    }

    private func order(_ prefix: String) throws -> [TowerKind] {
        try #require(strategies.first { $0.name.hasPrefix(prefix) }).order
    }

    @Test("Jede Mischung gewinnt, jede Monokultur außer Wachtürmen verliert")
    func outcomes() throws {
        for name in ["Mix", "Wach + Blitz", "Wach + Sporen", "Blitz + Sporen", "Nur Wachtürme"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        for name in ["Nur Blitztürme", "Nur Sporentürme"] {
            #expect(sim.play(try order(name)).state.outcome == .lost, "\(name)")
        }
    }

    @Test("Die Kernsynergie trägt: Blitz mit Sporen weit vor Blitz allein, Mischung vor Monokultur")
    func synergy() throws {
        let lightningSpore = sim.reserve(try order("Blitz + Sporen"))
        let lightningOnly = sim.reserve(try order("Nur Blitztürme"))
        let mix = sim.reserve(try order("Mix"))
        let watchOnly = sim.reserve(try order("Nur Wachtürme"))
        #expect(lightningSpore > lightningOnly + 0.3)
        #expect(mix > watchOnly + 0.1)
        // Mission 1 soll leicht bleiben: Selbst Monokultur hat etwas Luft.
        #expect(watchOnly > 1.0)
    }
}
