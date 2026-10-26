# Karten — Entstehung

## `map_mission01_ground` (Mission 1)

Der Weg ist nicht frei gemalt, sondern liegt auf der Geometrie aus
`mvp-mission-01.json` (`map.path`, Zellkoordinaten, Ursprung oben links).

1. **Texturen** (FLUX.1-schnell, 512 × 512, Seed 21, euler, 4 Schritte):
   - `textur-gras-rohbild.png`: Stil-Teil `stylized 3D cartoon render, hand-painted textures, vibrant saturated colors, warm light from top left, highly detailed, mobile strategy game terrain, seen from directly above, seamless, full bleed, no objects, no text, no letters`, Motiv `lush green meadow ground texture with dense short grass blades, small clover patches, tiny yellow and white flowers, subtle light and shadow variation`. Benutzt nur der Ausschnitt (60, 140, 400, 512): Rest hat Baumstümpfe und Steine.
   - `textur-sand-rohbild.png`: gleicher Stil-Teil, Motiv `sandy dirt path ground texture, packed warm beige sand with small pebbles, faint footprints and wheel ruts, subtle cracks`. Ausschnitt (100, 140, 400, 512), Medianfilter 25 gegen die großen Kiesel, Sättigung × 0,55, Helligkeit × 0,92.
2. **Zusammensetzen:** `karte_zusammensetzen.py mvp-mission-01.json gras sand aus 64` → `mission01-zusammengesetzt.png` (1024 × 576, 64 px je Zelle).
3. **Bild-zu-Bild:** `INIT=mission01-zusammengesetzt.png STAERKE=0.35 erzeugen.sh aus 5 "<prompt>" 1024x576` → `mission01-rohbild.png`. Prompt: `mobile strategy game battlefield ground seen from directly above, stylized 3D cartoon render, hand-painted textures, vibrant saturated colors, lush green meadow with small flowers, a sandy dirt path with packed earth, small pebbles, footprints and soft darker sunken edges where the grass overhangs, warm afternoon light from top left, highly detailed, no buildings, no characters, no text, no letters, full bleed`.
4. **Hochrechnen:** Real-ESRGAN x4 anime 6B, dann Lanczos auf 2064 × 1161, `atlas.py … 16x9 voll 43 App/Assets.xcassets/Maps` (JPEG, Qualität 88).

**Verworfen:** `verworfen-frei-gemalt.png`, Bild-zu-Bild mit Stärke 0,7 direkt
auf `mission01-vorlage.png` (`kartenvorlage.py`): Der Weg wurde zur
Schlangenlinie und bekam Steine, die Oberfläche wirkte flach.

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
