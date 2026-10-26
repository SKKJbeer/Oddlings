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
    public var towers: [Tower]
    public var enemies: [Enemy]
    public var nextEntityID: Int
    public var outcome: Outcome?
    public var rng: SplitMix64
    public var ability = AbilityState()

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

public struct Tower: Codable, Equatable, Sendable {
    public var id: Int
    public var kind: TowerKind
    public var cell: Cell
    /// Ticks bis zum nächsten Angriff; 0 heißt bereit.
    public var cooldownTicks: Int
    /// Bezahltes Gold; Grundlage der Erstattung beim Verkaufen.
    public var spent: Int
}

public struct Enemy: Codable, Equatable, Sendable {
    public var id: Int
    public var kind: EnemyKind
    public var hp: Double
    public var maxHP: Double
    /// Zurückgelegte Weglänge in Feldern. Die Position folgt daraus (`PathGeometry`).
    public var distance: Double
    /// Aktive Verlangsamung; nil, sobald sie abgelaufen ist.
    public var slow: SlowEffect? = nil
    /// Erster Tick, in dem der Gegner nach Steinregen wieder läuft.
    public var stunUntilTick: Int? = nil
    /// Mondmal: nimmt mehr Schaden; nil, sobald es abgelaufen ist.
    public var vulnerable: VulnerableEffect? = nil
}

/// Verwundbar durch Mondmal. Wie die Verlangsamung: kein Stapeln, es gilt der
/// stärkste aktive Faktor. `untilTick` ist der erste Tick ohne Wirkung.
public struct VulnerableEffect: Codable, Equatable, Sendable {
    public var factor: Double
    public var untilTick: Int
}

/// Bollwerk: eine Mauer an einer Stelle des Wegs, gemessen als Wegstrecke. Wer
/// sie von vorn erreicht, bleibt dort, bis sie fällt.
public struct Barrier: Codable, Equatable, Sendable {
    public var distance: Double
    /// Erster Tick ohne Mauer.
    public var untilTick: Int
}

/// Stand der Festungsfähigkeit. Bereit ab Tick 0 (03).
public struct AbilityState: Codable, Equatable, Sendable {
    /// Erster Tick, in dem wieder geworfen werden darf.
    public var readyTick = 0
    /// Geworfen, noch nicht eingeschlagen (Steinregen, Mondmal).
    public var strike: Strike?
    /// Stehende Mauer (Bollwerk). Eine zur Zeit.
    public var barrier: Barrier?

    public init(readyTick: Int = 0, strike: Strike? = nil, barrier: Barrier? = nil) {
        self.readyTick = readyTick
        self.strike = strike
        self.barrier = barrier
    }
}

public struct Strike: Codable, Equatable, Sendable {
    public var center: Point
    public var impactTick: Int
}

/// Verlangsamung durch Sporen. `untilTick` ist der erste Tick ohne Wirkung.
public struct SlowEffect: Codable, Equatable, Sendable {
    public var factor: Double
    public var untilTick: Int
}

/// Eingaben von außen (Architekturregel 2). Die Darstellung schickt Befehle,
/// sie ändert den Zustand nie selbst.
public enum Command: Codable, Equatable, Sendable {
    case build(TowerKind, Cell)
    case sell(towerID: Int)
    /// Startet die nächste Welle sofort, statt auf den Takt zu warten.
    case callNextWave
    /// Festungsfähigkeit auf eine Stelle (Felder); wird auf den Weg gezogen.
    case useAbility(Point)
}

public enum Rejection: Equatable, Sendable {
    case notEnoughGold
    case cellOccupied
    case tooCloseToPath
    case outsideMap
    case unknownTower
    case noWaveLeft
    case abilityNotReady
    case notOnPath
    case noAbility
}

public enum Event: Equatable, Sendable {
    case towerBuilt(id: Int)
    case towerSold(id: Int, refund: Int)
    case commandRejected(Command, reason: Rejection)
    /// Ziele in Trefferreihenfolge: beim Blitz die Kette, beim Sporenturm alle im Puls.
    case towerFired(towerID: Int, targets: [Int])
    case enemyDamaged(id: Int, amount: Double)
    case enemySlowed(id: Int)
    case enemyKilled(id: Int, reward: Int)
    case waveStarted(index: Int)
    case enemySpawned(id: Int)
    case enemyLeaked(id: Int, damage: Int)
    case missionEnded(won: Bool)
    /// Geworfen: Der Schatten liegt ab jetzt bei `center`, der Einschlag kommt in `impactTick`.
    case abilityCast(center: Point, impactTick: Int)
    /// Steinregen oder Mondmal schlägt ein; `hits` in Zustandsreihenfolge.
    case abilityImpact(center: Point, hits: [Int])
    /// Bollwerk steht an `distance` (Wegstrecke) bis `untilTick`.
    case barrierRaised(distance: Double, untilTick: Int)
    case barrierFell
}
