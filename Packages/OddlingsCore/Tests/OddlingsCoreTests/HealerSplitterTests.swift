import Foundation
import Testing
@testable import OddlingsCore

/// Heiler und Teiler (D-143, D-175, D-176). Eigene Werte (testing-strategy.md,
/// Regel 4): Moorhexe heilt alle 2 s im Umkreis von 1 Feld um 6 %, Pilzbalg
/// (100 Leben) zerfällt in drei Sporlinge (20 Leben) im Abstand 0,4.
@Suite("Heiler und Teiler")
struct HealerSplitterTests {
    static func config() -> BalanceConfig {
        var config = TestConfig.make()
        config.enemies[.witch] = EnemyConfig(hp: 100, speed: 1, reward: 8, leakDamage: 1,
                                             heal: HealConfig(radius: 1, interval: 2, share: 0.06))
        config.enemies[.puffball] = EnemyConfig(hp: 100, speed: 1, reward: 3, leakDamage: 2,
                                                split: SplitConfig(into: .sporeling, count: 3, spread: 0.4))
        config.enemies[.sporeling] = EnemyConfig(hp: 20, speed: 2, reward: 1, leakDamage: 1)
        config.enemies[.moorKing] = BossTests.config().enemies[.moorKing]
        config.ability = AbilityTests.ability
        return config
    }
    let sim = Simulation(config: HealerSplitterTests.config())

    private func game(_ enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies
        state.nextEntityID = 100
        return state
    }

    private func witch(_ id: Int = 1, at distance: Double = 10, hp: Double = 100, healTick: Int = 60) -> Enemy {
        var enemy = Enemy(id: id, kind: .witch, hp: hp, maxHP: 100, distance: distance)
        enemy.healTick = healTick
        return enemy
    }

    private func hurt(_ id: Int, at distance: Double, hp: Double, kind: EnemyKind = .raider) -> Enemy {
        Enemy(id: id, kind: kind, hp: hp, maxHP: 100, distance: distance)
    }

    private func run(_ state: inout GameState, ticks: Int) -> [Event] {
        var all: [Event] = []
        for _ in 0..<ticks { all += sim.step(&state) }
        return all
    }

    // MARK: Heilen

    @Test("Die Hexe heilt im Takt Nachbarn im Umkreis um 6 % ihres Höchstlebens, Fernere nicht")
    func healsNeighbours() {
        var state = game([witch(), hurt(2, at: 10.5, hp: 50), hurt(3, at: 12, hp: 50)])
        var events = run(&state, ticks: 60)
        #expect(state.enemies[1].hp == 50, "vor dem Takt keine Heilung")
        events = sim.step(&state)
        #expect(state.enemies[1].hp == 56)
        #expect(state.enemies[2].hp == 50, "zwei Felder weg")
        #expect(events.contains(.enemiesHealed(healerID: 1, healed: [2], amount: 6)))
        #expect(state.enemies[0].healTick == 120)
    }

    @Test("Nie über das Höchstleben, nie sich selbst, keine Meldung ohne Geheilte")
    func capsAndSelf() {
        var state = game([witch(hp: 50, healTick: 0), hurt(2, at: 10.2, hp: 98)])
        let first = sim.step(&state)
        #expect(state.enemies[1].hp == 100)
        #expect(state.enemies[0].hp == 50, "sie heilt sich nicht selbst")
        #expect(first.contains(.enemiesHealed(healerID: 1, healed: [2], amount: 2)))
        let rest = run(&state, ticks: 60)
        #expect(!rest.contains { if case .enemiesHealed = $0 { true } else { false } }, "alle voll, also kein Puls")
    }

    @Test("Bosse werden nicht geheilt, damit die Schildschwelle hält")
    func noBossHealing() {
        var king = Enemy(id: 2, kind: .moorKing, hp: 800, maxHP: 1_000, distance: 10.2)
        king.shieldSpent = true
        var state = game([witch(healTick: 0), king])
        sim.step(&state)
        #expect(state.enemies[1].hp == 800)
    }

