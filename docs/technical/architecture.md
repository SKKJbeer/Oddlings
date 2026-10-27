# Architektur

Status: **gilt** (D-003, D-020), umgesetzt bis 0.12.0. Offen ist nur die Messung des
Technik-Spikes (WP-01) auf dem iPhone; sie kann die Stack-Wahl (D-002) noch kippen.

**Pflege (D-067):** Dieses Dokument beschreibt den Stand von `main`. Wer einen Ordner
unter `App/` oder eine Quelldatei in `OddlingsCore` anlegt, umbenennt oder einen
Datenfluss ändert, zieht es im selben PR nach. `scripts/regeln-pruefen.sh` bricht
die CI, wenn ein Ordner oder eine Kerndatei hier fehlt.

## 1. Bewertung des Stacks

| Option | Für | Gegen | Urteil |
|---|---|---|---|
| **Swift + SwiftUI + SpriteKit** | Nativ, kein Lizenz- oder Engine-Risiko, kleine App, beste iOS-Integration (Haptik, Game Center, StoreKit später), Steffen kennt den Weg Xcode → TestFlight bereits aus Zählora und Stack & Siege, Simulation als reines Swift-Paket testbar | Nur Apple-Plattformen; SpriteKit wird von Apple kaum weiterentwickelt; kein Szeneneditor auf Engine-Niveau; Partikel- und Animationswerkzeuge einfacher als in Unity/Godot | **Empfehlung** für dieses Projekt |
| Godot 4 | Kostenlos, guter 2D-Editor, Animationen, plattformübergreifend | iOS-Export mit mehr Reibung, GDScript/C# statt Swift, zweites Ökosystem | Plan B, falls der Spike bei Effekten scheitert |
| Unity | Größtes Ökosystem, starke Effekte | Lizenzrisiko, schwere App, Overkill für 2D-TD | nein |

**SpriteKit-Bewertung im Einzelnen.** Für ein 2D-TD mit wenigen hundert Objekten
reicht SpriteKit sicher: Batching über Texturatlanten, `SKEmitterNode` für
Partikel, `SKShader` und `SKLightNode` für die 2.5D-Anmutung. Die Schwäche ist
nicht Leistung, sondern Werkzeug: Animationen werden eher im Code oder über
Spritesheets gebaut als in einem Editor. Da die Spiellogik ohnehin nicht in
SpriteKit liegt, bleibt ein späterer Wechsel der Darstellung (Metal, Godot) möglich,
ohne die Simulation anzufassen.

**SwiftUI** für Menüs, HUD und Ergebnisbildschirm. Das Schlachtfeld läuft in einer
`SpriteView`. Das HUD liegt als SwiftUI-Ebene darüber.

## 2. Schichten

```
┌──────────────────────────────────────────────────────┐
│ App (SwiftUI)        Menüs, HUD, Ergebnis, Navigation │
├──────────────────────────────────────────────────────┤
│ Battle (SpriteKit)   Szene, Knoten, Effekte, Eingabe  │  liest Zustand + Ereignisse,
│                      → übersetzt Antippen in Befehle  │  schreibt nur Befehle
├──────────────────────────────────────────────────────┤
│ OddlingsCore (Swift-Paket, nur Foundation)            │
│   Config    Balancewerte laden und prüfen             │
│   Model     GameState, Tower, Enemy, Wave … (Werte)   │
│   Sim       step(state, commands) → (state, events)   │
│   Rules     Zielwahl, Schaden, Kette, Verlangsamung   │
└──────────────────────────────────────────────────────┘
```

Regeln:

1. **`OddlingsCore` importiert weder SpriteKit noch SwiftUI noch UIKit.** Ein Test
   prüft das (Quelltext-Suche).
2. **Eingaben sind Befehle**, nicht direkte Zustandsänderungen:
   `build(type, cell)`, `sell(towerID)`, `callNextWave`. Die Darstellung ruft nie
   eine Methode auf, die Gold abzieht.
3. **Die Simulation meldet Ereignisse** (`enemyKilled`, `towerFired(targets:)`,
   `enemyLeaked`, `waveStarted`, `missionEnded` …). Effekte und Ton hängen an
   Ereignissen, nicht an Zustandsvergleichen.
