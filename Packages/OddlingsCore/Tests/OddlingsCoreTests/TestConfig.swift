@testable import OddlingsCore

/// Eigene kleine Konfiguration für Regeltests (testing-strategy.md, Regel 4):
/// Eine Balanceänderung an Mission 1 soll keinen Regeltest brechen. Gerader Weg
/// in Zeile 0,5 von x = 0 bis 40, damit Abstände entlang des Wegs gleich
/// Abständen in der Ebene sind.
enum TestConfig {
    static func make() -> BalanceConfig {
        BalanceConfig(
            simulation: SimulationConfig(ticksPerSecond: 30),
            mission: MissionConfig(id: "test", fortressLives: 10, startGold: 1_000,
                                   firstWaveDelay: 0, timeBetweenWaves: 10, sellRefundRate: 0.5),
            map: MapConfig(width: 40, height: 6, minDistanceFromPath: 0.9,
                           path: [Point(x: 0, y: 0.5), Point(x: 40, y: 0.5)]),
            towers: [
                .watch: TowerConfig(cost: 10, range: 3, damage: 10, attackInterval: 1, targeting: .first),
                .lightning: TowerConfig(cost: 10, range: 3, damage: 18, attackInterval: 1, targeting: .first,
                                        chainJumps: 4, chainRadius: 1.3, chainFalloff: 0.8),
                .spore: TowerConfig(cost: 10, range: 3, damage: 1, attackInterval: 1, targeting: .aura,
                                    slowFactor: 0.5, slowDuration: 1.5),
            ],
            enemies: [
                .raider: EnemyConfig(hp: 100, speed: 1, reward: 5, leakDamage: 1),
                .runner: EnemyConfig(hp: 50, speed: 2, reward: 4, leakDamage: 1),
                .brute: EnemyConfig(hp: 400, speed: 0.5, reward: 20, leakDamage: 3),
            ],
            waves: [WaveConfig(hpScale: 1, groups: [SpawnGroup(enemy: .raider, count: 1, interval: 1)])]
        )
    }

    static func enemy(_ id: Int, at distance: Double, hp: Double = 100, kind: EnemyKind = .raider) -> Enemy {
        Enemy(id: id, kind: kind, hp: hp, maxHP: hp, distance: distance)
    }
}
