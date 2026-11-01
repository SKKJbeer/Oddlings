#!/usr/bin/env python3
"""Gleicht gerenderte Bildfolgen (FX 02, D-051) an das gemalte Spielbild an: Farbe und Kontur.

angleichen.py <vorbild.png> <ein_ordner> <aus_ordner> [staerke=1.0] [kontur=0.012]

vorbild.png   freigestellte gemalte Figur (z. B. art/spielfeld/enemy_raider-frei.png)
ein_ordner    PNGs aus tools/figuren-3d/figur.py (walk_00 … die_05), transparent
aus_ordner    gleiche Namen, gleiche Bildgroesse

Warum: Rohrender sind dunkler und blasser als die gemalten Bilder (Blender-Licht
statt Malerlicht); nebeneinander auf dem Feld sieht man zwei Spiele. Gemessen
wird im Lab-Raum nur auf deckenden Pixeln, beim Vorbild ohne dessen Kontur
(Rand um KONTUR_ABSTAND weggenommen), sonst zieht die dunkle Linie alles mit.

EINE Umrechnung fuer alle Bilder der Folge, aus allen Bildern zusammen gemessen:
Je Bild eigens gemessen, flackerte die Farbe, sobald sich die Figur dreht oder
faellt und andere Flaechen zeigt.

Kontur wie freistellen.py (dunkles Braun #22160F), Breite als Anteil der Hoehe
der Figur im ersten Bild, fuer alle Bilder gleich. Die Bilder werden nicht
zugeschnitten: Fuss und Anker liegen in der Folge an fester Stelle.
"""
import glob, os, sys
import numpy as np
from PIL import Image, ImageFilter

vorbild, ein, aus = sys.argv[1:4]
staerke = float(sys.argv[4]) if len(sys.argv) > 4 else 1.0
kontur = float(sys.argv[5]) if len(sys.argv) > 5 else 0.012
KONTUR_FARBE = (34, 22, 18)
KONTUR_ABSTAND = 7  # Pixel, die am Vorbild vor dem Messen abgetragen werden
STREUUNG = (0.5, 2.5)  # Grenzen fuer das Verhaeltnis der Streuung je Kanal


def zu_lab(rgb):
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    xyz = c @ np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]]).T
    xyz /= np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def aus_lab(lab):
    fy = (lab[..., 0] + 16) / 116
    f = np.stack([fy + lab[..., 1] / 500, fy, fy - lab[..., 2] / 200], -1)
    xyz = np.where(f ** 3 > 0.008856, f ** 3, (f - 16 / 116) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    c = xyz @ np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]]).T
    c = np.where(c > 0.0031308, 1.055 * np.clip(c, 0, None) ** (1 / 2.4) - 0.055, 12.92 * c)
    return np.clip(c * 255, 0, 255)


def deckend(bild, abtragen=0):
    a = bild.getchannel("A").point(lambda v: 255 if v > 200 else 0)
    if abtragen:
        a = a.filter(ImageFilter.MinFilter(2 * abtragen + 1))
    return np.asarray(a) > 0


v = Image.open(vorbild).convert("RGBA")
soll = zu_lab(np.asarray(v.convert("RGB"), float)[deckend(v, KONTUR_ABSTAND)])
namen = sorted(glob.glob(os.path.join(ein, "*.png")))
if not namen:
    sys.exit(f"keine PNGs in {ein}")
bilder = [Image.open(n).convert("RGBA") for n in namen]
ist = zu_lab(np.concatenate([np.asarray(b.convert("RGB"), float)[deckend(b)] for b in bilder]))
m_ist, s_ist = ist.mean(0), ist.std(0) + 1e-6
m_soll, s_soll = soll.mean(0), soll.std(0)
faktor = np.clip(s_soll / s_ist, *STREUUNG)
print("Lab ist  ", np.round(m_ist, 1), np.round(s_ist, 1))
print("Lab soll ", np.round(m_soll, 1), np.round(s_soll, 1))

box = bilder[0].getchannel("A").point(lambda x: 255 if x > 24 else 0).getbbox()
r = max(1, round((box[3] - box[1]) * kontur)) if box and kontur > 0 else 0
os.makedirs(aus, exist_ok=True)
for name, b in zip(namen, bilder):
    rgb = np.asarray(b.convert("RGB"), float)
    lab = zu_lab(rgb)
    neu = (lab - m_ist) * faktor + m_soll
    rgb = rgb + (aus_lab(neu) - rgb) * staerke
    frei = Image.fromarray(rgb.round().astype(np.uint8)).convert("RGBA")
    frei.putalpha(b.getchannel("A"))
    if r:
        rand = b.getchannel("A").point(lambda x: 255 if x > 96 else 0).filter(ImageFilter.MaxFilter(2 * r + 1)) \
            .filter(ImageFilter.GaussianBlur(max(0.6, r * 0.12)))
        unten = Image.new("RGBA", b.size, KONTUR_FARBE + (0,))
        unten.putalpha(rand)
        unten.alpha_composite(frei)
        frei = unten
    frei.save(os.path.join(aus, os.path.basename(name)))
print(f"✓ {len(namen)} Bilder nach {aus}, Kontur {r} px")
