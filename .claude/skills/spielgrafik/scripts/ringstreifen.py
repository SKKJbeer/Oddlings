#!/usr/bin/env python3
"""Wickelt einen gemalten Ring zu einem kachelbaren Streifen ab (A-5, D-171).

ringstreifen.py <ring.png> <aus.png> [breite=1536] [hoehe=96] [vorschau.png]

Eingabe: ein mit FLUX gemalter Ring auf schwarzem Grund, von oben. Der Ring ist
selten genau rund. Deshalb sucht das Skript je Winkel den hellsten Radius und
schneidet das Band um ihn herum aus: So wird jeder Ring zu einem geraden Streifen.
Alpha aus der Helligkeit (schwarzer Grund = durchsichtig), Kontur oben und unten
in #22160F wie bei allen Bildern (freistellen.py). Die Enden werden über ein
Achtel der Breite überblendet, damit der Ring in der App ohne Naht schließt.

Ausgabe: oben Außenkante, unten Innenkante. Das App-Gegenstück ist
App/Battle/GroundMarks.swift; mit [vorschau.png] rechnet es dasselbe Wickeln nach.
"""
import math, sys
import numpy as np
from PIL import Image, ImageFilter

quelle, ziel = sys.argv[1], sys.argv[2]
B = int(sys.argv[3]) if len(sys.argv) > 3 else 1536
H = int(sys.argv[4]) if len(sys.argv) > 4 else 96
vorschau = sys.argv[5] if len(sys.argv) > 5 else None

bild = np.asarray(Image.open(quelle).convert("RGB")).astype(np.float32) / 255
hell = bild.mean(axis=2)
n = hell.shape[0]
# Mitte: Schwerpunkt der hellen Pixel.
ys, xs = np.nonzero(hell > 0.35)
cx, cy = xs.mean(), ys.mean()
rmax = min(cx, cy, n - cx, n - cy) - 2

def probe(x, y):
    x0, y0 = int(math.floor(x)), int(math.floor(y))
    tx, ty = x - x0, y - y0
    x0, y0 = min(max(x0, 0), n - 2), min(max(y0, 0), n - 2)
    p = bild[y0:y0 + 2, x0:x0 + 2]
    return (p[0, 0] * (1 - tx) + p[0, 1] * tx) * (1 - ty) + (p[1, 0] * (1 - tx) + p[1, 1] * tx) * ty

# Radius je Winkel: hellste Stelle, geglättet, damit das Band nicht zittert.
winkel = 720
radien = []
for i in range(winkel):
    a = 2 * math.pi * i / winkel
    profil = [hell[int(cy + r * math.sin(a)), int(cx + r * math.cos(a))] for r in range(int(rmax * 0.4), int(rmax))]
    radien.append(int(rmax * 0.4) + int(np.argmax(profil)))
radien = np.array(radien, dtype=np.float32)
k = 31
radien = np.convolve(np.concatenate([radien[-k:], radien, radien[:k]]), np.ones(k) / k, mode="same")[k:-k]
# Bandbreite: wo die Helligkeit quer zum Ring über die Hälfte des Gipfels liegt.
breiten = []
for i in range(0, winkel, 8):
    a = 2 * math.pi * i / winkel
    r0 = radien[i]
    profil = np.array([hell[int(cy + r * math.sin(a)), int(cx + r * math.cos(a))] for r in np.arange(r0 - 40, r0 + 40)])
    breiten.append((profil > profil.max() * 0.35).sum())
band = float(np.median(breiten)) * 1.25
print(f"Mitte {cx:.0f},{cy:.0f}  Radius {radien.mean():.0f}±{radien.std():.1f}  Band {band:.1f} px")

streifen = np.zeros((H, B, 3), np.float32)
for x in range(B):
    a = 2 * math.pi * x / B
    r0 = np.interp(x / B * winkel, np.arange(winkel + 1), np.append(radien, radien[0]))
    for y in range(H):
        r = r0 + band / 2 - band * (y + 0.5) / H
        streifen[y, x] = probe(cx + r * math.cos(a), cy + r * math.sin(a))
# Naht: Ende über den Anfang blenden, danach ist Spalte 0 die Fortsetzung der letzten.
ueber = B // 8
w = np.linspace(0, 1, ueber)[None, :, None]
streifen[:, :ueber] = streifen[:, :ueber] * w + streifen[:, B - ueber:] * (1 - w)
streifen = streifen[:, : B - ueber]
streifen = np.asarray(Image.fromarray((streifen * 255).astype(np.uint8)).resize((B, H), Image.LANCZOS)).astype(np.float32) / 255

alpha = np.clip((streifen.max(axis=2) - 0.08) / 0.35, 0, 1)
# Kontur: dunkle Kante an der Außenseite des deckenden Bandes, wie bei allen Bildern.
maske = Image.fromarray((alpha * 255).astype(np.uint8))
kontur = np.asarray(maske.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1))).astype(np.float32) / 255
dunkel = np.array([0x22, 0x16, 0x0F], np.float32) / 255
farbe = streifen / np.maximum(alpha[..., None], 1e-3)
farbe = np.clip(farbe, 0, 1)
a_ges = alpha + kontur * (1 - alpha)
rgb = (farbe * alpha[..., None] + dunkel * (kontur * (1 - alpha))[..., None]) / np.maximum(a_ges[..., None], 1e-3)
# Erste und letzte Zeile durchsichtig: Ecken frei (art-check), weicher Auslauf.
rand = np.ones(H, np.float32); rand[:2] = 0; rand[-2:] = 0
a_ges = a_ges * rand[:, None]
aus = np.dstack([np.clip(rgb, 0, 1), a_ges])
Image.fromarray((aus * 255).astype(np.uint8), "RGBA").save(ziel)
print(f"✓ {ziel} {B}x{H}")

if vorschau:
    # Gleiche Rechnung wie GroundMarks.render: Streifen um den Kreis gewickelt, auf Wiese.
    s = aus
    rand_px, r = 10, 120
    seite = 2 * (r + rand_px) + 40
    wiese = Image.new("RGBA", (seite * 2, seite), (96, 128, 64, 255))
    for k_, (rr, rim) in enumerate([(r, 14), (55, 12)]):
        natur = B * rim / H
        wdh = max(1, round(2 * math.pi * rr / natur))
        o = np.zeros((seite, seite, 4), np.float32)
        c = seite / 2
        for y in range(seite):
            for x in range(seite):
                dx, dy = x + 0.5 - c, y + 0.5 - c
                d = math.hypot(dx, dy)
                v = (rr + rim / 2 - d) / rim
                if 0 <= v <= 1:
                    u = ((math.atan2(dy, dx) / (2 * math.pi) + 0.5) * wdh) % 1
                    o[y, x] = s[min(H - 1, int(v * (H - 1))), min(B - 1, int(u * B))]
        wiese.alpha_composite(Image.fromarray((o * 255).astype(np.uint8), "RGBA"), (k_ * seite, 0))
    wiese.convert("RGB").save(vorschau)
