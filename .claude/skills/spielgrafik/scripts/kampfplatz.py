#!/usr/bin/env python3
"""Setzt den Boden einer Mission als Waldlichtung aus gemalten Teilen zusammen.

kampfplatz.py <mission.json> <teileordner> <ausgabe> [px_je_zelle=130] [rand=2 | 4x2] [vorschau.png]

Teileordner wie bei regionscollage.py (gleiche Teile, damit Kampfplatz und
Kampagnenkarte eine Welt sind): gras.png, weg.png, baum*.png, hoehle*.png.

Das Bild deckt das Feld (map.width x map.height Zellen) plus `rand` Zellen je
Seite. Der Rand ist Wald und fuellt auf dem iPhone die Breite, auf dem iPad die
Hoehe (BattleStyle.groundMargin). Das Feld selbst ist bis auf den Weg ueberall
bebaubar; Baeume stehen deshalb nur im Rand und ragen hoechstens UEBERHANG
Zellen ins Feld.

Der Weg liegt auf map.path (Zellmitten, Ursprung oben links), mit runden Ecken
vom Halbmesser ECKE: Gegner laufen in der Simulation eckig, weichen dort aber
weniger als eine Viertelzelle ab, und eckige Wege sahen gezeichnet aus.

Mit [vorschau.png] zeichnet das Skript zusaetzlich Zellgitter und Weglinie ein.
"""
import glob, json, math, os, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

mission, teile, ziel = sys.argv[1:4]
C = int(sys.argv[4]) if len(sys.argv) > 4 else 130
# Rand je Seite in Zellen: "2" fuer alle Seiten oder "4x2" (waagrecht x senkrecht).
rand_arg = sys.argv[5] if len(sys.argv) > 5 else "2"
MX, MY = (float(v) for v in rand_arg.split("x")) if "x" in rand_arg else (float(rand_arg),) * 2
vorschau = sys.argv[6] if len(sys.argv) > 6 else None
karte = json.load(open(mission))["map"]
W, H = karte["width"], karte["height"]
BB, HH = round((W + 2 * MX) * C), round((H + 2 * MY) * C)
pfad = [tuple(p) for p in karte["path"]]
rnd = random.Random(7)
at = lambda x, y: ((x + MX) * C, (y + MY) * C)

UEBERHANG = 0.2   # Zellen, so weit darf eine Krone ins Feld ragen
WEGBREITE = 0.95  # Zellen; BattleStyle.pathWidth (0,8) ist die Linie der Platzhaltergrafik
ECKE = 0.45       # Zellen, Halbmesser der Wegecken
FESTUNG = (W + 0.9, pfad[-1][1] - 0.4, 1.7)  # Mitte x, y und Halbmesser des Festungsplatzes


def lade(muster):
    return [Image.open(p).convert("RGBA") for p in sorted(glob.glob(os.path.join(teile, muster)))]


