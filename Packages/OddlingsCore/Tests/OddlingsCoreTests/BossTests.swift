import Foundation
import Testing
@testable import OddlingsCore

/// Boss mit Schild und Ruf (P3-4, K7). Eigene Werte (testing-strategy.md,
/// Regel 4): Moorkönig 1000 Leben, Schild bei der Hälfte für 2 s, ruft jede
/// Sekunde zwei Plünderer mit halbem Leben, Verlangsamung wirkt halb.
@Suite("Boss")
struct BossTests {
    static func config() -> BalanceConfig {
        var config = TestConfig.make()
        config.enemies[.moorKing] = EnemyConfig(
            hp: 1_000, speed: 1, reward: 100, leakDamage: 10, slowScale: 0.5,
            boss: BossConfig(shieldAt: 0.5, shieldDuration: 2, summonEvery: 1,
                             summon: .raider, summonCount: 2, summonHPScale: 0.5))
        config.ability = AbilityTests.ability
        return config
    }
    let sim = Simulation(config: BossTests.config())

    private func game(_ enemies: [Enemy]) -> GameState {
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = enemies
        state.nextEntityID = 100
        return state
    }

    private func king(hp: Double = 1_000, at distance: Double = 10) -> Enemy {
        Enemy(id: 1, kind: .moorKing, hp: hp, maxHP: 1_000, distance: distance)
    }

    @Test("Ein schwerer Treffer hält an der Schwelle an, und der Schild steigt im selben Tick")
    func shieldAtThreshold() {
        var state = game([king(hp: 505)])
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(state.enemies[0].hp == 500, "10 Schaden, aber nur 5 bis zur Schwelle")
        #expect(events.contains(.bossShieldRaised(id: 1, untilTick: 60)))
        #expect(state.enemies[0].shieldSpent == true)
    }

    @Test("Mit Schild: kein Schaden, kein Laufen, gemeldet als geschluckt")
    func shieldBlocks() {
        var state = game([king(hp: 500)])
        sim.step(&state)
        state.enemies = state.enemies.filter { $0.id == 1 }
        let distance = state.enemies[0].distance
        let events = sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(state.enemies[0].hp == 500)
        #expect(state.enemies[0].distance == distance)
        #expect(events.contains(.shieldAbsorbed(id: 1)))
        #expect(!events.contains { if case .enemyDamaged(1, _) = $0 { true } else { false } })
    }

    @Test("Ruf im Takt: zwei Plünderer mit halbem Leben an seiner Stelle, beim Heben und jede Sekunde")
    func summons() {
        var state = game([king(hp: 500, at: 12)])
        var all: [Event] = []
        for _ in 0..<60 { all += sim.step(&state) }
        let calls = all.compactMap { if case .bossSummoned(1, let ids) = $0 { ids } else { nil } }
        #expect(calls == [[100, 101], [102, 103]], "Tick 0 und 30; in Tick 60 fällt der Schild")
        let first = state.enemies.first { $0.id == 100 }
        #expect(first?.maxHP == 50)
        #expect(first?.kind == .raider)
        #expect(all.contains(.enemySpawned(id: 103)))
    }

    @Test("Der Schild fällt nach seiner Zeit, danach nimmt der Boss Schaden und läuft")
    func shieldDrops() {
        var state = game([king(hp: 500)])
        var all: [Event] = []
        for _ in 0...60 { all += sim.step(&state) }
        #expect(all.contains(.bossShieldDropped(id: 1)))
        #expect(state.enemies[0].shieldUntilTick == nil)
        state.enemies = state.enemies.filter { $0.id == 1 }
        let distance = state.enemies[0].distance
        sim.step(&state, commands: [.build(.watch, Cell(x: 10, y: 1))])
        #expect(state.enemies[0].hp == 490, "kein zweiter Schild")
        #expect(state.enemies[0].distance > distance)
    }

    @Test("Verlangsamung wirkt halb")
    func halfSlow() {
        var state = game([king()])
        sim.step(&state, commands: [.build(.spore, Cell(x: 10, y: 1))])
        #expect(state.enemies[0].slow?.factor == 0.75, "0,5 halb wirksam")
        var raider = TestConfig.enemy(2, at: 10)
        sim.applySlow(to: &raider, stats: sim.config.towers[.spore]!, tick: 0)
        #expect(raider.slow?.factor == 0.5, "andere Gegner unverändert")
    }

