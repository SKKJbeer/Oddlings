#!/usr/bin/env python3
"""Gleicht grosse helle oder dunkle Flecken im Gras aus, die das Uebermalen hineinmalt.

ausgleichen.py <ein.png> <aus.png> <x0,y0,x1,y1> [...]   Rechtecke in Feldzellen (24 x 13 mit Rand 4 x 2)

Warum nicht retusche.py: Der Fleck in M3 (01.11.2026) war vier Zellen gross, so viel
sauberes Gras ohne Weg gibt es woanders nicht am Stueck. Hier bleibt die Malerei, nur die
grobe Helligkeit wird auf die Umgebung gezogen. Die Rechtecke duerfen keinen Weg enthalten,
sonst zieht seine Helligkeit mit.
"""
import sys
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageStat

ein, aus, *felder = sys.argv[1:]
bild = Image.open(ein).convert("RGB")
z = bild.width / 24
for f in felder:
    x0, y0, x1, y1 = (float(v) for v in f.split(","))
    box = tuple(round(v) for v in ((x0 + 4) * z, (y0 + 2) * z, (x1 + 4) * z, (y1 + 2) * z))
    teil = bild.crop(box)
    grob = teil.filter(ImageFilter.GaussianBlur(z * 0.8))
    # Ziel aus der Umgebung (zwei Zellen weiter), nur Gras: Im Rechteck selbst ueberwiegt
    # der Fleck, und Wegpixel (rot > gruen) wuerden das Mittel aufhellen.
    weit = np.asarray(bild.crop((max(0, box[0] - round(2 * z)), max(0, box[1] - round(2 * z)),
                                 min(bild.width, box[2] + round(2 * z)), min(bild.height, box[3] + round(2 * z))))).reshape(-1, 3).astype(float)
    gras = weit[(weit[:, 1] > weit[:, 0] + 25) & (weit[:, 1] > 60)]
    ziel = np.median(gras, axis=0)
    # Faktor je Pixel: Zielmittel / grobe Helligkeit, getrennt je Kanal.
    t = np.asarray(teil).astype(float); g = np.asarray(grob).astype(float)
    neu = np.clip(t * (ziel / np.maximum(g, 1)), 0, 255).astype("uint8")
    maske = Image.new("L", teil.size, 0)
    r = round(z * 0.5)
    ImageDraw.Draw(maske).rounded_rectangle((r, r, teil.width - r, teil.height - r), radius=r, fill=255)
    bild.paste(Image.fromarray(neu), box[:2], maske.filter(ImageFilter.GaussianBlur(r / 2)))
bild.save(aus)
print(f"✓ {aus}")
