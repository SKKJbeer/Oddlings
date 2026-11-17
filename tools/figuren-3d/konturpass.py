"""Konturpass für Bildfolgen (A-3): eine Außenlinie, für alle Gegner gleich breit.

Eigene Datei, damit folge.py und die Tests in tools/art-check dieselbe Umsetzung
benutzen (eine Umsetzung je Sache).
"""
import numpy as np
from PIL import Image

KONTURFARBE = (34, 22, 18)  # wie freistellen.py, damit Gemälde und 3D gleich umrandet sind


def kontur(bild, breite):
    """Silhouette um `breite` Pixel erweitert, dunkel, hinter dem Bild.

    Kreisförmig statt quadratisch (Ecken bleiben rund), mit weichem Rand für
    Bruchteile eines Pixels. Innen ändert sich nichts: das Bild liegt obenauf.
    """
    if breite <= 0:
        return bild
    a = np.asarray(bild.getchannel("A"), dtype=np.float32) / 255
    r = int(np.ceil(breite))
    p = np.pad(a, r)
    hoehe, weite = a.shape
    aussen = np.zeros_like(a)
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            gewicht = min(1.0, max(0.0, breite + 0.5 - (dx * dx + dy * dy) ** 0.5))
            if gewicht > 0:
                aussen = np.maximum(aussen, gewicht * p[r + dy:r + dy + hoehe, r + dx:r + dx + weite])
    linie = Image.new("RGBA", bild.size, KONTURFARBE + (0,))
    linie.putalpha(Image.fromarray((aussen * 255).round().astype(np.uint8)))
    return Image.alpha_composite(linie, bild)
