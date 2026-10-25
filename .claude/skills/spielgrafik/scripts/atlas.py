#!/usr/bin/env python3
"""Legt ein freigestelltes Bild als @2x/@3x in den Sprite-Atlas der App.

atlas.py <frei.png> <name> <seite_in_zellen> <anker_y> [zellenpunkte=43] [atlas=App/Assets.xcassets/Battle.spriteatlas]
atlas.py <boden.png> <name> <breite>x<hoehe> voll [zellenpunkte] [ordner]
  Boden: ganzes Bild, kein Rand, als JPEG (Qualitaet 88). Ein gemalter Boden
  waere als PNG @3x ueber 5 MB und gehoert nicht in einen Sprite-Atlas.

Die Groesse ergibt sich aus dem Asset-Vertrag (docs/art/asset-vertrag.md und
art/asset-vertrag.json): Seite in Zellen mal Punkte je Zelle, dann x2/x3. So
bleibt das Verhaeltnis der Figuren zueinander an EINER Stelle festgelegt.

Figuren werden auf ein QUADRAT gesetzt, mittig, der Fuss (unterste deckende
Zeile) auf Hoehe anker_y. Die Szene setzt jedes Bild als Quadrat mit festem
anchorPoint; ein zugeschnittenes, schmales Bild wuerde sonst gestaucht.
"""
import json, os, sys
from PIL import Image

quelle, name, groesse, anker = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
pt = float(sys.argv[5]) if len(sys.argv) > 5 else 43.0
atlas = sys.argv[6] if len(sys.argv) > 6 else "App/Assets.xcassets/Battle.spriteatlas"
bild = Image.open(quelle).convert("RGBA")
if anker == "voll":
    bz, hz = map(float, groesse.split("x"))
    bild = bild.convert("RGB")  # Boden ohne Alphakanal: keine Loecher, kleinere Datei
    ziel = lambda f: (round(bz * pt * f), round(hz * pt * f))
else:
    ay = float(anker)
    box = bild.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    figur = bild.crop(box)
    # Kleinstes Quadrat, in dem die Figur mittig steht und ihr Fuss auf ay liegt.
    seite = max(figur.width, round(figur.height / (1 - ay)))
    quadrat = Image.new("RGBA", (seite, seite), (0, 0, 0, 0))
    quadrat.alpha_composite(figur, ((seite - figur.width) // 2, seite - round(ay * seite) - figur.height))
    bild = quadrat
    ziel = lambda f: (round(float(groesse) * pt * f),) * 2
ordner = os.path.join(atlas, f"{name}.imageset")
os.makedirs(ordner, exist_ok=True)
endung = "jpg" if anker == "voll" else "png"
for f in (2, 3):
    b, h = ziel(f)
    if h > bild.height * 1.05:
        print(f"WARNUNG {name}@{f}x: Quelle {bild.height}px kleiner als Ziel {h}px — erst hochrechnen")
    datei = os.path.join(ordner, f"{name}@{f}x.{endung}")
    if endung == "jpg":
        bild.resize((b, h), Image.LANCZOS).save(datei, quality=88, optimize=True, progressive=True)
    else:
        bild.resize((b, h), Image.LANCZOS).save(datei, optimize=True)
json.dump({"images": [{"idiom": "universal", "scale": f"{f}x", "filename": f"{name}@{f}x.{endung}"} for f in (1, 2, 3) if f != 1]
           + [{"idiom": "universal", "scale": "1x"}], "info": {"author": "xcode", "version": 1}},
          open(os.path.join(ordner, "Contents.json"), "w"), indent=2)
if not os.path.exists(os.path.join(atlas, "Contents.json")):
    # Ein Ordner im Katalog braucht eine eigene Contents.json, sonst sieht Xcode ihn nicht.
    json.dump({"info": {"author": "xcode", "version": 1}}, open(os.path.join(atlas, "Contents.json"), "w"), indent=2)
print(f"✓ {ordner}")
