#!/usr/bin/env python3
"""Setzt die Regionskarte aus gemalten Einzelteilen an die Knotenlagen der Regionsdatei.

regionscollage.py <region.json> <teileordner> <ausgabe> [breite=2400] [vorschau.png]

Teileordner (aus erzeugen.sh + zerlegen.py):
  gras.png, weg.png      Bodentexturen
  baum*.png              freigestellte Baumkronen von oben
  teich*.png             Sumpfteiche (oberer Ast)
  ruine*.png             Mauerreste (unterer Ast)
  hoehle*.png            Bosshoehle

Warum zusammensetzen statt malen: Bild-zu-Bild ueber regionsvorlage.py hat die
Lichtungen nie unter die Knoten gelegt (gemessen 26.10.2026: Staerke 0,3 bis
0,6, 4 bis 16 Schritte, auch mehrere leichte Durchgaenge). Die App setzt die
Knoten an feste Anteile der Flaeche; hier liegen Lichtung, Weg und Gebiet
pixelgenau dort, und nur die Teile selbst sind gemalt.

Wege folgen CampaignMapView.drawTrails (quadratisch, Kontrollpunkt 0,18 seitlich),
damit die gestrichelte Spur der App auf dem gemalten Weg liegt. Seitenverhaeltnis
16:10 wie CampaignStyle.mapAspect.

Mit [vorschau.png] zeichnet das Skript zusaetzlich die Knoten in App-Groesse ein
(52/66/44 pt auf einer 454 pt breiten Karte: iPhone quer, abzueglich
seitlicher Sicherheitsraender und der 280 pt breiten Missionstafel), um die Lichtungen zu beurteilen.
"""
import glob, json, math, os, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageOps

region, teile, ziel = sys.argv[1:4]
B = int(sys.argv[4]) if len(sys.argv) > 4 else 2400
vorschau = sys.argv[5] if len(sys.argv) > 5 else None
H = round(B / 1.6)
knoten = {k["id"]: k for k in json.load(open(region))["nodes"]}
rnd = random.Random(5)
at = lambda p: (p[0] * B, p[1] * H)
SUMPF, RUINEN = ("m5a", "m6a"), ("m5b", "m6b")


def lade(muster):
    return [Image.open(p).convert("RGBA") for p in sorted(glob.glob(os.path.join(teile, muster)))]


def flaeche(quelle, weich):
    """Wie karte_zusammensetzen.py: versetzte, weich ueberblendete Stuecke statt Kacheln,
    sonst steht dieselbe Blume im Raster."""
    q = Image.open(quelle).convert("RGB")
    stueck = int(min(q.size) * 0.6)
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
            bild.paste(teil, (x, y), maske)
    return bild


def ellipse(mitte, rx, ry, weich):
    m = Image.new("L", (B, H), 0)
    x, y = mitte
    ImageDraw.Draw(m).ellipse((x - rx, y - ry, x + rx, y + ry), fill=255)
    return m.filter(ImageFilter.GaussianBlur(weich)) if weich else m


def kurve(a, b, schritte=60):
    (x0, y0), (x1, y1) = at(a), at(b)
    mx, my = (x0 + x1) / 2 - (y1 - y0) * 0.18, (y0 + y1) / 2 + (x1 - x0) * 0.18
    return [((1 - t) ** 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1,
             (1 - t) ** 2 * y0 + 2 * (1 - t) * t * my + t * t * y1) for t in (i / schritte for i in range(schritte + 1))]


kanten = [kurve(knoten[v]["position"], k["position"]) for k in knoten.values() for v in k.get("requires", [])]
wegpunkte = [p for k in kanten for p in k]


def lichtung(k):
    """Halbachsen der Lichtung in Pixeln. Die Karte ist auf dem iPhone rund 454 pt breit,
    ein Knoten 52 pt (Boss 66, Nebenmission 44), also gut ein Zehntel der Breite: Die
    Lichtung muss rings um die Medaille sichtbar bleiben, sonst steht sie im Laub."""
    r = {"boss": 0.092, "side": 0.064}.get(k["kind"], 0.074) * B
    return r, r * 1.05


