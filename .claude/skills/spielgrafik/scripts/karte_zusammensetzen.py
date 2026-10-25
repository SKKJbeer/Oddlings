#!/usr/bin/env python3
"""Setzt den Boden einer Karte aus gemalten Texturen entlang der echten Weggeometrie zusammen.

karte_zusammensetzen.py <mission.json> <gras.png> <sand.png> <ausgabe.png> [pixel_je_zelle=64]
  gras.png/sand.png: gemalte Texturen (erzeugen.sh), am besten schon auf
  stoerungsfreie Ausschnitte zugeschnitten (keine Steine, Stuempfe, Rahmen).

Warum zusammensetzen statt frei malen: Ein frei oder per Bild-zu-Bild mit hoher
Staerke gemalter Boden verbiegt den Weg (gemessen: Staerke 0,7 machte aus den
rechten Winkeln Schlangenlinien) und setzt Steine auf den Weg. Hier liegt der
Weg pixelgenau auf der Geometrie; ein abschliessender Bild-zu-Bild-Lauf mit
geringer Staerke (~0,3) vereinheitlicht nur noch Licht und Pinselstrich.
"""
import json, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

mission, gras_q, sand_q, ziel = sys.argv[1:5]
px = int(sys.argv[5]) if len(sys.argv) > 5 else 64
karte = json.load(open(mission))["map"]
B, H = karte["width"] * px, karte["height"] * px
rnd = random.Random(11)


def flaeche(quelle, weich):
    """Fuellt die Karte mit zufaellig versetzten, weich ueberblendeten Stuecken.
    Spiegeln oder Kacheln waere sichtbar (gleiche Blume im Raster)."""
    q = Image.open(quelle).convert("RGB")
    s = min(q.width, q.height)
    stueck = int(s * 0.6)
    bild = Image.new("RGB", (B, H))
    maske = Image.new("L", (stueck, stueck), 0)
    ImageDraw.Draw(maske).ellipse((weich, weich, stueck - weich, stueck - weich), fill=255)
    maske = maske.filter(ImageFilter.GaussianBlur(weich / 2))
    for y in range(-stueck // 2, H + stueck // 2, stueck // 3):
        for x in range(-stueck // 2, B + stueck // 2, stueck // 3):
            ox, oy = rnd.randint(0, q.width - stueck), rnd.randint(0, q.height - stueck)
            teil = q.crop((ox, oy, ox + stueck, oy + stueck))
            if rnd.random() < 0.5:
                teil = teil.transpose(Image.FLIP_LEFT_RIGHT)
            bild.paste(teil, (x + rnd.randint(-8, 8), y + rnd.randint(-8, 8)), maske)
    return bild


gras = flaeche(gras_q, px // 3)
sand = flaeche(sand_q, px // 3)

punkte = [(x * px, y * px) for x, y in karte["path"]]  # stetige Zellkoordinaten, kein Versatz


def wegmaske(breite):
    m = Image.new("L", (B, H), 0)
    d = ImageDraw.Draw(m)
    d.line(punkte, fill=255, width=int(breite * px), joint="curve")
    r = breite * px / 2
    for x, y in punkte:
        d.ellipse((x - r, y - r, x + r, y + r), fill=255)
    return m


# Unruhiger Rand: Gras greift ueber die Wegkante, wie getreten.
rauschen = Image.effect_noise((B // 8, H // 8), 64).resize((B, H), Image.BICUBIC)
weg = wegmaske(1.15).filter(ImageFilter.GaussianBlur(px * 0.08))
weg = ImageChops.subtract(weg, rauschen.point(lambda v: max(0, v - 150)))
kante = wegmaske(1.32).filter(ImageFilter.GaussianBlur(px * 0.12))

bild = gras.copy()
# Dunkle Furche entlang der Kante: Der Weg liegt tiefer als die Wiese.
bild.paste(Image.new("RGB", (B, H), (70, 52, 30)), (0, 0), kante.point(lambda v: int(v * 0.55)))
bild.paste(sand, (0, 0), weg)
# Licht von oben links: obere/linke Wegkante etwas heller, untere dunkler.
schatten = ImageChops.offset(weg, int(px * 0.06), int(px * 0.06))
innen = ImageChops.subtract(weg, schatten).filter(ImageFilter.GaussianBlur(px * 0.05))
bild = Image.composite(ImageEnhance.Brightness(bild).enhance(1.12), bild, innen)
bild.save(ziel)
print(f"✓ {ziel} {B}x{H}")
