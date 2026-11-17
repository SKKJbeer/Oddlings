# Moorhexe: 3D-Figur (0.42.0)

Entstanden am 17.11.2026 für die Gegnerrolle Heiler (D-143, D-178,
[Konzept](../../../docs/konzepte/a-6-heiler-und-teiler.md)), nach der Kette von A-3.

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0
(Apache 2.0), euler, 4 Schritte, cfg 1,0, Seed 12, 512 × 512.
Prompt: "a small hunched old bog witch with greenish grey skin, a long crooked nose and a wide clearly visible face with bright green glowing eyes, wild stringy dark hair with moss, a short ragged dark purple hooded cape pushed back off the head, a patched brown dress with a belt of hanging herbs and little bottles, bare bony arms, holding a gnarled wooden staff topped with a small glowing green moss lantern in one hand, stylized 3D cartoon character render, hand-painted textures, chunky proportions, vibrant saturated colors, soft even studio light, highly detailed, no outlines, full body, standing straight, three-quarter view, arms held slightly away from the body, centered, on a plain flat light grey background, no ground, no shadow, no text, no letters".
Seed 11 verworfen: Laterne am Stab statt in der zweiten Hand und eine breite Hutkrempe,
die bei 30° Kamera das Gesicht verdeckt. Seed 12 hält Stab und Laterne in getrennten
Händen, das Gesicht liegt frei. Freigestellt mit `freistellen.py` (isnet-general-use,
Kontur 0).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1` gegen
die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz), Einstellungen
wie beim Flitzer. Hochgeladen wird nur die eigene Vorlage.

**Skelett** (`rig.json`): Gelenkpunkte aus Vorder- und Seitenansicht des Modells
(Raster über einer Blender-Ansicht). Der Stab bekommt einen eigenen, starren Knochen an
der rechten Hand; ohne ihn zöge das rechte Bein das untere Stabende mit. Sie geht
gebückt und humpelnd: kleiner Hub, kurze Schritte, die Laternenhand schwingt, die
Stabhand kaum. Treffer: Rumpf knickt zurück. Sturz: rücklings.

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag, Sonne Azimut 135°, Höhe 45°.
Seitlich 45° gedreht, `walkFront` 20°, `walkBack` 160°.

**Bildfolgen im Atlas** (`enemy_witch_walk`, `enemy_witch_walkFront`,
`enemy_witch_walkBack`, `enemy_witch_hit`, `enemy_witch_die`): `figur.py` mit 512
Pixeln, `angleichen.py` (Stärke 1,0, Kontur 0) gegen `vorlage.png`; mit 0,5 blieb sie neben Plünderer und Flitzer zu dunkel, dann
`tools/figuren-3d/folge.py` mit dem Konturpass. Das Standbild `enemy_witch` ist das
erste Laufbild (gleicher Anker, gleicher Maßstab). Abnahme:
`tools/figuren-3d/bildpaar.py enemy_witch`.
