# Konzept: Kampfplätze für Mission 2 bis 4 (Grafik 06)

Status: **umgesetzt in 0.16.1** · Stil D-016 · Thread „Kampfplätze für Mission 2 bis 4 malen"
Anlass: Steffen, 01.11.2026, „ja zu allem" auf den Vorschlag, die gemalten
Kampfplätze für M2 bis M4 parallel zu den Missionsregeln zu bauen.

## Ziel

Jede Mission der Region 1 hat einen eigenen gemalten Kampfplatz in der Qualität
von Mission 1 ([Grafik 05](grafik-05-kampfplatz.md)). Alle liegen im Flüsterwald
und teilen Gras, Weg, Bäume und Höhle der Kampagnenkarte; jede Mission ist aber
auf den ersten Blick ein anderer Ort. Maßstab ist die Liste „AAA-Anmutung" der
[Marktanalyse](../game-design/market-analysis.md) (Abschnitt 3): ein Ort statt
einer Fläche, und Abwechslung zwischen Missionen, ohne dass die Lesbarkeit des
Feldes leidet.

## Wer was festlegt

| Was | Wer |
|---|---|
| Weg, Feldgröße, Bauzonen von M2 | Thread „Mission 2 mit Zwergenbank bauen", `mission-02.json` (abgestimmt 01.11.2026, Weg fest) |
| Weg von M3 und M4 | **[ENTSCHIEDEN D-081]** Steffen, 01.11.2026: dieser Thread schlägt je einen Weg vor (unten) und malt danach; die Missions-Threads übernehmen ihn oder ändern ihn, dann wird nachgemalt |
| Bild, Rand, Deko, Licht | dieser Thread |

Die Simulation und die Missionsdateien ändern sich durch dieses Paket nicht.

## Die drei Orte

Die Abwechslung kommt aus drei Mitteln, die das Feld nicht berühren: Deko nur im
Waldrand, ein eigener Lichtton und der Übermal-Prompt. Auf dem Feld liegt wie in M1
nur Gras und Weg, denn das Feld ist bis auf den Weg überall bebaubar; Deko dort
würde lügen.

| Mission | Neuheit | Ort | Rand-Deko | Licht |
|---|---|---|---|---|
| M2 | Zwergenbank | **Zwergenstollen am Waldrand**: Die Zwerge haben hier geschürft | Stolleneingang mit Balken, Lore, Holzstapel, Erzbrocken | Morgen, kühles Grün, goldene Spitzen |
| M3 | Aufwerten | **Pilzhain**: tiefer im Wald, moosig | große Pilze, bemooste Steine, Farn | Nachmittag, gedämpft, leicht türkis |
| M4 | Fähigkeit, Panzerbestie | **Ruinenrand**: Übergang zu den Ruinen der Gabelung (M5b) | verfallene Mauern und Säulen (Blatt aus `region01`) | später Nachmittag, warm, längere Schatten |

### Wegvorschläge M3 und M4 **[VORSCHLAG]**

Feld 16 × 9, Eingang links (x = −1), Ausgang rechts (x = 17), wie M1 und M2. Die
Geometrie liegt unter `art/karten/wegvorschlaege/`, bis eine Missionsdatei sie
ersetzt.

