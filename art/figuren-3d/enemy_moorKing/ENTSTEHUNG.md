# Moorkönig: 3D-Figur (FX 03)

Erste Fassung vom 03.11.2026, Thread „Moorkönig als 3D-Boss bauen“. Konzept:
[docs/konzepte/fx-03-moorkoenig.md](../../../docs/konzepte/fx-03-moorkoenig.md).

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0
(Apache 2.0), stable-diffusion.cpp d308544, euler, 4 Schritte, cfg 1,0,
**Seed 71**, 512 × 512. Prompt: "a huge hunched bog troll king, a towering swamp
monster with dark mossy green skin and a big round belly, a wide frowning face with
a heavy brow, a broad flat nose, two small yellow glowing eyes and a long wet beard
of hanging moss and reeds, a crown of twisted dark roots and small antlers set with
three glowing green gems, a ragged cloak of moss and lily leaves over the shoulders,
bark armor plates on the shoulders and chest, a thick gnarled wooden staff topped
with a glowing green lantern held upright in one hand, a large round shield of bark
and turtle shell strapped to the other forearm, stylized 3D cartoon character
render, hand-painted textures, chunky heavy proportions, vibrant saturated colors,
soft even studio light, highly detailed, no outlines, full body, standing straight,
three-quarter view, arms held slightly away from the body, centered, on a plain flat
light grey background, no ground, no shadow, no text, no letters". Freigestellt mit
`freistellen.py` (isnet-general-use, Kontur 0). Seeds 72 bis 74 mit demselben
Prompt liegen als Vergleich in `/mnt/project-files/moorkoenig/`; verworfen, weil
dort Stab und Schild am selben Arm hängen (72) oder der Schild am Bauch anliegt
(73, 74) und sich nicht getrennt bewegen ließe.

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1`
gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz),
gradio_client 2.7.2, Seed 1, SS 7,5/12, SLat 3/12, mesh_simplify 0,95, Textur 1024.
Stab und Schild sind Teil des Netzes. `figur.py` verschweißt die Nähte, entfernt
lose Splitter bis 60 Punkte (`splitterBis`; einer blieb sonst beim Sturz in der
Luft hängen) und setzt Metallic auf 0.

**Skelett** (`rig.json`): sieben Knochen, Gelenkpunkte von Hand aus Vorder- und
Seitenansicht gesetzt. Stab am Knochen `arm_stab` (rechte Hand, −x), Schild am
Knochen `arm_schild` (linker Unterarm, +x).

**Folgen:** `walk` (8, schweres Stapfen), `hit` (3), `die` (8, kippt nach hinten),
`shield` (4: Schildarm um 45° nach innen und 25° nach vorn, Rumpf und Kopf neigen
sich), `summon` (5: aus der Schildhaltung den Stab hoch über den Kopf und zurück,
`basis` und `bogen` in `rig.json`). Mehrere Drehungen je Knochen gehen als Liste.

**Kamera und Licht:** 12° von oben, 35° gedreht, Bildhöhe 1,6 (der Sturz bleibt
im Bild). Fülllicht 3,0, Welt 1,6, Comic-Stil Sättigung 1,45, Helligkeit 1,7,
Eigenlicht 0,45, Kontur 0,006.

**Bildfolgen im Atlas** (`enemy_moorKing_walk`, `enemy_moorKing_hit`,
`enemy_moorKing_die`, `enemy_moorKing_shield`, `enemy_moorKing_summon`):
`figur.py` mit 512 Pixeln, `angleichen.py` (Stärke 0,5) gegen `vorlage.png`, dann
`tools/figuren-3d/folge.py` (ein Maßstab für alle 28 Bilder). Das Standbild
`enemy_moorKing` ist eine Kopie von `walk_00`.
