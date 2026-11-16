# Konzept A-5 Teil 1: Spezialisierungen als Bilder, gemalte Ringe

Status: **in Umsetzung** · Stil D-016 · Plan [AAA-Schnitt](aaa-review.md#plan), Paket A-5
Befunde: G5 (Vektorformen in der gemalten Welt), G7 (Spezialisierungen sehen aus wie Stufe 2)
Entscheidungen: [D-170, D-171](../decisions/decision-log.md)

## Ziel

Die größte Entscheidung des Spiels ist auf dem Feld zu sehen: Wer zwei Wachtürme verschieden
spezialisiert, erkennt Salve und Falkenhorst ohne Antippen. Was am Boden liegt, ist gemalt wie
alles andere; keine Linien aus dem Entwicklerwerkzeug mehr neben den Türmen.

## Umfang

| Drin | Nicht drin (folgt in A-5 Teil 2 nach A-4 oder in A-2) |
|---|---|
| Sechs Turmbilder `tower_watch_volley`, `tower_watch_falcon`, `tower_lightning_crown`, `tower_lightning_spark`, `tower_spore_moor`, `tower_spore_rot` samt Schatten (`turmboden.py`) | Kopfleiste im Material der Tafeln, Effektbudget, Türme zielen (G6, G9, R1) |
| Schild „II“/„III“ am Turm entfällt | Auftritt beim Spezialisieren (A-2, „Wirbel, neue Gestalt“) |
| Gemalter Ring für die gewählte Zelle und die Reichweite (`mark_ring`) | Lebensleisten, Bauplätze (Bauinseln kommen mit A-4) |
| | Bilder im Kreismenü (A-2, „Turmbilder statt Symbole“); die Atlasnamen stehen bereit |

## Bilder

Die Entwürfe aus Grafik 02 (`art/phase-2`) taugten nicht unverändert: Falkenhorst und
Funkensäule hatten eine andere Grundform als der Turm, aus dem sie entstehen (Pyramide,
Gittermast), drei Bilder trugen einen eingebrannten Bodenschatten, der Falke war ein Adler.
Neben den Türmen der Stufe 1 und 2 sahen sie aus wie aus einem anderen Spiel.

Deshalb nachgemalt **aus dem Rohbild der Stufe 2** (Bild-zu-Bild, Stärke 0,68): Stufe 3 baut auf
Stufe 2 auf, also bleiben Grundkörper, Stein, Kupferringe und Pilzstiel; oben wechselt die
Silhouette so deutlich, dass A und B einfarbig unterscheidbar sind (Tabelle in
[Grafik 02](grafik-02-phase-2.md#gestaltung)). Ohne Schatten gemalt, den rechnet `turmboden.py`
wie bei jedem Turm. Herkunft: [art/phase-2/ENTSTEHUNG.md](../../art/phase-2/ENTSTEHUNG.md).

## Ringe

Ein Ringbild zu skalieren hätte einen Rand, der mit der Reichweite wächst (1,15 bis über 4
Felder). Stattdessen ein **gemalter Streifen** `mark_ring` (oben Außenkante, unten Innenkante,
waagerecht kachelbar), aus einem mit FLUX gemalten Goldring abgewickelt. `GroundMarks` wickelt
ihn zur Laufzeit um den Kreis, Rand in Feldern fest (`BattleStyle.rangeRim`), innen ein Schein in
der Streifenfarbe, der zur Mitte ausläuft. Einmal je Größe gerechnet und zwischengespeichert;
die Szene baut die Auswahl ohnehin nur neu, wenn sie sich ändert.

Die gewählte Zelle bekommt denselben Ring, eng (0,5 Felder) und mit stärkerem Schein. Fehlt der
Streifen im Katalog, zeichnet die Szene die alten Linien (Rückfall, im Test rot).

## Architektur und Datenfluss

- `BattleSprites.towerName(kind, level:, specialization:)` und `towerNames(…)`: Folge von der
  genauesten Gestalt abwärts (Spezialisierung, Stufen, Grundturm); `towerNameAvailable` nimmt das
  erste Bild im Katalog, `shadowNameAvailable` ebenso.
- `TowerNode.show(level:specialization:)` liest beides aus dem Zustand (`Tower.specialization`),
  in `sync` jedes Bild und beim Ereignis `towerUpgraded`. Darstellung ändert keinen Zustand.
- `GroundMarks` (neu, `App/Battle`): Streifen laden, Ring rechnen, Textur je Größe merken.
- Keine Änderung an `OddlingsCore`.

## Sicherheit

Keine neuen Eingaben von außen. Der Streifen kommt aus dem eigenen Katalog; fehlt er, gibt es den
Rückfall, kein Absturz.

## Tests

- `BattleSpritesTests`: jede Spezialisierung hat Bild und Schatten im Katalog, sechs verschiedene
  Bilder, Rückfallfolge.
- `SpecializationControllerTests`, `UpgradeControllerTests`: Bildwechsel, kein Schild, keine
  `SKShapeNode` am Turm.
- `TowerGroundingTests`: Schatten der Spezialisierung, auch beim Fortsetzen.
- `GroundMarksTests`: Streifen kachelbar, Randbreite unabhängig vom Radius, Mitte frei ohne
  Schein, Zwischenspeicher, Szene zeichnet die Auswahl gemalt.
- E2E `SpecializationE2ETests`: nach dem Kauf der Salve meldet `scene.art`
  `towers=tower_watch_volley` und `selection=gemalt`.
- `tools/art-check`: Größe, Anker, Freistellung, Herkunft der neuen Bilder.
