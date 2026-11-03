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
    /// Tick des Baus. Die Bank rechnet ihren Ertrag daraus; Kampftürme
    /// brauchen ihn nicht.
    public var builtTick: Int = 0
    /// Gold, das eine Bank schon ausgezahlt hat. Erreicht es den Deckel, ist sie leer.
    public var paid: Int = 0
    /// Stufe 1 nach dem Bau, 2 nach der Aufwertung (P2-6), 3 nach der Spezialisierung (P3-1).
    public var level: Int = 1
    /// Zielwahl, ab Stufe 2 umschaltbar. Bis dahin `first` wie in Mission 1.
    public var targetMode: TargetMode = .first
    /// Gesetzt genau auf Stufe 3 (P3-1).
    public var specialization: Specialization? = nil

    public init(id: Int, kind: TowerKind, cell: Cell, cooldownTicks: Int, spent: Int,
                builtTick: Int = 0, paid: Int = 0, level: Int = 1, targetMode: TargetMode = .first,
                specialization: Specialization? = nil) {
        self.id = id
        self.kind = kind
        self.cell = cell
        self.cooldownTicks = cooldownTicks
        self.spent = spent
        self.builtTick = builtTick
        self.paid = paid
        self.level = level
        self.targetMode = targetMode
        self.specialization = specialization
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, cell, cooldownTicks, spent, builtTick, paid, level, targetMode, specialization
    }

    /// Zustände ohne Bankfelder (vor 0.16.0), ohne Stufe (vor 0.18.0) und ohne
    /// Spezialisierung (vor P3-1) bleiben lesbar.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        kind = try c.decode(TowerKind.self, forKey: .kind)
        cell = try c.decode(Cell.self, forKey: .cell)
        cooldownTicks = try c.decode(Int.self, forKey: .cooldownTicks)
        spent = try c.decode(Int.self, forKey: .spent)
        builtTick = try c.decodeIfPresent(Int.self, forKey: .builtTick) ?? 0
        paid = try c.decodeIfPresent(Int.self, forKey: .paid) ?? 0
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? 1
        targetMode = try c.decodeIfPresent(TargetMode.self, forKey: .targetMode) ?? .first
        specialization = try c.decodeIfPresent(Specialization.self, forKey: .specialization)
    }
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

    /// Öffentlich für die Darstellungstests der App; die Simulation legt
    /// Gegner sonst selbst an.
    public init(id: Int, kind: EnemyKind, hp: Double, maxHP: Double, distance: Double,
                slow: SlowEffect? = nil, stunUntilTick: Int? = nil, vulnerable: VulnerableEffect? = nil) {
        self.id = id
        self.kind = kind
        self.hp = hp
        self.maxHP = maxHP
        self.distance = distance
        self.slow = slow
        self.stunUntilTick = stunUntilTick
        self.vulnerable = vulnerable
    }
}

/// Verwundbar durch Mondmal. Wie die Verlangsamung: kein Stapeln, es gilt der
/// stärkste aktive Faktor. `untilTick` ist der erste Tick ohne Wirkung.
public struct VulnerableEffect: Codable, Equatable, Sendable {
    public var factor: Double
    public var untilTick: Int

    public init(factor: Double, untilTick: Int) {
        self.factor = factor
        self.untilTick = untilTick
    }
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

    /// Öffentlich, damit die App-Tests einen verlangsamten Gegner bauen können;
    /// in der Simulation setzt nur `Simulation` die Verlangsamung.
    public init(factor: Double, untilTick: Int) {
        self.factor = factor
        self.untilTick = untilTick
    }
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
    /// Hebt einen Turm auf die nächste Stufe (P2-6).
    case upgrade(towerID: Int)
    /// Zielwahl eines Turms ab Stufe 2; kostet nichts.
    case setTargetMode(towerID: Int, TargetMode)
    /// Hebt einen Turm von Stufe 2 auf Stufe 3 mit dieser Spezialisierung (P3-1).
    case specialize(towerID: Int, Specialization)
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
    /// So viele Banken stehen schon, wie die Mission erlaubt.
    case limitReached
    /// Die Mission wertet diese Turmart nicht auf, oder der Turm steht schon
    /// auf der höchsten Stufe. Beim Spezialisieren auch: Turm nicht auf Stufe 2,
    /// Spezialisierung nicht angeboten oder für einen anderen Turm.
    case notUpgradable
    /// Zielwahl erst ab Stufe 2 und nur für Türme mit Einzelziel.
    case targetModeLocked
}

public enum Event: Equatable, Sendable {
    case towerBuilt(id: Int)
    case towerSold(id: Int, refund: Int)
    case commandRejected(Command, reason: Rejection)
    /// Ziele in Trefferreihenfolge: beim Blitz die Kette, beim Sporenturm alle im Puls.
    case towerFired(towerID: Int, targets: [Int])
    case enemyDamaged(id: Int, amount: Double)
    /// Die Rüstung hat von einem Turmtreffer `amount` geschluckt (P2-10). Nur wenn sie griff.
    case armorAbsorbed(id: Int, amount: Double)
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
    /// Eine Bank zahlt `gold` aus; `paid` ist ihr Stand danach.
    case bankPaid(towerID: Int, gold: Int, paid: Int)
    /// Die Bank hat ihren Deckel ausgezahlt und steht leer.
    case bankEmptied(towerID: Int)
    /// Die Welle kam früher; dafür gab es `gold`.
    case earlyCallBonus(gold: Int)
    /// Ein Turm steht jetzt auf `level`.
    case towerUpgraded(id: Int, level: Int)
    /// Ein Turm nimmt ab jetzt seine Ziele nach `mode`.
    case targetModeChanged(id: Int, mode: TargetMode)
}
