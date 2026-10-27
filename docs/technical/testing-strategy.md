# Teststrategie

Status: **gilt**, umgesetzt bis 0.12.0; Ende-zu-Ende-Tests **[ENTSCHIEDEN D-029]**

## Ebenen

| Ebene | Was | Wo | Wann |
|---|---|---|---|
| Regeltests | Einzelregeln von `OddlingsCore`: Kosten, Zielwahl, Kette, Verlangsamung, Durchbruch, Sieg/Niederlage | `swift test` im Paket | bei jeder Änderung |
| Konfigurationstests | JSON lädt, Validierung greift, ungültige Werte werden abgewiesen | Paket | bei jeder Änderung |
| Determinismus | Gleiche Befehlsfolge → gleiche Prüfsumme des Endzustands; 1× = 2×; Speichern/Laden mitten in der Welle ändert das Ergebnis nicht | Paket | bei jeder Änderung |
| Balancetests | Bot-Bauweisen aus der Konfiguration: „Mischung gewinnt", „nur Sporen verliert", Reserve-Grenzen | Paket | bei jeder Änderung an Werten |
| Architekturtest | `OddlingsCore` importiert kein SpriteKit/SwiftUI/UIKit | Paket | bei jeder Änderung |
| Darstellung | Szene startet, Knotenzahl folgt dem Zustand | XCTest in der App | im CI auf macOS |
| Oberfläche | Mission starten, Turm bauen, Mission zu Ende spielen (2× Tempo, Bot-Befehle) | XCUITest | im CI, vor TestFlight |
| **Ende-zu-Ende** | Die ganze App wie ein Spieler: Menü, bauen, verkaufen, Welle, Pause, 2×, Sieg, Niederlage, Nochmal, Hintergrund; siehe unten und [e2e-tests.md](../konzepte/e2e-tests.md) | XCUITest (`AppUITests/`) | in der CI bei jedem PR, Pflicht vor TestFlight |
| Spieltest | Menschen, echtes iPhone, Beobachtungsprotokoll | manuell | Ende jeder Phase |

## Regeln

1. **Ein Regeltest pro Regel, mit konstruiertem Fall.** Beispiel Kette: drei
   Gegner im Abstand 1,0, Radius 1,3, Sprünge 4 → genau drei Treffer in der
   Reihenfolge nach Nähe, Schaden 18 / 14,4 / 11,52.
2. **Jeder Test wird einmal rot gesehen.** Regel kurz kaputt machen, Test muss
   fehlschlagen. Ein Test, der nie rot war, beweist nichts.
3. **Balancetests prüfen Beziehungen, nicht exakte Zahlen.** „Blitz + Sporen
   Reserve > nur Blitz Reserve + 0,3" bleibt bei kleinen Wertänderungen stabil;
   „Reserve = 1,42" bricht bei jeder.
4. **Testkonfigurationen sind eigene kleine JSON-Dateien** in den Tests, nicht die
   Missionsdatei. Sonst bricht jede Balanceänderung Regeltests.

## Werkzeuge und Orte

- Swift Testing (`@Test`) oder XCTest im Paket; beides läuft mit `swift test`.
- **CI:** GitHub Actions auf macOS: `swift test` für das Paket, `xcodebuild test`
  für App und Oberfläche. Das Repository ist öffentlich, macOS-Minuten kosten
  deshalb nichts (Stand 25.10.2026). Wird es privat, kosten sie ein
  Vielfaches; dann Oberflächentests nur noch bei Pull Requests.
- Seit WP-01 läuft `.github/workflows/ci.yml`: App-Bau
  und Probelauf im Simulator (starten, 20 s laufen lassen, Bild sichern) auf macOS.
- Seit WP-02 testet die CI OddlingsCore zweimal: unter Linux (Container
  `swift:6.2-noble`, fängt Apple-Importe sofort) und auf macOS vor dem App-Bau.
- **Cloud-Sitzungen** bekommen Swift für Linux über `scripts/swift-linux.sh`
  (Startup-Haken, gemessen am 25.10.2026: läuft, 46 Tests in unter einer
  Sekunde). Das deckt nur das Paket ab; App und Oberfläche baut allein die
  macOS-CI.
- **CI-Jobs heute** (`.github/workflows/ci.yml`): `regeln` (`scripts/regeln-pruefen.sh`:
  Architektur, Sicherheit, Verweise, Doku-Stand nach D-067), `art` (`tools/art-check`),
  `core-linux` (Paket unter Linux), `iphone` (Paket im Release-Bau, App-Bau,
  `AppTests`, `AppUITests`, Probelauf im Simulator mit Bildschirmfotos und
  Spielstand im Artefakt `simulator-probe`). Zusammengeführt wird nur, wenn alle grün sind.
- Seit WP-10 decken die Swift-Tests Determinismus (`DeterminismTests`: Replay
  mit Prüfsumme, 1× = 2×, Speichern/Laden mitten in der Welle, feste Prüfsumme
  einer kleinen Mission, die Linux und macOS gleich liefern müssen) und Balance
  (`BalanceTests`) ab. Das Python-Prüfskript der Phase 0 ist gelöscht.

