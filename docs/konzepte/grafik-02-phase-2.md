# Konzept: Bilder für Phase 2 (Grafik 02)

Status: **[VORSCHLAG]** · Stil D-016 · Thread „AAA-Grafik und Art-Direction"
Grundlage: D-024 (Aufwertungen mit Gabelung), D-025 (Steinregen), D-026 (Zwergenbank),
D-060 (Spielrahmen R-1 bis R-4).

## Ziel

Wenn die Simulation Aufwertungen, Bank und Steinregen kann, liegen die Bilder
fertig bereit. Jedes neue Bild zeigt auf einen Blick, **welche Wirkung** ein Turm
hat, nicht nur, dass er stärker ist. Wer zwei Blitztürme verschieden spezialisiert,
soll den Unterschied ohne Antippen sehen (Säule 1: Kombinationen erkennen).

## Umfang

| Gruppe | Namen | Anzahl |
|---|---|---|
| Stufe 2 je Turm | `tower_watch_2`, `tower_lightning_2`, `tower_spore_2` | 3 |
| Spezialisierungen | `tower_watch_falcon`, `tower_watch_volley`, `tower_lightning_crown`, `tower_lightning_spark`, `tower_spore_moor`, `tower_spore_rot` | 6 |
| Zwergenbank | `tower_bank` (arbeitet), `tower_bank_empty` (Deckel erreicht) | 2 |
| Steinregen | `fx_stonefall_shadow` (Vorwarnung), `fx_stonefall_rock` (fallender Brocken), `fx_stonefall_dust` (Einschlag) | 3 |
| Zustand | `icon_vulnerable` (über dem Gegner, Fäulnis/Mondmal) | 1 |
| Symbole fürs Menü | `ui_spec_<id>` je Spezialisierung, `ui_target_first`, `ui_target_last`, `ui_target_strong`, `ui_upgrade`, `ui_ability_stonefall`, `ui_bank` | 12 |

Dazu für den Spielrahmen (D-060, R-1 bis R-4):

| Paket | Name | Form |
|---|---|---|
| R-1 Hauptmenü | `ui_keyart_menu` | Querformat 2796 × 1290, JPEG, Ordner UI, Festung am Weg durch den Flüsterwald, alle drei Türme, Goblins im Anmarsch; rechtes Drittel ruhig für die Menüknöpfe |
| R-2 Kampagnenkarte | `map_region01` | 16:10, 2400 × 1500, JPEG, Ordner Maps, ohne Knoten und ohne Schrift; Ränder laufen dunkel in Wald aus |
| R-3 Steinregen | `fx_stonefall_*` (oben) | wie Effekte |
| R-4 Völkerwahl | `banner_race_dwarves`, `banner_race_elves` | Hochkant-Banner, Zwerge Rot/Messing mit Amboss, Elfen Grün/Silber mit Mondsichel |

**Regionskarte wie die Kampfkarte:** Die Lage der Missionsknoten steht in
`Campaign/region-01.json` (Anteile der Fläche). Daraus entsteht zuerst eine
Vorlage mit Lichtungen an den Knoten, Sumpf am oberen Pfad (m5a, m6a), Ruinen am
unteren (m5b, m6b) und einer dunkleren Bosslichtung (m7), dann wird sie per
Bild-zu-Bild ausgemalt. So liegen Lichtung und Knoten aufeinander; ein Test
prüft, dass jede Knotenlage im Bild auf einer Lichtung liegt, wie heute bei der
Kampfkarte der Weg.

Nicht drin: Völkerporträts, Boss und neue Gegner. Eigene Konzepte, wenn sie dran sind.

## Gestaltung

