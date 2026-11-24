# Zwergenschütze auf dem Wachturm: 3D-Figur (0.48.0)

Entstanden am 23.11.2026 für A-5 Teil 3 „Türme zielen“ (D-185, D-186,
[Konzept](../../../docs/konzepte/a-5-tuerme-zielen.md)), nach der Kette von A-3. Er steht
bei Zwergen und ohne Avatar auf dem Wachturm; bei Elfen steht dort der Elfenschütze
(`tower_guardElf`), der Schütze folgt dem Volk (Steffens Wahl, 23.11.2026).

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0 (Apache 2.0),
euler, 4 Schritte, cfg 1,0, Seed 21, 512 × 512.
Prompt: "a stocky dwarf crossbowman guard with a thick braided red-brown beard and a wide clearly visible friendly face, a round steel helmet without visor, a short red tabard over grey chainmail, brown leather gloves and boots, holding a big chunky wooden crossbow with a thick steel bow in both hands at chest height, the crossbow held level and pointing straight toward the viewer, the bow wide and clearly visible in front of his belly, stylized 3D cartoon character render, hand-painted textures, chunky proportions, vibrant saturated colors, soft even studio light, highly detailed, no outlines, full body, standing straight, front view, centered, on a plain flat light grey background, no ground, no shadow, no text, no letters".
Verworfen: Seed 11 (dünne Armbrust schräg nach unten), Seed 12 (nur ein Stab), Seed 22
(ein Rohr ohne Bogen). Freigestellt mit `freistellen.py` (isnet-general-use, Kontur 0).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1` gegen die
Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz). Hochgeladen wird nur die
eigene Vorlage.

**Skelett** (`rig.json`): Gelenkpunkte aus Vorder- und Seitenansicht des Modells (Raster
über einer Blender-Ansicht). Trotz Prompt hält er die Armbrust quer vor dem Bauch. Zwei
starre Knochen mit gemeinsamem Drehpunkt in der Mitte der Armbrust drehen sie in der Ruhe
um 90° nach vorn; so zeigen Gesicht und Waffe in dieselbe Richtung, und die Richtung liest
sich auch klein. Schuss: Rumpf und Kopf nicken zurück und kommen wieder (`bogen`).

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag (40°), Sonne Azimut 135°.
Acht Blickrichtungen aus der gedrehten Figur, Richtung r → `blick` = 45·r + 90.

**Bildfolgen im Atlas** (`tower_guard_shoot0`, `tower_guard_shoot1`, `tower_guard_shoot2`,
`tower_guard_shoot3`, `tower_guard_shoot4`, `tower_guard_shoot5`, `tower_guard_shoot6`,
`tower_guard_shoot7`, je `_00` bis `_04`; 00 ist der Anschlag): `figur.py` mit 512 Pixeln,
`angleichen.py` (Stärke 1,0, Kontur 0) gegen `vorlage.png`, dann
`BEZUG=shoot tools/figuren-3d/folge.py <ordner> tower_guard` mit dem Konturpass.
