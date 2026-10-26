#!/usr/bin/env python3
"""Zerlegt ein gemaltes Teileblatt (mehrere Baeume, Steine, Teiche auf weissem Grund) in Einzelteile.

zerlegen.py <blatt.png> <ordner> <praefix> [mindestanteil=0.004]

Laeuft mit $SPIELGRAFIK_HOME/rv/bin/python -I (rembg, numpy, scipy).

Warum ein Blatt statt eines Bilds je Teil: Ein Lauf malt neun Baeume im selben
Licht und Pinselstrich, und neun Laeufe kosten neunmal die Zeit. Teile, die den
Bildrand beruehren, fallen weg: Sie sind abgeschnitten, und eine gerade Kante
an einer Baumkrone sieht man in der Karte sofort (gemessen an den ersten
Ausschnitten aus fertigen Karten). Ebenso Krümel unter dem Mindestanteil der
Bildflaeche.
"""
import os, sys
import numpy as np
from PIL import Image
from rembg import remove, new_session
from scipy import ndimage

blatt, ordner, praefix = sys.argv[1:4]
mindest = float(sys.argv[4]) if len(sys.argv) > 4 else 0.004
os.makedirs(ordner, exist_ok=True)
frei = remove(Image.open(blatt).convert("RGBA"), session=new_session("isnet-general-use"))
a = np.asarray(frei.getchannel("A"))
teile, n = ndimage.label(a > 40)
H, B = a.shape
gespeichert = 0
for i, (sy, sx) in enumerate(ndimage.find_objects(teile), 1):
    flaeche = int((teile[sy, sx] == i).sum())
    if flaeche < mindest * B * H:
        continue
    if sy.start == 0 or sx.start == 0 or sy.stop == H or sx.stop == B:
        print(f"  verworfen (Rand) {sx.start},{sy.start}")
        continue
    rand = 4
    box = (max(0, sx.start - rand), max(0, sy.start - rand), min(B, sx.stop + rand), min(H, sy.stop + rand))
    teil = frei.crop(box)
    # Nur dieses Teil: Nachbarn, die in den Rahmen ragen, ausblenden.
    # Um drei Pixel geweitet, sonst faellt der weiche Rand (Alpha unter der Schwelle) weg.
    eigen = ndimage.binary_dilation(teile[box[1]:box[3], box[0]:box[2]] == i, iterations=3)
    eigen = Image.fromarray((eigen * 255).astype(np.uint8))
    teil.putalpha(Image.fromarray(np.minimum(np.asarray(teil.getchannel("A")), np.asarray(eigen))))
    teil.save(os.path.join(ordner, f"{praefix}{gespeichert}.png"))
    gespeichert += 1
print(f"✓ {gespeichert} Teile aus {blatt}")
