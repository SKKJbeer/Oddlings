# Figuren in 3D zu Bildfolgen (FX 02)

Konzept: [docs/konzepte/fx-02-figuren-in-3d.md](../../docs/konzepte/fx-02-figuren-in-3d.md).

```
python3 -m venv $HOME/bpy && $HOME/bpy/bin/pip install bpy
$HOME/bpy/bin/python -I figur.py <modell.glb> <rig.json> <ausgabe> 192
```

- `figur.py`: Modell laden, Skelett aus `rig.json` setzen, automatisch binden,
  Folgen `walk`, `hit`, `die` als Schlüsselbilder rendern.
- `test-ork.json`: Probe mit Kenneys Ork aus „Mini Dungeon" (CC0), dessen eigenes
  Skelett absichtlich verworfen wird, um ein TRELLIS-Modell ohne Skelett
  nachzustellen. Ergebnis: [art/fx-02/probe-eigenes-skelett.jpg](../../art/fx-02/probe-eigenes-skelett.jpg).
  Der Ork kommt nicht ins Spiel.

Felder in `rig.json` über den Plünderer hinaus (FX 03, Moorkönig):
`verlauf`/`bogen` nehmen je Knochen auch eine Liste von Drehungen
(`[["y", 45], ["x", -25]]`); `bogen` geht hin und zurück (erstes und letztes Bild
in der Grundhaltung); `basis` legt eine andere Folge voll ausgeführt darunter
(der Ruf beginnt in der Schildhaltung); `splitterBis` entfernt lose Netzinseln bis
zu so vielen Punkten. `NUR=walk,shield` rendert nur diese Folgen.

Blender (`bpy`) steht unter GPL und ist nur Werkzeug; gerenderte Bilder sind
davon nicht berührt. Es wird nicht in die App gebaut.
