#!/usr/bin/env python3
"""Schneidet den mitgemalten Bodenschatten rechts vom Turmfuß ab.

schatten_schneiden.py <frei.png> <aus.png> [rand=4] [kontur=5]

FLUX malt trotz „no ground" oft einen bläulich grauen Schlagschatten rechts
unten neben den Turm, und rembg hält ihn für einen Teil des Turms (A-5:
Falkenhorst, Gewitterkrone, Funkensäule). Den Schatten rechnet `turmboden.py`
ohnehin selbst; der gemalte stünde doppelt und in falscher Richtung da.

Warum Geometrie statt Farbe: Schatten und Turmstein haben fast dieselbe Farbe
(grau-blau), eine Flut vom Bildrand fraß einmal den hellen Turmkopf, ein
andermal blieb sie an der weichen Schattenkante hängen. Die Türme sind aber
um ihre senkrechte Achse gebaut, und das Licht kommt von oben links: Der linke
Rand des Fußes ist sauber, der rechte darf nicht weiter hinausragen als sein
Spiegelbild. Die Achse kommt aus dem Rumpf (40–75 % der Höhe), nicht aus dem
Fuß, den der Schatten schon verschiebt.

Danach bekommt die neue rechte Kante dieselbe dunkle Kontur wie der Rest
(freistellen.py, 0,9 % von 512 Punkten).
"""
import sys
import numpy as np
from PIL import Image, ImageFilter

ein, aus = sys.argv[1], sys.argv[2]
RAND = int(sys.argv[3]) if len(sys.argv) > 3 else 4
KONTUR = int(sys.argv[4]) if len(sys.argv) > 4 else 5
bild = Image.open(ein).convert("RGBA")
px = np.asarray(bild).copy()
a = px[..., 3] > 96
zeilen = np.where(a.any(axis=1))[0]
oben, unten = zeilen[0], zeilen[-1]
hoehe = unten - oben
mitten = []
for y in range(oben + int(0.40 * hoehe), oben + int(0.75 * hoehe)):
    xs = np.where(a[y])[0]
    if len(xs):
        mitten.append((xs[0] + xs[-1]) / 2)
achse = float(np.median(mitten))
geschnitten = 0
nah = np.zeros(a.shape, bool)
for y in range(oben + int(0.55 * hoehe), unten + 1):
    xs = np.where(a[y])[0]
    if not len(xs):
        continue
    grenze = int(np.ceil(2 * achse - xs[0])) + RAND
    if grenze < px.shape[1]:
        geschnitten += int((px[y, grenze:, 3] > 0).sum())
        px[y, grenze:, 3] = 0
        nah[max(0, y - KONTUR):y + KONTUR + 1, max(0, grenze - KONTUR - 1):] = True
frei = Image.fromarray(px)
maske = frei.getchannel("A").point(lambda v: 255 if v > 96 else 0)
rand = maske.filter(ImageFilter.MaxFilter(2 * KONTUR + 1)).filter(ImageFilter.GaussianBlur(max(0.6, KONTUR * 0.12)))
# Nur an der Schnittkante neu umranden; überall sonst liegt die alte Kontur schon.
rand = Image.fromarray(np.where(nah, np.asarray(rand), 0).astype(np.uint8))
unter = Image.new("RGBA", frei.size, (34, 22, 18, 0))
unter.putalpha(rand)
unter.alpha_composite(frei)
box = unter.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
unter.crop(box).save(aus)
print(f"✓ {aus}: Achse {achse:.0f}, {geschnitten} Punkte Schatten weg")