    @Test("Betäubt heilt sie nicht, ihr Takt beginnt nach der Betäubung neu")
    func stunPostpones() {
        var hexe = witch(healTick: 60)
        hexe.stunUntilTick = 90
        var patient = hurt(2, at: 10.2, hp: 50)
        patient.stunUntilTick = 90
        var state = game([hexe, patient])
        _ = run(&state, ticks: 150)
        #expect(state.enemies[1].hp == 50, "bei Tick 60 betäubt, also nichts")
        #expect(state.enemies[0].healTick == 150)
        sim.step(&state)
        #expect(state.enemies[1].hp == 56)
    }

    @Test("Wer im selben Tick stirbt, wird nicht mehr geheilt")
    func deadStayDead() {
        var state = game([witch(healTick: 0), hurt(2, at: 10.2, hp: 1)])
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(events.contains { if case .enemyKilled(2, _) = $0 { true } else { false } })
        #expect(!events.contains { if case .enemiesHealed = $0 { true } else { false } })
    }

    @Test("Eine erscheinende Hexe bekommt ihren Takt ab dem Erscheinen")
    func healTickFromSpawn() {
        var config = HealerSplitterTests.config()
        config.waves = [WaveConfig(hpScale: 1, groups: [SpawnGroup(enemy: .witch, count: 1, interval: 1)])]
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        sim.step(&state)
        #expect(state.enemies.first?.healTick == 60)
        #expect(state.enemies.first.map { sim.config.enemies[$0.kind]?.heal != nil } == true)
    }

    // MARK: Zerfallen

    @Test("Ein toter Balg zerfällt in drei Sporlinge am Todesort und dahinter, mit der Stärke der Welle")
    func splitsOnDeath() throws {
        var state = game([Enemy(id: 1, kind: .puffball, hp: 5, maxHP: 200, distance: 10)])
        let gold = state.gold
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        let cost = try #require(sim.config.cost(of: .watch))
        #expect(state.gold == gold - cost + 3)
        #expect(state.enemies.map(\.kind) == [.sporeling, .sporeling, .sporeling])
        #expect(state.enemies.map(\.id) == [101, 102, 103], "neue IDs hinten, nach dem Turm")
        #expect(state.enemies.map(\.maxHP) == [40, 40, 40], "doppeltes Leben des Balgs, doppeltes der Sporlinge")
        let speed = 2.0 / 30
        let expected = [10.0, 9.6, 9.2].map { $0 + speed }
        for (enemy, distance) in zip(state.enemies, expected) {
            #expect(abs(enemy.distance - distance) < 1e-9)
        }
        #expect(events.contains(.enemySplit(id: 1, into: [101, 102, 103])))
        #expect(events.filter { if case .enemySpawned = $0 { true } else { false } }.count == 3)
    }

    @Test("Am Anfang des Wegs liegt kein Sporling vor dem Start")
    func clampsAtStart() {
        var state = game([Enemy(id: 1, kind: .puffball, hp: 5, maxHP: 100, distance: 0.5)])
        sim.step(&state, commands: [.build(.watch, Cell(x: 1, y: 1))])
        #expect(state.enemies.allSatisfy { $0.distance >= 0 })
    }

    @Test("Wer durchbricht, zerfällt nicht")
    func leakDoesNotSplit() {
        var state = game([Enemy(id: 1, kind: .puffball, hp: 100, maxHP: 100, distance: 39.99)])
        let events = sim.step(&state)
        #expect(state.enemies.isEmpty)
        #expect(events.contains(.enemyLeaked(id: 1, damage: 2)))
        #expect(state.fortressLives == 8)
    }

