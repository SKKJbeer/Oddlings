"""Legt gerenderte Bildfolgen als Bildsätze in den Sprite-Atlas (FX 02).

    python folge.py <ein_ordner> <figur> [repo-wurzel]

ein_ordner  PNGs aus figur.py und angleichen.py (walk_00 …, hit_00 …, die_00 …)
figur       Name im Asset-Vertrag, z. B. enemy_raider; geschrieben wird
            <figur>_<folge>_NN.imageset mit @2x und @3x

EINE Umrechnung für alle Bilder einer Figur: Fuß von walk_00 auf dem Anker aus
dem Vertrag, Maßstab so, dass jedes Bild ganz ins Quadrat passt. Je Bild
eingepasst, würde die Figur beim Laufen pumpen und beim Sturz wachsen. Das gilt
auch für die Blickrichtungen walkFront/walkBack (A-3): Beim Umdrehen darf die
Figur weder wachsen noch hüpfen.

Danach der Konturpass (A-3): eine dunkle Außenlinie aus der Silhouette, breit
`konturPunkte` aus dem Vertrag. Gerechnet nach dem Verkleinern, damit jede
Figur auf dem Schirm dieselbe Linie trägt, egal wie stark sie skaliert wurde.
"""
import glob, json, os, re, sys
from PIL import Image
from konturpass import kontur

ein, figur = sys.argv[1], sys.argv[2]
wurzel = sys.argv[3] if len(sys.argv) > 3 else "."
vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
pt = vertrag["punkteJeZelle"]
atlas = os.path.join(wurzel, vertrag["atlas"])
RAND = 0.02  # Anteil der Seite, der frei bleibt, damit die Kontur nicht anstößt
kontur_pt = vertrag.get("konturPunkte", 0)

bilder = {}
for pfad in sorted(glob.glob(os.path.join(ein, "*.png"))):
    m = re.fullmatch(r"([a-z][A-Za-z0-9]*)_(\d\d)\.png", os.path.basename(pfad))
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


boxen_je = {schluessel: box(b) for schluessel, b in bilder.items()}
boxen = list(boxen_je.values())
links, oben = min(b[0] for b in boxen), min(b[1] for b in boxen)
rechts, unten = max(b[2] for b in boxen), max(b[3] for b in boxen)
# Fuß je Blickrichtung: Von hinten gedreht liegt der tiefste Fuß auf dem Bild
# höher als von der Seite (das hintere Bein steht weiter in der Tiefe). Jede
# Richtung stellt ihr erstes Bild auf den Anker; Treffer, Sturz und die Folgen
# des Bosses gehören zur Seitenansicht.
# BEZUG: Folgen, die je einen eigenen Fuß haben (Blickrichtungen). Gegner
# laufen (`walk`, `walkFront`, `walkBack`); der Schütze auf dem Wachturm
# (A-5 Teil 3) hat nur Schussfolgen `shoot0` bis `shoot7`, je eine Richtung.
BEZUG = os.environ.get("BEZUG", "walk")
fuesse = {f: box(bilder[(f, 0)])[3] for f in folgen if f.startswith(BEZUG)}
GRUND = BEZUG if BEZUG in fuesse else sorted(fuesse)[0]
fuss = fuesse[GRUND]


def gruppe(folge):
    return folge if folge in fuesse else GRUND

regel = vertrag["assets"][f"{figur}_{GRUND}"]
anker = regel["anker"]

for faktor in (2, 3):
    seite = round(regel["seiteZellen"] * pt * faktor)
    # Die Kontur wächst nach außen; ihr Platz geht vom Rand ab, sonst stößt sie an.
    rand = seite * RAND + kontur_pt * faktor
    nutz = seite - 2 * rand
    # Über dem Fuß ist (1 - anker) der Seite frei, darunter anker; beides muss reichen.
    # Je Blickrichtung zählen nur ihre eigenen Bilder: Der Sturz der
    # Seitenansicht liegt tiefer als der Fuß von hinten und soll die Figur
    # nicht für alle Richtungen verkleinern.
    k = nutz / (rechts - links)
    for richtung, fu in fuesse.items():
        eigene = [boxen_je[(f, i)] for (f, i) in bilder if gruppe(f) == richtung]
        ob, un = min(b[1] for b in eigene), max(b[3] for b in eigene)
        k = min(k, (seite * (1 - anker) - rand) / max(1, fu - ob))
        if un > fu:
            k = min(k, (seite * anker - rand) / (un - fu))
    for (f, i), bild in bilder.items():
        name = f"{figur}_{f}_{i:02d}"
        klein = bild.resize((round(bild.width * k), round(bild.height * k)), Image.LANCZOS)
        x = round(seite / 2 - (links + rechts) / 2 * k)
        # Die Kontur reicht unter den Fuß; der Anker gilt für ihre Unterkante,
        # so wie bei den gemalten Figuren, deren Kontur Teil des Bildes ist.
        y = round(seite * (1 - anker) - fuesse.get(f, fuss) * k - kontur_pt * faktor)
        # Über eine größere Leinwand, weil alpha_composite keinen Versatz über
        # den Rand nimmt und paste mit Maske die Kanten ausdünnt.
        gross = Image.new("RGBA", (seite + 2 * klein.width, seite + 2 * klein.height))
        gross.alpha_composite(klein, (x + klein.width, y + klein.height))
        leinwand = kontur(gross.crop((klein.width, klein.height, klein.width + seite, klein.height + seite)),
                          kontur_pt * faktor)
        ordner = os.path.join(atlas, f"{name}.imageset")
        os.makedirs(ordner, exist_ok=True)
        leinwand.save(os.path.join(ordner, f"{name}@{faktor}x.png"), optimize=True)
        json.dump({"images": [{"idiom": "universal", "scale": "2x", "filename": f"{name}@2x.png"},
                              {"idiom": "universal", "scale": "3x", "filename": f"{name}@3x.png"},
                              {"idiom": "universal", "scale": "1x"}],
                   "info": {"author": "xcode", "version": 1}},
                  open(os.path.join(ordner, "Contents.json"), "w"), indent=2)
print(f"✓ {len(bilder)} Bilder von {figur} in {os.path.relpath(atlas, wurzel)}")
