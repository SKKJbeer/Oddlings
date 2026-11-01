import Foundation
import Testing
@testable import OddlingsCore

/// Zwergenbank (D-026, 04 „Zwergenbank“, P2-5). Eigene Testwerte, damit eine
/// Balanceänderung an Mission 2 keinen Regeltest bricht.
@Suite("Zwergenbank")
struct BankTests {
    static let bank = BankConfig(cost: 100, delay: 2, interval: 1, payout: 5, cap: 12, limit: 2)
    let sim: Simulation
    let a = Cell(x: 0, y: 3), b = Cell(x: 1, y: 3), c = Cell(x: 2, y: 3)

    init() {
        var config = TestConfig.make()
        config.bank = Self.bank
        // Keine Welle in Sicht: Der Ertrag soll nicht vom Sieg beendet werden.
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    /// Läuft bis einschließlich `tick` und sammelt die Ereignisse.
    private func run(_ state: inout GameState, through tick: Int) -> [Event] {
        var events: [Event] = []
        while state.tick <= tick { events += sim.step(&state) }
        return events
    }

    @Test("Bauen kostet den Preis aus dem Abschnitt bank und merkt sich den Bau-Tick")
    func build() {
        var state = sim.newGame(seed: 1)
        _ = run(&state, through: 9)
        #expect(sim.step(&state, commands: [.build(.bank, a)]) == [.towerBuilt(id: 1)])
        #expect(state.gold == 1_000 - 100)
        #expect(state.towers.first?.builtTick == 10)
        #expect(state.towers.first?.kind == .bank)
    }

    @Test("Erste Auszahlung genau nach delay + interval, dann je interval")
    func firstPayout() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.bank, a)])
        let gold = state.gold
        let first = sim.ticks(Self.bank.delay + Self.bank.interval)
        #expect(run(&state, through: first - 1).isEmpty)
        #expect(state.gold == gold)
        #expect(sim.step(&state) == [.bankPaid(towerID: 1, gold: 5, paid: 5)])
        #expect(state.gold == gold + 5)
        #expect(run(&state, through: first + sim.ticks(Self.bank.interval) - 1) == [])
        #expect(sim.step(&state) == [.bankPaid(towerID: 1, gold: 5, paid: 10)])
    }

    @Test("Die letzte Auszahlung füllt nur bis zum Deckel, danach steht die Bank leer")
    func cap() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.bank, a)])
        let gold = state.gold
        let events = run(&state, through: 600)
        let paid = events.compactMap { if case .bankPaid(_, let gold, _) = $0 { gold } else { nil } }
        #expect(paid == [5, 5, 2])
        #expect(events.filter { $0 == .bankEmptied(towerID: 1) }.count == 1)
        #expect(state.gold == gold + Self.bank.cap)
        #expect(state.towers.first?.paid == Self.bank.cap)
    }

    @Test("Mehr Banken als limit werden abgelehnt, eine verkaufte zählt nicht mehr")
    func limit() {
        var state = sim.newGame(seed: 1)
        let third = Command.build(.bank, c)
        let events = sim.step(&state, commands: [.build(.bank, a), .build(.bank, b), third])
        #expect(events.last == .commandRejected(third, reason: .limitReached))
        #expect(sim.banks(in: state) == 2)
        #expect(state.gold == 1_000 - 200)
        sim.step(&state, commands: [.sell(towerID: 1)])
        #expect(sim.step(&state, commands: [third]) == [.towerBuilt(id: 3)])
    }

    @Test("Zu wenig Gold für die Bank")
    func notEnoughGold() {
        var state = sim.newGame(seed: 1)
        state.gold = 99
        let command = Command.build(.bank, a)
        #expect(sim.step(&state, commands: [command]) == [.commandRejected(command, reason: .notEnoughGold)])
    }

    @Test("Verkaufen erstattet nach Baukosten, unabhängig vom Ertrag")
    func sellAfterPayout() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.bank, a)])
        _ = run(&state, through: 600)
        let gold = state.gold
        #expect(sim.step(&state, commands: [.sell(towerID: 1)]) == [.towerSold(id: 1, refund: 50)])
        #expect(state.gold == gold + 50)
    }

    @Test("Die Bank schießt nicht")
    func doesNotFire() {
        var config = sim.config
        config.mission.firstWaveDelay = 0
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        state.enemies = [TestConfig.enemy(99, at: 0.5)]
        state.nextWaveTick = nil
        sim.step(&state, commands: [.build(.bank, Cell(x: 0, y: 1))])
        let events = run(&state, through: 30)
        #expect(!events.contains { if case .towerFired = $0 { true } else { false } })
    }

    @Test("Ohne Abschnitt bank gibt es keine Bank")
    func missionWithoutBank() {
        let sim = Simulation(config: TestConfig.make())
        var state = sim.newGame(seed: 1)
        let command = Command.build(.bank, a)
        #expect(sim.step(&state, commands: [command]).first == .commandRejected(command, reason: .unknownTower))
        #expect(state.towers.isEmpty)
        #expect(sim.config.buildable == TowerKind.combat)
        #expect(self.sim.config.buildable == TowerKind.combat + [.bank])
    }

    @Test("Ein Volk mit Preisfaktor auf bank verbilligt auch die Bank")
    func raceCostFactor() {
        let race = RaceConfig(ability: AbilityConfig(kind: .bulwark, cooldown: 30, snapDistance: 1, duration: 4),
                              costFactor: [.bank: 0.8])
        #expect(sim.config.applying(race).cost(of: .bank) == 80)
    }

    @Test("Zustände ohne Bankfelder bleiben lesbar")
    func decodesOldTower() throws {
        let json = #"{"id":1,"kind":"watch","cell":{"x":0,"y":0},"cooldownTicks":0,"spent":50}"#
        let tower = try JSONDecoder().decode(Tower.self, from: Data(json.utf8))
        #expect(tower.builtTick == 0 && tower.paid == 0)
    }
}