## Ende-zu-Ende-Tests (D-029)

Steffen, 25.10.2026: Allgemeine Ende-zu-Ende-Tests sollen mit allen möglichen
Tests prüfen, dass die App genau so funktioniert wie gedacht. **[ENTSCHIEDEN]**

Umgesetzt ab Version 0.5.1; Aufbau und Grundsätze: [e2e-tests.md](../konzepte/e2e-tests.md).

**Stand 0.12.0: 27 Fälle** in `AppUITests/`:

| Datei | Fälle | Ablauf |
|---|---|---|
| `NavigationE2ETests` | 4 | Menü → Karte → Mission → zurück, Vorführung, Hintergrund pausiert, Einstellung übersteht Neustart |
| `CampaignE2ETests` | 2 | Sterne nach Sieg überstehen Neustart, gesperrte Missionen nennen den Grund |
| `AvatarE2ETests` | 4 | Avatar einmal aufbauen (R-5), Zwerge mit Preis und Fähigkeit, Rang schaltet Talent frei (R-6), Aufbau und Menü passen auf den Schirm |
| `BuildAndSellE2ETests` | 4 | Kreismenü, Vorschau, bauen, verkaufen, „fehlt N“, Schließen |
| `HUDE2ETests` | 4 | Startwerte, Welle rufen, Pause hält Countdown, Tempo |
| `TablesE2ETests` | 4 | Pausetafel (weiter, neu starten), Aufgeben, Bildschirmfotos zum Abgleich |
| `MissionE2ETests` | 2 | Niederlage und Nochmal setzt alles zurück, Sieg und zurück ins Menü |
| `AbilityE2ETests` | 2 | Fähigkeit auf den Weg, Abklingzeit, Knopf verschwindet am Missionsende |
| `EffectsE2ETests` | 1 | Vorführung spielt jede Effektart (FX 01) |

**Testschalter** (nur Debug-Bau, ändern keine Regel): `--play` (Mission direkt),
`--demo`, `--e2e-frisch` (leerer Speicher), `--e2e-speicher`, `--e2e-avatar <volk>`
(fertiger Avatar), `--e2e-volle-sterne`, `--e2e-erste-welle` (erste Welle gehalten),
`--e2e-zeitraffer N`, `--e2e-abklingzeit`, `--e2e-mitspieler`, `--e2e-fx`,
`--fx-messung`. Ein neuer Schalter kommt hier in die Liste.

**Was sie prüfen.** Nicht einzelne Regeln (das tun die Paket-Tests), sondern dass
ein Mensch mit Fingern durch die fertige App kommt:

| Bereich | Ablauf (Beispiele) |
|---|---|
| Start | App startet kalt in unter einer Grenze, Startbildschirm, Mission wählen |
| Bauen | Bauzelle antippen, Baumenü, Reichweite sichtbar, bestätigen, Gold sinkt; nicht leistbarer Turm ist gesperrt; abgelehnter Befehl zeigt den Grund |
| Verkaufen | Turm antippen, Werte, Verkaufen, Gold steigt um die Erstattung |
| Ablauf | Pause, 1×/2×, „Nächste Welle“, Kopfleiste zeigt dieselben Werte wie der Zustand |
| Ende | Sieg und Niederlage erreichen (mit Testschalter für schnelle Missionen), Ergebnis, Neustart, zurück |
| Unterbrechung | App in den Hintergrund und zurück, Drehen, Anruf-Simulation; ab P2-2 Fortsetzen nach Beenden |
| Zugänglichkeit | Jedes Bedienelement hat eine Kennung und eine Beschriftung, Tippziele ≥ 44 pt, große Schrift bricht nichts |
| Geräte | kleinstes und größtes Zielgerät im Simulator (Querformat) |

**Regeln**

1. **Jedes neue Feature bringt seinen Ende-zu-Ende-Ablauf mit.** Das ist
   Abnahmekriterium jedes Arbeitspakets mit Bedienung, ab WP-15. Ohne ihn wird
   nicht zusammengeführt.
2. **Bedienelemente bekommen feste Kennungen** (`accessibilityIdentifier`), die
   Tests suchen nie nach sichtbarem Text. Text ändert sich mit Sprache und Stil.
3. **Kein Warten auf feste Zeiten.** Tests warten auf Zustände
   (`waitForExistence`), damit sie auf langsamen CI-Rechnern nicht flackern.
4. **Testschalter nur über Startargumente** (wie heute `--demo`): kurze
   Testmission, festes Tempo, Bot-Befehle. Nie im ausgelieferten Ablauf erreichbar.
5. **Bildschirmfotos jedes Schritts** als CI-Artefakt, damit ein roter Lauf
   ohne Nachstellen lesbar ist.
6. Gegenprobe wie überall: jeder Ablauf einmal rot gesehen.

**Wer baut sie.** Der Code-Thread legt die Grundlage mit XCUITest in der CI an
(Stand: Tabelle oben). Die Abdeckungsliste oben ist die Messlatte; jedes Paket
mit Bedienung ergänzt die Tabelle im selben PR (D-067).
