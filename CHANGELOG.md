# Änderungsprotokoll

Jede Auslieferung auf `main` bekommt hier einen Eintrag, neueste oben.

- **Version** = `MARKETING_VERSION` in `project.yml`. Neue Funktion oder neues
  Arbeitspaket: zweite Stelle (0.2.0 → 0.3.0). Korrektur, Doku, Werkzeug: dritte
  Stelle (0.2.0 → 0.2.1).
- **Bau** = Laufnummer von `testflight.yml`, wird beim Archivieren als
  `CURRENT_PROJECT_VERSION` gesetzt. Ein Bau zählt erst, wenn Apple ihn als VALID
  meldet. Gescheiterte Bauten stehen mit Grund dabei, weil ihre Nummer verbraucht ist.
- Ein Eintrag, der nichts an der App ändert (nur Dokumente), hebt die Version
  nicht und löst keinen Bau aus. Dort steht „Dokumente, kein Bau“ (D-023).

<<<<<<< Updated upstream
## Dokumente, kein Bau – 25.10.2026 (Bedienung Phase 2, Kreismenü entschieden)

- Bedienung für Aufwerten und Gabelung, Zielwahl, Zwergenbank, Bonus für frühes Rufen und Steinregen ([07](docs/game-design/07-ui-ux.md#8-phase-2-aufwerten-fähigkeit-bank)), Kampagnenkarte nach K4. D-033 entschieden: Steinregen unten rechts, Tempo oben neben der Pause.
- D-031 entschieden: Türme werden im Kreismenü am Feld gewählt, Bauen und Verkaufen per zweitem Tippen ([07](docs/game-design/07-ui-ux.md#bauen)).
=======
## 0.5.2 – 25.10.2026 (Grafik), Bau folgt

**Neu**
- Gemalte Grafik im Stil „Stylized 3D" (D-016, aus drei Stilmustern gewählt):
  Wachturm, Blitzturm, Sporenturm, Plünderer, Flitzer, Panzerbestie, Festung und
  der Boden von Mission 1 mit eingemaltem Weg. Ersetzen die Platzhalterformen.
- Bildwerkzeug `.claude/skills/spielgrafik` (aus Stack & Siege übernommen),
  ergänzt um Freistellen mit Kontur, Atlas, Bild-zu-Bild und Karten aus der
  Weggeometrie. Konzept: [grafik-01-spielfeld](docs/konzepte/grafik-01-spielfeld.md).
- Art-Direction, Asset-Vertrag, Konzeptblätter der Figuren und Rückmeldung je
  Ereignis unter `docs/art/`.

**Tests**
- CI-Job `art`: 14 Tests der Bildpipeline (Atlas gegen Vertrag, Herkunft,
  Lizenz, Weg der Kartenvorlage) und die Prüfung des echten Atlas.
- `AppTests/BattleSpritesTests`: Bilder gefunden, Maße und Anker, Boden deckt
  die Karte, Weglinie entfällt.
>>>>>>> Stashed changes

## Dokumente, kein Bau – 25.10.2026 (Oberfläche)

**Neu**
- Konzept für Oberfläche und Bedienung: [07-ui-ux.md](docs/game-design/07-ui-ux.md)
  mit Raster je iPhone, HUD-Ecken, Bauen und Verkaufen am Feld, Pause, Sieg,
  Niederlage, Hauptmenü, Richtung der Kampagnenkarte und der Architektur
  (neu `HudLayout` neben `BoardLayout`, `UITheme`, `FeedbackPlayer`; Auswahl und Kopien bleiben im `BattleController`).
- Klickbare Entwürfe aller Schirme: [Oddlings – Spieloberfläche](https://claude.ai/artifact/PKpZrLVV42wje1isSfvB8z).
- Vorschläge D-030 (HUD-Ecken), D-031 (Kreismenü), D-032 (Schriften).

**Tests**: keine, nur Dokumente. Die Tests der Bausteine stehen in 07 und kommen
mit der Umsetzung.

## Dokumente, kein Bau – 25.10.2026

**Neu**
- Projektplanung: Konzepte für Phase 2 und 3 (Aufwertungen mit Gabelung,
  Festungsfähigkeit, Völker, Zwergenbank, Kampagne mit kostenloser Region 1,
  Fortschritt, Speicherstand, Gegner und Bosse, Einstieg, Ton) in
  `docs/konzepte/phase-2-3.md`.
- Register aller offenen Fragen (`docs/production/offene-fragen.md`) und
  Statusübersicht für Steffen (`docs/production/status.md`).
- Roadmap mit Meilensteinen für Phase 1, Entwurf für Phase 2, Ausblick Phase 3
  und den Abhängigkeiten zwischen den Threads.
- Entscheidungen D-020 bis D-023 festgelegt, D-024 bis D-027 Steffen vorgelegt.

**Tests**: neue Prüfung `scripts/links-pruefen.py` im CI-Schritt `regeln`:
bricht ab, wenn ein Verweis in den Dokumenten auf eine fehlende Datei oder
einen fehlenden Abschnitt zeigt oder eine Nummer im Entscheidungsprotokoll
doppelt vergeben ist. Einmal rot gesehen (falscher Anker, falsche Datei,
doppelte Nummer).
- Nummern im Entscheidungsprotokoll vergibt die Projektplanung zentral, in Blöcken je Thread.
- Konzeptdatei liegt nach D-017 unter `docs/konzepte/phase-2-3.md`.

## 0.5.1 – 25.10.2026

**Neu**
- End-zu-End-Tests (D-029): Die CI spielt die App bei jedem PR wie ein Spieler
  durch, mit 13 Fällen in vier Dateien unter `AppUITests/`. Sie decken Menü
  und Zurück ab, Bauen und Verkaufen samt Gold, Vorschau, Ausgrauen,
  Kopfleiste, Welle rufen, Pause, 2×, Niederlage mit Nochmal, Sieg der
  Vorführung und den Wechsel in den Hintergrund. Konzept:
  `docs/konzepte/e2e-tests.md`.
- Die Mission hält an, wenn die App in den Hintergrund geht (D-034, Vorschlag).
- Die CI listet jeden App-Testfall mit Ergebnis. Bisher kürzte sie das
  Protokoll, und man sah nicht, ob ein Testziel gelaufen war.
- Zeitraffer `--e2e-zeitraffer N`, nur im Debug-Bau, damit ganze Missionen im
  Simulator in Sekunden durchlaufen.

**Tests**: Die neuen Fälle aus 0.5.0 sind jeweils einmal rot gesehen worden,
mit einem Probelauf mit umgedrehten Prüfungen.

Bau: wird nach dem Zusammenführen nachgetragen.

## 0.5.0 – 25.10.2026

**Neu**
- Mission 1 ist spielbar (WP-12 bis WP-14). Der Startbildschirm hat ein großes
  „Spielen“.
- Bauen: Bauzelle antippen, Turm wählen (zeigt die Reichweite), noch einmal
  tippen baut. Nicht leistbare Türme sind ausgegraut.
- Verkaufen: Turm antippen, „Verkaufen +Erstattung“.
- Abgelehnte Befehle erscheinen als roter Text an der Stelle.
- Kopfleiste: Gold, Leben, Welle n/m, „Nächste Welle“ mit Countdown, 1×/2×,
  Pause, Zurück.
- Ergebnistafel bei Sieg oder Niederlage mit „Nochmal“ und „Zurück“.
- Konzept vor Umsetzung: `docs/konzepte/wp-12-14-spielbare-mission.md`, Regel in
  `CLAUDE.md` und im Skill `arbeitspaket-ausliefern` (D-017).

**Tests**: `BattleControllerTests` (11 Fälle: Auswahl, Vorschau, Bauen,
Verkaufen, Gold, Zuschauen, Welle rufen, Countdown, Pause, 2×, Niederlage,
Neustart). Neues Oberflächentest-Ziel `OddlingsUITests`: bauen und verkaufen
mit echtem Tippen, Kopfleiste und Pause.

Bau: **19 VALID**.

## 0.4.0 – 25.10.2026

**Neu**
- WP-11: Die App zeigt die echte Simulation. Startbildschirm mit „Mission 1
  ansehen“: Ein Mitspieler baut nach der Demo-Bauweise aus der Konfiguration,
  Türme schießen, Blitze springen, Sporen verlangsamen, Gegner laufen den Weg
  entlang, die Festung nimmt Treffer. Neustart und Zurück.
- Fester Takt mit Zwischenbildern: Die Szene rechnet in festen Schritten und
  zeichnet zwischen zwei Zuständen weich, auch bei 2×.
- Platzhaltergrafik nach dem Asset-Vertrag der Grafik: Sobald die gemalten
  Bilder unter ihren Namen im Katalog liegen, ersetzen sie die Platzhalter ohne
  Codeänderung.
- Probelauf im Simulator startet direkt die Mission (`--demo`) und legt ein
  Bildschirmfoto ab.

**Tests**: `AutoplayerTests` (Paket), `BattleSceneTests` (App: Knoten passen
über eine ganze Mission zum Zustand, Neustart räumt auf, 2× macht doppelt so
viele Schritte). Neuer CI-Schritt „App testen“.

Bau: **18 VALID**.

## 0.3.1 – 25.10.2026

**Neu**
- CI-Schritt `regeln` (`scripts/regeln-pruefen.sh`): bricht ab, wenn die
  Simulation mehr als Foundation importiert oder Uhrzeit, Zufall oder Umgebung
  benutzt, bei Netzcode, bei eingecheckten Schlüsseln oder Zertifikaten, bei
  Abläufen ohne festgelegte Rechte und bei fremden Actions ohne festen Commit.
- `CLAUDE.md`: Abschnitt „Qualität und Sicherheit“ und die Absprachen mit Steffen
  (selbstständig arbeiten, Entscheidungen festhalten, Änderungsprotokoll führen).
- Skill `.claude/skills/arbeitspaket-ausliefern`: der Weg von der Änderung bis zum
  VALID-Bau in TestFlight.

**Tests**: Jede Prüfung in `regeln-pruefen.sh` einmal mit einem eingebauten
Verstoß rot gesehen.

Bau: **17 VALID**.

## 0.3.0 – 25.10.2026

**Neu**
- WP-10: Prüfsumme über den ganzen Spielzustand. Gleicher Startwert und gleiche
  Befehle ergeben dieselbe Prüfsumme, auch nach Speichern und Laden mitten in der
  Welle und bei doppelter Geschwindigkeit.
- Balance wird jetzt im Swift-Paket geprüft (`BalanceTests`), mit denselben
  Bot-Bauweisen wie vorher in Python. Die Bauweisen stehen in
  `mvp-mission-01.json` unter `simStrategies`.

**Entfernt**
- Python-Prüfskript `tools/balance-sim` und der CI-Schritt `balance`. Zwei
  Umsetzungen derselben Regeln wären auseinandergelaufen.

**Befund**: Rangfolge der Bauweisen wie in Phase 0, die Abstände sind kleiner,
weil Türme nicht mehr auf schon tote Ziele schießen (Einzelheiten in
`docs/game-design/04-economy-and-balance.md`).

**Tests**: `DeterminismTests`, `BalanceTests`.

Bau: **16 VALID**.

## 0.2.0 – 25.10.2026

**Neu**
- WP-09: Sieg, sobald alle Wellen erschienen und keine Gegner mehr da sind.
  Ein letzter Durchbruch zählt vorher, eine verlorene Festung gewinnt nicht mehr.
- Befehl „Nächste Welle“ (`callNextWave`): startet die nächste Welle sofort und
  schiebt den restlichen Takt mit. Ohne verbleibende Welle wird er abgewiesen.

**Tests**: `VictoryTests` (Sieg, Reihenfolge Durchbruch vor Sieg, Welle rufen).

Bau: **15 VALID**.

## 0.1.1 – 25.10.2026

**Behoben**
- TestFlight-Bau scheiterte seit Bau 6 beim Archivieren: Das Profil wurde über
  die Befehlszeile gesetzt und galt damit auch für das Ressourcenbündel von
  `OddlingsCore`. Es gilt jetzt nur noch für die App.

**Neu**
- Dieses Änderungsprotokoll, rückwirkend ab Phase 0.

Bau: **13 VALID** (Probebau vom Arbeitszweig vor dem Zusammenführen), **14 VALID** (von main).

## 0.1.0 – 25.10.2026

Alles bis hierher lief unter Version 0.1.0.

| PR | Inhalt | Bau |
|---|---|---|
| #12 | WP-08: Sporenturm mit Puls und Verlangsamung | 12 gescheitert (Profil) |
| #11 | WP-07: Blitzturm mit Kettenblitz | 11 gescheitert (Profil, siehe 0.1.1) |
| #10 | Marktanalyse in Doku, Backlog und Roadmap; D-015 Geschäftsmodell | kein Bau |
| #9 | WP-06: Wachturm, Schaden, Belohnung | 10 gescheitert (Profil) |
| #8 | WP-05: Bauen und Verkaufen, Gold | 9 gescheitert (Profil) |
| #7 | Marktanalyse der führenden mobilen Tower-Defense-Spiele | kein Bau |
| #6 | WP-04: Wellen, Bewegung, Festung | 8 gescheitert (Profil) |
| #5 | WP-03: Weggeometrie und Bauzonen | 7 gescheitert (Profil) |
| #4 | WP-02: Paket OddlingsCore, Konfiguration mit Prüfung | 6 gescheitert (Profil) |
| #3 | Bauen mit Xcode 26, damit TestFlight den Bau annimmt | **5 VALID** |
| #2 | WP-01: Technik-Spike (App-Hülle, Leistungsprobe, CI, TestFlight-Ablauf) | 1–3 gescheitert (Einrichtung), **4 VALID** |
| #1 | Phase 0: Designdokumentation, Balance für Mission 1, Backlog | kein Bau |

Bauten 6 bis 12 enthielten in der App nichts Neues gegenüber Bau 5: Die
Simulation ist bis WP-11 nicht an die Darstellung angebunden.
