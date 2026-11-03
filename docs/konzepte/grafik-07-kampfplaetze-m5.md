# Konzept: Kampfplätze für Mission 5a und 5b (Grafik 07)

Status: **umgesetzt in 0.26.1** · Stil D-016 · Thread „Kampfplätze für Mission 5a und 5b malen"
Anlass: Roadmap, Region 1 weitere Missionen. Mission 5a „Sumpfpfad" entsteht parallel
im Thread „Oddlings-Designstand und MVP-Plan aufsetzen" (P3-1, Spezialisierungen).
Vorgehen wie [Grafik 06](grafik-06-kampfplaetze-m2-m4.md); dieses Dokument nennt nur,
was neu ist.

## Ziel

Die Gabelung nach Mission 4 soll sich schon am Boden anfühlen wie zwei Wege: oben
der Sumpf, unten die Ruinen (Kampagnenkarte, Knoten `m5a` und `m5b`). Beide Karten in
der Qualität von M1 bis M4, gleiche Teile (Bäume, Höhle, Gras, Weg), eigener Ort.

## Wer was festlegt

| Was | Wer |
|---|---|
| Weg, Feldgröße, Bauzonen von M5a | `mission-05a.json` (P3-1, 0.25.0) hat den Vorschlag unten wörtlich übernommen (abgestimmt 03.11.2026). Ändert sich die Datei, wird nachgemalt; `MissionFiveATests` und `test_wegvorschlag_stimmt_mit_der_missionsdatei` schlagen dann an |
| Weg von M5b | `mission-05b.json` (P3-2, 0.26.0) hat den Vorschlag unten wörtlich übernommen |
| Bild, Rand, Deko, Licht | dieser Thread |

Simulation, Missionsdateien und App-Code ändern sich durch dieses Paket nicht.

## Die zwei Orte

Auf dem Feld liegt wie bisher nur Gras und Weg (überall bebaubar); der Ort steckt im
Waldrand, im Licht und im angehängten Übermal-Prompt.

| Mission | Gegner-Schwerpunkt | Ort | Rand-Deko (neues Teileblatt) | Licht |
|---|---|---|---|---|
| M5a | Flitzer | **Sumpfpfad**: der Weg führt über eine feuchte Insel im Moor | Schilfbüschel, kleine Moortümpel mit Seerosen, knorriger toter Baum, morsche Stümpfe, Irrlicht-Laterne | Abenddämmerung, grünlich-kühl, leichter Dunst |
| M5b | Panzerbestie | **Ruinenhof**: mitten in den Ruinen, an denen M4 nur vorbeiführte | zerbrochener Torbogen, Steinbecken, Säulenstümpfe, Schuttfeld (neues Blatt, nicht das von M4) | kühles Grau mit violettem Abendlicht |

M4 (Ruinenrand) und M5b teilen das Thema. Deshalb bekommt M5b eigene, größere
Ruinenteile und kühles statt warmes Licht, damit man die beiden nicht verwechselt.

### Wege (beide von den Missionsdateien übernommen)

Feld 16 × 9, Eingang links (x = −1), Ausgang rechts (x = 17). Dateien unter
`art/karten/wegvorschlaege/`.

- **M5a** (Flitzer, 36 Zellen Weg, Mäander):
  `[[-1,4.5],[2.5,4.5],[2.5,1.5],[6.5,1.5],[6.5,7.5],[10.5,7.5],[10.5,1.5],[13.5,1.5],[13.5,4.5],[17,4.5]]`.
  Zwei lange senkrechte Bahnen von je sechs Zellen. Ein Turm zwischen ihnen trifft
  beide: Flitzer bleiben länger in Reichweite, und Verlangsamung (Moorherz) lohnt sich.
- **M5b** (Panzerbestie, 26 Zellen Weg, Becken):
  `[[-1,2.5],[5.5,2.5],[5.5,6.5],[10.5,6.5],[10.5,2.5],[17,2.5]]`.
  Ein Becken in der Mitte, umschlossen auf drei Seiten: Türme im Becken treffen
  drei Wegstücke, das belohnt wenige starke Türme gegen zähe Ziele.

## Architektur

Unverändert aus Grafik 06:

- Name aus der Missionskennung: `mission-05a` → `map_mission05a_ground`,
  `mission-05b` → `map_mission05b_ground`. Die App findet das Bild ohne Änderung,
  sobald die Mission existiert.
- 24 × 13 Zellen, 3096 × 1677 px @3x, JPEG in `App/Assets.xcassets/Maps`.
- `art/asset-vertrag.json` je Karte mit `zellen`, `rand`, `mission` (M5a auf
  `mission-05a.json`, M5b auf `mission-05b.json`).
- Werkzeug: `kampfplatz.py` bekommt `DEKO_BREITE=a,b`, denn Sumpf und Ruinenhof tragen
  den Ort fast nur über die Deko und brauchen sie größer. Hohe Teile (tote Bäume, Säulen)
  werden nach ihrer Höhe bemessen: In der ersten Collage ragten tote Bäume aus dem unteren
  Rand über Bauzellen, weil nur die Breite zählte. Für die Teile von M2 bis M4 (breiter
  als hoch) ändert sich nichts.
- Ablauf: Teileblatt malen und zerlegen → `DEKO=… LICHT=… kampfplatz.py` → übermalen
  (Stärke 0,3, Prompt von M1 plus Ort) → hochrechnen → `ebene.py` → nachbessern →
  `atlas.py`. Prompts, Seeds und Schritte in `art/karten/ENTSTEHUNG.md`.

## Tests

- `tools/art-check`: Die Prüfung „Weg und Wald liegen richtig" läuft für jede Karte
  im Vertrag, also ohne Codeänderung auch für die zwei neuen. Einmal rot gesehen mit
  einem absichtlich verschobenen Weg im Vorschlag.
- `test_wegvorschlag_stimmt_mit_der_missionsdatei` und `MissionFiveATests` halten Bild
  und Missionsweg von M5a gleich.
- `test_deko_nur_im_rand` mit einem hohen Teil (einmal rot gesehen mit dem alten Werkzeug).
- App: `testEveryBundledMissionHasItsPaintedGround` umfasst `mission-05a`.
- Neu: Die Wegvorschläge selbst sind gültig (Weg nur waagrecht und senkrecht, Eingang
  links, Ausgang rechts, alle Knicke im Feld, Bahnen mindestens zwei Zellen
  auseinander, damit zwischen ihnen gebaut werden kann).
- Vor der Abgabe jede Karte in einer Szene mit Türmen, Festung und Gegnern ansehen
  (`vorschau.py`).

## Risiken

- **Weg ändert sich.** Nachmalen kostet etwa zwei Stunden Rechenzeit; Collage und
  Übermalen sind reproduzierbar.
- **Sumpf auf dem Feld.** FLUX malt bei „swamp" gern Wasser ins Gras. Das Feld muss
  bebaubar aussehen; Tümpel nur im Rand, Feldflecken mit `ausgleichen.py`.
- **App-Größe:** je Karte rund 1,5 MB JPEG.
