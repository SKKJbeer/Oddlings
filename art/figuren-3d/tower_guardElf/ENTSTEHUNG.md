# Elfenschütze auf dem Wachturm: 3D-Figur (0.48.0)

Entstanden am 23. und 24.11.2026 für A-5 Teil 3 „Türme zielen“ (D-185, D-186,
[Konzept](../../../docs/konzepte/a-5-tuerme-zielen.md)), nach der Kette des Zwergenschützen
(`../tower_guard/ENTSTEHUNG.md`). Er steht bei Elfen auf dem Wachturm (der Schütze folgt dem
Volk, Steffens Wahl, 23.11.2026).

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0 (Apache 2.0),
euler, 4 Schritte, cfg 1,0, Seed 31, 512 × 512.
Prompt: "a slender elf archer guard with long pointed ears, a friendly clearly visible face and long blond hair in a ponytail, a green hooded cloak over a light leather tunic with golden leaf trim, brown leather boots and bracers, a quiver of arrows on the back, holding a big curved wooden longbow with both hands at chest height with an arrow nocked, the bow held upright and clearly visible in front of the body, stylized 3D cartoon character render, hand-painted textures, chunky proportions, vibrant saturated colors, soft even studio light, highly detailed, no outlines, full body, standing straight, front view, centered, on a plain flat light grey background, no ground, no shadow, no text, no letters".
Freigestellt mit `freistellen.py` (isnet-general-use, Kontur 0).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1` gegen die
Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz), am 24.11.2026 (am 23.11.
war das Tageskontingent nach dem Zwerg verbraucht). Hochgeladen wird nur die eigene Vorlage.

**Skelett** (`rig.json`): Gelenkpunkte aus Vorder- und Seitenansicht des Modells (Raster
über einer Blender-Ansicht). Der Bogen steht senkrecht vor der linken Hand, der Pfeil liegt
gespannt quer vor dem Körper und zeigt nach +x. Ein Bogenschütze steht seitlich zum Ziel;
darum braucht er anders als der Zwerg keine Ruhedrehung: Bogen und Pfeil hängen an der
Bogenhand, und der Pfeil zeigt in die Blickrichtung des Bilds. Schuss: Die Zughand schnellt
nach dem Lösen zurück, der Rumpf gibt leicht nach (`bogen`).

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag (40°), Sonne Azimut 135°.
Acht Blickrichtungen aus der gedrehten Figur, Richtung r → `blick` = 45·r.

**Bildfolgen im Atlas** (`tower_guardElf_shoot0`, `tower_guardElf_shoot1`,
`tower_guardElf_shoot2`, `tower_guardElf_shoot3`, `tower_guardElf_shoot4`,
`tower_guardElf_shoot5`, `tower_guardElf_shoot6`, `tower_guardElf_shoot7`, je `_00` bis
`_04`; 00 ist der Anschlag): `figur.py` mit 512 Pixeln, `angleichen.py` (Stärke 1,0,
Kontur 0) gegen `vorlage.png`, dann `BEZUG=shoot tools/figuren-3d/folge.py <ordner>
tower_guardElf` mit dem Konturpass.
