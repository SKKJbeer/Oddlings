#!/usr/bin/env python3
"""Zeichnet aus der Weggeometrie einer Mission eine grobe Kartenvorlage.

kartenvorlage.py <mission.json> <ausgabe.png> [pixel_je_zelle=64]

Die Vorlage wird danach per Bild-zu-Bild uebermalt (erzeugen.sh mit
INIT=vorlage.png). Warum ueberhaupt eine Vorlage: Ein frei gemalter Boden
traefe den gerechneten Weg nie. So bleibt der Weg dort, wo die Simulation
ihn fuehrt, und das Modell liefert nur Oberflaeche und Licht.

Koordinaten wie in der Simulation: Zellen, Ursprung oben links, y nach unten.
"""
import json, random, sys
from PIL import Image, ImageDraw, ImageFilter

mission, ziel = sys.argv[1], sys.argv[2]
px = int(sys.argv[3]) if len(sys.argv) > 3 else 64
karte = json.load(open(mission))["map"]
B, H = karte["width"] * px, karte["height"] * px
rnd = random.Random(7)

bild = Image.new("RGB", (B, H), (86, 140, 62))
d = ImageDraw.Draw(bild)
# Grobe Farbflecken, damit das Modell Wiese statt Flaeche malt.
for _ in range(900):
    x, y, r = rnd.uniform(0, B), rnd.uniform(0, H), rnd.uniform(px * 0.2, px * 0.9)
    g = rnd.randint(-22, 22)
    d.ellipse((x - r, y - r, x + r, y + r), fill=(86 + g // 2, 140 + g, 62 + g // 3))
bild = bild.filter(ImageFilter.GaussianBlur(px * 0.25))

# Wegpunkte sind stetige Koordinaten, Zelle (i, j) reicht von i bis i+1
# (MissionMap: cell.center = i + 0.5). Deshalb kein Versatz.
punkte = [(x * px, y * px) for x, y in karte["path"]]

def weg(breite, farbe):
    lage = Image.new("L", (B, H), 0)
    dl = ImageDraw.Draw(lage)
    dl.line(punkte, fill=255, width=int(breite * px), joint="curve")
    for x, y in punkte:
        r = breite * px / 2
        dl.ellipse((x - r, y - r, x + r, y + r), fill=255)
    return lage.filter(ImageFilter.GaussianBlur(px * 0.06)), farbe

for breite, farbe in ((1.25, (120, 98, 60)), (1.05, (196, 164, 108)), (0.55, (214, 186, 132))):
    maske, f = weg(breite, farbe)
    bild.paste(Image.new("RGB", (B, H), f), (0, 0), maske)

bild.save(ziel)
print(f"✓ {ziel} {B}x{H}")