@Suite("Bonus für frühes Rufen")
struct EarlyCallTests {
    let sim: Simulation

    init() {
        var config = TestConfig.make()
        config.mission.firstWaveDelay = 20
        config.mission.earlyCallBonus = 0.5
        sim = Simulation(config: config)
    }

    @Test("Eingesparte Sekunden mal Bonus, abgerundet, im selben Tick")
    func bonus() {
        var state = sim.newGame(seed: 1)
        // 20 s gespart × 0,5 = 10 Gold.
        let gold = state.gold
        let events = sim.step(&state, commands: [.callNextWave])
        #expect(events.first == .earlyCallBonus(gold: 10))
        #expect(state.gold == gold + 10)
    }

    @Test("Die Vorschau zeigt, was der Befehl gutschreibt, und sinkt mit der Zeit")
    func preview() {
        var state = sim.newGame(seed: 1)
        for _ in 0..<sim.ticks(5.5) { sim.step(&state) }
        // 14,5 s × 0,5 = 7,25 → 7
        #expect(sim.earlyCallBonus(in: state) == 7)
        let gold = state.gold
        sim.step(&state, commands: [.callNextWave])
        #expect(state.gold == gold + 7)
    }

    @Test("Ohne Wert kein Bonus")
    func noBonusWithoutValue() {
        let sim = Simulation(config: TestConfig.make())
        var state = sim.newGame(seed: 1)
        state.nextWaveTick = 300
        #expect(sim.earlyCallBonus(in: state) == 0)
        #expect(!sim.step(&state, commands: [.callNextWave]).contains { if case .earlyCallBonus = $0 { true } else { false } })
    }

    @Test("Ohne ausstehende Welle kein Bonus")
    func noWaveLeft() {
        var state = sim.newGame(seed: 1)
        state.nextWaveTick = nil
        #expect(sim.earlyCallBonus(in: state) == 0)
        let gold = state.gold
        #expect(sim.step(&state, commands: [.callNextWave]).first == .commandRejected(.callNextWave, reason: .noWaveLeft))
        #expect(state.gold == gold)
    }
}
