# Konzept: Spielrahmen (R-1 bis R-4)

Stand 25.10.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-060 (Spielrahmen vorgezogen), D-022 (Speicherstand), D-025
(Festungsfähigkeit und Völker), D-027 (Region 1), [05](../game-design/05-campaign-and-progression.md),
[03](../game-design/03-races-and-avatar.md), [07](../game-design/07-ui-ux.md#3-schirme-und-abläufe),
Pakete R-1 bis R-4 in der [Roadmap](../production/roadmap.md).

Dieses Konzept legt die Architektur für alle vier Pakete fest, damit R-2 bis R-4
nichts umbauen müssen, was R-1 gerade gebaut hat. R-1 und R-2 kommen in einem PR:
Ein Speicherstand ohne Karte zeigt dem Spieler nichts, und „Spielen“ braucht ein Ziel.
R-3 und R-4 bekommen je einen eigenen.

## Ziel

Wer die App öffnet, sieht ein Spiel und keine Probe: Hauptmenü, „Weiter mit
Mission 1", die Karte des Flüsterwalds mit allen neun Missionen, Sterne für den
Sieg, und das Spiel weiß beim nächsten Start noch, was man geschafft hat.
Danach (R-3, R-4) greift man mit der Festungsfähigkeit ein und wählt sein Volk.

## Umfang je Paket

| Paket | Drin | Version |
|---|---|---|
| R-1 | Schirmfolge Menü → Karte → Schlacht → Ergebnis → Karte; Speicherstand nach D-022; Sterne je Mission aus der Missionsdatei; Karte „Weiter mit Mission N" im Menü; Einstellungen (Vibration) | 0.7.0, zusammen mit R-2 |
| R-2 | Kampagnenkarte Region 1: neun Knoten, Wege, Gabelung, Bossknoten, Nebenmissionen als Rauten; Missionstafel; Sternsumme; Sperrgründe | 0.7.0 |
| R-3 | Steinregen als Befehl `useAbility(Point)` mit Verzögerung, Kreis, Anhalten, Abklingzeit; Knopf unten rechts (D-033) | eigenes Konzept vor dem Code |
| R-4 | Völkerwahl Zwerge und Elfen, Bollwerk und Mondmal, passiver Zug, Volk im Speicherstand | eigenes Konzept vor dem Code |

**Nicht drin:** Missionen 2 bis 9 als spielbare Karten. Sie brauchen Zwergenbank,
Aufwertungen, Panzerbestie in eigener Rolle und einen Boss, also Phase 2. Eine
Mission, die nur Mission 1 mit anderem Weg wäre, würde versprechen, was sie
nicht hält. Auf der Karte stehen sie deshalb sichtbar, mit ihrer Neuheit
(„Neu: Zwergenbank") und einem ehrlichen Zustand: gesperrt, solange die
Vorgängermission fehlt, „in Arbeit", sobald sie nach den Regeln offen wäre.
Fortsetzen einer laufenden Mission nach App-Ende (P2-2). Ton und Musik in den
Einstellungen: Ein Schalter ohne Wirkung wäre unprofessionell, er kommt mit K9.

## Architektur

### Wer was darf

```
Kern (OddlingsCore, nur Foundation, unter Linux getestet)
├── BalanceConfig.mission.stars       Sterngrenzen je Mission (Daten)
├── StarRating                        Leben übrig → 0 bis 3 Sterne (rein)
├── CampaignConfig  (region-01.json)  Knoten, Bedingungen, Lage auf der Karte (Daten)
├── CampaignProgress                  beste Sterne je Mission (Wert)
├── Campaign                          Regeln: Zustand eines Knotens, Sternsumme, nächste Mission (rein)
├── SaveGame + SaveGameCodec          Speicherstand, Schema, Prüfung, Migration (rein)
└── SaveStore                         Datei schreiben und lesen, atomar, mit voriger Fassung

App (SwiftUI)
├── AppFlow        @Observable: aktueller Schirm, Fortschritt, schreibt nach jedem Ergebnis
├── AppSettings    UserDefaults: Vibration (gehört nicht zum Spielstand, K6)
├── MainMenuView   Gestaltung vom Oberflächen-Thread, Aufrufe vom AppFlow
├── CampaignMapView, MissionPanel   R-2
└── BattleView     bekommt die Mission und meldet das Ergebnis, sonst unverändert
```

| Baustein | Darf | Darf nicht |
|---|---|---|
| `Campaign` | aus Konfiguration und Fortschritt ableiten, was offen ist | Dateien lesen, Zustand halten |
| `SaveGameCodec` | Daten prüfen, Unbekanntes verwerfen, alte Schemata hochheben | raten: Eine unbekannte Mission wird verworfen, nicht umgedeutet |
| `SaveStore` | im übergebenen Verzeichnis schreiben und lesen | wissen, wo das Verzeichnis liegt (das sagt die App) |
| `AppFlow` | Schirme wechseln, nach einem Ergebnis `Campaign.recording` aufrufen und speichern | Sterne selbst rechnen, Spielzustand ändern |
| `BattleView` | ein Ergebnis melden (gewonnen/verloren, Leben übrig) | Fortschritt kennen |

**Warum die Dateiarbeit im Kern liegt:** `SaveStore` nutzt nur `FileManager` und
`Data`, also Foundation (Regel 1 bleibt). Im Kern läuft er unter Linux in jedem
CI-Lauf mit echten Dateien, auch die Fälle „Datei beschädigt" und „Schreiben
mitten drin abgebrochen". In der App wäre er nur im Simulator testbar.

### Datenfluss nach einer Mission

```
Simulation ─Outcome + fortressLives─▶ BattleView.onFinish(MissionResult)
  ─▶ AppFlow.finish ─▶ StarRating ─▶ Campaign.recording(…) ─▶ SaveStore.save
  ─▶ Ergebnistafel zeigt Sterne; „Weiter" führt zur Karte
```

Gespeichert wird beim Ergebnis, nicht beim Verlassen der App: Ein Sieg, der
verloren geht, weil das System die App beendet hat, wäre der schlimmste Fehler
dieses Pakets.

### Missionsdaten

- Sterne nach verbleibendem Leben (05): `mission.stars = { "two": 15, "three": 20 }`
  in `mvp-mission-01.json`. Ein Sieg gibt immer mindestens einen Stern. Geprüft:
  `0 < two ≤ three ≤ fortressLives`.
- Die Region steht in `Resources/Campaign/region-01.json`:

```json
{
  "id": "region-01",
  "nodes": [
    { "id": "m1", "kind": "main", "mission": "mvp-mission-01", "position": [0.10, 0.70], "requires": [] },
    { "id": "m2", "kind": "main", "position": [0.22, 0.52], "requires": ["m1"], "novelty": "bank" },
    { "id": "m5a", "kind": "main", "position": [0.55, 0.30], "requires": ["m4"] },
    { "id": "m7", "kind": "boss", "position": [0.90, 0.45], "requires": ["m6a", "m6b"], "requiresAny": true },
    { "id": "n1", "kind": "side", "position": [0.24, 0.84], "requires": [], "stars": 6 }
  ]
}
```

  `mission` fehlt, solange die Mission nicht gebaut ist. `requiresAny` macht den
  Boss nach einem der beiden Wege erreichbar (05: „Beide Wege führen zum Boss").
  `position` ist ein Anteil der Kartenfläche, damit jede Bildschirmgröße dieselbe
  Karte zeigt. Die Lage gibt die Skizze aus 05 wieder. Nebenmissionen haben keinen
  Vorgänger, nur ihre Sterngrenze (6 und 15, aus 05); ihre Lage unter dem Weg ist
  **[VORSCHLAG]**.
- Prüfung beim Laden: eindeutige Kennungen, jede Bedingung zeigt auf einen
  bekannten Knoten, keine Kreise, mindestens ein Knoten ohne Bedingung, jede
  genannte Missionsdatei lädt und ist gültig. Ein Test lädt die echte Datei.
- Anzeigenamen und Neuheiten stehen in der App (`CampaignTexts`), nicht in der
  Datei: Namen sind laut 07 Platzhalter, und Texte gehören zur Oberfläche.
  Feste Namen aus 05: „Sumpfpfad" (M5a), „Ruinen" (M5b). Die übrigen heißen
  „Mission 2" usw. und „Nebenmission 1/2", bis Steffen Namen festlegt. Erfunden
  wird keiner.

### Knotenzustand

| Zustand | Bedingung | Karte zeigt |
|---|---|---|
| `completed(stars)` | Sterne > 0 im Fortschritt | Sterne unter dem Knoten, nochmal spielbar |
| `open` | Bedingungen erfüllt, Mission vorhanden | leuchtend, Tafel mit „Starten" |
| `inPreparation` | Bedingungen erfüllt, Mission noch nicht gebaut | offen gezeichnet, Tafel „Kommt mit dem nächsten Paket", kein Start |
| `locked(.after(ids))` | Vorgänger fehlt | gedimmt mit Schloss, „Nach Mission 4" |
| `locked(.stars(n))` | Nebenmission, Sternsumme zu klein | Raute gedimmt, „Ab 6 Sternen" |

„Weiter mit Mission N" im Menü ist der erste Knoten in Kartenreihenfolge, der
`open` und nicht `completed` ist; gibt es keinen, die zuletzt gewonnene Mission.

### Speicherstand (D-022)

```
SaveGame {
  schemaVersion: 1
  progress: CampaignProgress { records: [ { mission: "m1", bestStars: 3 } ] }   // nach Kennung sortiert
  race: Race?                                                                    // ab R-4, im Schema schon vorgesehen
}
```

- **Ort:** `Application Support/Oddlings/save.json`, daneben `save.previous.json`.
- **Schreiben:** vorhandene Datei nach `save.previous.json` kopieren, dann
  `Data.write(…, options: .atomic)` (temporäre Datei, dann umbenennen). Ein
  Abbruch hinterlässt immer eine ganze Datei.
- **Lesen:** Größe begrenzt (ein Spielstand ist wenige hundert Byte; eine
  übergroße Datei ist kein Spielstand), dann JSON, dann Prüfung. Scheitert die
  Hauptdatei, gilt die vorige; scheitert auch sie, beginnt ein neuer Stand. Der
  Grund geht ins Protokoll (`os.Logger` in der App), nie still.
- **Prüfung:** bekanntes Schema, Sterne 0 bis 3, Kennungen aus der Region.
  Unbekannte Einträge werden einzeln verworfen, der Rest bleibt.
- **Neueres Schema** (ältere App nach einem Update zurückgespielt): nicht lesen
  und **nicht überschreiben**. Die App spielt mit einem neuen Stand im Speicher,
  schreibt aber nichts, damit der neuere Stand erhalten bleibt.
- **Migration:** `SaveGameCodec.migrate(from:)` je Version als reine Funktion;
  zu Schema 1 gibt es noch keine, der Test hält die Stelle fest.
- **Oberflächentests** bekommen über das Startargument `--e2e-speicher <name>`
  (nur in Debug-Bauten) ein eigenes Verzeichnis im temporären Ordner. So kann ein
  Test die App beenden, neu starten und prüfen, dass der Sieg noch da ist, ohne
  den echten Stand zu berühren.

### Schirmfolge

```
Hauptmenü ──Spielen──▶ Karte ──Starten──▶ Schlacht ──Ergebnis──▶ Karte
    │  └──Weiter mit Mission N─────────────▲
    ├──Einstellungen (Tafel über dem Menü)
    └──Vorführung, Leistungsprobe (bleiben bis WP-01 gemessen ist)
Schlacht ──Zurück/Aufgeben──▶ Karte  (ohne Ergebnis, nichts gespeichert)
```

`--play` startet weiter direkt Mission 1 und `--demo` die Vorführung (CI-Probelauf,
bestehende Oberflächentests).

## Bedienentscheidungen

- **Nach dem Sieg zur Karte, nicht ins Menü.** Dort sieht man die neuen Sterne
  und den nächsten Knoten. „Nochmal" bleibt auf der Ergebnistafel.
- **Kein Bestätigungsdialog beim Starten**: ein Tipp auf den Knoten öffnet die
  Tafel, „Starten" startet (07). Doppeltippen auf den Knoten startet nicht; ein
  versehentlicher Start kostet sonst eine Mission.
- **Sterne nur aus einem Sieg.** Eine Niederlage ändert den Fortschritt nie, auch
  nicht nach unten. Gespeichert wird die beste Wertung.
- **Einstellungen**: zuerst nur „Vibration" (wirkt, sobald der FeedbackPlayer
  des Oberflächen-Threads da ist) und der Hinweis „Offline · ohne Konto".

## Sicherheit

- Kein Netz, keine neue Bibliothek, keine neuen Rechte.
- Der Speicherstand ist Fremddaten: Größe, Schema, Wertebereich und Kennungen
  werden geprüft, bevor er den Fortschritt erreicht. Er erreicht nie die
  Simulation; die rechnet jede Mission mit denselben Werten (05: keine Werteboni).
- Kein Spielstand im Protokoll, nur der Grund einer Ablehnung.
- Das Startargument für Tests gibt es nur in Debug-Bauten.

## Testplan

Jeder neue Test wird einmal rot gesehen.

| Ebene | Test |
|---|---|
| Kern `StarRatingTests` | Grenzen genau (14/15/19/20 Leben), Niederlage 0, Sieg mindestens 1; ungültige Grenzen in der Prüfung gemeldet |
| Kern `CampaignTests` | echte Region lädt und ist gültig; jeder Fehler der Prüfung (doppelte Kennung, unbekannter Vorgänger, Kreis, kein Start, fehlende Missionsdatei) einzeln; Zustände je Knoten; Gabelung: Boss nach einem Weg offen; Nebenmission an der Sternsumme; „Weiter mit" |
| Kern `SaveGameTests` | Hin und zurück gleich; Prüfung verwirft unbekannte Mission und Sterne außerhalb 0–3 einzeln; neueres Schema → nicht lesbar und nicht beschreibbar; kaputtes JSON |
| Kern `SaveStoreTests` | schreiben, lesen; vorige Fassung entsteht; kaputte Hauptdatei → vorige gilt; beide kaputt → neuer Stand; übergroße Datei abgelehnt; neueres Schema wird nicht überschrieben |
| App `AppFlowTests` | Sieg mit 20 Leben → 3 Sterne gespeichert; Niederlage ändert nichts; schlechterer Sieg senkt nicht; „Weiter mit" wandert nach dem Sieg |
| E2E `CampaignE2ETests` | Menü → Karte → M1 → Sieg (Vorführung) → Karte zeigt Sterne; App neu starten → Sterne noch da; M2 zeigt „in Arbeit"; Weiter mit Mission 1 startet direkt |
| E2E bestehend | laufen mit `--play` unverändert weiter |

## Schritte

R-1 und R-2 (ein PR, 0.7.0): Kern (Sterne, Region, Fortschritt, Speicherstand) →
AppFlow und Einstellungen → Kartenansicht → Tests → Dokumente, CHANGELOG. R-3 und R-4 bekommen vor dem Code je
einen Abschnitt hier oder ein eigenes Konzept.

## Abstimmung

- **Oberflächen-Thread** (0.6.0): liefert `MainMenuView` (Aufrufe `onPlay`,
  `onWatch`, `onSpike`; ich ergänze `onContinue`), `UITheme`, Tafeln und Knöpfe,
  und baut BattleView um. Ich docke nur an `init` und an die Ergebnistafel an
  (`controller.shownOutcome`). Wer zuerst auf main ist, der andere zieht nach.
- **Grafik-Thread:** Kartenbild Flüsterwald, Knotensymbole; bis dahin gezeichnet.
- **Planung:** Sperrzustand „in Arbeit" und die Lage der Nebenmissionen sind
  Vorschläge. Völker sind sofort wählbar, solange nur M1 spielbar ist (Steffen, 25.10.2026: „ja“ auf den Vorschlag der Roadmap, R-4); die Freischaltung nach D-027 greift, sobald M7 steht.

## Risiken

- **Zwei PRs am selben Einstieg** (StartView, BattleView): Abstimmung oben,
  kleine Ansatzstellen, Kern zuerst.
- **Ein Spieler verliert Fortschritt:** abgefangen durch atomares Schreiben,
  vorige Fassung und Speichern beim Ergebnis; jeder Weg hat einen Test.
- **Karte wirkt leer**, solange acht von neun Knoten nicht spielbar sind: Die
  Neuheit je Knoten zeigt, was kommt; das ist die Vorschau, die 05 will.