    @Test("Der Sieg wartet auf die Sporlinge")
    func victoryWaits() {
        var state = game([Enemy(id: 1, kind: .puffball, hp: 5, maxHP: 100, distance: 10)])
        sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(state.outcome == nil)
        #expect(state.enemies.count == 3)
    }

    // MARK: Rahmen

    @Test("Missionen ohne Heiler und Teiler: kein Zustand, keine Ereignisse")
    func neutralWithout() throws {
        let sim = Simulation(config: try .missionOne())
        var state = sim.newGame(seed: 3)
        for _ in 0..<1_800 { sim.step(&state) }
        #expect(state.enemies.allSatisfy { $0.healTick == nil })
    }

    @Test("Ein Spielstand mit Takt lädt, einer ohne auch")
    func codable() throws {
        let enemy = witch()
        let data = try JSONEncoder().encode(enemy)
        #expect(try JSONDecoder().decode(Enemy.self, from: data) == enemy)
        let plain = try JSONEncoder().encode(TestConfig.enemy(1, at: 3))
        #expect(!String(decoding: plain, as: UTF8.self).contains("healTick"))
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand mit Hexen und Bälgen")
    func deterministic() {
        var config = HealerSplitterTests.config()
        config.waves = [WaveConfig(hpScale: 1.2, groups: [
            SpawnGroup(enemy: .raider, count: 6, interval: 0.5),
            SpawnGroup(enemy: .witch, count: 2, interval: 1, delay: 1),
            SpawnGroup(enemy: .puffball, count: 4, interval: 0.8, delay: 2),
        ])]
        let sim = Simulation(config: config)
        func play() -> GameState {
            var state = sim.newGame(seed: 9)
            sim.step(&state, commands: [.build(.watch, Cell(x: 8, y: 1)), .build(.lightning, Cell(x: 12, y: 1)),
                                        .build(.spore, Cell(x: 16, y: 1))])
            for _ in 0..<2_400 { sim.step(&state) }
            return state
        }
        let state = play()
        #expect(state == play())
        #expect(state.outcome != nil)
    }

    @Test("Prüfung beim Laden", arguments: [
        ("radius", "enemies.witch.heal.radius", ConfigIssue.Rule.mustBePositive),
        ("interval", "enemies.witch.heal.interval", .mustBePositive),
        ("share", "enemies.witch.heal.share", .mustBeFraction),
        ("count", "enemies.puffball.split.count", .mustBePositive),
        ("spread", "enemies.puffball.split.spread", .mustNotBeNegative),
        ("intoMissing", "enemies.puffball.split.into", .splitIntoInvalid),
        ("intoBoss", "enemies.puffball.split.into", .splitIntoInvalid),
        ("intoSplitter", "enemies.puffball.split.into", .splitIntoInvalid),
    ])
    func validation(change: String, field: String, rule: ConfigIssue.Rule) {
        var config = HealerSplitterTests.config()
        #expect(config.issues().isEmpty)
        switch change {
        case "radius": config.enemies[.witch]?.heal?.radius = 0
        case "interval": config.enemies[.witch]?.heal?.interval = 0
        case "share": config.enemies[.witch]?.heal?.share = 1.5
        case "count": config.enemies[.puffball]?.split?.count = 0
        case "spread": config.enemies[.puffball]?.split?.spread = -1
        case "intoMissing": config.enemies[.sporeling] = nil
        case "intoBoss": config.enemies[.puffball]?.split?.into = .moorKing
        default: config.enemies[.puffball]?.split?.into = .puffball
        }
        #expect(config.issues() == [ConfigIssue(field: field, rule: rule)])
    }

    @Test("Ein Boss zerfällt nicht")
    func bossDoesNotSplit() {
        var config = HealerSplitterTests.config()
        config.enemies[.moorKing]?.split = SplitConfig(into: .sporeling, count: 2, spread: 0.5)
        #expect(config.issues() == [ConfigIssue(field: "enemies.moorKing.split", rule: .bossSplits)])
    }
}