hindernisse = []  # (x, y, Radius) gesetzter Teile, die kein Baum verdecken darf


def im_freien(x, y, rand):
    """Liegt ein Punkt (mit Abstand rand) auf einer Lichtung oder einem Weg?"""
    for k in knoten.values():
        kx, ky = at(k["position"])
        rx, ry = lichtung(k)
        if ((x - kx) / (rx + rand)) ** 2 + ((y - ky) / (ry + rand)) ** 2 < 1:
            return True
    if any(math.dist((x, y), (hx, hy)) < hr + rand for hx, hy, hr in hindernisse):
        return True
    weg = B * 0.016 + rand
    return any((x - px) ** 2 + (y - py) ** 2 < weg * weg for px, py in wegpunkte)


def gebietsmitte(ids):
    xs = [knoten[i]["position"][0] for i in ids]
    ys = [knoten[i]["position"][1] for i in ids]
    return at(((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2)), (max(xs) - min(xs)) / 2 * B + B * 0.12


# --- Boden ---------------------------------------------------------------------------
gras = flaeche(os.path.join(teile, "gras.png"), B // 60)
# FLUX malt den Weg zu orange; auf der Karte soll er Erde sein, nicht Leuchtfarbe.
weg = ImageEnhance.Color(flaeche(os.path.join(teile, "weg.png"), B // 60)).enhance(0.7)
# Waldboden: dunkel und kuehl, man sieht ihn nur zwischen den Kronen.
bild = ImageEnhance.Brightness(ImageEnhance.Color(gras).enhance(0.8)).enhance(0.42)
offen = Image.new("L", (B, H), 0)
for k in knoten.values():
    rx, ry = lichtung(k)
    offen = ImageChops.lighter(offen, ellipse(at(k["position"]), rx * 1.08, ry * 1.08, B * 0.012))
bild.paste(gras, (0, 0), offen)

# Gebiete: Sumpf kuehl und gruenblau, Ruinen staubig grau, Boss dunkel und rotbraun.
(sx, sy), srx = gebietsmitte(SUMPF)
(rx_, ry_), rrx = gebietsmitte(RUINEN)
for (mitte, rx, ry, farbe, staerke) in (((sx, sy), srx, H * 0.2, (70, 120, 110), 0.45),
                                         ((rx_, ry_), rrx, H * 0.2, (150, 140, 120), 0.4),
                                         (at(next(k for k in knoten.values() if k["kind"] == "boss")["position"]), B * 0.13, H * 0.26, (90, 40, 30), 0.5)):
    maske = ellipse(mitte, rx, ry, B * 0.05).point(lambda v: int(v * staerke))
    bild.paste(ImageChops.multiply(bild, Image.new("RGB", (B, H), tuple(min(255, c * 2) for c in farbe))), (0, 0), maske)

# --- Wege ----------------------------------------------------------------------------
def wegmaske(breite):
    m = Image.new("L", (B, H), 0)
    d = ImageDraw.Draw(m)
    for k in kanten:
        d.line(k, fill=255, width=round(breite), joint="curve")
    return m


rauschen = Image.effect_noise((B // 10, H // 10), 70).resize((B, H), Image.BICUBIC)
wm = ImageChops.subtract(wegmaske(B * 0.022).filter(ImageFilter.GaussianBlur(B * 0.002)),
                         rauschen.point(lambda v: max(0, v - 160)))
furche = wegmaske(B * 0.029).filter(ImageFilter.GaussianBlur(B * 0.003))
bild.paste(Image.new("RGB", (B, H), (52, 38, 22)), (0, 0), furche.point(lambda v: int(v * 0.5)))
bild.paste(weg, (0, 0), wm)

# --- Teile ---------------------------------------------------------------------------
lagen = []  # (fuss_y, bild, x, y): nach Fuss sortiert, damit untere Teile vorn liegen


def setze(teil, x, y, breite, spiegeln=False, schatten=0.55, drehen=0):
    if drehen:
        teil = teil.rotate(drehen, Image.BICUBIC, expand=True)
    s = breite / teil.width
    t = teil.resize((max(1, round(teil.width * s)), max(1, round(teil.height * s))), Image.LANCZOS)
    if spiegeln:
        t = t.transpose(Image.FLIP_LEFT_RIGHT)
    lagen.append((y + t.height / 2, t, round(x - t.width / 2), round(y - t.height / 2), schatten))


baeume = lade("baum*.png")
boss_mitte = at(next(k for k in knoten.values() if k["kind"] == "boss")["position"])


def abschattiert(teil, x, y):
    """Jeder Baum etwas anders hell, damit der Wald nicht gestempelt aussieht; am Sumpf
    kuehler, an der Bosshoehle dunkler. Der Rand wird spaeter ohnehin abgedunkelt."""
    hell = rnd.uniform(0.78, 1.04)
    kuehl = max(0.0, 1 - math.dist((x, y), (sx, sy)) / (srx * 1.2))
    finster = max(0.0, 1 - math.dist((x, y), boss_mitte) / (B * 0.2))
    farbe = (hell * (1 - 0.25 * kuehl - 0.35 * finster), hell * (1 - 0.1 * kuehl - 0.4 * finster), hell * (1 + 0.05 * kuehl - 0.3 * finster))
    r, g, b, a = teil.split()
    r, g, b = (k.point(lambda v, f=f: min(255, int(v * f))) for k, f in zip((r, g, b), farbe))
    return Image.merge("RGBA", (r, g, b, a))
def am_rand(k, anzahl, teile_, breite, abstand=1.0, drehbar=False):
    """Teile an den Rand einer Lichtung, nicht auf den Weg: Mitte gehoert dem Knoten."""
    kx, ky = at(k["position"])
    rx, ry = lichtung(k)
    gesetzt, versuche = 0, 0
    while gesetzt < anzahl and versuche < 200:
        versuche += 1
        w = rnd.uniform(0, 2 * math.pi)
        x, y = kx + math.cos(w) * rx * abstand, ky + math.sin(w) * ry * abstand
        b = breite * rnd.uniform(0.7, 1.25)
        if any((x - px) ** 2 + (y - py) ** 2 < (B * 0.016 + b * 0.5) ** 2 for px, py in wegpunkte):
            continue
        if any(math.dist((x, y), (hx, hy)) < hr + b * 0.4 for hx, hy, hr in hindernisse):
            continue
        # Teiche sind von oben gesehen und duerfen sich drehen; so wirkt ein einziger
        # gemalter Teich nicht gestempelt. Ruinen stehen aufrecht und bleiben gerade.
        setze(rnd.choice(teile_), x, y, b, rnd.random() < 0.5, 0.35, rnd.uniform(0, 360) if drehbar else 0)
        hindernisse.append((x, y, b * 0.4))
        gesetzt += 1


for name, gruppe, breite, drehbar in (("teich*.png", SUMPF, B * 0.05, True), ("ruine*.png", RUINEN, B * 0.07, False)):
    stuecke = lade(name)
    if stuecke:
        for i in gruppe:
            am_rand(knoten[i], 3, stuecke, breite, 1.05, drehbar)
for k in knoten.values():
    if k["kind"] == "boss" and (bau := lade("hoehle*.png")):
        kx, ky = at(k["position"])
        # Hoehle ueber der Medaille, nicht dahinter: Die Medaille ist auf dem iPhone ein
        # Siebtel der Kartenhoehe hoch und verdeckte die Hoehle sonst ganz (Vorschau 26.10.).
        hy = ky - lichtung(k)[1] * 1.55
        setze(bau[0], kx, hy, B * 0.15, schatten=0.5)
        hindernisse.append((kx, hy, B * 0.06))

# Baeume zuletzt, um Lichtungen, Wege und die gesetzten Teile herum: Sonst steht ein
# Baum vor der Ruine, und die Ruine ist weg (Vorschau 26.10.).
schritt = B * 0.034
y = -schritt
while y < H + schritt:
    x = -schritt + (rnd.random() * schritt)
    while x < B + schritt:
        px, py = x + rnd.uniform(-0.4, 0.4) * schritt, y + rnd.uniform(-0.4, 0.4) * schritt
        breite = B * rnd.uniform(0.05, 0.078)
        if not im_freien(px, py, breite * 0.4):
            setze(abschattiert(rnd.choice(baeume), px, py), px, py, breite, rnd.random() < 0.5)
        x += schritt
    y += schritt * 0.8



# Schatten aller Teile zuerst (Licht oben links), dann die Teile von hinten nach vorn.
schattenbild = Image.new("L", (B, H), 0)
for _, t, x, y, st in lagen:
    a = t.getchannel("A").point(lambda v: int(v * st))
    schattenbild.paste(ImageChops.lighter(schattenbild.crop((x, y, x + t.width, y + t.height)), a),
                       (x + round(t.width * 0.12), y + round(t.height * 0.16)))
schattenbild = schattenbild.filter(ImageFilter.GaussianBlur(B * 0.006))
bild.paste(Image.new("RGB", (B, H), (8, 14, 8)), (0, 0), schattenbild)
bild = bild.convert("RGBA")
for _, t, x, y, _ in sorted(lagen, key=lambda l: l[0]):
    bild.alpha_composite(t, (x, y)) if x >= 0 and y >= 0 else bild.paste(t, (x, y), t)
bild = bild.convert("RGB")

# --- Licht ---------------------------------------------------------------------------
# Sonne auf den Lichtungen, warmer Ton ueberall, Rand dunkel in den Wald.
schein = Image.new("L", (B, H), 0)
for k in knoten.values():
    rx, ry = lichtung(k)
    schein = ImageChops.lighter(schein, ellipse(at(k["position"]), rx * 1.3, ry * 1.3, B * 0.03).point(lambda v: int(v * 0.35)))
bild = Image.composite(ImageEnhance.Brightness(bild).enhance(1.25), bild, schein)
bild = ImageChops.multiply(bild, Image.new("RGB", (B, H), (255, 236, 205)))
rand = Image.new("L", (B, H), 255)
ImageDraw.Draw(rand).rounded_rectangle((B * 0.035, H * 0.05, B * 0.965, H * 0.95), radius=B * 0.08, fill=0)
bild.paste(Image.new("RGB", (B, H), (8, 18, 12)), (0, 0), rand.filter(ImageFilter.GaussianBlur(B * 0.035)).point(lambda v: int(v * 0.85)))

if ziel.lower().endswith((".jpg", ".jpeg")):
    bild.save(ziel, quality=86, optimize=True, progressive=True)
else:
    bild.save(ziel)
print(f"✓ {ziel} {B}x{H}")

if vorschau:
    v = bild.copy()
    d = ImageDraw.Draw(v)
    pt = B / 454
    for k in knoten.values():
        x, y = at(k["position"])
        r = {"boss": 33, "side": 22}.get(k["kind"], 26) * pt
        d.ellipse((x - r, y - r, x + r, y + r), fill=(120, 80, 40), outline=(240, 200, 90), width=round(4 * pt))
    for kurve_ in kanten:
        for i in range(0, len(kurve_) - 1, 4):
            d.line(kurve_[i:i + 3], fill=(230, 200, 140), width=round(3 * pt))
    v.resize((B // 2, H // 2), Image.LANCZOS).save(vorschau)
    print(f"✓ {vorschau}")
