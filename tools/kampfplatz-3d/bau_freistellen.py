#!/usr/bin/env python3
"""Stellt einen übermalten Bau frei: Farbe aus FLUX, Form und Schatten aus Blender.

bau_freistellen.py <blender.png> <flux.png> <bau.png> [<schatten.png>]

Ohne zweite Ausgabe liegen Bau und Schatten in einem Bild.

Warum nicht `freistellen.py` (rembg): Der Bau kommt aus `bauten.py` mit genauer Alpha
und einem Schattenfänger. Diese Form ist die Wahrheit über Fuß, Anker und Schatten
(Vertragskamera und -sonne, D-165); das Übermalen (Bild-zu-Bild, Stärke 0,5) ändert nur
Oberfläche und kleine Teile wie Fahnen. Also:

1. Kern = deckende Blender-Pixel. Sein Inneres gilt immer als Bau, sein Rand nur, wo
   FLUX dort Bau gemalt hat.
2. Um den Kern dürfen FLUX-Pixel dazukommen, die sich vom gemalten Hintergrund
   abheben (Fahnen, Zinnen, die beim Übermalen wuchsen), oben weit, im Schatten nur
   knapp: Sonst würde der gemalte Schatten zu grauem, deckendem Bau.
3. Schatten = halbdeckende Blender-Pixel (Schattenfänger), schwarz mit dieser Deckung.

Der Hintergrund wird als Ebene über den Bildrand geschätzt, weil FLUX ihn mit leichtem
Verlauf malt. Nur Pillow, kein Modell.
"""
import sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

KERN = 230          # Blender-Alpha ab hier: Bau
WEIT, KNAPP = 12, 3  # Spielraum in Pixeln (bei 512) außerhalb und im Schatten
ABSTAND = 75        # Farbabstand zum Hintergrund (dreifach, also roh 25), ab dem ein Pixel Bau ist
INNEN = 5           # so tief im Kern gilt Blender ohne Rückfrage


def hintergrund(bild):
    """Ebene r = a + b·x + c·y je Kanal, kleinste Quadrate über den Randstreifen."""
    w, h = bild.size
    px = bild.load()
    punkte = [(x, y) for x in range(0, w, 4) for y in (2, h - 3)] + \
             [(x, y) for y in range(0, h, 4) for x in (2, w - 3)]
    n = len(punkte)
    sx = sum(x for x, _ in punkte); sy = sum(y for _, y in punkte)
    sxx = sum(x * x for x, _ in punkte); syy = sum(y * y for _, y in punkte)
    sxy = sum(x * y for x, y in punkte)
    ebenen = []
    for k in range(3):
        v = [px[p][k] for p in punkte]
        sv = sum(v); sxv = sum(x * a for (x, _), a in zip(punkte, v)); syv = sum(y * a for (_, y), a in zip(punkte, v))
        # 3×3-Normalgleichungen, Cramer
        m = [[n, sx, sy], [sx, sxx, sxy], [sy, sxy, syy]]
        r = [sv, sxv, syv]

        def det(a):
            return (a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1])
                    - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
                    + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0]))
        d = det(m)
        loes = []
        for i in range(3):
            mi = [row[:] for row in m]
            for j in range(3):
                mi[j][i] = r[j]
            loes.append(det(mi) / d)
        ebenen.append(loes)
    return Image.frombytes("RGB", (w, h), bytes(
            max(0, min(255, round(e[0] + e[1] * x + e[2] * y)))
            for y in range(h) for x in range(w) for e in ebenen))


def wachse(maske, r):
    return maske.filter(ImageFilter.MaxFilter(2 * r + 1)) if r > 0 else maske


def freistellen(blender, flux, schatten=0.8):
    blender = blender.convert("RGBA")
    flux = flux.convert("RGB").resize(blender.size, Image.LANCZOS)
    a = blender.getchannel("A")
    kern = a.point(lambda v: 255 if v >= KERN else 0)
    schattenflaeche = a.point(lambda v: 255 if 8 <= v < KERN else 0)
    abstand = ImageChops.difference(flux, hintergrund(flux)).convert("L").point(lambda v: v * 3)
    hebt_ab = abstand.point(lambda v: 255 if v > ABSTAND else 0)
    weit = ImageChops.subtract(wachse(kern, WEIT), wachse(schattenflaeche, 1))
    spielraum = ImageChops.lighter(wachse(kern, KNAPP), weit)
    # Auch im Kern zählt am Rand nur, was FLUX als Bau gemalt hat: Dort, wo es dünne
    # Teile (Grashalme, Fahnenstange) übermalt hat, bliebe sonst Hintergrundgrau stehen.
    bau = ImageChops.lighter(kern.filter(ImageFilter.MinFilter(2 * INNEN + 1)), ImageChops.multiply(spielraum, hebt_ab))
    # Löcher schließen, Kante weich ziehen.
    bau = bau.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    dunkel = Image.new("RGBA", blender.size, (12, 10, 8, 0))
    # Schatten nur außerhalb der Blender-Kante: Dort, wo FLUX den Bau schmaler malte,
    # stünde sonst ein schwarzer Strich. Am Fuß schließt der aufgeweitete Schatten an.
    rand = wachse(kern, 2)
    draussen = ImageChops.multiply(a.point(lambda v: round(v * schatten) if v < KERN else 0),
                                   ImageChops.invert(rand))
    s = Image.composite(draussen.filter(ImageFilter.MaxFilter(7)), draussen, rand)
    # Nur der Schatten, der am Bau hängt: Schatten von übermalten Kleinteilen (Halme)
    # blieben sonst als dunkle Flecken ohne Ding stehen.
    zusammen = ImageChops.lighter(bau, s).point(lambda v: 255 if v > 20 else 0)
    x0, y0, x1, y1 = kern.filter(ImageFilter.MinFilter(2 * INNEN + 1)).getbbox()
    ImageDraw.floodfill(zusammen, ((x0 + x1) // 2, (y0 + y1) // 2), 128)
    s = ImageChops.multiply(s, zusammen.point(lambda v: 255 if v == 128 else 0))
    # Am Bildrand ausblenden: Ein abgeschnittener Schatten wäre eine gerade Kante im Gras.
    w, h = s.size
    k = max(8, w // 20)
    rampe = Image.frombytes("L", (w, h), bytes(
        min(255, 255 * min(x, y, w - 1 - x, h - 1 - y) // k) for y in range(h) for x in range(w)))
    dunkel.putalpha(ImageChops.multiply(s, rampe))
    farbe = flux.convert("RGBA")
    farbe.putalpha(bau)
    return farbe, dunkel


if __name__ == "__main__":
    bau, schatten = freistellen(Image.open(sys.argv[1]), Image.open(sys.argv[2]))
    if len(sys.argv) > 4:
        # Getrennt: Der Schatten liegt in der Szene unter dem Bild, wie bei den Türmen
        # (D-120), und der Fuß des Baus bleibt messbar (art-check, Anker).
        bau.save(sys.argv[3])
        schatten.save(sys.argv[4])
    else:
        schatten.alpha_composite(bau)
        schatten.save(sys.argv[3])
