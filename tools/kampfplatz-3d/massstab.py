#!/usr/bin/env python3
"""Maßstabsbild (D-166): alle Dinge eines Kampfplatzes in ihrer Zielhöhe aus dem Vertrag.

  python3 massstab.py <boden.jpg> <ausgabe.jpg>

Setzt die heutigen Figuren-, Turm- und Festungsbilder auf den Boden, je so skaliert, dass
die sichtbare Höhe (deckende Pixel) der Zielhöhe in `massstab` entspricht, und stellt
einen Zellmaßstab daneben. Das Bild ist ein Ziel zum Ansehen, kein Atlas: Umgestellt
werden die Bilder von den Paketen, die sie malen (A-3, A-5).
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

WURZEL = Path(__file__).resolve().parents[2]
ATLAS = WURZEL / "App/Assets.xcassets/Battle.spriteatlas"

# Fußpunkt je Ding in Zellen der Karte von Mission 1: auf dem Weg, auf einer Insel, am
# Wegende. Nur für dieses Bild; die Szene setzt Figuren nach der Simulation.
STELLEN = {
    "enemy_runner": (5.3, 6.6),
    "enemy_raider": (6.6, 6.6),
    "enemy_brute": (8.1, 6.6),
    "tower": (7.0, 5.3),
    "enemy_moorKing": (11.6, 2.6),
    "fortress": (15.6, 7.7),
}
BILD = {"tower": "tower_watch", "fortress": "fortress"}


def sprite(name):
    ordner = ATLAS / f"{name}.imageset"
    datei = max(ordner.glob("*.png"), key=lambda p: Image.open(p).width)
    bild = Image.open(datei).convert("RGBA")
    return bild.crop(bild.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox())


def main(boden, ziel):
    vertrag = json.loads((WURZEL / "art/asset-vertrag.json").read_text())
    massstab = {k: v for k, v in vertrag["massstab"].items() if not k.startswith("_")}
    grund = Image.open(boden).convert("RGBA")
    rx, ry = 4, 2
    zelle = grund.width / (16 + 2 * rx)
    zeichnen = ImageDraw.Draw(grund)
    try:
        schrift = ImageFont.truetype("DejaVuSans-Bold.ttf", int(zelle * 0.22))
    except OSError:
        schrift = ImageFont.load_default()
    for name, (fx, fy) in sorted(STELLEN.items(), key=lambda e: e[1][1]):
        figur = sprite(BILD.get(name, name))
        hoehe = massstab[name] * zelle
        figur = figur.resize((max(1, round(figur.width * hoehe / figur.height)), round(hoehe)), Image.LANCZOS)
        px, py = (fx + rx) * zelle, (fy + ry) * zelle
        grund.alpha_composite(figur, (round(px - figur.width / 2), round(py - figur.height)))
        x = round(px + figur.width / 2 + zelle * 0.08)
        zeichnen.line([(x, py), (x, py - hoehe)], fill=(255, 255, 255, 230), width=max(2, round(zelle / 40)))
        zeichnen.text((x + 4, py - hoehe), f"{massstab[name]:.2f}".replace(".", ","), font=schrift,
                      fill=(255, 255, 255, 255), stroke_width=2, stroke_fill=(30, 24, 18, 255))
    # Zellmaßstab: drei Felder senkrecht am linken Rand der Karte
    x0, y0 = rx * zelle - zelle * 0.5, (ry + 8.5) * zelle
    for k in range(3):
        farbe = (255, 255, 255, 235) if k % 2 == 0 else (40, 32, 24, 235)
        zeichnen.rectangle([x0, y0 - (k + 1) * zelle, x0 + zelle * 0.12, y0 - k * zelle], fill=farbe)
    zeichnen.text((x0 - zelle * 0.1, y0 + zelle * 0.05), "3 Felder", font=schrift, fill=(255, 255, 255, 255),
                  stroke_width=2, stroke_fill=(30, 24, 18, 255))
    grund.convert("RGB").save(ziel, quality=88)
    print("✓", ziel)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
