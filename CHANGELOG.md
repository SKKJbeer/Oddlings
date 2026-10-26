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

## 0.9.0 – 26.10.2026 (Völkerwahl Zwerge und Elfen, R-4)

**Neu**
- Auf der Missionstafel der Karte stehen Zwerge und Elfen über „Starten“. Ohne
  Wahl gilt der Steinregen. Die Wahl steht im Spielstand. Beide Völker sind
  sofort wählbar, solange nur Mission 1 spielbar ist (D-061).
- Zwerge: Bollwerk. Eine Mauer quer zum Weg, sofort und 4 s lang. Wer sie von
  vorn erreicht, bleibt dort stehen.
- Elfen: Mondmal. Nach 0,5 s nehmen Gegner im Kreis 4 s lang jeden Treffer
  ×1,5. Dazu reichen Sporentürme 10 % weiter.
- Knopf unten rechts mit Bild und Namen je Volk. Mauer, Mal und Effekte sind
  Platzhalter.
- Werte stehen in `Balance/races.json` und gelten als **[HYPOTHESE]**. Beim
  Laden wird die Datei geprüft wie die Missionsdatei.
- Ein passiver Zug der Zwerge fehlt, bis die Zwergenbank kommt. Die Frage an
  Steffen ist offen.
- Konzept: [r-4-voelker](docs/konzepte/r-4-voelker.md).

