# Architektur

Status: **[VORSCHLAG]** bis zur Freigabe; der Technik-Spike (WP-01) bestätigt oder
widerlegt die Stack-Wahl.

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
├── CLAUDE.md, README.md
├── project.yml                  XcodeGen-Beschreibung (das .xcodeproj wird erzeugt, nicht eingecheckt)
├── App/                         SwiftUI-App und SpriteKit-Szene
│   ├── OddlingsApp.swift, StartView.swift   vorläufiger Einstieg (Mission, Leistungsprobe)
│   ├── Battle/                  Takt (BattleModel), Szene, Sprites nach Asset-Vertrag, Platzhalterstil
│   ├── Spike/                   Leistungsprobe WP-01, Wegwerfcode
│   └── Assets.xcassets/         Symbol; Battle.spriteatlas folgt aus dem Art-Direction-Thread
├── AppTests/                    Darstellungstests (XCTest, nur macOS-CI)
├── Packages/OddlingsCore/       Simulation, nur Foundation
│   ├── Sources/OddlingsCore/
│   │   └── Resources/Balance/   Balancewerte, die einzige Quelle (seit WP-02)
│   └── Tests/OddlingsCoreTests/
└── docs/
```

Begründung **XcodeGen**: Projektdateien werden aus einer lesbaren YAML erzeugt,
neue Dateien landen nur im Ordner, keine Merge-Konflikte im `.pbxproj`. Zählora
arbeitet genauso (`project.yml`, Skill `xcode-workflow`).

Begründung **eigenes Paket**: `swift test` für die Simulation läuft in Sekunden,
ohne Simulator, und grundsätzlich auch unter Linux.

## 6. Darstellung

- Für jede Entität ein Knoten, verwaltet über ein Wörterbuch `ID → SKNode`
  (nur in der Darstellung; dort ist die Reihenfolge egal). Neue IDs erzeugen
  Knoten, verschwundene werden zurückgegeben (Knoten-Pool).
- Koordinaten: Simulation in Feldern, Darstellung rechnet einmal in Punkte um.
- **HUD-Anbindung:** ein `@Observable`-Modell, das nur geänderte Werte setzt
  (Gold, Leben, Welle, Zustand). Nie den ganzen Zustand je Bild veröffentlichen
  (Risiko T3).

## 7. Mindestanforderungen [VORSCHLAG D-006]

iOS 17, iPhone, Querformat. iOS 17 bringt `@Observable` und läuft auf allen
iPhones ab XS/XR. Ältere Geräte verdoppeln den Testaufwand für wenige Nutzer.
iPad: nicht gezielt, aber nicht verhindern.

## 8. Technische Risiken

Siehe [phase-0-analyse.md](../production/phase-0-analyse.md#technik), T1–T6.
