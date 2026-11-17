"""Bildpaar zur Abnahme (A-3): gemalte Vorlage neben den Bildfolgen, auf dem Kampfplatz.

    python bildpaar.py <figur> <ausgabe.jpg> [repo-wurzel] [vergroesserung=3]

Zeigt in einer Reihe: das Gemälde aus art/spielfeld (falls vorhanden), dann
walk_00, walk_04, walkFront_00, walkBack_00, hit_02, die_05 aus dem Atlas,
in @3x auf einem Ausschnitt des Bodens von Mission 1. Vergrößert mit
Nächster-Nachbar, damit man die echten Pixel sieht und nichts schöner wirkt,
als es auf dem Telefon ist. Eine zweite Reihe zeigt dieselben Bilder in
Spielgröße (1 Punkt = 1 Pixel @3x / 3), wie man sie im Spiel sieht.
"""
import json, os, sys
from PIL import Image

figur, aus = sys.argv[1], sys.argv[2]
wurzel = sys.argv[3] if len(sys.argv) > 3 else "."
mal = int(sys.argv[4]) if len(sys.argv) > 4 else 3
vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
atlas = os.path.join(wurzel, vertrag["atlas"])

bilder = []
gemaelde = os.path.join(atlas, f"{figur}.imageset", f"{figur}@3x.png")
if os.path.exists(gemaelde):
    bilder.append(Image.open(gemaelde).convert("RGBA"))
for name in ("walk_00", "walk_04", "walkFront_00", "walkFront_04", "walkBack_00", "walkBack_04", "hit_02", "die_05"):
    pfad = os.path.join(atlas, f"{figur}_{name}.imageset", f"{figur}_{name}@3x.png")
    if os.path.exists(pfad):
        bilder.append(Image.open(pfad).convert("RGBA"))
if not bilder:
    sys.exit(f"keine Bilder von {figur} im Atlas")

seite = max(b.width for b in bilder)
boden = Image.open(os.path.join(wurzel, "App/Assets.xcassets/Maps/map_mission02_ground.imageset",
                                sorted(f for f in os.listdir(os.path.join(wurzel, "App/Assets.xcassets/Maps/map_mission02_ground.imageset"))
                                       if f.endswith((".jpg", ".png")))[-1])).convert("RGBA")
breite = len(bilder) * seite
gross = boden.crop((0, 0, breite, seite)).resize((breite * mal, seite * mal), Image.NEAREST)
for i, b in enumerate(bilder):
    gross.alpha_composite(b.resize((b.width * mal, b.height * mal), Image.NEAREST), (i * seite * mal, (seite - b.height) * mal))
klein = boden.crop((0, seite, breite, 2 * seite))
for i, b in enumerate(bilder):
    klein.alpha_composite(b, (i * seite, seite - b.height))
blatt = Image.new("RGB", (gross.width, gross.height + klein.height))
blatt.paste(gross.convert("RGB"), (0, 0))
blatt.paste(klein.convert("RGB"), (0, gross.height))
blatt.save(aus, quality=88)
print("✓", aus, blatt.size)
