# Datenmodelle

Status: **[VORSCHLAG]**. Namen im Code englisch, Begriffe im Spiel deutsch.

| Spiel | Code |
|---|---|
| Wachturm / Blitzturm / Sporenturm / Zwergenbank | `watch` / `lightning` / `spore` / `bank` |
| Plünderer / Flitzer / Panzerbestie / Schattenflieger | `raider` / `runner` / `brute` / `shadowFlyer` |
| Festung | `fortress` |
| Feld | `cell` (Raster), Strecken in `Double` Feldern |

## Konfiguration (unveränderlich, aus JSON)

```swift
struct BalanceConfig: Codable {
    var simulation: SimulationConfig        // ticksPerSecond
    var mission: MissionConfig               // fortressLives, startGold, firstWaveDelay, timeBetweenWaves, sellRefundRate
    var map: MapConfig                       // width, height, path [[x,y]], buildZones (ab WP-03)
    var towers: [TowerKind: TowerConfig]
    var enemies: [EnemyKind: EnemyConfig]
    var waves: [WaveConfig]
}

struct TowerConfig: Codable {               // ein Typ, optionale Felder je Rolle
    var cost: Int; var range: Double; var damage: Double; var attackInterval: Double
    var targeting: Targeting                 // .first, .aura
    var chainJumps: Int?; var chainRadius: Double?; var chainFalloff: Double?
    var slowFactor: Double?; var slowDuration: Double?
}

struct EnemyConfig: Codable { var hp: Double; var speed: Double; var reward: Int; var leakDamage: Int }
struct WaveConfig: Codable { var hpScale: Double; var groups: [SpawnGroup] }
struct SpawnGroup: Codable { var enemy: EnemyKind; var count: Int; var interval: Double; var delay: Double? }
```

`[TowerKind: …]` in der **Konfiguration** ist unbedenklich, weil nur nachgeschlagen
und nie darüber iteriert wird. Die Validierung (WP-02) prüft u. a.: alle Kosten > 0,
Reichweiten > 0, `slowFactor` in (0, 1], jede Welle hat mindestens eine Gruppe, jeder
referenzierte Gegner existiert, Weg hat ≥ 2 Punkte. Umgesetzt in
`ConfigValidation.swift`: `BalanceConfig.load(from:)` liest und prüft in einem
Schritt und meldet **alle** Verstöße mit Ort (`towers.watch.cost muss größer als 0
sein`). Jeder Turmtyp muss Werte haben; ein Gegner ohne Werte ist nur ein Fehler,
wenn eine Welle ihn ruft (die Panzerbestie ist optional). Ein Turmtyp, den es im
MVP nicht gibt (`bank`), lässt das Lesen scheitern. Punkte stehen im JSON als
`[x, y]`.

**Später zur Wahl:** Optionale Felder genügen für drei Türme. Kommen viele Rollen
dazu, wird `TowerConfig` zu einer Liste von Wirkungen (`effects: [Effect]`). Erst
umbauen, wenn der vierte Rollentyp es verlangt.

## Zustand (veränderlich, ein Wert)

```swift
struct GameState: Codable, Equatable {
    var tick: Int
    var gold: Int
    var fortressLives: Int
    var phase: Phase                 // .building(untilTick), .wave(index), .won, .lost
    var waveIndex: Int               // -1 vor der ersten Welle
    var pendingSpawns: [PendingSpawn]  // sortiert nach Tick
    var towers: [Tower]              // sortiert nach id
    var enemies: [Enemy]             // sortiert nach id
    var nextEntityID: Int
    var rng: SplitMix64
}

struct Tower: Codable, Equatable { var id: Int; var kind: TowerKind; var cell: Cell; var cooldownTicks: Int; var spent: Int }
struct Enemy: Codable, Equatable {
    var id: Int; var kind: EnemyKind
    var hp: Double; var maxHP: Double
    var distance: Double              // zurückgelegte Weglänge in Feldern
    var slow: SlowEffect?             // factor, untilTick
}
```

**Umgesetzt seit WP-04** mit einer Abweichung: Statt `phase` stehen drei Felder im
Zustand, `waveIndex`, `nextWaveTick: Int?` (nil, wenn alle Wellen begonnen haben)
und `outcome: Outcome?` (`won`/`lost`). Das sind dieselben Informationen ohne
Aufzählungsfall je Kombination. `step` ist eine Methode von `Simulation`, die
Konfiguration und daraus berechnete Karte hält, damit die Bauzonen nicht in jedem
Tick neu entstehen; der Zustand liegt weiterhin nur in `GameState`. Sekunden aus
der Konfiguration werden gerundet in Ticks umgerechnet (`ticks(_:)`). Gegenüber dem
Prüfskript fällt die Niederlage ohne Türme 4 Ticks früher (2731 statt 2735), weil
Python mit aufsummierter Zeit statt mit ganzen Ticks rechnet; für WP-10 zählt die
Rangfolge der Bauweisen, nicht der einzelne Tick.

Gegnerposition wird aus `distance` und dem Weg berechnet, nicht gespeichert.
Das hält den Zustand klein und schließt Abweichungen zwischen Position und
Fortschritt aus.

## Befehle und Ereignisse

```swift
enum Command: Codable, Equatable { case build(TowerKind, Cell), sell(towerID: Int), callNextWave }

enum Event: Equatable {
    case towerBuilt(id: Int), towerSold(id: Int, refund: Int)
    case commandRejected(Command, reason: Rejection)      // zu wenig Gold, Zelle belegt, außerhalb Zone
    case waveStarted(index: Int), enemySpawned(id: Int)
    case towerFired(towerID: Int, targets: [Int])         // Kettenreihenfolge
    case enemyDamaged(id: Int, amount: Double), enemySlowed(id: Int)
    case enemyKilled(id: Int, reward: Int), enemyLeaked(id: Int, damage: Int)
    case missionEnded(won: Bool)
}

func step(_ state: inout GameState, commands: [Command], config: BalanceConfig) -> [Event]
```

**Reihenfolge innerhalb eines Schritts** (festgeschrieben, weil sie Ergebnisse
ändert): Befehle → Wellen/Spawns → Türme feuern (nach ID) → Tote auswerten und
Gold gutschreiben → Bewegung → Durchbrüche → Sieg/Niederlage.

## Speicherstand (Phase 2)

`SaveGame { schemaVersion, settings, campaignProgress, suspendedMission: GameState? }`
als JSON. `schemaVersion` von Anfang an, damit spätere Migrationen möglich sind.
