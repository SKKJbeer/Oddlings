# Kampfplatz als 3D-Diorama (A-4, D-140, D-165)

Baut einen Kampfplatz aus seiner Missionsdatei als einfache 3D-Szene und rendert ihn in
der gemeinsamen Kamera aus `art/asset-vertrag.json` (`kamera`, `sonne`). Das Ergebnis
wird danach mit FLUX im Stil übermalt (Skill `spielgrafik`). Konzept:
[A-4](../../docs/konzepte/a-4-diorama-mission-1.md).

| Datei | Aufgabe |
|---|---|
| `plan.py` | reines Python (Pillow): Szene aus Daten planen (Weg, Inseln, Wald im Rand, Landschaft zwischen den Inseln, Steinkanten), prüft vor dem Rendern, dass nichts Hohes Weg oder Insel verdeckt; schreibt `plan.json` und die Bodentexturen |
| `diorama.py` | Blender (`bpy`): baut die Szene aus `plan.json`, Kamera 40° orthografisch mit Kabinettstreckung, Sonne 135°/45°, Cycles |
| `massstab.py` | Maßstabsbild (D-166): heutige Figuren, Turm und Festung in Zielhöhe auf dem Boden |
| `orte/<mission>.json` | Ort: Zufall, Rand, Licht (gleich `kampfplatzlicht.json`), Texturen, Farben, Landschaft |

## Ablauf (Mission 1)

```bash
M=Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json
python3 tools/kampfplatz-3d/plan.py $M tools/kampfplatz-3d/orte/mission-01.json /tmp/d 64
(cd tools/kampfplatz-3d && $HOME/bpy/bin/python -I diorama.py /tmp/d /tmp/d/render.png 24)
# render.png → 1024×576 → FLUX Bild-zu-Bild (STAERKE 0.4, VERSCHIEBUNG 0.5) → hochskalieren.sh → atlas.py
python3 tools/kampfplatz-3d/massstab.py <boden.jpg> art/karten/diorama/massstab-mission01.jpg
```

Einzelheiten zu jedem ausgelieferten Bild (Prompt, Seed, Schritte) stehen in
`art/karten/ENTSTEHUNG.md`.

## Kamera

Die Tiefe der Szene wird um 1/sin 40° gestreckt: Eine Bodenzelle erscheint im Bild genau
quadratisch, das Raster der Simulation bleibt gültig, und alles mit Höhe zeigt seine
Seite im selben Winkel wie Türme und Figuren. Erhöhte Inseln werden um ihre Höhe nach
hinten verschoben, damit ihre Oberseite genau die Zellen der Simulation deckt.

## Lizenz und Umgebung

Blender (GPL) ist Werkzeug und läuft nur im Entwicklungscontainer (`pip install bpy` in
eine eigene Umgebung unter `$HOME/bpy`); nichts davon gelangt in die App. Das Skript
liest nur Dateien aus dem Repository und schreibt nur ins angegebene Ziel.
