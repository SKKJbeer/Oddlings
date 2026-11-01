#!/usr/bin/env python3
"""Legt die Ebene aus kampfplatz.py (Hoehle und Deko) auf das uebermalte, hochgerechnete Bild.

ebene.py <gross.png> <ebene.png> <aus.png>

Warum: Das Uebermalen vereinheitlicht Gras, Weg und Wald, macht aber aus der Hoehle,
dem Ursprung der Gegner, eine Lore oder Kuppel und aus Pilzen dunkle Kugeln (gemessen
01.11.2026, Staerke 0,3 und 0,4). Die Teile sind selbst gemalt; obenauf gelegt bleibt die
Hoehle in jeder Mission dieselbe wie auf der Kampagnenkarte. Ein weicher Schatten nach
unten rechts (Licht oben links) setzt sie auf den Boden.
"""
import sys
from PIL import Image, ImageChops, ImageFilter

gross, ebene, aus = sys.argv[1:4]
bild = Image.open(gross).convert("RGB")
oben = Image.open(ebene).convert("RGBA").resize(bild.size, Image.LANCZOS)
a = oben.getchannel("A")
z = bild.width / 24  # Pixel je Zelle (24 x 13 Zellen)
schatten = Image.new("L", bild.size, 0)
schatten.paste(a, (round(z * 0.12), round(z * 0.16)))
schatten = schatten.filter(ImageFilter.GaussianBlur(z * 0.1)).point(lambda v: int(v * 0.5))
bild.paste(Image.new("RGB", bild.size, (8, 14, 8)), (0, 0), schatten)
# Kante um einen Hauch weich, sonst wirkt das Teil ausgeschnitten.
bild.paste(oben.convert("RGB"), (0, 0), a.filter(ImageFilter.GaussianBlur(1.2)))
bild.save(aus)
print(f"✓ {aus}")
