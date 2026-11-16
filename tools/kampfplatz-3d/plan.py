#!/usr/bin/env python3
"""Plan eines Kampfplatz-Dioramas aus der Missionsdatei (A-4, D-140).

plan.py <mission.json> <ort.json> <ausgabeordner> [px_je_zelle=96]

Reines Python mit Pillow, ohne Blender, damit die CI den Plan prüfen kann. Schreibt:

  plan.json    Kamera, Sonne, Rand, Inseln, Weglinie und jedes Ding der Szene
               (Art, Lage in Zellen, Halbmesser, Höhe) für diorama.py
  boden.png    Bodenfarbe von oben (Gras, Waldboden, Weg, Inseln, Festungsplatz),
               Pixel für Pixel so, wie die Kamera den Boden sieht
  maske-weg.png, maske-inseln.png  dieselben Flächen als Masken, für das Nachlegen
               nach dem Übermalen und für die Tests

Die Kamera blickt orthografisch und ohne Gierwinkel mit `kamera.hoehe` Grad auf den
Boden. Die Tiefe der Szene ist um 1/sin(hoehe) gestreckt (Kabinettprojektion), damit eine
Zelle am Boden im Bild genau quadratisch ist wie in der Simulation; was Höhe hat, ragt um
hoehe·cos(winkel) nach oben. Darum gilt für alles mit Höhe: Seine Spitze darf weder den Weg
noch eine Insel verdecken. Das prüft dieser Plan, bevor gerendert wird.
"""
import json, math, os, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

WURZEL = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
WEGBREITE = 0.95      # Zellen, wie kampfplatz.py: Weg der gemalten Karten
ECKE = 0.45           # Halbmesser der Wegecken; A-1 lässt die Figuren auf demselben Bogen laufen
WEG_FREI = 0.62       # so weit vom Weg darf nichts Hohes ins Bild ragen (halbe Breite + Luft)
INSEL_FREI = 0.08     # Luft um eine Insel für Dinge mit Höhe
HOEHLE_X = -0.95      # Mitte der Höhle am Wegeingang, wie kampfplatz.py


def lade_vertrag():
    v = json.load(open(os.path.join(WURZEL, "art/asset-vertrag.json")))
    return v["kamera"], v["sonne"]


def wegabstand(pfad, x, y):
    best = 1e9
    for (ax, ay), (bx, by) in zip(pfad, pfad[1:]):
        dx, dy = bx - ax, by - ay
        l2 = dx * dx + dy * dy
        t = 0 if l2 == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / l2))
        best = min(best, math.hypot(x - ax - t * dx, y - ay - t * dy))
    return best