def flaeche(quelle, weich, zellen):
    """Versetzte, weich ueberblendete Stuecke statt Kacheln, sonst steht dieselbe Blume im Raster.
    Ein Stueck deckt `zellen` Zellen: Die Texturen sind fuer die Kampagnenkarte gemalt, in
    Originalgroesse waeren Blumen und Kiesel hier so gross wie ein Gegner."""
    q = Image.open(quelle).convert("RGB")
    f = zellen * C / (min(q.size) * 0.6)
    q = q.resize((round(q.width * f), round(q.height * f)), Image.LANCZOS)
    stueck = int(min(q.size) * 0.6)
    bild = Image.new("RGB", (BB, HH))
    maske = Image.new("L", (stueck, stueck), 0)
    ImageDraw.Draw(maske).ellipse((weich, weich, stueck - weich, stueck - weich), fill=255)
    maske = maske.filter(ImageFilter.GaussianBlur(weich / 2))
    for y in range(-stueck // 2, HH + stueck // 2, stueck // 3):
        for x in range(-stueck // 2, BB + stueck // 2, stueck // 3):
            ox, oy = rnd.randint(0, q.width - stueck), rnd.randint(0, q.height - stueck)
            teil = q.crop((ox, oy, ox + stueck, oy + stueck))
            if rnd.random() < 0.5:
                teil = teil.transpose(Image.FLIP_LEFT_RIGHT)
            bild.paste(teil, (x, y), maske)
    return bild


def gerundet(punkte):
    """Polylinie mit Kreisboegen an den Ecken, in Zellkoordinaten."""
    aus = [punkte[0]]
    for a, b, c in zip(punkte, punkte[1:], punkte[2:]):
        r = min(ECKE, math.dist(a, b) / 2, math.dist(b, c) / 2)
        e1 = ((b[0] - a[0]) / math.dist(a, b), (b[1] - a[1]) / math.dist(a, b))
        e2 = ((c[0] - b[0]) / math.dist(b, c), (c[1] - b[1]) / math.dist(b, c))
        p0 = (b[0] - e1[0] * r, b[1] - e1[1] * r)
        p1 = (b[0] + e2[0] * r, b[1] + e2[1] * r)
        for i in range(13):
            t = i / 12  # quadratische Bezierkurve mit der Ecke als Kontrollpunkt
            aus.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * b[0] + t * t * p1[0],
                        (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * b[1] + t * t * p1[1]))
    aus.append(punkte[-1])
    return aus


# Weg reicht ueber beide Enden hinaus: links in die Hoehle, rechts unter die Festung.
ende = (pfad[-1][0] + MX, pfad[-1][1])
weglinie = gerundet([(pfad[0][0] - MX, pfad[0][1])] + pfad[1:-1] + [ende])
wegpixel = [at(*p) for p in weglinie]
dichte = [(weglinie[i][0] + (weglinie[i + 1][0] - weglinie[i][0]) * t / 4,
           weglinie[i][1] + (weglinie[i + 1][1] - weglinie[i][1]) * t / 4)
          for i in range(len(weglinie) - 1) for t in range(4)]


def wegabstand(x, y):
    return min(math.dist((x, y), p) for p in dichte)


# --- Boden ---------------------------------------------------------------------------
gras = flaeche(os.path.join(teile, "gras.png"), C // 8, 1.3)
# Bluetenteppich beruhigen: halb mit dem Median gemischt bleiben Halme, die vielen
# Bluetenpunkte treten zurueck. Sonst wirkt das Feld wie Tapete und Gegner gehen unter.
# MedianFilter(1) bricht in Pillow 12 mit SIGFPE ab (gemessen 26.10.2026), deshalb mindestens 3.
gras = Image.blend(gras, gras.filter(ImageFilter.MedianFilter(max(3, 2 * (C // 26) + 1))), 0.55)
# Grosse helle und dunkle Grasflaechen: Ohne sie sieht man das Muster der Textur.
tonung = Image.effect_noise((max(2, BB // (C * 3)), max(2, HH // (C * 3))), 60).resize((BB, HH), Image.BICUBIC)
gras = Image.composite(ImageEnhance.Brightness(ImageEnhance.Color(gras).enhance(0.85)).enhance(0.8), gras,
                       tonung.point(lambda v: max(0, min(255, (v - 128) * 4))))
# Wie bei Mission 1 bisher: Median gegen die grossen Kiesel, sonst liegen Schokostuecke im Weg.
weg = flaeche(os.path.join(teile, "weg.png"), C // 8, 1.1)
weg = ImageEnhance.Color(weg.filter(ImageFilter.MedianFilter(max(3, 2 * (C // 18) + 1)))).enhance(0.7)
# Waldboden im Rand dunkel und kuehl, die Lichtung hell: Das Feld ist der Ort, an dem
# gespielt wird, der Blick soll dort bleiben.
bild = ImageEnhance.Brightness(ImageEnhance.Color(gras).enhance(0.8)).enhance(0.42)
offen = Image.new("L", (BB, HH), 0)
x0, y0 = at(-UEBERHANG, -UEBERHANG)
x1, y1 = at(W + UEBERHANG, H + UEBERHANG)
ImageDraw.Draw(offen).rounded_rectangle((x0, y0, x1, y1), radius=C * 0.8, fill=255)
fx, fy, fr = FESTUNG
ImageDraw.Draw(offen).ellipse((*at(fx - fr, fy - fr), *at(fx + fr, fy + fr)), fill=255)
offen = offen.filter(ImageFilter.GaussianBlur(C * 0.25))
bild.paste(gras, (0, 0), offen)


def wegmaske(breite):
    m = Image.new("L", (BB, HH), 0)
    ImageDraw.Draw(m).line(wegpixel, fill=255, width=round(breite), joint="curve")
    r = breite / 2
    for x, y in (wegpixel[0], wegpixel[-1]):
        ImageDraw.Draw(m).ellipse((x - r, y - r, x + r, y + r), fill=255)
    return m


rauschen = Image.effect_noise((BB // 12, HH // 12), 70).resize((BB, HH), Image.BICUBIC)
wm = ImageChops.subtract(wegmaske(C * WEGBREITE).filter(ImageFilter.GaussianBlur(C * 0.03)),
                         rauschen.point(lambda v: max(0, v - 165)))
# Furche: Grasrand faellt zum Weg hin ab, dunkel und weich.
furche = wegmaske(C * (WEGBREITE + 0.25)).filter(ImageFilter.GaussianBlur(C * 0.06))
bild.paste(Image.new("RGB", (BB, HH), (40, 32, 16)), (0, 0), furche.point(lambda v: int(v * 0.55)))
bild.paste(weg, (0, 0), wm)
# Trittspur in der Wegmitte, etwas dunkler: Hier laufen die Gegner.
spur = wegmaske(C * 0.35).filter(ImageFilter.GaussianBlur(C * 0.12))
bild.paste(ImageChops.multiply(bild, Image.new("RGB", (BB, HH), (200, 180, 160))), (0, 0), spur.point(lambda v: int(v * 0.6)))
# Festungsplatz: festgetretene Erde vor dem Tor.
platz = Image.new("L", (BB, HH), 0)
ImageDraw.Draw(platz).ellipse((*at(fx - fr * 0.75, fy - fr * 0.6), *at(fx + fr * 0.75, fy + fr * 0.9)), fill=255)
bild.paste(weg, (0, 0), ImageChops.subtract(platz.filter(ImageFilter.GaussianBlur(C * 0.25)),
                                             rauschen.point(lambda v: max(0, v - 150))).point(lambda v: int(v * 0.8)))

# --- Teile ---------------------------------------------------------------------------
lagen = []  # (fuss_y, bild, x, y, schatten)


def setze(teil, x, y, breite, spiegeln=False, schatten=0.55):
    s = breite / teil.width
    t = teil.resize((max(1, round(teil.width * s)), max(1, round(teil.height * s))), Image.LANCZOS)
    if spiegeln:
        t = t.transpose(Image.FLIP_LEFT_RIGHT)
    lagen.append((y + t.height / 2, t, round(x - t.width / 2), round(y - t.height / 2), schatten))


hindernisse = []  # (x, y, Halbmesser) in Zellen
hoehle = lade("hoehle*.png")
if hoehle:
    # Die Gegner kommen aus der Hoehle der Kampagnenkarte (Bosshoehle m7).
    hx, hy = -0.95, pfad[0][1]
    setze(hoehle[0], *at(hx, hy), C * 2.0, spiegeln=True, schatten=0.5)
    hindernisse.append((hx, hy, 1.0))
hindernisse.append((fx, fy, fr))

baeume = lade("baum*.png")


def abschattiert(teil):
    hell = rnd.uniform(0.74, 1.02)
    r, g, b, a = teil.split()
    r, g, b = (k.point(lambda v, f=f: min(255, int(v * f))) for k, f in zip((r, g, b), (hell, hell, hell * 1.03)))
    return Image.merge("RGBA", (r, g, b, a))


def frei(x, y, breite):
    """Zellkoordinaten. Krone (Halbmesser breite/2) darf hoechstens UEBERHANG ins Feld."""
    r = breite / 2
    if -r + UEBERHANG < x < W + r - UEBERHANG and -r + UEBERHANG < y < H + r - UEBERHANG:
        return False
    if wegabstand(x, y) < WEGBREITE / 2 + r * 0.7:
        return False
    return not any(math.dist((x, y), (hx, hy)) < hr + r * 0.6 for hx, hy, hr in hindernisse)


schritt = 0.85
y = -MY - 0.5
while y < H + MY + 0.5:
    x = -MX - 0.5 + rnd.random() * schritt
    while x < W + MX + 0.5:
        px, py = x + rnd.uniform(-0.35, 0.35) * schritt, y + rnd.uniform(-0.35, 0.35) * schritt
        breite = rnd.uniform(1.15, 1.75)
        if frei(px, py, breite):
            setze(abschattiert(rnd.choice(baeume)), *at(px, py), C * breite, rnd.random() < 0.5)
        x += schritt
    y += schritt * 0.8

# Schatten aller Teile zuerst (Licht oben links), dann die Teile von hinten nach vorn.
schattenbild = Image.new("L", (BB, HH), 0)
for _, t, x, y, st in lagen:
    a = t.getchannel("A").point(lambda v, st=st: int(v * st))
    schattenbild.paste(ImageChops.lighter(schattenbild.crop((x, y, x + t.width, y + t.height)), a),
                       (x + round(t.width * 0.14), y + round(t.height * 0.18)))
schattenbild = schattenbild.filter(ImageFilter.GaussianBlur(C * 0.12))
bild.paste(Image.new("RGB", (BB, HH), (8, 14, 8)), (0, 0), schattenbild)
bild = bild.convert("RGBA")
for _, t, x, y, _ in sorted(lagen, key=lambda l: l[0]):
    bild.paste(t, (x, y), t)
bild = bild.convert("RGB")

# --- Licht ---------------------------------------------------------------------------
# Lichtflecken wie Sonne durch Laub: grosse weiche Flecken, nur auf der Lichtung.
flecken = Image.effect_noise((max(2, BB // (C * 2)), max(2, HH // (C * 2))), 90).resize((BB, HH), Image.BICUBIC)
flecken = ImageChops.multiply(flecken.point(lambda v: max(0, min(255, (v - 110) * 3))), offen)
bild = Image.composite(ImageEnhance.Brightness(bild).enhance(1.16), bild, flecken.point(lambda v: int(v * 0.6)))
bild = ImageChops.multiply(bild, Image.new("RGB", (BB, HH), (255, 238, 210)))
# Aussenrand dunkel in den Wald: Er ist nur auf breiten Bildschirmen zu sehen.
rand = Image.new("L", (BB, HH), 255)
ImageDraw.Draw(rand).rounded_rectangle((*at(-MX * 0.55, -MY * 0.55), *at(W + MX * 0.55, H + MY * 0.55)), radius=C * 1.5, fill=0)
bild.paste(Image.new("RGB", (BB, HH), (8, 18, 12)), (0, 0), rand.filter(ImageFilter.GaussianBlur(C * 0.6)).point(lambda v: int(v * 0.8)))

if ziel.lower().endswith((".jpg", ".jpeg")):
    bild.save(ziel, quality=88, optimize=True, progressive=True)
else:
    bild.save(ziel)
print(f"✓ {ziel} {BB}x{HH}")

if vorschau:
    v = bild.copy()
    d = ImageDraw.Draw(v)
    for i in range(W + 1):
        d.line((*at(i, 0), *at(i, H)), fill=(255, 255, 255), width=1)
    for j in range(H + 1):
        d.line((*at(0, j), *at(W, j)), fill=(255, 255, 255), width=1)
    d.line([at(*p) for p in pfad], fill=(255, 40, 40), width=3)
    v.resize((BB // 2, HH // 2), Image.LANCZOS).save(vorschau)
    print(f"✓ {vorschau}")
