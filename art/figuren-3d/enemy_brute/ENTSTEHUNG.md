# Panzerbestie: 3D-Figur (A-3, Teil 2)

Entstanden am 17.11.2026 für den AAA-Schnitt ([Konzept](../../../docs/konzepte/a-3-figuren-vollstaendig.md)).

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0
(Apache 2.0), euler, 4 Schritte, cfg 1,0, Seed 21, 512 × 512.
Prompt: "a stocky armored war boar beast standing on four sturdy legs, dark brown bristly fur, a tall dark blue-black mane along the back, huge curved ivory tusks, a pink snout, two short curved horns, small fierce eyes, heavy steel-blue armor plates riveted on the back and flanks, one large golden shoulder plate, brown leather straps across the chest, steel greaves on all four legs, stylized 3D cartoon creature render, hand-painted textures, chunky proportions, vibrant saturated colors, soft even studio light, highly detailed, no outlines, full body, standing straight on all four legs, three-quarter view facing right, legs clearly separated, centered, on a plain flat light grey background, no ground, no shadow, no text, no letters".
Seed 22 verworfen: rötliches Fell und ein Stern auf der Schulter, weiter weg vom
dunklen Keiler des Gemäldes. Freigestellt mit `freistellen.py` (isnet-general-use,
Kontur 0).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1`
gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz),
gradio_client 2.7.2, Seed 1, SS 7,5/12, SLat 3/12, mesh_simplify 0,95, Textur 1024.
Hochgeladen wird nur die eigene Vorlage (freigegeben seit FX 02).

**Skelett** (`rig.json`): vierbeinig, Gelenkpunkte aus Vorder- und Seitenansicht des
Modells. Becken (Hinterleib) trägt die Hinterbeine, Rumpf (Brust) die Vorderbeine
und den Kopf. `splitterBis` 30 entfernt lose Splitter; ein höherer Wert (200) nahm
die Hauer mit, weil TRELLIS sie als eigene Inseln anlegt.
Laufen: Beine diagonal paarweise (vorn links mit hinten rechts), Kopf nickt.
Treffer: Kopf ruckt hoch. Sturz: kippt auf die Seite.

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag (30° für Figuren), Sonne
Azimut 135°, Höhe 45°. Seitlich 45° gedreht, `walkFront` 20°, `walkBack` 160°.

**Bildfolgen im Atlas** (`enemy_brute_walk`, `enemy_brute_walkFront`,
`enemy_brute_walkBack`, `enemy_brute_hit`, `enemy_brute_die`): `figur.py` mit
512 Pixeln, `angleichen.py` (Stärke 0,5, Kontur 0) gegen
`art/spielfeld/enemy_brute-frei.png`, dann `tools/figuren-3d/folge.py` mit dem
Konturpass. Abnahme: `tools/figuren-3d/bildpaar.py enemy_brute`.