4. **Zustand ist ein Wert** (`struct`, `Codable`, `Equatable`). Das macht
   Speichern, Replay, Vergleich und Tests trivial – und ist die einzige
   Vorleistung für späteren Mehrspieler.

## 3. Zeit und Determinismus

- **Fester Takt:** 30 Schritte je Sekunde (`ticksPerSecond` in der Konfiguration).
  Die Szene sammelt die Bildzeit und führt so viele Schritte aus, wie fällig sind
  (höchstens 8 je Bild, sonst Zeitlupe statt Absturz). Positionen werden für die
  Anzeige zwischen zwei Schritten interpoliert.
- **2× Geschwindigkeit** = doppelt so viele Schritte je Bild, nicht größere
  Schritte. Ergebnis bei 1× und 2× identisch (Test).
- **Zufall** nur über einen eigenen, gesäten Generator im Zustand (SplitMix64).
  Mission 1 braucht keinen Zufall; der Generator ist trotzdem da, damit niemand
  später `Int.random` benutzt.
- **Keine Iteration über `Dictionary` oder `Set`** in der Simulation. Swift mischt
  deren Reihenfolge je Prozess; zwei Läufe gingen still auseinander. Entitäten
  liegen in Arrays, sortiert nach fortlaufender ID.
- **Keine Uhrzeit** (`Date()`) in der Simulation. Zeit ist `tick`.
- **Fließkomma:** `Double`. Auf iPhones (alle ARM64) mit gleichem Binärstand
  reproduzierbar. Für künftigen geräteübergreifenden Lockstep-Mehrspieler wäre das
  zu prüfen; bis dahin bewusst nicht vorweggenommen.

## 4. Spätere Mehrspieler-Fähigkeit – was jetzt getan wird und was nicht

Getan: Befehle statt Direktzugriff, Zustand als Wert, Determinismus.
Damit bleiben beide üblichen Wege offen (Lockstep mit Befehlsaustausch oder ein
autoritativer Host, der Zustand verschickt).

Nicht getan: Netzcode, Spieler-IDs in Befehlen, Teamressource, Backend. Ein
`playerID`-Feld in Befehlen kommt, wenn Koop beginnt; das ist eine kleine,
mechanische Änderung.

## 5. Projektaufbau

```
Oddlings/
├── CLAUDE.md, README.md, CHANGELOG.md
├── project.yml                  XcodeGen-Beschreibung (das .xcodeproj wird erzeugt, nicht eingecheckt)
├── App/                         SwiftUI-App und SpriteKit-Szene (Module in §6)
│   ├── OddlingsApp.swift, StartView.swift   Einstieg: zeigt den Schirm, den AppFlow vorgibt
│   ├── Flow/                    Schirmfolge, Spielstand-Ort, Einstellungen
│   ├── UI/                      Hauptmenü, UITheme, Schriften, Haptik
│   ├── Campaign/                Kampagnenkarte Region 1
│   ├── Avatar/                  Avatar-Aufbau, Avatar-Menü, Porträtkatalog
│   ├── Battle/                  Mission: Takt, Szene, Bedienung, HUD, Kreismenü
│   │   └── Fx/                  Bewegung und Effekte an Ereignissen (D-050)
│   ├── Spike/                   Leistungsprobe WP-01, Wegwerfcode
│   └── Assets.xcassets/         Battle.spriteatlas, Maps, UI, Avatar, AppIcon
├── AppTests/                    Darstellungstests (XCTest, nur macOS-CI)
├── AppUITests/                  Ende-zu-Ende-Tests (XCUITest, D-029)
├── Packages/OddlingsCore/       Simulation und Spielstand, nur Foundation
│   ├── Sources/OddlingsCore/
│   │   └── Resources/
│   │       ├── Balance/         mvp-mission-01.json, races.json: die einzige Quelle der Zahlen
│   │       └── Campaign/        region-01.json: Knoten, Bedingungen, Sternschwellen
│   └── Tests/OddlingsCoreTests/
├── art/                         Rohbilder und ENTSTEHUNG.md je Bildgruppe (nicht in der App)
├── tools/art-check/             Prüft Atlas und Bilder gegen den Asset-Vertrag (CI-Job „art")
├── scripts/                     regeln-pruefen.sh, links-pruefen.py, apple.py, swift-linux.sh
├── .claude/skills/              arbeitspaket-ausliefern, spielgrafik
└── docs/
```

