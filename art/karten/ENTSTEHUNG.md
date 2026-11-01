# Karten — Entstehung

## `map_mission01_ground` (Mission 1, Lichtung im Flüsterwald)

Grafik 05 (26.10.2026, [Konzept](../../docs/konzepte/grafik-05-kampfplatz.md)).
Das Bild deckt das Feld **plus 4 Zellen Rand links und rechts und 2 oben und
unten** (24 × 13 Zellen). Der Rand ist Wald und füllt die Karte unter der
Kopfleiste: auf dem iPhone bis 22,7 Zellen breit, auf dem iPad bis 11,3 hoch. Der Weg liegt auf der
Geometrie aus `mvp-mission-01.json` (`map.path`), Bäume nur im Rand.

1. **Collage:** `kampfplatz.py mvp-mission-01.json <teile> aus.png 130 4x2` mit den
   Teilen der Kampagnenkarte (Gras, Weg, Bäume, Höhle; zerlegt aus
   `region01/`, siehe unten). Zufall fest (`random.Random(7)`). Auf 1024 × 576
   verkleinert → `mission01-collage.png` (1152 × 640 lief über den Speicher).
2. **Übermalen:** `INIT=mission01-collage.png STAERKE=0.4 VERSCHIEBUNG=0.5
   erzeugen.sh aus 5 "<prompt>" 1024x576` → `mission01-rohbild.png`. Prompt:
   `mobile strategy game battlefield seen from directly above, a sunlit forest clearing surrounded by dense round tree canopies, stylized 3D cartoon render, hand-painted textures, vibrant saturated colors, lush green grass with subtle variation and small flowers, a winding packed brown dirt path with small pebbles and grass tufts along its edges, a dark rocky goblin cave entrance on the left, warm afternoon light from top left, soft tree shadows, highly detailed, no buildings, no characters, no text, no letters, full bleed`.
   Das Übermalen vereinheitlicht Licht und Malstil von Gras, Weg und Wald.
3. **Hochrechnen:** `hochskalieren.sh rohbild aus 3096x1677` (Real-ESRGAN x4
   anime 6B, Lanczos), `atlas.py aus map_mission01_ground 24x13 voll _
   App/Assets.xcassets/Maps` (JPEG, Qualität 88).

