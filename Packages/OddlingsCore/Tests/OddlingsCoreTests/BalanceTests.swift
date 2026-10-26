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

    /// 03: Die Fähigkeit hilft, ersetzt aber keine Türme. Gemessen an der
    /// Mischung, der Bauweise, die ein Spieler am ehesten wählt.
    @Test("Steinregen hebt die Reserve, aber um höchstens 0,1")
    func abilityBounded() throws {
        let mix = try order("Mix")
        let without = sim.reserve(mix)
        let with = sim.reserve(mix, castsAbility: true)
        #expect(with > without)
        #expect(with <= without + 0.1)
    }

    /// 03: Völker verändern den Spielstil, sind aber nie Voraussetzung. Je Volk
    /// gilt dieselbe Grenze wie für den Steinregen, gemessen gegen dieselbe
    /// Mission ohne Fähigkeit; und keins darf dem anderen davonlaufen.
    @Test("Jedes Volk hebt die Reserve um höchstens 0,1, Zwerge und Elfen liegen nah beieinander")
    func racesBounded() throws {
        let mix = try order("Mix")
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        var reserves: [Race: Double] = [:]
        for race in Race.allCases {
            let config = sim.config.applying(try #require(table[race]))
            let with = Simulation(config: config).reserve(mix, castsAbility: true)
            #expect(with > without, "\(race) hilft")
            #expect(with <= without + 0.1, "\(race) ersetzt keine Türme")
            reserves[race] = with
        }
        let dwarves = try #require(reserves[.dwarves]), elves = try #require(reserves[.elves])
        #expect(abs(dwarves - elves) <= 0.05, "kein Volk ist Pflicht")
    }
}
