# Plünderer: 3D-Figur (FX 02)

Zweite Fassung vom 26.10.2026. Die erste Vorlage (Seed 32, freundliches Gesicht,
Kapuze, Keule und Sack als eigene Modelle) wirkte neben dem gemalten Plünderer zu
brav; Steffen wollte den Comic-Look des Gemäldes. Sie liegt in der Git-Historie.

**Vorlage** (`vorlage.png`, aus `vorlage-rohbild.png`), gemalt vom Grafik-Thread:
FLUX.1-schnell Q4_0 (Apache 2.0), euler, 4 Schritte, cfg 1,0, Seed 52, 512 × 512.
Prompt: "a small grim goblin raider with bright green skin, bare green arms and
legs, a small pointed brown leather cap, a scowling face with two lower tusks and
narrow yellow eyes, a ragged brown tunic with a rope belt, a large bulging brown
loot sack slung over one shoulder, a dark heavy wooden club bound with an iron
band in the other hand, stylized 3D cartoon character render, hand-painted
textures, chunky proportions, vibrant saturated colors, soft even studio light,
highly detailed, no outlines, full body, standing straight, three-quarter view,
arms held slightly away from the body, centered, on a plain flat light grey
background, no ground, no shadow, no text, no letters". Freigestellt mit
`freistellen.py` (isnet-general-use, Kontur 0), weil TRELLIS eine Kontur in die
Textur backen würde. Seed 51 verworfen: verschränkte Arme lassen sich nicht riggen.

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py vorlage.png modell.glb 1`
gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft, MIT-Lizenz),
gradio_client 2.7.2, Seed 1, SS 7,5/12, SLat 3/12, mesh_simplify 0,95, Textur 1024.
Hochladen der Vorlage von Steffen freigegeben. Keule und Sack sind Teil des Netzes;
eigene Requisiten (Feld `requisiten` in `rig.json`) braucht diese Fassung nicht.
`figur.py` verschweißt die Texturnähte und setzt Metallic auf 0.

**Skelett** (`rig.json`): Gelenkpunkte von Hand aus Vorder- und Seitenansicht
gesetzt. Die Arme stehen in der Vorlage schon vom Körper ab, deshalb keine
`ruhe`-Drehungen. Die Keule bewegt sich mit `arm_r`.

**Kamera und Licht:** 12° von oben, 35° gedreht. Höher verdeckt die Mütze das
Gesicht. Fülllicht 2,2, weil die Textur dunkel ausfällt.

**Comic-Look:** `stil` in `rig.json` macht die Texturfarbe satter und heller
(Sättigung 1,5, Helligkeit 1,4), lässt einen Teil selbst leuchten (flächige
Schatten), zeichnet mit einer dunklen Hülle Umriss und Innenkonturen, dazu
Randlicht von hinten.

**Bildfolgen im Atlas** (`enemy_raider_walk`, `enemy_raider_hit`,
`enemy_raider_die`): `figur.py` mit 512 Pixeln, `angleichen.py` (Stärke 0,5) gegen
`art/spielfeld/enemy_raider-frei.png`, dann `tools/figuren-3d/folge.py` (ein
Maßstab für alle 17 Bilder, Fuß von `walk_00` auf dem Anker 0,1). Vergleich mit
dem Gemälde: `/mnt/project-files/fx-02/raider-v2-vergleich.jpg`.

## A-3: gemeinsame Kamera, drei Blickrichtungen, Konturpass (16.11.2026)

Neu gerendert für die gemeinsame Kamera (D-140): 30° statt 12° von oben (Spielraum
des Vertrags 30 bis 40°), Sonne aus dem Vertrag (Azimut 135°, Höhe 45°), Aufhellung
von der Gegenseite. Bei 30° verdeckte die breite Krempe das Gesicht; `verformen` in
`rig.json` schiebt die Mütze nach hinten (Punkte über 0,80 der Höhe um 50° gekippt),
der Kopf ist in der Grundhaltung um 15° gehoben. Seitlich jetzt 45° gedreht statt 35°.

Neue Folgen `enemy_raider_walkFront` (Figur 20° gedreht, kommt auf den Betrachter zu)
und `enemy_raider_walkBack` (160°, geht weg), dieselben Schlüsselbilder wie `walk`.
`angleichen.py` (Stärke 0,5, Kontur 0) gegen `art/spielfeld/enemy_raider-frei.png`,
dann `folge.py` mit dem Konturpass (1 Punkt) statt der Kontur aus `angleichen.py`.
Abnahme am Bildpaar: `tools/figuren-3d/bildpaar.py enemy_raider`.