**Balance**
- Je Volk höchstens +0,1 Reserve, zwischen den Völkern höchstens 0,05. Gemessen:
  Zwerge +0,05, Elfen +0,07
  ([04](docs/game-design/04-economy-and-balance.md#völker-zwerge-und-elfen-r-4-26102026-hypothese)).

**Tests**
- Kern: `BulwarkTests` (5), `MoonMarkTests` (6) und `RaceTests` (6). Dazu
  Wiederholung je Volk, Prüfsumme mit Mauer und Mal und die Völkergrenze in
  `BalanceTests`. Jeder neue Test wurde einmal rot gesehen. Die feste
  Prüfsumme ist neu, weil sie Mauer und Mal mitzählt.
- App: Wahl und Spielstand in `AppFlowTests`, Fähigkeit je Volk in
  `BattleControllerTests`, Mauer und Mal in `BattleSceneTests`, Haptik.
- E2E: `RaceE2ETests`. Dort wird ein Volk gewählt und die Mission gestartet,
  dann die App neu gestartet und ein Bollwerk gesetzt. Ein zweiter Test prüft,
  dass die Tafel mit der Wahl ins Bild passt.
- Zwei ältere E2E-Tests liefen gegen die Uhr der Mission. Sie halten die erste
  Welle jetzt mit `--e2e-erste-welle` zurück (nur im Debug-Bau).

## 0.8.0 – 25.10.2026 (Festungsfähigkeit Steinregen, R-3), Bau 24 (VALID)

**Neu**
- Steinregen (D-025, D-060): Knopf unten rechts, dann auf den Weg tippen. Der
  Wurf rastet am Weg ein, nach 0,8 s schlägt er im Kreis ein, macht Schaden und
  hält Getroffene 1 s an. Danach lädt er 35 s. Daneben gezielt kostet nichts.
  Mission 1 hat ihn, solange sie die einzige spielbare ist. Werte
  **[HYPOTHESE]** bis zum Spieltest.
- Knopf und Effekt sind Platzhalter; Ladering, Zielansicht (Oberfläche) und
  Einschlag (Animation) folgen.
- Konzept: [r-3-steinregen](docs/konzepte/r-3-steinregen.md).

**Balance**
- Gemessen, bevor die Werte feststanden: Die ersten Werte (40 Schaden, 25 s)
  hoben die Reserve um 0,29, erlaubt sind 0,1. Jetzt +0,075
  ([04](docs/game-design/04-economy-and-balance.md#steinregen-r-3-25102026-hypothese)).

**Tests**
- Kern: `AbilityTests` (8), Wiederholung mit Würfen in `DeterminismTests`,
  Grenze der Reserve in `BalanceTests`; jeder einmal rot gesehen. Die feste
  Prüfsumme ist neu, weil sie Anhalten und Fähigkeit mitzählt.
- App: Zielen, Werfen, Laden und Zuschauen in `BattleControllerTests`, Haptik.
- E2E: `AbilityE2ETests` (bereit, daneben gezielt, Wurf, Laden, wieder bereit;
  nach dem Ende kein Knopf).

## 0.7.0 – 25.10.2026 (Spielrahmen R-1 und R-2), Bau 23 (VALID)

**Neu**
- Kampagnenkarte Region 1 „Flüsterwald“ (D-027, D-060): sieben Hauptmissionen mit
  Gabelung nach Mission 4 (Sumpfpfad oder Ruinen), Boss, zwei Nebenmissionen ab 6
  und 15 Sternen. Missionstafel rechts mit Art, Name, Sternen, was die Mission
  lehrt, ihrer Neuheit und dem Grund, warum sie noch zu ist. Mission 1 ist
  spielbar, die übrigen zeigen „gesperrt“ oder „in Arbeit“.
- Sterne nach Leben übrig (1 / ab 15 / alle 20, Grenzen in der Missionsdatei).
- Speicherstand nach D-022: lokal, atomar geschrieben, vorige Fassung bleibt,
  beim Laden geprüft; ein Stand einer neueren App wird nicht überschrieben.
  Gespeichert wird beim Ergebnis, nicht beim Verlassen der App.
- Hauptmenü: „Weiter mit Mission 1“ führt direkt in die nächste Mission, „Spielen“
  öffnet die Karte; nach dem Ergebnis geht es zur Karte zurück.
- Einstellungen mit Vibration an/aus (getrennt vom Spielstand).
- Konzept: [r-spielrahmen](docs/konzepte/r-spielrahmen.md).

**Tests**
- Kern: `StarRatingTests`, `CampaignTests`, `SaveGameTests`, `SaveStoreTests`
  (22 neu, jeder einmal rot gesehen), u. a. kaputte Datei, übergroße Datei,
  neueres Schema, Gabelung, Sternsumme.
- App: `AppFlowTests`, `AppSettingsTests`.
- E2E: `CampaignE2ETests` (Sieg → Sterne auf der Karte → App neu starten → Sterne
  noch da; gesperrte Missionen starten nicht und sagen warum), Einstellung bleibt
  nach Neustart, Weg Menü → Karte → Mission → Karte → Menü. Jeder Oberflächentest
  spielt mit eigenem Spielstand im temporären Ordner.

## 0.6.0 – 25.10.2026 (Spieloberfläche UI 01), Bau 22 (VALID)

**Neu**
- Kreismenü am Feld (D-031): drei runde Turmknöpfe im Bogen mit Preisschild,
  erstes Tippen zeigt Reichweite und Infotafel (Rolle, Zusammenspiel), zweites baut.
  Der Bogen weicht Rändern, Kamera und Home-Leiste aus (`HudLayout`).
- Verkaufen mit zweitem Tippen: „Verkaufen +N“, dann „Sicher?“.
- Zu wenig Gold: Schild „fehlt N“, Gold blinkt, Warnhaptik, kein Befehl.
- Kopfleiste neu: Leben, Gold, Welle mit Symbolen, Zahlen rollen bei Änderung,
  Leben wackeln bei Durchbruch; „Welle N“ mit Countdown-Ring; 2× goldfarben.
- Pausentafel mit Stand, „Weiter“, „Neu starten“ und „Aufgeben“.
- Ergebnistafel mit Band „Sieg!“ bzw. „Die Festung ist gefallen“ und hochzählenden
  Werten: Leben übrig, Dauer, Türme gebaut bzw. Wellen gehalten, Dauer, besiegte Gegner.
- Haptik zu jeder eigenen Handlung (07, Abschnitt 5), beim Zuschauen keine.
- Hauptmenü im Stil der Entwürfe, „Spielen“ groß im Daumenbereich.
- Schriften Lilita One und Nunito (D-032), mit Lizenz und Herkunft in `App/UI/Fonts/`.
- Konzept: [ui-01-hud-und-tafeln](docs/konzepte/ui-01-hud-und-tafeln.md).
- Nach Durchsicht der Bildschirmfotos: Band der Niederlage dunkler (Schiefer statt
  Hellgrau), damit die helle Schrift lesbar bleibt (Kontrast über 6 : 1).

**Tests**
- Neu: `HudLayoutTests` (jede Bauzelle auf vier iPhone-Größen), `FeedbackPlayerTests`,
  `AppFontsTests`; `BattleControllerTests` um Verkaufen mit Bestätigung, Aufgeben,
  Zähler, Dauer, Haptik und Countdown-Ring erweitert.
- E2E: `TablesE2ETests` (Pause, Neu starten, Aufgeben, Bildschirmfotos zum
  Vergleich mit dem Entwurf), Verkaufen mit Bestätigung, „fehlt N“, Werte der
  Ergebnistafel nach Sieg und Niederlage.
- `regeln-pruefen.sh`: keine Schriftdatei ohne Lizenz und Herkunftseintrag.

## Dokumente, kein Bau – 25.10.2026 (Grafik: Konzept Phase 2 und Spielrahmen)

- Konzept [Grafik 02](docs/konzepte/grafik-02-phase-2.md): Bilder für Aufwertungen,
  Spezialisierungen, Zwergenbank, Steinregen, Hauptmenü, Regionskarte und
  Volksbanner, mit Namen, Maßen und Qualitätsprüfung vor der Abgabe.

## 0.5.2 – 25.10.2026 (Grafik), Bau 21 (VALID)

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
- CI-Job `art`: 16 Tests der Bildpipeline (Atlas gegen Vertrag, Herkunft,
  Lizenz, Weg der Kartenvorlage) und die Prüfung des echten Atlas.
- `AppTests/BattleSpritesTests`: Bilder gefunden, Maße und Anker, Boden deckt
  die Karte, Weglinie entfällt.

## Dokumente, kein Bau – 25.10.2026 (Bedienung Phase 2, Kreismenü entschieden)

- Bedienung für Aufwerten und Gabelung, Zielwahl, Zwergenbank, Bonus für frühes Rufen und Steinregen ([07](docs/game-design/07-ui-ux.md#8-phase-2-aufwerten-fähigkeit-bank)), Kampagnenkarte nach K4. D-033 entschieden: Steinregen unten rechts, Tempo oben neben der Pause.
- D-031 entschieden: Türme werden im Kreismenü am Feld gewählt, Bauen und Verkaufen per zweitem Tippen ([07](docs/game-design/07-ui-ux.md#bauen)).

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

**Tests**: Die App-Tests aus 0.5.0 und alle 13 neuen End-zu-End-Fälle sind
jeweils einmal rot gesehen worden, mit Probeläufen mit umgedrehten Prüfungen
(CI-Läufe 40205226937, 40208318048, 40208954005).

**Nachgereicht (nur Dokumente, kein Bau)**: Beobachtungsbogen für den
Spieltest WP-15 in `docs/production/playtests/beobachtungsbogen.md`.

Bau: **20 VALID**.

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
