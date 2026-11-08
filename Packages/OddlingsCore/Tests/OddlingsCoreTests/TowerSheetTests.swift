import Foundation
import Testing
@testable import OddlingsCore

/// Wertetafel und Vorher-nachher am Turm (D-130). Eigene Testwerte, damit
/// eine Balanceänderung keinen Tafeltest bricht.
@Suite("Turmwerte")
struct TowerSheetTests {
    let config: BalanceConfig

    init() {
        var config = TestConfig.make()
        config.upgrades = [
            .watch: UpgradeConfig(cost: 7, scale: [.damage: 1.5]),
            .lightning: UpgradeConfig(cost: 7, scale: [.damage: 2]),
            .spore: UpgradeConfig(cost: 7, scale: [.range: 1.5, .slowFactor: 0.8]),
        ]
        config.specializations = [
            .volley: SpecializationConfig(cost: 9, targets: 3),
            .falconHold: SpecializationConfig(cost: 9, scale: [.damage: 2, .attackInterval: 2, .range: 1.2]),
            .rot: SpecializationConfig(cost: 9, vulnerableFactor: 1.4),
        ]
        self.config = config
    }

    private func sheet(_ kind: TowerKind, level: Int = 1) throws -> TowerSheet {
        TowerSheet(kind: kind, stats: try #require(config.stats(of: kind, level: level)))
    }

    private func sheet(_ special: Specialization) throws -> TowerSheet {
        TowerSheet(kind: special.tower, stats: try #require(config.stats(of: special.tower, specialization: special)))
    }

    private func close(_ a: Double?, _ b: Double) -> Bool { abs((a ?? .nan) - b) < 1e-9 }

    @Test("Wachturm: Schaden je Sekunde vorn, dann Schaden, Tempo, Reichweite")
    func watch() throws {
        let watch = try sheet(.watch)
        #expect(watch.readings.map(\.figure) == [.damagePerSecond, .damage, .rate, .range])
        #expect(close(watch.value(.damagePerSecond), 10))
        #expect(close(watch.value(.rate), 1))
        #expect(close(watch.value(.range), 3))
    }

    @Test("Blitzturm: Schaden je Sekunde über die volle Kette mit Abfall")
    func lightningChain() throws {
        let lightning = try sheet(.lightning)
        // 18 × (1 + 0,8 + 0,64 + 0,512 + 0,4096)
        #expect(close(lightning.value(.damagePerSecond), 18 * 3.3616))
        #expect(lightning.value(.chainTargets) == 5)
        #expect(lightning.value(.damage) == 18, "erster Treffer")
    }

    @Test("Sporenturm: Bremse als Anteil, kein Schaden je Sekunde")
    func spore() throws {
        let spore = try sheet(.spore)
        #expect(spore.readings.first?.figure == .slow)
        #expect(close(spore.value(.slow), 0.5))
        #expect(spore.value(.damagePerSecond) == nil, "seine Wirkung ist die Kontrolle")
    }

    @Test("Die Bank hat keine Kampfwerte")
    func bank() {
        let bank = TowerConfig(cost: 1, range: 0, damage: 0, attackInterval: 1, targeting: .first)
        #expect(TowerSheet(kind: .bank, stats: bank).readings.isEmpty)
    }

    @Test("Aufwerten: jede Kennzahl alt und neu, was gleich bleibt, ist gleich")
    func upgradeChanges() throws {
        let changes = try sheet(.watch).changes(to: try sheet(.watch, level: 2))
        #expect(changes.map(\.figure) == [.damagePerSecond, .damage, .rate, .range])
        #expect(close(changes[0].ratio, 0.5))
        #expect(close(changes[1].difference, 5))
        #expect(changes[2].isUnchanged)
        #expect(changes[3].isUnchanged)
    }

    @Test("Sporenturm II: Bremse von 50 auf 60 Prozent, Reichweite +50 Prozent")
    func sporeUpgrade() throws {
        let changes = try sheet(.spore).changes(to: try sheet(.spore, level: 2))
        let slow = try #require(changes.first { $0.figure == .slow })
        #expect(close(slow.after, 0.6))
        #expect(close(slow.difference, 0.1))
        let range = try #require(changes.first { $0.figure == .range })
        #expect(close(range.ratio, 0.5))
    }

    @Test("Salve: neue Kennzahl Ziele kommt von eins, Schaden je Sekunde verdreifacht")
    func volley() throws {
        let changes = try sheet(.watch, level: 2).changes(to: try sheet(.volley))
        let targets = try #require(changes.first { $0.figure == .targets })
        #expect(targets.before == 1)
        #expect(targets.after == 3)
        #expect(close(changes.first?.ratio, 2))
    }

    @Test("Falkenhorst: ein Tausch zeigt ein Minus beim Tempo")
    func falconTradeOff() throws {
        let changes = try sheet(.watch, level: 2).changes(to: try sheet(.falconHold))
        let rate = try #require(changes.first { $0.figure == .rate })
        #expect(close(rate.ratio, -0.5))
        #expect(changes.first?.isUnchanged == true, "doppelter Schaden, halbes Tempo")
    }

    @Test("Fäulnis: Zusatzschaden kommt von null")
    func rot() throws {
        let changes = try sheet(.spore, level: 2).changes(to: try sheet(.rot))
        let vulnerable = try #require(changes.first { $0.figure == .vulnerable })
        #expect(vulnerable.before == 0)
        #expect(close(vulnerable.after, 0.4))
    }

    @Test("Volk und Ausrüstung stecken in den Werten: Tafel rechnet nur aus der Konfiguration")
    func followsConfig() throws {
        var boosted = config
        boosted.towers[.watch]?.damage = 20
        let stats = try #require(boosted.stats(of: .watch, level: 2))
        #expect(close(TowerSheet(kind: .watch, stats: stats).value(.damage), 30))
    }
}

/// Kampfbilanz je Turm (D-130): was die Simulation dem Schützen gutschreibt.
@Suite("Kampfbilanz")
struct TowerTallyTests {
    @Test("Wachturm: Schaden bis zum Restleben, der tödliche Treffer zählt als erledigt")
    func watchTally() {
        var config = TestConfig.make()
        config.mission.firstWaveDelay = 600
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.watch, Cell(x: 2, y: 1))])
        state.enemies = [TestConfig.enemy(90, at: 2, hp: 15)]
        for _ in 0..<70 { sim.step(&state, commands: []) }
        let tower = state.towers[0]
        #expect(tower.kills == 1)
        #expect(tower.damageDealt == 15, "10 + 5, der Überschuss des zweiten Schusses zählt nicht")
    }

    @Test("Blitzturm: jeder Kettentreffer zählt für den Turm")
    func lightningTally() {
        var config = TestConfig.make()
        config.mission.firstWaveDelay = 600
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.lightning, Cell(x: 2, y: 1))])
        state.enemies = [TestConfig.enemy(90, at: 2.5), TestConfig.enemy(91, at: 2)]
        sim.step(&state, commands: [])
        #expect(abs(state.towers[0].damageDealt - (18 + 18 * 0.8)) < 1e-9)
        #expect(state.towers[0].kills == 0)
    }

    @Test("Sporenturm zählt gebremste Treffer")
    func sporeTally() {
        var config = TestConfig.make()
        config.mission.firstWaveDelay = 600
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.spore, Cell(x: 2, y: 1))])
        state.enemies = [TestConfig.enemy(90, at: 2.5), TestConfig.enemy(91, at: 2)]
        sim.step(&state, commands: [])
        #expect(state.towers[0].slowHits == 2)
    }

    @Test("Ein alter Spielstand ohne Bilanz bleibt lesbar")
    func decodesWithoutTally() throws {
        let json = #"{"id":1,"kind":"watch","cell":{"x":1,"y":1},"cooldownTicks":0,"spent":10}"#
        let tower = try JSONDecoder().decode(Tower.self, from: Data(json.utf8))
        #expect(tower.damageDealt == 0 && tower.kills == 0 && tower.slowHits == 0)
    }

    @Test("Bilanz übersteht Speichern und Laden")
    func roundTrip() throws {
        var tower = Tower(id: 1, kind: .watch, cell: Cell(x: 1, y: 1), cooldownTicks: 0, spent: 10)
        tower.damageDealt = 123.5
        tower.kills = 4
        let copy = try JSONDecoder().decode(Tower.self, from: JSONEncoder().encode(tower))
        #expect(copy == tower)
    }
}
