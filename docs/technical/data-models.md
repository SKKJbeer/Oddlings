# Datenmodelle

Status: **gilt**, Stand 0.12.0. Wer ein Feld in Konfiguration, Zustand oder Spielstand
ändert, zieht dieses Dokument im selben PR nach (D-067). Namen im Code englisch,
Begriffe im Spiel deutsch.

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
    var mission: MissionConfig               // fortressLives, startGold, firstWaveDelay, timeBetweenWaves, sellRefundRate,
                                             // earlyCallBonus: Double? (Gold je eingesparter Sekunde, P2-5)
    var map: MapConfig                       // width, height, path [[x,y]], buildZones (ab WP-03)
    var towers: [TowerKind: TowerConfig]     // nur Kampftürme (TowerKind.combat)
    var bank: BankConfig?                    // Zwergenbank, nur wo die Mission sie anbietet (P2-5, D-083)
    var upgrades: [TowerKind: UpgradeConfig]? // Stufe 2 je Kampfturm, ab Mission 3 (P2-6, D-084)
    var enemies: [EnemyKind: EnemyConfig]
    var waves: [WaveConfig]
}

struct TowerConfig: Codable {               // ein Typ, optionale Felder je Rolle
    var cost: Int; var range: Double; var damage: Double; var attackInterval: Double
    var targeting: Targeting                 // .first, .aura
    var chainJumps: Int?; var chainRadius: Double?; var chainFalloff: Double?
    var slowFactor: Double?; var slowDuration: Double?
}

struct BankConfig: Codable {                // eigener Typ: keine Reichweite, kein Schaden, kein Takt (D-083)
    var cost: Int; var delay: Double; var interval: Double; var payout: Int; var cap: Int; var limit: Int
}

struct UpgradeConfig: Codable {             // Faktoren auf die Werte der Stufe 1 (D-084)
    var cost: Int; var scale: [TowerStat: Double]   // range, damage, attackInterval, chainRadius, slowFactor, slowDuration
}
// config.stats(of: tower) = Werte der Stufe des Turms; config.maxLevel(of:), config.upgradeCost(of:)
// Bauweisen der Bots (simStrategies) sind [StrategyStep]: "watch" baut, "watch+" wertet den ältesten Wachturm auf.

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
wenn eine Welle ihn ruft (die Panzerbestie ist optional). Ein unbekannter Turmtyp
lässt das Lesen scheitern; `bank` unter `towers` meldet die Prüfung als
`bankNotATower`, denn die Bank hat ihren eigenen Abschnitt `bank`. Eine Bauweise
der Bots, die eine Bank nennt, ohne dass die Mission eine hat, meldet
`strategyNeedsBank`, eine mit Aufwerten ohne Abschnitt `upgrades`
`strategyNeedsUpgrades`. `upgrades` prüft: nur Kampftürme
(`upgradeNeedsCombatTower`), Preis und Faktoren > 0, mindestens ein Faktor
(`emptyUpgrade`), jeder Faktor nennt einen Wert, den der Turm hat
(`statNotInTower`), und `slowFactor` bleibt danach in (0, 1]. `config.buildable` ist die Liste fürs Kreismenü (drei
Kampftürme, mit Bank vier), `config.cost(of:)` der Preis jeder Art. Punkte stehen
im JSON als `[x, y]`.

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

struct Tower: Codable, Equatable {
    var id: Int; var kind: TowerKind; var cell: Cell; var cooldownTicks: Int; var spent: Int
    var builtTick: Int               // ab hier zählt die Verzögerung der Bank (P2-5)
    var paid: Int                    // von der Bank ausgezahlt, höchstens `cap`
    var level: Int                   // 1 oder 2 (P2-6); ältere Stände lesen sich mit 1
    var targetMode: TargetMode       // .first, .last, .strongest; ältere Stände .first
}
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
enum Command: Codable, Equatable {
    case build(TowerKind, Cell), sell(towerID: Int), callNextWave
    case useAbility(Point)                                // Fähigkeit des Volks, rastet am Weg ein
    case upgrade(towerID: Int), setTargetMode(towerID: Int, TargetMode)   // P2-6
}

enum Event: Equatable {
    case towerBuilt(id: Int), towerSold(id: Int, refund: Int)
    case commandRejected(Command, reason: Rejection)      // zu wenig Gold, Zelle belegt, außerhalb Zone
    case waveStarted(index: Int), enemySpawned(id: Int)
    case towerFired(towerID: Int, targets: [Int])         // Kettenreihenfolge
    case enemyDamaged(id: Int, amount: Double), enemySlowed(id: Int)
    case enemyKilled(id: Int, reward: Int), enemyLeaked(id: Int, damage: Int)
    case missionEnded(won: Bool)
    case abilityCast(center: Point, impactTick: Int)      // Schatten bis zum Einschlag
    case abilityImpact(center: Point, hits: [Int])       // Steinregen oder Mondmal
    case barrierRaised(distance: Double, untilTick: Int), barrierFell   // Bollwerk (R-4)
    case bankPaid(towerID: Int, gold: Int, paid: Int), bankEmptied(towerID: Int)   // Zwergenbank (P2-5)
    case earlyCallBonus(gold: Int)                        // frühes Rufen der nächsten Welle
    case towerUpgraded(id: Int, level: Int), targetModeChanged(id: Int, mode: TargetMode)   // P2-6
}