Die Regel aus [art-direction.md](../art/art-direction.md#farbwelt) bleibt: Grün
heißt Sporen/verlangsamt, Blau heißt Blitz. Neu dazu: **Violett-Schwarz heißt
verwundbar** (Fäulnis, später Mondmal), **Messing und warmes Gold heißt Bank**.

- **Stufe 2 ist ein Anbau, kein neuer Turm.** Gleicher Grundkörper, gleiche
  Silhouette unten, oben kommt etwas dazu (Wachturm: zweite Plattform mit
  Schild; Blitz: zweiter Kupferring, größerer Kristall; Sporen: zweiter kleiner
  Pilz am Stiel). So bleibt der Turm wiedererkennbar.
- **Stufe 3 ändert die Silhouette oben deutlich**, damit A und B einfarbig
  unterscheidbar sind:

| Spezialisierung | Silhouette oben | Farbakzent |
|---|---|---|
| Falkenhorst | hoher, schmaler Ausguck, großer Langbogen, Falke auf der Spitze | Rot, Weiß |
| Salve | breite Plattform mit zwei Armbrüsten nebeneinander | Rot, Holz |
| Gewitterkrone | Kristall von einer Krone aus drei Kupferzacken umfasst, kleine Wolke | helles Blau |
| Funkensäule | ein einzelner langer Spieß mit großem Kristall an der Spitze | tiefes Blau, Weißglut |
| Moorherz | breiter, flacher Hut, Moospolster und Wurzeln über den Sockel | Grün, Moosgrün |
| Fäulnis | spitzer, dunkler Hut mit violetten Flecken, tropfend | Violett-Schwarz |

- **Zwergenbank:** gedrungenes Steinhaus mit Messingkuppel, Goldkessel, kleiner
  Kran. `tower_bank_empty`: gleiches Bild, Kessel leer, Licht aus. Keine Münzen
  mit Währungszeichen.
- **Steinregen:** Schatten als weicher dunkler Kreis (Größe = Wirkradius, die
  Szene skaliert), Brocken als gemalter Felsen mit Kontur, Staub als Wolke in
  Erdfarben. Die Bewegung (Fallen, Aufblähen) rechnet die Szene.
- **Symbole:** gleiche Machart wie die UI-Symbole aus dem Oberflächen-Thread
  (gemalt, dunkle Kontur, auf transparentem Grund, mindestens 44 pt Tippfläche
  kommt aus dem Knopf, nicht aus dem Bild).

## Architektur

Gleiche Pipeline wie Grafik 01 ([grafik-01-spielfeld.md](grafik-01-spielfeld.md)):
Prompt + Seed → FLUX lokal → freistellen → `atlas.py` → Atlas, Herkunft in
`art/phase-2/ENTSTEHUNG.md`, Maße im Asset-Vertrag.

- **Abgabe in zwei Schritten.** Die Rohbilder und die freigestellten Bilder
  kommen jetzt nach `art/phase-2/`. In den Atlas (`Battle.spriteatlas`) und in
  den Vertrag kommen sie erst mit dem Arbeitspaket, das sie anzeigt. Grund: Ein
  Bild im App-Bündel, das keine Szene lädt, ist totes Gewicht, und der Vertrag
  soll nur Namen enthalten, die die Simulation kennt.
- **Namensregel** `tower_<turm>_<stufe oder spezialisierung>` mit den englischen
  IDs aus der Missionsdatei. `BattleSprites` wählt das Bild nach Stufe und
  Spezialisierung des Turms und fällt auf `tower_<turm>` zurück, wenn ein Bild
  fehlt (dieselbe Rückfallkette wie heute). Die IDs selbst legt der
  Simulations-Thread fest; weichen sie ab, werden die Dateien umbenannt.
- **Maße:** Stufe 2 und 3 wie der Grundturm (Seite 1,9 Zellen, Anker 0,2),
  damit ein Wechsel der Stufe den Turm nicht springen lässt. Falkenhorst ist
  höher, bleibt aber im selben Quadrat. Bank wie ein Turm. Effekte ohne Anker
  (Mitte), Symbole quadratisch.

## Qualität

Steffen, 25.10.2026: „es muss auch wirklich immer top qualität und professionell
sein". Kein Bild geht in den Katalog, bevor es **in der echten Szene** angesehen
wurde (Vorschau mit Boden, Nachbartürmen und Gegnern bzw. im Menü) und neben den
Bildern aus Grafik 01 und den Fortress-Avataren besteht. Abgelehnt wird: glatte
Stockbild-Optik ohne Malstruktur und Kontur, falsche Farbe einer Wirkung,
Silhouette nicht von der Schwester-Spezialisierung unterscheidbar, Unschärfe nach
dem Hochrechnen. Verworfene Fassungen bleiben mit Grund in der `ENTSTEHUNG.md`.

## Entscheidungen

Keine für Steffen: Das Aussehen folgt aus D-016 und den Regeln in 02/03/04.
Offen und mit dem Simulations-Thread abzustimmen: die genauen IDs der
Spezialisierungen.

## Sicherheit

Wie Grafik 01: keine neue Bibliothek, keine Netzverbindung, nur PNG; Lizenzprüfung
der Herkunft in der CI.

## Tests

| Ebene | Test |
|---|---|
| Jetzt (CI-Job `art`) | `check_assets.py` prüft auch `art/phase-2/ENTSTEHUNG.md` auf verbotene Modelle |
| Mit dem Arbeitspaket | Vertrag kennt jede Stufe und Spezialisierung aus der Missionsdatei; `BattleSpritesTests` je Stufe und Spezialisierung ein Bild, Rückfall auf den Grundturm, gleiche Größe und gleicher Anker über alle Stufen |
