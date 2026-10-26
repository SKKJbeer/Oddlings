#!/usr/bin/env python3
"""Zeichnet aus einer Regionsdatei (Campaign/region-*.json) eine Vorlage fuer die Regionskarte.

regionsvorlage.py <region.json> <ausgabe.png> [breite=1024]

Wie kartenvorlage.py fuer die Kampfkarte: Die App setzt die Knoten an feste
Anteile der Bildflaeche. Ein frei gemaltes Bild haette Lichtungen irgendwo,
und die Knoten stuenden mitten im Wald. Die Vorlage legt Lichtungen, Pfade,
Sumpf (oberer Ast), Ruinen (unterer Ast) und die Bosslichtung an die richtigen
Stellen; das Modell malt per Bild-zu-Bild nur Oberflaeche und Licht darueber.

Pfade folgen derselben Kurve wie CampaignMapView.drawTrails (quadratisch,
Kontrollpunkt 0,18 der Strecke seitlich), damit die gestrichelte Spur der App
auf einem gemalten Weg liegt. Seitenverhaeltnis 16:10 wie CampaignStyle.mapAspect.
"""
import json, math, random, sys
from PIL import Image, ImageDraw, ImageFilter

region, ziel = sys.argv[1], sys.argv[2]
B = int(sys.argv[3]) if len(sys.argv) > 3 else 1024
H = round(B / 1.6)
knoten = {k["id"]: k for k in json.load(open(region))["nodes"]}
rnd = random.Random(7)
at = lambda p: (p[0] * B, p[1] * H)

WALD, WALD_DUNKEL, WALD_HELL = (40, 78, 46), (18, 38, 24), (70, 112, 58)
LICHTUNG, PFAD, SUMPF, RUINE, BOSS = (122, 160, 78), (196, 166, 110), (52, 82, 72), (128, 122, 108), (70, 54, 52)

bild = Image.new("RGB", (B, H), WALD_DUNKEL)
d = ImageDraw.Draw(bild)
# Baumkronen von schraeg oben: dunkler Schatten, Krone, Licht oben links.
# So malt das Modell Wald statt gefleckter Flaeche.
for _ in range(2600):
    x, y, r = rnd.uniform(0, B), rnd.uniform(0, H), rnd.uniform(B * 0.007, B * 0.016)
    d.ellipse((x - r * 0.9, y - r * 0.6, x + r * 1.1, y + r * 1.2), fill=(10, 24, 14))
    d.ellipse((x - r, y - r, x + r, y + r), fill=WALD)
    d.ellipse((x - r * 0.75, y - r * 0.8, x + r * 0.25, y + r * 0.1), fill=WALD_HELL)


def flaeche(mitte, rx, ry, farbe, weich):
    maske = Image.new("L", (B, H), 0)
    x, y = at(mitte)
    ImageDraw.Draw(maske).ellipse((x - rx * B, y - ry * H, x + rx * B, y + ry * H), fill=255)
    bild.paste(Image.new("RGB", (B, H), farbe), (0, 0), maske.filter(ImageFilter.GaussianBlur(B * weich)))


# Gebiete der beiden Aeste und des Bosses: Lage aus den Knoten selbst, nicht fest.
def gebiet(ids, farbe):
    xs = [knoten[i]["position"][0] for i in ids]
    ys = [knoten[i]["position"][1] for i in ids]
    flaeche(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2), (max(xs) - min(xs)) / 2 + 0.1, 0.16, farbe, 0.03)


gebiet(["m5a", "m6a"], SUMPF)
gebiet(["m5b", "m6b"], RUINE)


def kurve(a, b, schritte=40):
    (x0, y0), (x1, y1) = at(a), at(b)
    mx, my = (x0 + x1) / 2 - (y1 - y0) * 0.18, (y0 + y1) / 2 + (x1 - x0) * 0.18
    return [((1 - t) ** 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1,
             (1 - t) ** 2 * y0 + 2 * (1 - t) * t * my + t * t * y1) for t in (i / schritte for i in range(schritte + 1))]


pfade = Image.new("L", (B, H), 0)
dp = ImageDraw.Draw(pfade)
for k in knoten.values():
    for v in k.get("requires", []):
        dp.line(kurve(knoten[v]["position"], k["position"]), fill=255, width=round(B * 0.014), joint="curve")
bild.paste(Image.new("RGB", (B, H), PFAD), (0, 0), pfade.filter(ImageFilter.GaussianBlur(B * 0.003)))

# Lichtungsfarbe nach Gebiet: Sumpfast schlammig mit Wasser, Ruinenast Steinboden.
SUMPF_LICHTUNG, RUINE_LICHTUNG = (104, 128, 76), (176, 164, 132)
farbe = {"m5a": SUMPF_LICHTUNG, "m6a": SUMPF_LICHTUNG, "m5b": RUINE_LICHTUNG, "m6b": RUINE_LICHTUNG}
for k in knoten.values():
    boss = k["kind"] == "boss"
    r = 0.075 if boss else 0.05
    flaeche(k["position"], r, r * 1.6, BOSS if boss else farbe.get(k["id"], LICHTUNG), 0.006)
d = ImageDraw.Draw(bild)
for k in knoten.values():
    x, y = at(k["position"])
    # Wasserlachen bzw. Mauerreste am Rand geben dem Modell einen Anlass, nicht mitten
    # auf der Lichtung: Dort steht der Knoten.
    for _ in range(5 if k["id"] in farbe else 0):
        w = rnd.uniform(0, 6.28)
        sx, sy = x + math.cos(w) * 0.045 * B, y + math.sin(w) * 0.07 * H
        if k["id"] in ("m5a", "m6a"):
            d.ellipse((sx - B * 0.014, sy - B * 0.008, sx + B * 0.014, sy + B * 0.008), fill=(46, 92, 98))
        else:
            d.rectangle((sx - B * 0.007, sy - B * 0.016, sx + B * 0.007, sy + B * 0.003), fill=(196, 190, 172))
    if boss := k["kind"] == "boss":
        for _ in range(7):
            w = rnd.uniform(0, 6.28)
            sx, sy = x + math.cos(w) * 0.07 * B, y + math.sin(w) * 0.11 * H
            d.polygon([(sx - B * 0.012, sy + B * 0.008), (sx, sy - B * 0.022), (sx + B * 0.012, sy + B * 0.008)], fill=(42, 34, 36))

# Rand dunkel in den Wald auslaufen lassen (Blick auf die Mitte).
rand = Image.new("L", (B, H), 255)
ImageDraw.Draw(rand).rounded_rectangle((B * 0.04, H * 0.06, B * 0.96, H * 0.94), radius=B * 0.08, fill=0)
bild.paste(Image.new("RGB", (B, H), (10, 22, 14)), (0, 0), rand.filter(ImageFilter.GaussianBlur(B * 0.04)))

bild.save(ziel)
print(f"✓ {ziel} {B}x{H}")