    @Test("Der Steinregen trifft den Boss außerhalb des Schilds, mit Schild nicht")
    func stoneRain() {
        var state = game([king()])
        sim.step(&state, commands: [.useAbility(Point(x: 10, y: 0.5))])
        while state.tick <= 15 { sim.step(&state) }
        #expect(state.enemies[0].hp < 1_000)

        var shielded = game([king(hp: 500)])
        sim.step(&shielded)
        sim.step(&shielded, commands: [.useAbility(Point(x: 10, y: 0.5))])
        while shielded.tick <= 16 { sim.step(&shielded) }
        #expect(shielded.enemies.first { $0.id == 1 }?.hp == 500)
    }

    @Test("Läuft der Boss durch, kostet er seine Leben; mit allen Leben ist die Mission verloren")
    func leakLoses() {
        var config = BossTests.config()
        config.enemies[.moorKing]?.leakDamage = config.mission.fortressLives
        let sim = Simulation(config: config)
        var state = sim.newGame(seed: 1)
        state.pendingSpawns = []
        state.nextWaveTick = nil
        state.enemies = [Enemy(id: 1, kind: .moorKing, hp: 1_000, maxHP: 1_000, distance: 39.99)]
        sim.step(&state)
        #expect(state.outcome == .lost)
    }

    @Test("Gleicher Seed, gleiche Befehle, gleicher Endzustand")
    func deterministic() {
        var config = BossTests.config()
        config.waves = [WaveConfig(hpScale: 1, groups: [SpawnGroup(enemy: .moorKing, count: 1, interval: 1)])]
        let sim = Simulation(config: config)
        let build: [Command] = [.build(.watch, Cell(x: 10, y: 1)), .build(.lightning, Cell(x: 12, y: 1)),
                                .build(.spore, Cell(x: 14, y: 1)), .build(.watch, Cell(x: 16, y: 1))]
        func run() -> GameState {
            var state = sim.newGame(seed: 3)
            sim.step(&state, commands: build)
            while !state.isOver { sim.step(&state) }
            return state
        }
        #expect(run() == run())
    }

    @Test("Ein alter Spielstand ohne Bossfelder lädt")
    func oldStateDecodes() throws {
        let enemy = TestConfig.enemy(1, at: 3)
        let data = try JSONEncoder().encode(enemy)
        let text = String(decoding: data, as: UTF8.self)
        #expect(!text.contains("shield"), "leere Felder werden nicht geschrieben")
        #expect(try JSONDecoder().decode(Enemy.self, from: data) == enemy)
    }

    @Test("Prüfung beim Laden", arguments: [
        ("shieldAt", "enemies.moorKing.boss.shieldAt", ConfigIssue.Rule.mustBeFraction),
        ("duration", "enemies.moorKing.boss.shieldDuration", .mustBePositive),
        ("every", "enemies.moorKing.boss.summonEvery", .mustBePositive),
        ("count", "enemies.moorKing.boss.summonCount", .mustBePositive),
        ("scale", "enemies.moorKing.boss.summonHPScale", .mustBePositive),
        ("summonBoss", "enemies.moorKing.boss.summon", .bossSummonsBoss),
        ("slowScale", "enemies.moorKing.slowScale", .mustBeFraction),
        ("twoBosses", "waves[0]", .tooManyBossesInWave),
    ])
    func validation(change: String, field: String, rule: ConfigIssue.Rule) {
        var config = BossTests.config()
        #expect(config.issues().isEmpty)
        switch change {
        case "shieldAt": config.enemies[.moorKing]?.boss?.shieldAt = 1
        case "duration": config.enemies[.moorKing]?.boss?.shieldDuration = 0
        case "every": config.enemies[.moorKing]?.boss?.summonEvery = 0
        case "count": config.enemies[.moorKing]?.boss?.summonCount = 0
        case "scale": config.enemies[.moorKing]?.boss?.summonHPScale = 0
        case "summonBoss": config.enemies[.moorKing]?.boss?.summon = .moorKing
        case "slowScale": config.enemies[.moorKing]?.slowScale = 1.5
        default: config.waves = [WaveConfig(hpScale: 1, groups: [SpawnGroup(enemy: .moorKing, count: 2, interval: 1)])]
        }
        #expect(config.issues() == [ConfigIssue(field: field, rule: rule)])
    }
}
