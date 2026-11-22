# Pilzbalg: 3D-Figur (0.43.0)

Entstanden am 18.11.2026 für die Gegnerrolle Teiler (D-143, D-178,
[Konzept](../../../docs/konzepte/a-6-heiler-und-teiler.md)), nach der Kette von A-3.
In 0.42.0 lief der Pilzbalg als gemaltes Standbild, weil das Rechenkontingent von TRELLIS
aufgebraucht war.

**Vorlage:** das gemalte Bild `art/spielfeld/enemy_puffball-frei.png`, Herkunft und Prompt in
[art/spielfeld/ENTSTEHUNG.md](../../spielfeld/ENTSTEHUNG.md).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py art/spielfeld/enemy_puffball-frei.png
modell.glb 1` gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft,
MIT-Lizenz), Einstellungen wie bei der Moorhexe. Hochgeladen wird nur die eigene Vorlage.

**Skelett** (`rig.json`): Gelenkpunkte aus vier Ansichten des Modells (Raster über einer
Blender-Ansicht). TRELLIS legt das Gesicht nach hinten (+y); `drehungZ` 180 dreht es nach vorn. Dafür wirkt `drehungZ` in `figur.py` seit 0.43.0 direkt am Netz, vorher blieb es ohne Wirkung. Der Ball ist Rumpf und Kopf in einem, er watschelt: das Becken kippt seitlich, die Stummelbeine schwingen weit. Treffer: Rumpf knickt zurück, Arme fliegen auf. Sturz: rücklings.

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag, Sonne Azimut 135°, Höhe 45°.
Seitlich 45° gedreht, `walkFront` 20°, `walkBack` 160°.

**Bildfolgen im Atlas** (`enemy_puffball_walk`, `enemy_puffball_walkFront`,
`enemy_puffball_walkBack`, `enemy_puffball_hit`, `enemy_puffball_die`): `figur.py` mit 512
Pixeln, `angleichen.py` (Stärke 1,0, Kontur 0) gegen die gemalte Vorlage, dann
`tools/figuren-3d/folge.py` mit dem Konturpass, Seite 0.8 Zellen. Das Standbild
`enemy_puffball` ist das erste Laufbild (gleicher Anker, gleicher Maßstab). Abnahme:
`tools/figuren-3d/bildpaar.py enemy_puffball`.
