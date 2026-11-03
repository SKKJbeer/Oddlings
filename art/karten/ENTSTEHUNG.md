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
   **Verworfen:** ein erster Durchgang mit Stärke 0,4 und langen Ortsprompts
   (`a sunny morning forest clearing at the edge of an old dwarven mine, …`): Die runden
   Baumkronen wurden Farn, die Höhle eine Lore. Gilt jetzt der Prompt von Mission 1 mit
   angehängtem Ort, Stärke 0,3. Auch dann verwischt die Höhle, deshalb Schritt 5.
4. **Hochrechnen:** `hochskalieren.sh rohbild gross.png 3096x1677`.
5. **Ebene auflegen:** `ebene.py gross.png <collage>-ebene.png fertig.png` (Höhle und Deko
   aus der Collage obenauf, weicher Schatten).
6. **Nachbessern:** M2 `retusche.py fertig.png aus.png "1370,615,1470,720:1240,615"
   "1070,695,1165,790:1170,695" "2545,1290,2640,1385:2440,1290"` (drei große Kiesel im
   Feld); M3 zweimal `ausgleichen.py fertig.png aus.png 8.2,1.4,12.6,6.6` (dunkler Fleck).
7. **Atlas:** `atlas.py aus map_missionNN_ground 24x13 voll _ App/Assets.xcassets/Maps`.
   Collagen und Rohbilder liegen unter `kampfplaetze/` (`missionNN-collage.jpg`,
   `missionNN-rohbild.jpg`).

## `map_mission05a_ground`, `map_mission05b_ground` (Grafik 07)

03.11.2026, [Konzept](../../docs/konzepte/grafik-07-kampfplaetze-m5.md). Ablauf wie Grafik 06,
dieselben Teile aus `region01/` (Bäume, Höhle, Gras, Weg wie oben zerlegt und umgefärbt).
Weggeometrie M5a aus `mission-05a.json` (= `wegvorschlaege/mission-05a.json`), M5b aus
`wegvorschlaege/mission-05b.json` (D-081).

1. **Deko-Blätter** (FLUX.1-schnell, 768 × 768, Stil-Teil wie bei `region01`), zerlegt mit `zerlegen.py`:
   - `kampfplaetze/blatt-sumpf.jpg` (M5a, Seed 41, 6 Teile; Schilf und Rohrkolben fielen beim Zerlegen weg): `sprite sheet of six separate fantasy swamp props, a clump of tall green reeds and cattails, a small dark murky bog pond with lily pads, a gnarled dead tree with twisted bare branches, a rotting mossy tree stump, a crooked wooden post with a glowing green lantern, a cluster of swamp roots with hanging moss, each isolated and evenly spaced on a plain white background, <Stil>, no characters, no text`. Beim hohlen Stumpf den weißen Bodenrest (heller als 200, kaum Farbe) durchsichtig gemacht.
   - `kampfplaetze/blatt-ruinenhof.jpg` (M5b, Seed 42, 7 Teile, davon 6 genutzt): `sprite sheet of six separate ancient temple ruin props, a broken stone archway overgrown with ivy, a toppled weathered stone statue of a knight, a cracked round stone fountain basin, a cluster of broken column stumps, a pile of carved stone rubble, a tall crumbling stone obelisk with moss, each isolated and evenly spaced on a plain white background, <Stil>, no characters, no text`. Die Ritterstatue ist weggelassen (las sich wie eine Figur), beim Torbogen die halb durchsichtigen Efeuränder deckend gesetzt (Alpha > 40 → 255).
2. **Gras M5a:** `gras.png` im Teile-Ordner umgefärbt (HSV: Blütenpunkte Sättigung × 0,4 und Helligkeit × 0,75, dann Farbton −6, Sättigung × 0,8, Helligkeit × 0,88): olives Moorgras statt Blumenwiese.
3. **Collage:** `DEKO=<teile> DEKO_ANZAHL=<n> DEKO_BREITE=<a,b> LICHT=<r,g,b> kampfplatz.py <weg.json> <teile> aus.png 130 4x2`
   — M5a: 18, `2.4,3.2`, `215,235,205` (grünliche Dämmerung); M5b: 14, `2.2,3.0`, `225,222,245`
   (kühles Abendlicht). Auf 1024 × 576 verkleinert (`kampfplaetze/mission05X-collage.jpg`).
   **Verworfen:** die erste Collage mit Deko nach Breite bemessen: Tote Bäume ragten aus dem
   unteren Rand über Bauzellen. Seitdem zählt die längere Seite.
4. **Übermalen:** `INIT=<collage> STAERKE=0.3 VERSCHIEBUNG=0.5 erzeugen.sh aus 5 "<Gemeinsamer Teil wie Grafik 06>, <Ort>" 1024x576`:
   - M5a: `a damp mossy clearing on an island in a misty forest swamp, gnarled dead trees, rotting stumps, reeds and small murky bog ponds with lily pads among the dense round tree canopies, deep olive green mossy grass, cool greenish dusk light with soft mist, soft tree shadows`
   - M5b: `a grassy courtyard inside ancient overgrown temple ruins, broken stone archways, fallen pillars and carved rubble among the dense round tree canopies, lush grass with small flowers, cool silver evening light with a soft violet tint, long soft shadows`
   FLUX macht aus den Baumkronen hier große Blätter; im Sumpf passt das und bleibt. Den Weg in
   M5b malt es mit abgeschrägten, hellen Kanten wie Steinplatten, passend zum Ruinenhof.
5. **Hochrechnen** (`hochskalieren.sh … 3096x1677`), **Ebene auflegen** (`ebene.py`).
6. **Nachbessern:** M5a `RAND=20 retusche.py fertig.png aus.png "1510,920,1770,1100:1945,640"
   "1440,440,1660,670:1960,700" "1630,810,1750,910:1960,950"` (Seerosen und zwei Pfützen im
   Feld, sie hätten wie unbebaubar gewirkt). Ein Ausgleich mit `ausgleichen.py` wurde verworfen,
   er färbte die Mittelbahn gelblicher als das übrige Gras. M5b `RAND=16 retusche.py …
   "1410,460,1550,590:1640,700" "1360,600,1490,730:1640,850"` (zwei Steine im Becken).
7. **Atlas:** `atlas.py aus map_mission05X_ground 24x13 voll _ App/Assets.xcassets/Maps`.
