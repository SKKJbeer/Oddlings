"""Legt gerenderte Bildfolgen als Bildsätze in den Sprite-Atlas (FX 02).

    python folge.py <ein_ordner> <figur> [repo-wurzel]

ein_ordner  PNGs aus figur.py und angleichen.py (walk_00 …, hit_00 …, die_00 …)
figur       Name im Asset-Vertrag, z. B. enemy_raider; geschrieben wird
            <figur>_<folge>_NN.imageset mit @2x und @3x

EINE Umrechnung für alle Bilder einer Figur: Fuß von walk_00 auf dem Anker aus
dem Vertrag, Maßstab so, dass jedes Bild ganz ins Quadrat passt. Je Bild
eingepasst, würde die Figur beim Laufen pumpen und beim Sturz wachsen.
"""
import glob, json, os, re, sys
from PIL import Image

ein, figur = sys.argv[1], sys.argv[2]
wurzel = sys.argv[3] if len(sys.argv) > 3 else "."
vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
pt = vertrag["punkteJeZelle"]
atlas = os.path.join(wurzel, vertrag["atlas"])
RAND = 0.02  # Anteil der Seite, der frei bleibt, damit die Kontur nicht anstößt

bilder = {}
for pfad in sorted(glob.glob(os.path.join(ein, "*.png"))):
    m = re.fullmatch(r"([a-z]+)_(\d\d)\.png", os.path.basename(pfad))
    if m:
        bilder[(m.group(1), int(m.group(2)))] = Image.open(pfad).convert("RGBA")
folgen = sorted({f for f, _ in bilder})
for f in folgen:
    regel = vertrag["assets"].get(f"{figur}_{f}")
    if regel is None or "folge" not in regel:
        sys.exit(f"{figur}_{f} steht nicht als Folge im Vertrag")
    if sorted(i for g, i in bilder if g == f) != list(range(regel["folge"])):
        sys.exit(f"{figur}_{f}: Vertrag verlangt {regel['folge']} Bilder ohne Lücke")


def box(bild):
    return bild.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()


boxen = [box(b) for b in bilder.values()]
links, oben = min(b[0] for b in boxen), min(b[1] for b in boxen)
rechts, unten = max(b[2] for b in boxen), max(b[3] for b in boxen)
fuss = box(bilder[("walk", 0)])[3]
regel = vertrag["assets"][f"{figur}_walk"]
anker = regel["anker"]

for faktor in (2, 3):
    seite = round(regel["seiteZellen"] * pt * faktor)
    nutz = seite * (1 - 2 * RAND)
    # Über dem Fuß ist (1 - anker) der Seite frei, darunter anker; beides muss reichen.
    k = min(nutz / (rechts - links),
            (seite * (1 - anker) - seite * RAND) / max(1, fuss - oben),
            (seite * anker - seite * RAND) / max(1, unten - fuss) if unten > fuss else float("inf"))
    for (f, i), bild in bilder.items():
        name = f"{figur}_{f}_{i:02d}"
        klein = bild.resize((round(bild.width * k), round(bild.height * k)), Image.LANCZOS)
        x = round(seite / 2 - (links + rechts) / 2 * k)
        y = round(seite * (1 - anker) - fuss * k)
        # Über eine größere Leinwand, weil alpha_composite keinen Versatz über
        # den Rand nimmt und paste mit Maske die Kanten ausdünnt.
        gross = Image.new("RGBA", (seite + 2 * klein.width, seite + 2 * klein.height))
        gross.alpha_composite(klein, (x + klein.width, y + klein.height))
        leinwand = gross.crop((klein.width, klein.height, klein.width + seite, klein.height + seite))
        ordner = os.path.join(atlas, f"{name}.imageset")
        os.makedirs(ordner, exist_ok=True)
        leinwand.save(os.path.join(ordner, f"{name}@{faktor}x.png"), optimize=True)
        json.dump({"images": [{"idiom": "universal", "scale": "2x", "filename": f"{name}@2x.png"},
                              {"idiom": "universal", "scale": "3x", "filename": f"{name}@3x.png"},
                              {"idiom": "universal", "scale": "1x"}],
                   "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(ordner, "Contents.json"), "w"), indent=2)
print(f"✓ {len(bilder)} Bilder von {figur} in {os.path.relpath(atlas, wurzel)}")
