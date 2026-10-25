import Foundation

/// Alle Werte einer Mission. Unveränderlich, kommt ausschließlich aus JSON
/// (Architekturregel 7): Wer eine Zahl ändern will, ändert die Datei.
public struct BalanceConfig: Codable, Equatable, Sendable {
    public var simulation: SimulationConfig
    public var mission: MissionConfig
    public var map: MapConfig
    /// Nur zum Nachschlagen. Die Simulation iteriert nie über diese Tabelle
    /// (Architekturregel 6), sondern über `TowerKind.allCases`.
    public var towers: [TowerKind: TowerConfig]
    public var enemies: [EnemyKind: EnemyConfig]
    public var waves: [WaveConfig]

    public init(
        simulation: SimulationConfig, mission: MissionConfig, map: MapConfig,
        towers: [TowerKind: TowerConfig], enemies: [EnemyKind: EnemyConfig], waves: [WaveConfig]
    ) {
        self.simulation = simulation
        self.mission = mission
        self.map = map
        self.towers = towers
        self.enemies = enemies
        self.waves = waves
    }
}

public struct SimulationConfig: Codable, Equatable, Sendable {
    public var ticksPerSecond: Int
    public init(ticksPerSecond: Int) { self.ticksPerSecond = ticksPerSecond }
}

public struct MissionConfig: Codable, Equatable, Sendable {
    public var id: String
    public var fortressLives: Int
    public var startGold: Int
    /// Sekunden
    public var firstWaveDelay: Double
    /// Sekunden
    public var timeBetweenWaves: Double
    public var sellRefundRate: Double

    public init(
        id: String, fortressLives: Int, startGold: Int,
        firstWaveDelay: Double, timeBetweenWaves: Double, sellRefundRate: Double
    ) {
        self.id = id
        self.fortressLives = fortressLives
        self.startGold = startGold
        self.firstWaveDelay = firstWaveDelay
        self.timeBetweenWaves = timeBetweenWaves
        self.sellRefundRate = sellRefundRate
    }
}

public struct MapConfig: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int
    /// Mindestabstand einer Zellmitte zum Weg, damit dort gebaut werden darf.
    public var minDistanceFromPath: Double
    public var path: [Point]

    public init(width: Int, height: Int, minDistanceFromPath: Double, path: [Point]) {
        self.width = width
        self.height = height
        self.minDistanceFromPath = minDistanceFromPath
        self.path = path
    }
}

/// Punkt in Feldern. Im JSON als `[x, y]`, weil die Wegliste sonst unlesbar lang wird.
public struct Point: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(Double.self)
        y = try container.decode(Double.self)
        if !container.isAtEnd {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Ein Punkt hat genau zwei Koordinaten.")
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}

public enum TowerKind: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case watch, lightning, spore
}

public enum EnemyKind: String, Codable, CaseIterable, CodingKeyRepresentable, Sendable {
    case raider, runner, brute
}

public enum Targeting: String, Codable, Sendable {
    /// Der Gegner, der am weitesten auf dem Weg ist.
    case first
    /// Alle in Reichweite gleichzeitig.
    case aura
}

/// Ein Typ für alle Türme, die Rollen über optionale Felder. Reicht für drei
/// Türme; umgebaut wird erst, wenn der vierte Rollentyp es verlangt (data-models.md).
public struct TowerConfig: Codable, Equatable, Sendable {
    public var cost: Int
    public var range: Double
    public var damage: Double
    /// Sekunden
    public var attackInterval: Double
    public var targeting: Targeting
    public var chainJumps: Int?
    public var chainRadius: Double?
    public var chainFalloff: Double?
    public var slowFactor: Double?
    /// Sekunden
    public var slowDuration: Double?

    public init(
        cost: Int, range: Double, damage: Double, attackInterval: Double, targeting: Targeting,
        chainJumps: Int? = nil, chainRadius: Double? = nil, chainFalloff: Double? = nil,
        slowFactor: Double? = nil, slowDuration: Double? = nil
    ) {
        self.cost = cost
        self.range = range
        self.damage = damage
        self.attackInterval = attackInterval
        self.targeting = targeting
        self.chainJumps = chainJumps
        self.chainRadius = chainRadius
        self.chainFalloff = chainFalloff
        self.slowFactor = slowFactor
        self.slowDuration = slowDuration
    }
}

public struct EnemyConfig: Codable, Equatable, Sendable {
    public var hp: Double
    /// Felder je Sekunde
    public var speed: Double
    public var reward: Int
    public var leakDamage: Int

    public init(hp: Double, speed: Double, reward: Int, leakDamage: Int) {
        self.hp = hp
        self.speed = speed
        self.reward = reward
        self.leakDamage = leakDamage
    }
}

public struct WaveConfig: Codable, Equatable, Sendable {
    public var hpScale: Double
    public var groups: [SpawnGroup]

    public init(hpScale: Double, groups: [SpawnGroup]) {
        self.hpScale = hpScale
        self.groups = groups
    }
}

public struct SpawnGroup: Codable, Equatable, Sendable {
    public var enemy: EnemyKind
    public var count: Int
    /// Sekunden zwischen zwei Gegnern der Gruppe
    public var interval: Double
    /// Sekunden ab Wellenbeginn
    public var delay: Double?

    public init(enemy: EnemyKind, count: Int, interval: Double, delay: Double? = nil) {
        self.enemy = enemy
        self.count = count
        self.interval = interval
        self.delay = delay
    }
}
