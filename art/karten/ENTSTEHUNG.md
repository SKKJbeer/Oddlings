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