Begründung **XcodeGen**: Projektdateien werden aus einer lesbaren YAML erzeugt,
neue Dateien landen nur im Ordner, keine Merge-Konflikte im `.pbxproj`. Zählora
arbeitet genauso (`project.yml`, Skill `xcode-workflow`).

Begründung **eigenes Paket**: `swift test` für die Simulation läuft in Sekunden,
ohne Simulator, und auch unter Linux (CI-Job `core-linux`, Cloud-Sitzungen).

### Kern: wer was weiß

| Datei | Aufgabe |
|---|---|
| `BalanceConfig.swift`, `ConfigValidation.swift` | Werte einer Mission aus JSON lesen und **vollständig** prüfen, mit Ort jedes Verstoßes |
| `MissionMap.swift`, `PathGeometry.swift` | Raster, Bauzonen, Weg als Polylinie; Position aus zurückgelegter Strecke |
| `GameState.swift`, `Simulation.swift` | Zustand als Wert, `step` mit fester Reihenfolge (siehe [Datenmodelle](data-models.md#befehle-und-ereignisse)) |
| `SplitMix64.swift`, `Checksum.swift` | Einziger Zufall; Prüfsumme für Determinismus und Replays |
| `Autoplayer.swift` | Mitspieler für Vorführung, Oberflächen- und Balancetests |
| `Races.swift` | Völker aus `races.json`: Fähigkeit, Turmfaktoren, Ränge, Talente. `BalanceConfig.applying(race, talents:)` macht daraus eine zweite Missionskonfiguration, die Simulation kennt keine Völker |
| `Talents.swift`, `Avatar.swift` | Talentseiten, Rang aus Sternen (`AvatarRank`), Avatar nur gültig anlegbar |
| `Campaign.swift` | Region, Knoten, Sterne (`StarRating`), Fortschritt; Prüfung der Region beim Laden |
| `SaveGame.swift`, `SaveStore.swift` | Spielstand mit Schema 2, atomar geschrieben, vorige Fassung bleibt, beim Laden geprüft (D-022) |

Regel dahinter: **Alles, was ein Ergebnis ändert, liegt im Kern und ist rein.** Volk,
Talent und künftig Ausrüstung (D-066) wirken nur als Konfiguration, die vor dem
Missionsstart entsteht. So bleiben Simulation, Balancetests und Determinismus
unberührt, und jede Kombination ist eine geprüfte Konfiguration.

## 6. Darstellung und App

### Module

| Ordner | Was | Darf | Darf nicht |
|---|---|---|---|
| `Flow/` | `AppFlow` (Schirme `menu`, `setup`, `map`, `avatar`, `battle`), Spielstand laden und schreiben über `SaveStore`, `AppSettings` getrennt vom Spielstand | Schirm wechseln, Fortschritt nach einem Sieg eintragen, Talentwahl speichern | Sterne oder Rang selbst rechnen (kommt aus dem Kern) |
| `UI/` | `MainMenuView`, `UITheme` (Farben, Schriften, Formen), `AppFonts` (D-032), `FeedbackPlayer` (Haptik je Ereignis) | aussehen, rückmelden | Spielzustand ändern |
| `Campaign/` | `CampaignMapView`: gemalte Karte Region 1, Knoten, Missionstafel | Knoten wählen, Mission starten (über `AppFlow`) | Freischaltung entscheiden |
| `Avatar/` | `AvatarSetupView` (R-5), `AvatarScreen` (R-6, eigener Schirm zum Ausbauen), `AvatarPortraits` | Avatar anlegen, Talent wählen (über `AppFlow`) | Talentwerte kennen (stehen in `races.json`) |
| `Battle/` | `BattleModel` (Takt), `BattleScene`, `BattleController` (Tippen → Befehle), `BattleHUD`, `RingMenu`, `BoardLayout`, `HudLayout` | Befehle erzeugen, Zustand und Ereignisse lesen | Gold, Leben oder Gegner direkt ändern (Regel 2) |
| `Battle/Fx/` | `FxDirector` spielt Effekte an Ereignissen auf eigener Uhr; `FxMath` rein; `FxProbe`, `FxStatsOverlay` nur für Messung und E2E | gepoolte Sprites, Tweens im Bildtakt | `SKAction`/`SKShapeNode` für flüchtige Effekte, Zustand anfassen (D-050) |
| `Spike/` | Leistungsprobe WP-01 | – | wird nach der Messung gelöscht |

### Datenfluss beim Missionsstart

```
Spielstand (SaveStore) ──▶ AppFlow: Avatar (Volk, Talente), Fortschritt (Sterne)
                                 │
     mvp-mission-01.json ──▶ BalanceConfig ──applying(race, talents)──▶ BalanceConfig der Mission
                                                                          │
                       BattleModel ── Befehle ──▶ Simulation.step ──▶ Zustand + Ereignisse
                            ▲                                              │
                 BattleController (Tippen)            BattleScene, FxDirector, HUD, FeedbackPlayer
                                                                          │
                                         Sieg ──▶ AppFlow trägt Sterne ein ──▶ SaveStore
```

### Szene

- Für jede Entität ein Knoten, verwaltet über ein Wörterbuch `ID → SKNode`
  (nur in der Darstellung; dort ist die Reihenfolge egal). Neue IDs erzeugen
  Knoten, verschwundene werden zurückgegeben (Knoten-Pool).
- Koordinaten: Simulation in Feldern, `BoardLayout` rechnet einmal in Punkte um;
  Szene, Kreismenü und Oberflächentests nutzen dieselbe Rechnung.
- **HUD-Anbindung:** `BattleController` ist `@Observable` und setzt nur geänderte
  Werte (Gold, Leben, Welle, Zustand). Nie den ganzen Zustand je Bild
  veröffentlichen (Risiko T3).
- **Bilder** kommen aus dem Atlas unter den Namen des
  [Asset-Vertrags](../art/asset-vertrag.md); fehlt ein Bild, zeichnet `BattleStyle`
  einen Platzhalter. Der Kampfplatz ist eine gemalte Lichtung aus Teilen der
  Kampagnenkarte ([Grafik 05](../konzepte/grafik-05-kampfplatz.md)).
- **Bewegung (FX 01, D-050):** Laufen aus der zurückgelegten Strecke, Treffer, Tod,
  Turmangriffe und Fähigkeiten hängen an Ereignissen. Echte Gliedmaßen kommen als
  vorgerenderte Bildfolgen aus 3D-Modellen (FX 02, D-051,
  [Konzept](../konzepte/fx-02-figuren-in-3d.md)); ohne Bildfolge bleibt das
  gemalte Standbild.

### Testschalter

Die App kennt Startargumente nur für Tests (`--e2e-*`, `--play`, `--fx-messung`).
Sie stellen einen Zustand her (frischer Speicher, fertiger Avatar, gehaltene erste
Welle), ändern aber keine Regel. Liste und Zweck:
[Teststrategie](testing-strategy.md#ende-zu-ende-tests-d-029).

## 6a. Grafik und Werkzeuge

Bilder entstehen außerhalb der App und werden fertig eingecheckt:
Skill `spielgrafik` (FLUX lokal, Freistellen, Atlas, Karte, Kampfplatz) für
Gemälde, `tools/figuren-3d` (FX 02, in Arbeit) für Bildfolgen aus 3D. Jede
Bildgruppe hat eine `ENTSTEHUNG.md` mit Herkunft; `tools/art-check` prüft Namen,
Maße und Anker in der CI. Kein Werkzeug davon landet in der App.

## 7. Mindestanforderungen [ENTSCHIEDEN D-006]

iOS 17, iPhone, Querformat. iOS 17 bringt `@Observable` und läuft auf allen
iPhones ab XS/XR. Ältere Geräte verdoppeln den Testaufwand für wenige Nutzer.
iPad: nicht gezielt, aber nicht verhindern; Kampfplatz und Menüs werden auf dem
iPad mitgeprüft (Oberflächentests).

## 8. Technische Risiken

Siehe [phase-0-analyse.md](../production/phase-0-analyse.md#technik), T1–T6.
