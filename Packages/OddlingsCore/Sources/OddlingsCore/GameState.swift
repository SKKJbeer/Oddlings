import Foundation

/// Der ganze veränderliche Zustand einer Mission als ein Wert (Architekturregel 4).
/// Listen statt Mengen und Tabellen, jeweils nach Tick bzw. ID sortiert, damit
/// jede Iteration in derselben Reihenfolge läuft (Architekturregel 6).
public struct GameState: Codable, Equatable, Sendable {
    /// Der Tick, den der nächste `step` ausführt.
    public var tick: Int
    public var gold: Int
    public var fortressLives: Int
    /// -1 vor der ersten Welle.
    public var waveIndex: Int
    /// Tick, an dem die nächste Welle beginnt; `nil`, wenn alle begonnen haben.
    public var nextWaveTick: Int?
    public var pendingSpawns: [PendingSpawn]
    public var enemies: [Enemy]
    public var nextEntityID: Int
    public var outcome: Outcome?
    public var rng: SplitMix64

    public var isOver: Bool { outcome != nil }
}

public enum Outcome: String, Codable, Equatable, Sendable {
    case won, lost
}

public struct PendingSpawn: Codable, Equatable, Sendable {
    public var tick: Int
    public var enemy: EnemyKind
    public var hpScale: Double
}

public struct Enemy: Codable, Equatable, Sendable {
    public var id: Int
    public var kind: EnemyKind
    public var hp: Double
    public var maxHP: Double
    /// Zurückgelegte Weglänge in Feldern. Die Position folgt daraus (`PathGeometry`).
    public var distance: Double
}

public enum Event: Equatable, Sendable {
    case waveStarted(index: Int)
    case enemySpawned(id: Int)
    case enemyLeaked(id: Int, damage: Int)
    case missionEnded(won: Bool)
}
