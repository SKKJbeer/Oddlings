import Foundation
import Testing
@testable import OddlingsCore

/// Die drei Spezialisierungen der Ruinen (P3-2, D-077). Eigene Testwerte, damit
/// eine Balanceänderung an Mission 5b keinen Regeltest bricht.
@Suite("Spezialisieren in den Ruinen")
struct RuinSpecializationTests {
    static let specializations: [Specialization: SpecializationConfig] = [
        .falconHold: SpecializationConfig(cost: 9, scale: [.range: 2, .damage: 2, .attackInterval: 1.5]),
        .sparkColumn: SpecializationConfig(cost: 9, scale: [.damage: 2], extraJumps: -2),
        .rot: SpecializationConfig(cost: 9, vulnerableFactor: 1.5),
    ]
    let sim: Simulation
    let cell = Cell(x: 5, y: 2)

    init() {
        var config = TestConfig.make()
        config.upgrades = UpgradeTests.upgrades
        config.specializations = Self.specializations
        config.mission.firstWaveDelay = 600
        sim = Simulation(config: config)
    }

    private func specialized(_ kind: TowerKind, _ specialization: Specialization) -> GameState {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(kind, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        sim.step(&state, commands: [.specialize(towerID: 1, specialization)])
        return state
    }

    @Test("Jede gehört zu ihrem Turm, und die Ruinen bieten genau sie an")
    func towers() {
        #expect(Specialization.falconHold.tower == .watch)
        #expect(Specialization.sparkColumn.tower == .lightning)
        #expect(Specialization.rot.tower == .spore)
        #expect(sim.config.specializations(for: .spore) == [.rot])
        #expect(sim.config.issues().isEmpty)
    }

    @Test("Fäulnis: Was der Puls verlangsamt, ist so lange verwundbar, und der Puls selbst trifft nicht stärker")
    func rotMakesSlowedVulnerable() throws {
        var state = specialized(.spore, .rot)
        state.enemies = [TestConfig.enemy(7, at: 5)]
        state.towers[0].cooldownTicks = 0
        let events = sim.step(&state)
        #expect(events.contains(.enemyDamaged(id: 7, amount: 1)), "Pulsschaden ohne Faktor: \(events)")
        let enemy = try #require(state.enemies.first)
        let mark = try #require(enemy.vulnerable)
        #expect(mark.factor == 1.5)
        #expect(mark.untilTick == enemy.slow?.untilTick, "so lange wie die Verlangsamung")
        var hit = enemy
        #expect(sim.hurt(&hit, by: 10, tick: state.tick) == 15, "jeder Turm trifft stärker")
        #expect(sim.hurt(&hit, by: 10, tick: mark.untilTick) == 10, "danach nicht mehr")
    }

    @Test("Fäulnis stapelt nicht mit dem Mondmal: Es gilt der stärkere Faktor")
    func rotDoesNotStackWithMoonMark() throws {
        var state = specialized(.spore, .rot)
        var enemy = TestConfig.enemy(7, at: 5)
        enemy.vulnerable = VulnerableEffect(factor: 2, untilTick: 10_000)
        state.enemies = [enemy]
        state.towers[0].cooldownTicks = 0
        sim.step(&state)
        #expect(state.enemies.first?.vulnerable == VulnerableEffect(factor: 2, untilTick: 10_000))
    }

    @Test("Ohne Fäulnis macht der Sporenturm nichts verwundbar")
    func plainSporesDoNotMark() {
        var state = sim.newGame(seed: 1)
        sim.step(&state, commands: [.build(.spore, cell)])
        sim.step(&state, commands: [.upgrade(towerID: 1)])
        state.enemies = [TestConfig.enemy(7, at: 5)]
        state.towers[0].cooldownTicks = 0
        sim.step(&state)
        #expect(state.enemies.first?.slow != nil)
        #expect(state.enemies.first?.vulnerable == nil)
    }

    @Test("Funkensäule: erster Treffer stärker, zwei Sprünge weniger")
    func sparkColumn() throws {
        let column = try #require(sim.config.stats(of: .lightning, specialization: .sparkColumn))
        let enemies = (0..<8).map { TestConfig.enemy($0, at: 10 + Double($0)) }
        let chain = sim.chainTargets(in: enemies, from: 0, stats: column, tick: 100)
        #expect(chain.count == 3, "eins plus zwei Sprünge")
        #expect(abs((chain.first?.damage ?? 0) - 18 * 2 * 2) < 1e-9)
    }

    @Test("Falkenhorst rechnet von Stufe 2 aus: weiter, schwerer, langsamer")
    func falconHold() throws {
        let second = try #require(sim.config.stats(of: .watch, level: 2))
        let falcon = try #require(sim.config.stats(of: .watch, specialization: .falconHold))
        #expect(falcon.range == second.range * 2)
        #expect(falcon.damage == second.damage * 2)
        #expect(falcon.attackInterval == second.attackInterval * 1.5)
    }

    @Test("Prüfung: Kette nicht unter null, Fäulnis nur am Sporenturm und über 1")
    func validation() {
        var config = sim.config
        config.specializations = [
            .sparkColumn: SpecializationConfig(cost: 9, extraJumps: -5),
            .rot: SpecializationConfig(cost: 9, vulnerableFactor: 1),
            .falconHold: SpecializationConfig(cost: 9, vulnerableFactor: 2),
        ]
        let rules = config.issues().map { "\($0.field) \($0.rule)" }
        #expect(rules.contains("specializations.sparkColumn.extraJumps mustNotBeNegative"))
        #expect(rules.contains("specializations.rot.vulnerableFactor mustExceedOne"))
        #expect(rules.contains("specializations.falconHold.vulnerableFactor statNotInTower"))
    }
}