- **M3** (Aufwerten, „vertiefen statt verbreitern", 38 Zellen Weg):
  `[[-1,1.5],[7.5,1.5],[7.5,4.5],[2.5,4.5],[2.5,7.5],[13.5,7.5],[13.5,3.5],[17,3.5]]`.
  Eine Haarnadel links oben: Ein Turm zwischen den Bahnen erreicht drei
  Wegstücke. Wenige starke Plätze lohnen das Aufwerten.
- **M4** (Steinregen, Panzerbestie, 28 Zellen Weg):
  `[[-1,6.5],[4.5,6.5],[4.5,1.5],[14.5,1.5],[14.5,6.5],[17,6.5]]`.
  Eine lange Gerade oben (10 Zellen), auf der die Festungsfähigkeit viele
  Gegner zugleich trifft; kürzerer Weg, damit die zähe Panzerbestie Druck macht.

## Architektur

- **Name aus der Missionskennung** wie bisher: `BattleSprites.groundName("mission-02")`
  → `map_mission02_ground`. Die App braucht keine Änderung; fehlt ein Bild,
  zeichnet sie den Weg als Linie.
- **Maße wie M1:** 24 × 13 Zellen (Feld plus Rand 4 × 2, `BattleStyle.groundMargin`),
  3096 × 1677 px @3x, JPEG im Katalog `App/Assets.xcassets/Maps`.
- **Vertrag:** `art/asset-vertrag.json` bekommt je Mission einen Eintrag mit
  `zellen`, `rand` und neu `mission` (Pfad der Geometrie). Die Kunstprüfung prüft
  den Weg im Bild für **jede** Karte mit `mission`, nicht mehr fest nur M1.
- **Werkzeug:** `kampfplatz.py` bekommt zwei Schalter, ohne dass sich M1 ändert:
  `DEKO=<ordner>` setzt freigestellte Teile (`deko*.png`) in den Waldrand, mit
  Abstand zu Weg, Höhle und Festung, und `LICHT=r,g,b` tönt das Bild. Ohne beide
  rechnet es wie bisher.
- **Ablauf je Karte:** Teile malen und freistellen → Collage → einmal übermalen
  (Stärke 0,4) → hochrechnen → **Ebene auflegen** (`ebene.py`) → Flecken ausgleichen
  und Fremdkörper retuschieren → Atlas. Prompts, Seeds und Schritte in
  `art/karten/ENTSTEHUNG.md`.
- **Ebene:** Mit `DEKO` schreibt `kampfplatz.py` zusätzlich Höhle und Deko freigestellt
  und getönt in `<aus>-ebene.png`. Grund (gemessen 01.11.2026, Stärke 0,4 und 0,3): Das
  Übermalen machte aus der Höhle, dem Ursprung der Gegner, eine Lore oder Kuppel und aus
  Pilzen dunkle Kugeln. Obenauf gelegt bleibt die Höhle in jeder Mission dieselbe.

## Tests

- `tools/art-check`: Für jede Karte mit `mission` im Vertrag liegt der gemalte Weg
  auf der Weggeometrie (Farbabstand Weg gegen Gras entlang `map.path`, wie bei M1),
  der Rand ist dunkler als das Feld, Maße stimmen. Mit einem absichtlich
  verschobenen Weg einmal rot gesehen.
- Bauzellen frei: Kein Deko-Teil ragt mehr als 0,2 Zellen ins Feld (gleiche
  Prüfung wie die Bäume in `kampfplatz.py`, als Test über die Teilelagen).
- App: Die Szene lädt den Boden schon aus der Kennung; `BattleSceneTests` bekommt
  einen Fall, dass `mission-02` sein eigenes Bild findet (sobald M2 auf `main` ist).
- Vor der Abgabe jede Karte in der echten Ansicht mit Türmen und Gegnern ansehen
  (Vorschau mit Gitter und Bildschirmfoto aus dem Simulator-Probelauf).

## Ergebnis (01.11.2026)

Alle drei Karten in der Szene mit Türmen, Festung und Plünderern angesehen
(iPhone-Ausschnitt). Weg, Bauplätze und Gegner sind lesbar, der Waldrand trägt den Ort.
Nachgebessert: In M3 malte FLUX einen dunklen Fleck von vier Zellen ins Feld
(`ausgleichen.py`), in M2 drei Kiesel so groß wie ein Gegnerkopf (`retusche.py`).
Kleinere Kiesel bleiben, sie gehören zum Boden. Der erste Übermal-Durchgang mit langen
Prompts je Ort wurde verworfen (Bäume wurden Farn); der zweite nimmt den Prompt von M1
und hängt nur den Ort an.

## Risiken

- **Weg ändert sich nach dem Malen.** Nachmalen kostet etwa zwei Stunden
  Rechenzeit, die Collage ist reproduzierbar. Deshalb M2 zuerst (Weg fest).
- **App-Größe:** je Karte rund 1,5 MB JPEG (@2x und @3x zusammen etwa 3 MB).
- **FLUX malt Figuren in den Rand.** Retusche wie bei M1 (`retusche.py`).
- **Zu viel Deko macht den Rand unruhig.** Deko höchstens ein Teil je zwei
  Randzellen, dunkler als das Feld, nie in der Wegöffnung an der Höhle.
