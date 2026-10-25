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
