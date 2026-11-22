# Flitzer: 3D-Figur (A-3, Teil 2)

Entstanden am 17.11.2026 für den AAA-Schnitt ([Konzept](../../../docs/konzepte/a-3-figuren-vollstaendig.md)).

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0
(Apache 2.0), euler, 4 Schritte, cfg 1,0, Seed 12, 512 × 512.
Prompt: "a small lanky imp runner with bright orange skin, a slim wiry body, two very long thin straight dark brown antennae rising up and slightly back from the forehead like insect feelers, large pointed ears, narrow sly yellow-green eyes with a mischievous smirk, a red scarf wrapped around the neck with both ends hanging down the back, a small brown leather backpack, dark blue short trousers with a brown belt, bare orange arms and legs with long feet, stylized 3D cartoon character render, hand-painted textures, chunky proportions, vibrant saturated colors, soft even studio light, highly detailed, no outlines, full body, standing straight, three-quarter view, both arms hanging down at the sides held clearly away from the body, hands open, legs slightly apart, centered, on a plain flat light grey background, no ground, no shadow, no text, no letters".
Seed 11 (erster Prompt) verworfen: gebogene Hörner statt der langen geraden Fühler
des Gemäldes, Arme vor dem Bauch verschränkt. Freigestellt mit `freistellen.py`
(isnet-general-use, Kontur 0).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1`
gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz),
gradio_client 2.7.2, Seed 1, SS 7,5/12, SLat 3/12, mesh_simplify 0,95, Textur 1024.
Hochgeladen wird nur die eigene Vorlage (freigegeben seit FX 02). Rucksack und Schal
sind Teil des Netzes.

**Skelett** (`rig.json`): Gelenkpunkte aus Vorder- und Seitenansicht des Modells
(Raster über einer Blender-Ansicht). Der Schal bekommt keinen eigenen Knochen: Er
liegt eng am Hals und bewegt sich mit dem Rumpf. Der Rumpf ist in der Grundhaltung
14° vorgekippt, der Kopf 18° gehoben (schnell und flach, wie im Gemälde), Beine und
Arme schwingen weiter aus als beim Plünderer. Treffer: Rumpf knickt zurück. Sturz:
vornüber.

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag (30° für Figuren), Sonne
Azimut 135°, Höhe 45°. Seitlich 45° gedreht, `walkFront` 20°, `walkBack` 160°.

**Bildfolgen im Atlas** (`enemy_runner_walk`, `enemy_runner_walkFront`,
`enemy_runner_walkBack`, `enemy_runner_hit`, `enemy_runner_die`): `figur.py` mit
512 Pixeln, `angleichen.py` (Stärke 0,5, Kontur 0) gegen
`art/spielfeld/enemy_runner-frei.png`, dann `tools/figuren-3d/folge.py` mit dem
Konturpass. Abnahme: `tools/figuren-3d/bildpaar.py enemy_runner`.
