# Konzept A-4: Kampfplatz Mission 1 als Diorama mit Bauinseln

Status: **[ENTSCHIEDEN]** in der Richtung (D-140, D-141, D-142, Steffen 16.11.2026),
Einzelheiten **[VORSCHLAG]** · Stand 16.11.2026 · Thread „Kampfplatz Mission 1 als
Diorama bauen“ · Nummern D-165 bis D-169
Grundlage: [Review](aaa-review.md) (G1, G2, G4, G8, L1, P2),
[Bewegung, Bauen, Stimmigkeit](aaa-bewegung-und-bauen.md#a-4-ein-ort-kampfplatz-in-der-kamera-der-türme),
[Leveldesign](aaa-leveldesign.md#bauinseln-d-141), D-005 Bauzonen, D-016 Stil,
D-120 Ortslicht, D-121 Bauplätze nur beim Bauen.

## Ziel

Mission 1 wird der erste Ort, an dem Karte, Türme und Figuren aus **einer Kamera** in
**einem Licht** stehen, und an dem man nicht mehr überall, sondern auf **gestalteten
Bauinseln** baut. Steffen urteilt daran am Gerät (D-142), bevor M2 bis M7 folgen.

Messbar:

- Der Kampfplatz ist aus einer 3D-Szene mit der Kamera aus `art/asset-vertrag.json`
  gerendert; Bäume, Felsen, Inselränder und Höhle zeigen ihre Seiten im selben Winkel
  wie die Türme.
- Die Wiese ist nicht mehr leer: zwischen den Inseln liegt Landschaft (Büsche, Felsen,
  Baumstümpfe, Blumen), nie auf Weg oder Insel.
- Mission 1 hat 6 Inseln mit 36 Feldern statt 114 bebaubarer Felder.
- Der gemalte Weg liegt dort, wo die Simulation ihn führt (Test wie bisher).

## Umfang

| Drin | Nicht drin |
|---|---|
| `map.zones` in OddlingsCore (MapConfig, Prüfung, MissionMap), nur Mission 1 nutzt es | Gelände mit Regeln (Anhöhe, Furt), mehrere Wege, neue Gegner (A-6) |
| Bauinseln für Mission 1 | Inseln für M2 bis M7 (A-6/A-7 je Mission) |
| Werkzeug `tools/kampfplatz-3d/diorama.py` (Blender) und Übermalen | Turm-Vorschau, Hervorhebung der Inseln beim Bauen (A-2) |
| Neuer Boden `map_mission01_ground` | Neue Figuren und Blickrichtungen (A-3) |
| Kamera, Sonne und Zielmaßstab im Asset-Vertrag, Maßstabsbild | Umstellen der Figurengrößen im Atlas (A-3), Türme 1,4 Felder (A-5) |

## Architektur

### Bauinseln in der Simulation

```
mvp-mission-01.json  map.zones: [{ id, kind, rects: [[x, y, b, h]] }]
        │ Laden (BalanceConfig.issues → zoneIssues)
        ▼
MissionMap.init      Zelle ist Bauplatz ⇔ Abstand zum Weg ≥ minDistanceFromPath
        │                                 und (keine Inseln oder Zelle in einer Insel)
        ├── placement(of:) → .free / .occupied / .tooCloseToPath / .outsideZone / .outsideMap
        ├── buildableCells  (Bots, Hand des Einstiegs, E2E, Bauplätze beim Bauen)
        └── zone(of:)       (A-2: Insel hervorheben; A-6: Labor zählt Siege je Insel)
Simulation           .build auf .outsideZone → commandRejected(reason: .outsideZone)
```

- **Optional:** Fehlt `zones`, gilt alles wie bis 0.29. Die Prüfsummen und
  Fingerabdrücke der übrigen Missionen bleiben gleich, weil ein fehlendes Feld nicht
  kodiert wird.
- **Prüfung beim Laden** (`ConfigValidation`): Liste nicht leer, `id` gültig und
  eindeutig, jedes Rechteck mindestens eine Zelle, innerhalb der Karte, **jede Zelle**
  mit Mindestabstand zum Weg (eine Insel, die halb auf dem Weg liegt, wäre im Bild eine
  Lüge), keine Zelle in zwei Inseln.
- `kind` (`turn`, `longSide`, `outpost`, `lastLine`) ist Beschreibung für Leveldesign
  und Labor, **keine Regel**. Anhöhe kommt erst mit ihrer Regel (A-6).
- Deterministisch: Inselindex je Zelle als Feld, keine Tabelle, keine Menge.
- Gespeicherte Missionen mit Türmen außerhalb der neuen Inseln: Der Fingerabdruck der
  Konfiguration ändert sich, eine angehaltene Mission 1 aus 0.29 öffnet deshalb nicht
  wieder (Verhalten von P2-2, D-074), Sterne und Fortschritt bleiben.

### Inseln in Mission 1

```
......BBB.......      A vorposten    outpost   2×3   früh, sieht Eingang und erste Kehre
#####.BBB.......      B hang-nord    longSide  3×2   oben, sieht Ende der ersten Geraden
....#....#####..      C kehre-west   turn      2×2   in der ersten Schleife, sieht drei Wegstücke
.AA.#....#...#FF      D wiese-sued   longSide  5×2   breit, schwach: Sporen, später Bank
.AA.#.CC.#EE.#FF      E kehre-ost    turn      2×2   in der zweiten Schleife
.AA.#.CC.#EE.#FF      F letzte-linie lastLine  2×3   vor der Festung
....######...#..
.....DDDDD...###      36 Felder, davon 8 an Kehren (eng, stark) und 15 an langen Seiten
.....DDDDD......
```

Die beiden Kehren sind die starken, engen Orte (4 Felder je Insel, 4 bis 6,7 Felder Weg
im Bereich eines Turms), die langen Seiten bieten Platz und wenig Weg. Damit ist „wohin
mit dem nächsten Turm“ eine Abwägung, nicht „an die Kehre“. Werte [HYPOTHESE] bis zum
Spieltest; die Balancetests und das Labor laufen mit den Inseln.

### Diorama-Werkzeug

```
mvp-mission-01.json ─┐
orte/mission-01.json ┼─► diorama.py (bpy) ─► render.png ─► FLUX Bild-zu-Bild ─► hochrechnen ─► atlas.py
asset-vertrag.json ──┘    Szene aus Daten      (Kamera,       (Stärke niedrig,     (Real-ESRGAN)
 (kamera, sonne)          + plan.json          Licht, Schatten) Formen bleiben)
```

- **Kamera** (D-165): orthografisch, **40° über dem Boden**, ohne Gierwinkel. Damit das
  Raster der Simulation quadratisch auf dem Bildschirm bleibt, wird die Tiefe der Szene um
  `1 / sin 40°` gestreckt (Kabinettprojektion): Eine Zelle am Boden ist im Bild genau
  quadratisch, alles mit Höhe zeigt seine Seite wie ein Turm. Türme sind „45 degree“
  gemalt, Figuren dürfen bis 30° flacher sein, damit ihr Gesicht lesbar bleibt
  (`figurenSpielraum` 10).
- **Sonne** (D-165): Azimut 135° (links hinten), 45° hoch; Schatten fallen nach rechts
  unten wie bisher (D-120). Lichtfarbe je Ort bleibt in `kampfplatzlicht.json`.
- **Szene aus Daten:** Boden (Gras), Weg als Spur mit runden Ecken und Furche, Inseln als
  flache Plateaus aus festgetretener Erde mit Steinkante, Landschaft dazwischen (Busch,
  Fels, Stumpf, Farn, Blumen), Wald im Rand, Höhle am Eingang, Festungsplatz am Ende.
  Was Höhe hat, steht so, dass seine Spitze weder Weg noch Insel verdeckt; das prüft der
  Plan vor dem Rendern (`plan.json`), nicht das Auge.
- **Übermalen:** FLUX.1-schnell Bild-zu-Bild mit niedriger Stärke vereinheitlicht die
  Malweise mit Türmen und Figuren. Danach legt das Werkzeug Weg und Inselkanten aus dem
  Render wieder weich darüber, falls FLUX sie verschiebt (Erfahrung Grafik 06 bis 09).
- Läuft nur im Entwicklungscontainer. Blender (GPL) ist Werkzeug, nicht Teil der App.

### Maßstab (D-166)

Zielhöhen aus [aaa-bewegung-und-bauen](aaa-bewegung-und-bauen.md#a-4-ein-ort-kampfplatz-in-der-kamera-der-türme)
stehen als `massstab` im Vertrag (Flitzer 0,7 · Plünderer 0,8 · Panzerbestie 1,15 ·
Turm 1,4 · Boss 2,0 · Festung 2,6 Felder). Das **Maßstabsbild**
`art/karten/diorama/massstab-mission01.jpg` zeigt alle Dinge in diesen Höhen auf dem neuen
Kampfplatz. Umgestellt werden die Bilder von den Paketen, die sie malen (A-3 Figuren,
A-5 Türme); bis dahin bleibt der Atlas, wie er ist, und `art-check` prüft nur, dass die
Tabelle die Reihenfolge Festung > Boss > Turm > Panzerbestie > Plünderer > Flitzer hält.

## Bedienentscheidungen

- Ein Tipp auf Landschaft meldet „Hier ist kein Bauplatz“, wie bisher „Zu nah am Weg“.
- Bauplätze beim Bauen (D-121) zeigen nur noch die Inselzellen; wie die Inseln dabei
  aufleuchten, gestaltet A-2.

## Sicherheit

Die Missionsdatei kommt aus dem Bündel und wird beim Laden geprüft (oben). Keine neue
Eingabe von außen, kein Netz. Neue Bilder mit Herkunft in `art/karten/ENTSTEHUNG.md`.

## Testplan

| Ebene | Test |
|---|---|
| Simulation | `ZoneTests`: ohne Inseln wie bisher; mit Inseln nur Inselzellen; Landschaft `.outsideZone`; Bauen dort abgewiesen; `zone(of:)`; Mission 1 hat 4 bis 7 Inseln mit 35 bis 50 Feldern und je Insel einen freien Platz |
| Prüfung | leere Liste, Rechteck außerhalb, auf dem Weg, Überschneidung, doppelte und ungültige `id`, Rechteck ohne Fläche |
| Balance | alle `BalanceTests` und Labor mit den Inseln (Ergebnis in 04) |
| Werkzeug | `tools/kampfplatz-3d/tests`: Plan legt nichts Hohes auf Weg oder Insel, Kabinettprojektion bildet Zellen quadratisch ab |
| Bild | `art-check`: Weg liegt auf der Geometrie, Rand dunkel, Inselmitten sind Erde, Landschaftszellen nicht; Maßstab in Reihenfolge |
| App | `BattleTexts` kennt `.outsideZone`; E2E bauen weiter auf `buildableCells` (jetzt Inselzellen) |
| Ansehen | Vorher-nachher am echten Ort und Maßstabsbild im PR |

## Entscheidungen

| Nr. | Was | Stand |
|---|---|---|
| D-165 | Gemeinsame Kamera 40° orthografisch mit Kabinettstreckung, Sonne 135°/45° | gilt (Claude, Werkzeug, mit A-3 abgestimmt) |
| D-166 | Zielmaßstab im Vertrag, Umstellung durch die malenden Pakete | gilt (Claude, aus dem Review) |
| D-167 | Inseln von Mission 1 (6 Inseln, 36 Felder) | [HYPOTHESE] bis zum Spieltest |