def gerundet(punkte, ecke=ECKE):
    """Polylinie mit Bögen an den Ecken (quadratische Bezierkurve, Ecke als Kontrollpunkt)."""
    aus = [punkte[0]]
    for a, b, c in zip(punkte, punkte[1:], punkte[2:]):
        r = min(ecke, math.dist(a, b) / 2, math.dist(b, c) / 2)
        e1 = ((b[0] - a[0]) / math.dist(a, b), (b[1] - a[1]) / math.dist(a, b))
        e2 = ((c[0] - b[0]) / math.dist(b, c), (c[1] - b[1]) / math.dist(b, c))
        p0 = (b[0] - e1[0] * r, b[1] - e1[1] * r)
        p1 = (b[0] + e2[0] * r, b[1] + e2[1] * r)
        for i in range(13):
            t = i / 12
            aus.append(((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * b[0] + t * t * p1[0],
                        (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * b[1] + t * t * p1[1]))
    aus.append(punkte[-1])
    return aus


def inselzellen(karte):
    return [(x, y) for z in karte.get("zones", []) for rx, ry, rb, rh in z["rects"]
            for y in range(ry, ry + rh) for x in range(rx, rx + rb)]


def bildflaeche(ding, kosinus):
    """Rechteck im Bild (Zellen, y nach unten), das ein Ding mit Höhe überdeckt."""
    x, y, r, h = ding["x"], ding["y"], ding["r"], ding["h"]
    return (x - r, y - r * 0.6 - h * kosinus, x + r, y + r * 0.6)


def verdeckt(flaeche, weglinie, inseln, festung):
    """True, wenn die Fläche Weg, Insel oder Festungsplatz berührt."""
    x0, y0, x1, y1 = flaeche
    for px in (x0, (x0 + x1) / 2, x1):
        for py in (y0, (y0 + y1) / 2, y1):
            if wegabstand(weglinie, px, py) < WEG_FREI:
                return True
    # Kante des Rechtecks gegen jede Weg-Stützstelle (Rechteck größer als die Wegbreite)
    for wx, wy in weglinie:
        if x0 - WEG_FREI < wx < x1 + WEG_FREI and y0 - WEG_FREI < wy < y1 + WEG_FREI:
            return True
    for cx, cy in inseln:
        if x0 < cx + 1 + INSEL_FREI and x1 > cx - INSEL_FREI and y0 < cy + 1 + INSEL_FREI and y1 > cy - INSEL_FREI:
            return True
    fx, fy, fr = festung
    if math.hypot(min(max(fx, x0), x1) - fx, min(max(fy, y0), y1) - fy) < fr:
        return True
    return False


def plane(mission, ort, ziel, C=96):
    kamera, sonne = lade_vertrag()
    karte = json.load(open(mission))["map"]
    o = json.load(open(ort))
    W, H = karte["width"], karte["height"]
    MX, MY = o["rand"]
    BB, HH = round((W + 2 * MX) * C), round((H + 2 * MY) * C)
    kos = math.cos(math.radians(kamera["hoehe"]))
    pfad = [tuple(p) for p in karte["path"]]
    fest = (W + 0.9, pfad[-1][1] - 0.4, 1.7)  # Festungsplatz wie kampfplatz.py
    weglinie = gerundet([(HOEHLE_X - 0.35, pfad[0][1])] + pfad[1:-1] + [(fest[0], pfad[-1][1])])
    inseln = inselzellen(karte)
    rnd = random.Random(o.get("seed", 7))

    # --- Dinge -----------------------------------------------------------------------
    dinge = []

    def frei(d):
        if verdeckt(bildflaeche(d, kos), weglinie, inseln, fest):
            return False
        # Dinge stehen nicht ineinander (Fußkreise), Baumkronen dürfen sich berühren
        return all(math.hypot(d["x"] - e["x"], d["y"] - e["y"]) > (d["r"] + e["r"]) * 0.75 for e in dinge)

    def im_feld(x, y):
        return 0 <= x <= W and 0 <= y <= H

    # Höhle am Eingang: steht vor dem Weg, darf ihn verdecken (Gegner kommen heraus)
    dinge.append({"art": "hoehle", "x": HOEHLE_X, "y": pfad[0][1], "r": 1.0, "h": 1.0})
    # Wald im Rand: dicht, groß; zuerst die großen, damit kleine die Lücken füllen
    for versuch in range(o["wald"]["versuche"]):
        x = rnd.uniform(-MX + 0.2, W + MX - 0.2)
        y = rnd.uniform(-MY + 0.2, H + MY + 0.4)
        if im_feld(x, y):
            continue
        h = rnd.uniform(*o["wald"]["hoehe"])
        d = {"art": "baum", "x": round(x, 3), "y": round(y, 3), "r": round(h * 0.42, 3), "h": round(h, 3),
             "farbe": rnd.randrange(len(o["wald"]["farben"]))}
        if frei(d):
            dinge.append(d)
    # Landschaft zwischen den Inseln (G2): nur auf Zellen, die weder Weg noch Insel sind
    landschaft = [(x, y) for y in range(H) for x in range(W)
                  if (x, y) not in inseln and wegabstand(pfad, x + 0.5, y + 0.5) >= 0.9]
    for art, anzahl, (hmin, hmax), rf in o["landschaft"]:
        for _ in range(anzahl * 12):
            if sum(1 for d in dinge if d["art"] == art) >= anzahl:
                break
            cx, cy = rnd.choice(landschaft)
            h = rnd.uniform(hmin, hmax)
            d = {"art": art, "x": round(cx + rnd.uniform(0.2, 0.8), 3), "y": round(cy + rnd.uniform(0.25, 0.85), 3),
                 "r": round(h * rf, 3), "h": round(h, 3), "farbe": rnd.randrange(3)}
            if frei(d):
                dinge.append(d)
    # Steinkante um jede Insel: eine Reihe Feldsteine auf der Kante, damit man den
    # Bauplatz als gebauten Ort liest. Sie liegen auf dem Rand, ihre Höhe ist klein,
    # deshalb gilt die Prüfung oben nicht für sie.
    for z in karte.get("zones", []):
        for rx, ry, rb, rh in z["rects"]:
            kante = []
            for seite, laenge in (("o", rb), ("u", rb), ("l", rh), ("r", rh)):
                n = max(2, round(laenge / 0.32))
                for k in range(n):
                    t = (k + 0.5) / n * laenge
                    kante.append({"o": (rx + t, ry), "u": (rx + t, ry + rh), "l": (rx, ry + t), "r": (rx + rb, ry + t)}[seite])
            for (sx, sy) in kante:
                dinge.append({"art": "kantenstein", "x": round(sx + rnd.uniform(-0.04, 0.04), 3),
                              "y": round(sy + rnd.uniform(-0.04, 0.04), 3), "r": round(rnd.uniform(0.11, 0.15), 3),
                              "h": round(rnd.uniform(0.08, 0.12), 3), "farbe": rnd.randrange(3), "insel": True})

    plan = {
        "kamera": kamera, "sonne": sonne, "licht": o["licht"], "himmel": o["himmel"],
        "breite": W, "hoehe": H, "rand": [MX, MY], "px": C, "bild": [BB, HH],
        "inselhoehe": o["inselhoehe"], "weglinie": [[round(a, 4), round(b, 4)] for a, b in weglinie],
        "inseln": karte.get("zones", []), "festung": list(fest), "dinge": dinge, "farben": o["farben"],
        "waldfarben": o["wald"]["farben"],
    }
    os.makedirs(ziel, exist_ok=True)
    json.dump(plan, open(os.path.join(ziel, "plan.json"), "w"), indent=1)
    boden(plan, o, ziel, rnd)
    return plan


def boden(plan, o, ziel, rnd):
    """Bodenfarbe aus den gemalten Texturen der Kampagnenkarte (eine Welt mit ihr)."""
    W, H = plan["breite"], plan["hoehe"]
    MX, MY = plan["rand"]
    C = plan["px"]
    BB, HH = plan["bild"]
    at = lambda x, y: ((x + MX) * C, (y + MY) * C)

    def flaeche(quelle, weich, zellen):
        q = Image.open(os.path.join(WURZEL, quelle)).convert("RGB")
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

    gras = flaeche(o["texturen"]["gras"], C // 8, 1.3)
    gras = Image.blend(gras, gras.filter(ImageFilter.MedianFilter(max(3, 2 * (C // 26) + 1))), 0.55)
    tonung = Image.effect_noise((max(2, BB // (C * 3)), max(2, HH // (C * 3))), 60).resize((BB, HH), Image.BICUBIC)
    gras = Image.composite(ImageEnhance.Brightness(gras).enhance(0.86), gras,
                           tonung.point(lambda v: max(0, min(255, (v - 128) * 4))))
    erde = flaeche(o["texturen"]["weg"], C // 8, 1.1)
    erde = ImageEnhance.Color(erde.filter(ImageFilter.MedianFilter(max(3, 2 * (C // 10) + 1)))).enhance(0.75)
    erde = Image.blend(erde, erde.filter(ImageFilter.GaussianBlur(C * 0.08)), 0.5)
    # Waldboden dunkel und kühl, Lichtung hell: Der Blick bleibt auf dem Feld.
    bild = ImageEnhance.Brightness(ImageEnhance.Color(gras).enhance(0.75)).enhance(0.45)
    offen = Image.new("L", (BB, HH), 0)
    ImageDraw.Draw(offen).rounded_rectangle((*at(-0.25, -0.25), *at(W + 0.25, H + 0.25)), radius=C * 0.9, fill=255)
    fx, fy, fr = plan["festung"]
    ImageDraw.Draw(offen).ellipse((*at(fx - fr, fy - fr), *at(fx + fr, fy + fr)), fill=255)
    bild.paste(gras, (0, 0), offen.filter(ImageFilter.GaussianBlur(C * 0.3)))

    rauschen = Image.effect_noise((BB // 12, HH // 12), 70).resize((BB, HH), Image.BICUBIC)
    linie = [at(*p) for p in plan["weglinie"]]

    def wegmaske(breite):
        m = Image.new("L", (BB, HH), 0)
        ImageDraw.Draw(m).line(linie, fill=255, width=round(breite), joint="curve")
        r = breite / 2
        for x, y in (linie[0], linie[-1]):
            ImageDraw.Draw(m).ellipse((x - r, y - r, x + r, y + r), fill=255)
        return m

    furche = wegmaske(C * (WEGBREITE + 0.25)).filter(ImageFilter.GaussianBlur(C * 0.06))
    bild.paste(Image.new("RGB", (BB, HH), (40, 32, 16)), (0, 0), furche.point(lambda v: int(v * 0.5)))
    wm = ImageChops.subtract(wegmaske(C * WEGBREITE).filter(ImageFilter.GaussianBlur(C * 0.03)),
                             rauschen.point(lambda v: max(0, v - 165)))
    bild.paste(erde, (0, 0), wm)
    spur = wegmaske(C * 0.35).filter(ImageFilter.GaussianBlur(C * 0.12))
    bild.paste(ImageChops.multiply(bild, Image.new("RGB", (BB, HH), (205, 185, 165))), (0, 0), spur.point(lambda v: int(v * 0.6)))
    platz = Image.new("L", (BB, HH), 0)
    ImageDraw.Draw(platz).ellipse((*at(fx - fr * 0.75, fy - fr * 0.6), *at(fx + fr * 0.75, fy + fr * 0.9)), fill=255)
    bild.paste(erde, (0, 0), ImageChops.subtract(platz.filter(ImageFilter.GaussianBlur(C * 0.25)),
                                                 rauschen.point(lambda v: max(0, v - 150))).point(lambda v: int(v * 0.8)))
    wegmaske(C * WEGBREITE).save(os.path.join(ziel, "maske-weg.png"))

    # Inseln: festgetretene Erde, etwas heller und wärmer als der Weg, damit man sie als
    # Bauplatz liest und nicht als Wegstück. Die Oberseite deckt genau die Zellen.
    # Inseln: festgetretene, etwas dunklere Erde mit Moos am Rand, damit sie sich vom
    # sandigen Weg abheben und als Bauplatz, nicht als Wegstück gelesen werden.
    insel = ImageEnhance.Brightness(ImageEnhance.Color(erde).enhance(0.7)).enhance(0.82)
    insel = Image.composite(ImageEnhance.Brightness(gras).enhance(0.8), insel,
                            rauschen.point(lambda v: 255 if v > 175 else 0).filter(ImageFilter.GaussianBlur(C * 0.05)))
    im = Image.new("L", (BB, HH), 0)
    for z in plan["inseln"]:
        for rx, ry, rb, rh in z["rects"]:
            ImageDraw.Draw(im).rounded_rectangle((*at(rx + 0.03, ry + 0.03), *at(rx + rb - 0.03, ry + rh - 0.03)),
                                                 radius=C * 0.18, fill=255)
    im.save(os.path.join(ziel, "maske-inseln.png"))
    bild.save(os.path.join(ziel, "boden.png"))
    insel.save(os.path.join(ziel, "insel.png"))


if __name__ == "__main__":
    plane(sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]) if len(sys.argv) > 4 else 96)