func step(_ state: inout GameState, commands: [Command], config: BalanceConfig) -> [Event]
```

**Reihenfolge innerhalb eines Schritts** (festgeschrieben, weil sie Ergebnisse
ändert): Befehle → Mauer fällt, Einschlag von Stein oder Mal → Wellen/Spawns → Türme feuern (nach ID) → Tote auswerten und
Gold gutschreiben → Banken zahlen (nach ID) → Bewegung (Angehaltene stehen, niemand läuft durch die Mauer)
→ Durchbrüche → Sieg/Niederlage.
Fähigkeit im Zustand: `GameState.ability { readyTick, strike, barrier }`, am
Gegner `stunUntilTick` und `vulnerable { factor, untilTick }`; alles zählt in
die Prüfsumme. Jeder Treffer läuft durch `Simulation.hurt`, damit das Mondmal für
Türme und Stein gleich wirkt.

Zwergenbank (P2-5): Die erste Auszahlung kommt `delay + interval` nach
`builtTick`, danach alle `interval`; die letzte wird auf den Rest bis `cap`
gekürzt und meldet zusätzlich `bankEmptied`. Ältere Spielstände ohne `builtTick`
und `paid` lesen sich mit 0. Bau über der Höchstzahl lehnt die Simulation mit
`Rejection.limitReached` ab, vor der Goldprüfung. Der Bonus fürs frühe Rufen ist
eingesparte Sekunden mal `earlyCallBonus`, abgerundet;
`Simulation.earlyCallBonus(in:)` liefert dieselbe Zahl für den Knopf.

Aufwerten (P2-6): `upgrade` lehnt mit `notUpgradable` ab, wenn die Mission
keine Stufe 2 für den Turm kennt oder er schon oben ist, sonst mit
`notEnoughGold`; der Takt läuft weiter, `spent` wächst um den Preis.
`setTargetMode` lehnt auf Stufe 1 und beim Sporenturm mit `targetModeLocked` ab;
dieselbe Wahl noch einmal meldet nichts. Die Zielwahl rechnet
`Simulation.target(in:around:range:mode:)`, ohne Iteration über ein Wörterbuch.

**Völker (R-4):** `AbilityConfig.kind` ist `stoneRain`, `bulwark` oder
`moonMark`. Fehlt `kind`, gilt `stoneRain`. `issues()` verlangt genau die Felder
der Art. Die Werte der Völker stehen in `Balance/races.json` (`RaceTable`, beim
Laden geprüft): Fähigkeit, dazu `rangeFactor` und `costFactor` je Turmart
(Faktor > 0, Preis auf ganzes Gold gerundet). `BalanceConfig.applying(_:)` macht daraus eine zweite
Konfiguration derselben Mission, deshalb kennt die Simulation keine Völker.

**Avatar (R-5):** `SaveGame.avatar: Avatar?` mit `Avatar { race, name, portrait }`,
Schema 2. `Avatar` lässt sich nur gültig anlegen und decodieren: Name getrimmt,
1 bis 16 Zeichen, keine Steuerzeichen; Porträt nur `a-z`, `0-9`, `-`, höchstens
32 Zeichen. Ein ungültiger Avatar in der Datei kostet nur den Avatar
(`Dropped.invalidAvatar`). Schema 1 (nur `race`) wird zu Schema 2 ohne Avatar.
Welche Porträts es gibt, weiß nur die App (`AvatarPortraits`); eine unbekannte
Kennung zeigt das erste Porträt des Volks.

**Talente (R-6):** `Avatar.talents: [TalentSide]`, eine Seite (`a`/`b`) je Reihe in
Reihenfolge, höchstens `Avatar.maxTalentRows`. Das Feld ist optional, Schema bleibt 2.
Eine kaputte Liste verwirft nur die Wahl. Was gilt, rechnet `AvatarRank.effective`:
nur freie Reihen (Rang aus `RaceTable.rankStars` und den besten Sternen), fehlende
Seite = A. `RaceConfig.talents` hält je Reihe zwei `TalentOption` mit Faktoren auf
Felder der Fähigkeit; `ConfigValidation` prüft jede Kombination wie ein eigenes Volk.

## Kampagne (R-2)

`Resources/Campaign/region-01.json` → `CampaignConfig { id, nodes: [CampaignNode] }`.
Ein Knoten hat `id`, `kind` (`main`/`side`/`boss`), optional `mission` (Datei der
Mission; fehlt sie, ist der Knoten „in Vorbereitung“), `position`, `requires`
(oder `requiresAny` an der Gabelung), optional `stars` (Sternschwelle der
Nebenmissionen) und `novelty` (was die Mission neu einführt). Beim Laden geprüft
(`CampaignIssue`): doppelte IDs, unbekannte Bedingungen, Kreise, kein Start,
Lage außerhalb der Karte.

`CampaignProgress { records: [MissionRecord { mission, bestStars }] }` hält nur die
besten Sterne je Mission, sortiert, ohne Wörterbuch. Daraus rechnet der Kern
`state(of:)` (`completed`/`open`/`inPreparation`/`locked(Grund)`), `totalStars` und
den Avatarrang. `StarRating` vergibt 1 bis 3 Sterne aus übrigen Leben.

## Speicherstand (umgesetzt R-1, R-5, R-6)

`SaveGame { schemaVersion = 2, progress: CampaignProgress, avatar: Avatar? }` als
JSON in Application Support (`SaveLocation`). `SaveStore` schreibt atomar, behält die
vorige Fassung und prüft beim Laden: Ein kaputter Teil kostet nur diesen Teil
(Avatar, Talentwahl), nie den Fortschritt. Einstellungen (Lautstärke Klänge und Musik 0…1, beim Laden begrenzt; Vibration) liegen
getrennt in `AppSettings`, weil sie dem Gerät gehören. Noch nicht umgesetzt:
`suspendedMission` (Fortsetzen einer laufenden Mission, P2-2).

### Ursprünglicher Entwurf (Phase 0)

`SaveGame { schemaVersion, settings, campaignProgress, suspendedMission: GameState? }`
als JSON. `schemaVersion` von Anfang an, damit spätere Migrationen möglich sind.