**Verworfen:** die erste Fassung (0.5.2 bis 0.10.3): Wiese ohne Rand mit
rechtwinkligem Sandband, gemalt nach `karte_zusammensetzen.py`. Flach, ohne
Wald, nicht aus derselben Welt wie die Kampagnenkarte (Steffen, 26.10.2026:
„sieht noch billig und nicht abgestimmt mit dem rest aus").
Dazu eine Zwischenfassung mit 2 Zellen Rand ringsum (20 × 13): Im
Simulator-Probelauf blieben links und rechts je 1,3 Zellen leer, weil die Karte
unter der Kopfleiste breiter ist als der Bildschirm.

## `map_region01` (Kampagnenkarte Region 1, Flüsterwald)

Collage aus gemalten Einzelteilen, nicht als Ganzes gemalt. Die App setzt die
Knoten an feste Anteile der Fläche (`region-01.json`), und Bild-zu-Bild über
eine Vorlage hat die Lichtungen nie unter die Knoten gelegt (gemessen 26.10.2026:
Stärke 0,3 bis 0,6, 4 bis 16 Schritte, mehrere leichte Durchgänge). Hier liegen
Lichtungen, Wege, Sumpf, Ruinen und die Bosshöhle pixelgenau, nur die Teile sind
gemalt. Alle Bilder FLUX.1-schnell (Apache 2.0), euler, 4 Schritte, unter
`region01/`.

1. **Teile** (Stil-Teil `stylized 3D cartoon game asset, hand-painted textures, soft warm sunlight from top left, seen from directly above, top-down view`):
   - `blatt-baeume.jpg`, Seed 21, 768 × 768: `sprite sheet of six separate round fantasy forest tree canopies, lush deep green leaves with golden sunlit highlights, each tree isolated and evenly spaced on a plain white background, <Stil>, no ground, no text`. Zerlegt mit `zerlegen.py` (9 Bäume), dann je Baum Farbton im Bereich 25–75 (HSV, 0–255) um +14 Richtung Grün, Helligkeit × 0,82, Sättigung × 0,85.
   - `blatt-ruinen.jpg`, Seed 24, 768 × 768: `sprite sheet of six separate crumbling grey stone ruin pieces, broken walls, fallen pillars, mossy blocks, each isolated on a plain white background, <Stil>, no text`. Zerlegt (7 Teile).
   - `hoehle-rohbild.jpg`, Seed 25, 512 × 512: `a dark jagged rocky goblin lair entrance with spikes, bones and two burning torches, isolated on a plain white background, <Stil>, no text`. `freistellen.py … isnet-general-use 0`.
   - `textur-gras-rohbild.jpg`, Seed 22, 512: `seamless ground texture of a lush fairy forest meadow, short grass with tiny flowers and clover, <Stil>, uniform pattern filling the whole image, no objects, no paths`. Ausschnitt (170, 170, 512, 512), oben links liegt ein Lichtschein.
   - `textur-weg-rohbild.jpg`, Seed 23, 512: `seamless ground texture of a packed brown dirt forest path with small pebbles, <Stil>, uniform pattern filling the whole image, no objects`. Ausschnitt (120, 40, 380, 470) ohne die Pflanzen am Rand.
   - Teich: aus `teich-quelle-verworfene-karte.jpg` (Seed 11, Stärke 0,5 über die Vorlage von `regionsvorlage.py`, Stand 0.9.1), freigestellt mit isnet ohne Kontur. Der einzige Teil aus dem verworfenen Weg; er wird in der Karte gedreht und skaliert.
2. **Zusammensetzen:** `regionscollage.py region-01.json <teile> aus.png 2400` (Zufall mit festem Seed 5), dann `atlas.py aus.png map_region01 2400x1500px voll _ App/Assets.xcassets/Maps`.

**Verworfen:** `verworfen-blatt-teiche.jpg` (Seed 26): eckige Kästen mit
Plastikrand, auf der Karte wie Schachteln. Blätter in 1024 × 1024 liefen auf dem
Container über den Speicher (sd-cli, 14 GB), deshalb 768.

## `map_mission02_ground`, `map_mission03_ground`, `map_mission04_ground` (Grafik 06)

01.11.2026, [Konzept](../../docs/konzepte/grafik-06-kampfplaetze-m2-m4.md). Gleicher
Weg wie Mission 1, dieselben Teile aus `region01/` (Bäume, Höhle, Gras, Weg, wie oben
zerlegt und umgefärbt), dazu je Mission Deko im Waldrand und ein eigener Lichtton.
Weggeometrie: M2 aus `mission-02.json` (Thread „Mission 2 mit Zwergenbank"), M3 und M4
aus `wegvorschlaege/` (D-081).

1. **Deko-Blätter** (FLUX.1-schnell, Seed 31, 768 × 768, Stil-Teil wie bei `region01`),
   zerlegt mit `zerlegen.py`:
   - `kampfplaetze/blatt-zwerge.jpg` (M2, 7 Teile): `sprite sheet of six separate dwarven mining props, a wooden mine shaft entrance framed with heavy timber beams in a rocky mound, a small iron ore mine cart on a short rail piece, a stack of chopped logs, a pile of grey rocks with glittering gold ore, a wooden barrel, a crate with pickaxes, each isolated and evenly spaced on a plain white background, <Stil>, no characters, no text`
   - `kampfplaetze/blatt-pilze.jpg` (M3, 6 Teile): `sprite sheet of six separate fantasy forest floor props, a cluster of giant red and orange toadstool mushrooms, a cluster of glowing teal mushrooms, a mossy boulder, a large fern bush, a fallen mossy log, a ring of small brown mushrooms, each isolated and evenly spaced on a plain white background, <Stil>, no characters, no text`
   - M4: `region01/blatt-ruinen.jpg` (7 Teile), dieselben Ruinen wie auf der Kampagnenkarte.
2. **Collage:** `DEKO=<teile> DEKO_ANZAHL=<n> LICHT=<r,g,b> kampfplatz.py <weg.json> <teile> aus.png 130 4x2`
   — M2: 9 Teile, `245,245,225` (Morgen); M3: 10, `225,240,232` (gedämpft, leicht
   türkis); M4: 8, `255,226,190` (später Nachmittag). Das größte Teil (Stollen,
   große Mauer) steht genau einmal, oben, weit weg von der Höhle. Auf 1024 × 576
   verkleinert.
3. **Übermalen:** `INIT=<collage> STAERKE=0.4 VERSCHIEBUNG=0.5 erzeugen.sh aus 5 "<prompt>" 1024x576`.
   Gemeinsamer Teil: `mobile strategy game battlefield seen from directly above, stylized 3D cartoon render, hand-painted textures, vibrant saturated colors, a winding packed brown dirt path with small pebbles and grass tufts along its edges, a dark rocky goblin cave entrance on the left, highly detailed, no buildings in the clearing, no characters, no text, no letters, full bleed`, dahinter je Mission:
   - M2: `a sunny morning forest clearing at the edge of an old dwarven mine, a timber framed mine shaft entrance, an ore cart and stacked logs among the dense round tree canopies, lush fresh green grass with small flowers, cool fresh morning light from top left with golden highlights, soft tree shadows`
   - M3: `a mossy clearing deep in an enchanted forest, giant red toadstools and glowing teal mushrooms, ferns and mossy boulders among the dense round tree canopies, deep green mossy grass with clover, soft diffused afternoon light with a gentle teal tint, soft tree shadows`
   - M4: `a forest clearing at the edge of ancient crumbling grey stone ruins, broken mossy walls and fallen pillars among the dense round tree canopies, lush grass with small flowers, warm golden late afternoon light from top left, long soft tree shadows`
4. **Hochrechnen und Atlas** wie bei Mission 1: `hochskalieren.sh rohbild aus 3096x1677`,
   `atlas.py aus map_missionNN_ground 24x13 voll _ App/Assets.xcassets/Maps`.
   Collagen und Rohbilder liegen unter `kampfplaetze/`.
