# Sporling: 3D-Figur (0.43.0)

Entstanden am 18.11.2026 für die Gegnerrolle Teiler (Junges des Pilzbalgs) (D-143, D-178,
[Konzept](../../../docs/konzepte/a-6-heiler-und-teiler.md)), nach der Kette von A-3.
In 0.42.0 lief der Sporling als gemaltes Standbild, weil das Rechenkontingent von TRELLIS
aufgebraucht war.

**Vorlage:** das gemalte Bild `art/spielfeld/enemy_sporeling-frei.png`, Herkunft und Prompt in
[art/spielfeld/ENTSTEHUNG.md](../../spielfeld/ENTSTEHUNG.md).

**Modell** (`modell.glb`): `tools/figuren-3d/trellis.py art/spielfeld/enemy_sporeling-frei.png
modell.glb 1` gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft,
MIT-Lizenz), Einstellungen wie bei der Moorhexe. Hochgeladen wird nur die eigene Vorlage.

**Skelett** (`rig.json`): Gelenkpunkte aus vier Ansichten des Modells (Raster über einer
Blender-Ansicht). Der Hut ist mit `verformen` 25° nach hinten gekippt; sonst verdeckt seine Krempe bei 30° Kamera das Gesicht, wie bei der Mütze des Plünderers. Klein und flink: schnelle, große Schritte, weit schwingende Arme. Treffer: Rumpf und Kopf knicken zurück. Sturz: rücklings.

**Kamera und Licht:** gemeinsame Kamera aus dem Vertrag, Sonne Azimut 135°, Höhe 45°.
Seitlich 45° gedreht, `walkFront` 20°, `walkBack` 160°.

**Bildfolgen im Atlas** (`enemy_sporeling_walk`, `enemy_sporeling_walkFront`,
`enemy_sporeling_walkBack`, `enemy_sporeling_hit`, `enemy_sporeling_die`): `figur.py` mit 512
Pixeln, `angleichen.py` (Stärke 1,0, Kontur 0) gegen die gemalte Vorlage, dann
`tools/figuren-3d/folge.py` mit dem Konturpass, Seite 0.65 Zellen. Das Standbild
`enemy_sporeling` ist das erste Laufbild (gleicher Anker, gleicher Maßstab). Abnahme:
`tools/figuren-3d/bildpaar.py enemy_sporeling`.
