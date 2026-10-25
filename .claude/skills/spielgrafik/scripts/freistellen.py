#!/usr/bin/env python3
"""Stellt eine Figur oder einen Turm frei (Hintergrund -> transparent).

freistellen.py <ein.png> <aus.png> [modell=isnet-general-use] [kontur=0.009]

Braucht rembg in einer eigenen Umgebung (MIT; Modelle isnet/u2net Apache 2.0):
  python3 -m venv $SPIELGRAFIK_HOME/rv && $SPIELGRAFIK_HOME/rv/bin/pip install "rembg[cpu]"
und laeuft dann mit $SPIELGRAFIK_HOME/rv/bin/python.

Warum ein Modell statt Farbschluessel: FLUX malt den „einfarbigen" Hintergrund
mit Verlauf und Schein, und Farbsaum an den Kanten bleibt beim Schluesseln
stehen. Nie BRIA RMBG nehmen — nicht-kommerzielle Lizenz.

Kontur: dunkler Rand um die Figur, Breite als Anteil der Bildhoehe (0 = aus).
Sie gehoert zum Stil (D-016) und trennt die Figur vom Boden, auch wenn der
Generator selbst keine Linie gemalt hat. Farbe ist ein dunkles Braun statt
Schwarz, damit sie gemalt wirkt und nicht ausgeschnitten.

Danach wird die Kante leicht nach innen gezogen und auf die Figur zugeschnitten,
damit der Ankerpunkt in der Szene verlaesslich am Fuss liegt.
"""
import sys
from PIL import Image, ImageFilter
from rembg import remove, new_session

ein, aus = sys.argv[1], sys.argv[2]
modell = sys.argv[3] if len(sys.argv) > 3 else "isnet-general-use"
kontur = float(sys.argv[4]) if len(sys.argv) > 4 else 0.009
bild = Image.open(ein).convert("RGBA")
frei = remove(bild, session=new_session(modell), alpha_matting=True,
              alpha_matting_foreground_threshold=240, alpha_matting_background_threshold=15)
a = frei.getchannel("A").filter(ImageFilter.MinFilter(3))
frei.putalpha(a)
if kontur > 0:
    r = max(1, round(bild.height * kontur))
    rand = a.point(lambda v: 255 if v > 96 else 0).filter(ImageFilter.MaxFilter(2 * r + 1)).filter(ImageFilter.GaussianBlur(max(0.6, r * 0.12)))
    unten = Image.new("RGBA", frei.size, (34, 22, 18, 0))
    unten.putalpha(rand)
    unten.alpha_composite(frei)
    frei, a = unten, unten.getchannel("A")
box = a.point(lambda v: 255 if v > 24 else 0).getbbox()
if box:
    frei = frei.crop(box)
frei.save(aus)
print(f"✓ {aus} {frei.size[0]}x{frei.size[1]}")
