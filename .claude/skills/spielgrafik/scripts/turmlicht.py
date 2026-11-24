#!/usr/bin/env python3
"""Gemalte Türme ins Licht der 3D-Welt setzen (D-200 bis D-203), gerechnet statt gemalt.

turmlicht.py [wurzel=.]

Die Kampfplätze, Bäume und die Torburg sind in 3D gerechnet: Sonne von oben links
hinten (Vertrag `sonne`), jede Form hat eine helle und eine Schattenseite. Die Türme sind
gemalt und von vorn gleichmäßig hell. Nebeneinander wirken sie aufgeklebt. Dieses Skript
liest die Malerei aus `art/tuerme-in-der-welt/quelle/` (unverändert, die Quelle) und legt
in den Atlas je Turmbild:

- `tower_<name>`: dieselbe Malerei mit Schattenseite (rechts dunkler, links heller, als
  Zylinder je Zeile genähert) und Fußdunkel (Umgebungsverdeckung am Grundriss). Umriss
  und Lage bleiben Pixel für Pixel gleich, damit Kronen und Schützen (D-185) stimmen.
- `tower_<name>_grass`: Maske für den Boden vor dem Fuß. Die Szene legt darin den
  gemalten Boden des Kampfplatzes über den Fuß; mit einer Kante aus Halmen steht der
  Turm im Gras statt darauf (D-202).

Danach rechnet `turmboden.py` die Schatten aus den neuen Bildern. Kein Modell, kein
Zufall außer festem Samen: gleiche Eingabe, gleiches Bild. Werte stehen oben.
"""
import json, math, os, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
wurzel = sys.argv[1] if len(sys.argv) > 1 else "."
sys.argv = sys.argv[:1] + [wurzel]
import turmboden  # noqa: E402  (liest Vertrag und Atlas aus derselben Wurzel)

QUELLE = os.path.join(wurzel, "art/tuerme-in-der-welt/quelle")
vertrag = turmboden.vertrag
PT = vertrag["punkteJeZelle"]

LICHT_SEITE = 0.20      # links (zur Sonne) heller um bis zu diesen Anteil
SCHATTEN_SEITE = 0.34   # rechts (von der Sonne weg) dunkler um bis zu diesen Anteil
SCHATTEN_KURVE = 1.25   # >1: die Schattenseite beginnt erst hinter der Mitte
ZEILEN_GLAETTEN = 9     # Zeilen, über die Mitte und Breite gemittelt werden
FUSS_DUNKEL = 0.42      # Umgebungsverdeckung am Grundriss ...
FUSS_HOEHE = 0.22       # ... ausgeblendet bis zu diesem Anteil der Bildhöhe über dem Fuß
GRAS_SAUM = 0.045       # Zellen: so weit ragt der Boden vorn über die Fußlinie
GRAS_HALM = 0.13        # Zellen: längster Halm
GRAS_BREITE = 1.12      # Grundriss mal diesem Wert, damit Halme den Umriss überdecken
GRAS_DICHTE = 60        # Halme je Zelle Breite


def _spannen(alpha):
    w, h = alpha.size
    px = alpha.load()
    roh = {}
    for y in range(h):
        xs = [x for x in range(w) if px[x, y] > 128]
        if xs:
            roh[y] = (min(xs), max(xs))
    glatt = {}
    for y in roh:
        nah = [roh[v] for v in range(y - ZEILEN_GLAETTEN // 2, y + ZEILEN_GLAETTEN // 2 + 1) if v in roh]
        a = sorted(s[0] for s in nah)[len(nah) // 2]
        b = sorted(s[1] for s in nah)[len(nah) // 2]
        glatt[y] = ((a + b) / 2, max(1.0, (b - a) / 2))
    return glatt


def licht(turm):
    """Schattenseite und Fußdunkel; Alpha unverändert."""
    w, h = turm.size
    alpha = turm.getchannel("A")
    spannen = _spannen(alpha)
    _, unten, _, _ = turmboden.fuss(turm)
    oben_fuss = unten - FUSS_HOEHE * h
    faktor = Image.new("L", (w, h), 128)  # 128 = 1,0; Spielraum für Aufhellen
    fx = faktor.load()
    for y, (mitte, halb) in spannen.items():
        f_fuss = 0.0 if y < oben_fuss else min(1.0, (y - oben_fuss) / max(1.0, unten - oben_fuss))
        fuss = 1 - FUSS_DUNKEL * f_fuss ** 1.6
        for x in range(w):
            u = max(-1.0, min(1.0, (x - mitte) / halb))
            seite = 1 + LICHT_SEITE * max(0.0, -u) - SCHATTEN_SEITE * max(0.0, u) ** SCHATTEN_KURVE
            fx[x, y] = max(0, min(255, round(128 * seite * fuss)))
    r, g, b, a = turm.split()
    kanaele = [_mal(k, faktor) for k in (r, g, b)]
    return Image.merge("RGBA", (*kanaele, a))


def _mal(kanal, faktor):
    kp, fp = kanal.load(), faktor.load()
    w, h = kanal.size
    aus = Image.new("L", (w, h))
    ap = aus.load()
    for y in range(h):
        for x in range(w):
            ap[x, y] = min(255, kp[x, y] * fp[x, y] // 128)
    return aus


def grasmaske(turm, saat):
    """Boden vor dem Fuß: unter dem vorderen Bogen des Grundrisses, Kante aus Halmen."""
    w, h = turm.size
    z = PT * 3
    mx, unten, ha, hb = turmboden.fuss(turm)
    cy = unten - hb
    a, b = ha * GRAS_BREITE, hb * GRAS_BREITE
    rnd = random.Random(saat)
    m = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(m)

    def bogen(u):
        return cy + b * math.sqrt(max(0.0, 1 - u * u)) - GRAS_SAUM * z

    pts = [(mx + a * (-1 + 2 * i / 120), bogen(-1 + 2 * i / 120)) for i in range(121)]
    # Nach unten nur so weit, dass die Fußlinie sicher bedeckt ist.
    boden = min(h, unten + GRAS_SAUM * z * 2)
    d.polygon(pts + [(mx + a, boden), (mx - a, boden)], fill=255)
    for _ in range(round(GRAS_DICHTE * 2 * a / z)):
        u = rnd.uniform(-0.96, 0.96)
        x, y = mx + u * a, bogen(u) + 1
        # Vorn (Mitte) längere Halme, an den Seiten kurze: dort sieht man den Fuß von der Seite.
        lang = GRAS_HALM * z * rnd.uniform(0.3, 1.0) * (0.5 + 0.5 * math.sqrt(1 - u * u))
        breit = rnd.uniform(0.010, 0.018) * z
        neig = rnd.uniform(-0.025, 0.025) * z
        d.polygon([(x - breit, y), (x + breit, y), (x + neig, y - lang)], fill=255)
    return m.filter(ImageFilter.GaussianBlur(0.6))


def turm(name):
    quelle = Image.open(os.path.join(QUELLE, f"{name}.png")).convert("RGBA")
    regel = vertrag["assets"][name]
    turmboden.ablegen(licht(quelle), name, regel["seiteZellen"])
    maske = grasmaske(quelle, saat=sum(map(ord, name)))
    turmboden.ablegen(Image.merge("RGBA", (Image.new("L", maske.size, 255),) * 3 + (maske,)),
                      f"{name}_grass", regel["seiteZellen"])


if __name__ == "__main__":
    for datei in sorted(os.listdir(QUELLE)):
        if datei.endswith(".png"):
            turm(datei[:-4])
