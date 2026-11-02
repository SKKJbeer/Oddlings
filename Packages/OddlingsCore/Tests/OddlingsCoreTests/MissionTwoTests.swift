import Testing
@testable import OddlingsCore

/// Mission 2 „Zwergenbank“ (P2-5). Werte sind Hypothese bis nach WP-15; die
/// Tests halten Beziehungen fest, keine genauen Zahlen (testing-strategy.md).
@Suite("Mission 2")
struct MissionTwoTests {
    let sim: Simulation
    let strategies: [(name: String, order: [StrategyStep])]

    init() throws {
        let config = try BalanceConfig.bundledMission(named: "mission-02")
        sim = Simulation(config: config)
        strategies = Strategies.of(config)
    }

    private func order(_ name: String) throws -> [StrategyStep] {
        try #require(strategies.first { $0.name == name }).order
    }

    @Test("Die Datei ist gültig, bietet die Bank und den Bonus, Mission 1 keins von beiden")
    func offersBankAndBonus() throws {
        #expect(sim.config.mission.id == "mission-02")
        #expect(sim.config.buildable.contains(.bank))
        #expect((sim.config.mission.earlyCallBonus ?? 0) > 0)
        let one = try BalanceConfig.missionOne()
        #expect(one.bank == nil && one.mission.earlyCallBonus == nil, "M1 bleibt für den Spieltest unverändert")
        #expect(sim.config.map.path != one.map.path, "eigener Weg")
    }

    @Test("Zwischen den Schleifen gibt es Bauplätze abseits des Wegs")
    func quietCellsExist() {
        let quiet = sim.map.buildableCells.filter { sim.map.path.distance(from: $0.center) >= 2.5 }
        #expect(quiet.count >= 4, "\(quiet.count)")
    }

    @Test("Mischungen gewinnen mit und ohne Bank, die Monokultur verliert")
    func outcomes() throws {
        for name in ["Mix ohne Bank", "Mix mit Bank", "Mix, Bank spät"] {
            #expect(sim.play(try order(name)).state.outcome == .won, "\(name)")
        }
        #expect(sim.play(try order("Nur Wachtürme")).state.outcome == .lost)
    }

    /// Kennzahl aus 04: Die Bank ist weder Pflicht noch bedeutungslos.
    @Test("Die beste Bauweise mit Bank liegt höchstens 0,05 Reserve neben der besten ohne")
    func bankIsAChoice() throws {
        let withBank = try ["Mix mit Bank", "Mix, Bank spät"].map { sim.reserve(try order($0)) }.max() ?? 0
        let without = sim.reserve(try order("Mix ohne Bank"))
        #expect(abs(withBank - without) <= 0.05, "mit \(withBank), ohne \(without)")
    }

    /// 04: Die 100 Gold fehlen in den ersten Wellen. Wer gierig beide Banken
    /// zuerst baut, soll das spüren.
    @Test("Zwei Banken vor jedem Turm sind ein Risiko")
    func greedHurts() throws {
        #expect(sim.reserve(try order("Zwei Banken zuerst")) < sim.reserve(try order("Mix ohne Bank")))
    }

    @Test("Eine früh gebaute Bank zahlt ihren Deckel aus, jede ihren Preis zurück")
    func banksPayOut() throws {
        let run = sim.play(try order("Mix mit Bank"))
        let bank = try #require(sim.config.bank)
        let banks = run.state.towers.filter { $0.kind == .bank }
        #expect(banks.count == bank.limit)
        #expect(banks.first?.paid == bank.cap, "\(banks.map(\.paid))")
        #expect(banks.allSatisfy { $0.paid >= bank.cost }, "\(banks.map(\.paid))")
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() throws {
        let mix = try order("Mix mit Bank")
        #expect(sim.play(mix, seed: 7).state == sim.play(mix, seed: 7).state)
    }

    /// 03: Völker helfen, ersetzen aber keine Türme; gleiche Grenze wie in M1.
    @Test("Jedes Volk hebt die Reserve auch in M2 um höchstens 0,1")
    func racesBounded() throws {
        let mix = try order("Mix mit Bank")
        var plain = sim.config
        plain.ability = nil
        let without = Simulation(config: plain).reserve(mix)
        let table = try RaceTable.bundled()
        for race in Race.allCases {
            let with = Simulation(config: sim.config.applying(try #require(table[race]))).reserve(mix, castsAbility: true)
            #expect(with >= without, "\(race) hilft")
            #expect(with <= without + 0.1, "\(race): \(with) gegen \(without)")
        }
    }
}
