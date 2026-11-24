#!/usr/bin/env python3
"""Schatten der Türme (D-120, D-196), gerechnet statt gemalt.

turmboden.py [wurzel=.]

Legt in den Sprite-Atlas je Turmbild `tower_<name>_shadow`: Kontaktdunkel am Fuß und
Schlagschatten nach unten rechts (Licht von oben links, wie die Torburg aus Blender).

Der Fuß wird aus dem Turmbild selbst gemessen (`fuss`): Der Anker des Bildes ist der
vorderste Punkt des Grundrisses, die Mitte des Grundrisses liegt eine halbe Tiefe
dahinter. Kontaktdunkel und Wurzel des Schlagschattens sitzen in dieser Mitte, nicht
am Anker. Saßen sie am Anker (bis 0.47.0), lag ein dunkles Band vor dem Turm, und ein
Ding über seinem eigenen Schatten schwebt (D-196).

Quadrat mit dem Anker in der Mitte (Szene: anchorPoint 0,5/0,5). Kein Modell, kein
Zufall: gleiche Eingabe, gleiches Bild. Werte (Längen in Zellen) stehen oben.
"""
import json, os, re, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

wurzel = sys.argv[1] if len(sys.argv) > 1 else "."
vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
PT = vertrag["punkteJeZelle"]
ATLAS = os.path.join(wurzel, vertrag["atlas"])

SCHATTEN_SEITE = 2.4      # Zellen, Quadrat
SCHATTEN_LAENGE = 0.42    # Schlagschatten: Anteil der Turmhöhe
SCHATTEN_SCHERUNG = 1.0   # nach rechts je Länge nach unten (45°, wie die Torburg)
SCHATTEN_DECKUNG_FUSS = 0.62  # Kontakthärtung: am Fuß dunkel und scharf ...
SCHATTEN_DECKUNG = 0.40       # ... zur Spitze heller ...
SCHATTEN_WEICH = 0.06         # ... und weicher (Unschärfe in Zellen)
SCHATTEN_SCHARF = 0.008
KONTAKT_DECKUNG = 0.85    # Dunkel unter dem Grundriss, sichtbar nur als Saum
KONTAKT_UEBERSTAND = 1.12  # Grundriss mal diesem Wert
KONTAKT_SAUM = 0.02       # Zellen, die das Dunkel in der Tiefe übersteht
KONTAKT_WEICH = 0.05
SCHATTEN_FARBE = (18, 24, 18)
FUSS_BAND = 0.12          # untere Bildhöhe, in der der Grundriss gesucht wird


def ablegen(bild3, name, zellen):
    ordner = os.path.join(ATLAS, f"{name}.imageset")
    os.makedirs(ordner, exist_ok=True)
    for f in (2, 3):
        seite = round(zellen * PT * f)
        b = bild3 if bild3.width == seite else bild3.resize((seite, seite), Image.LANCZOS)
        b.save(os.path.join(ordner, f"{name}@{f}x.png"), optimize=True)
    json.dump({"images": [{"idiom": "universal", "scale": f"{f}x", "filename": f"{name}@{f}x.png"} for f in (2, 3)]
               + [{"idiom": "universal", "scale": "1x"}], "info": {"author": "xcode", "version": 1}},
              open(os.path.join(ordner, "Contents.json"), "w"), indent=2)
    print(f"✓ {name}")


def fuss(turm):
    """Grundriss im Turmbild: Mitte x, unterste Zeile, halbe Breite, halbe Tiefe (Pixel).

    Unterste Zeile ist der Anker. Die Tiefe kommt aus der Krümmung der Fußlinie: An
    den äußeren Spalten liegt der tiefste Punkt auf halber Tiefe des Grundrisses."""
    alpha = turm.getchannel("A")
    w, h = turm.size
    px = alpha.load()
    tief = {}
    for x in range(w):
        for y in range(h - 1, -1, -1):
            if px[x, y] > 128:
                tief[x] = y
                break
    unten = max(tief.values())
    band = [x for x, y in tief.items() if y > unten - FUSS_BAND * h]
    x0, x1 = min(band), max(band)
    rand = [tief[x] for x in band if x < x0 + 0.06 * (x1 - x0) or x > x1 - 0.06 * (x1 - x0)]
    return (x0 + x1) / 2, unten, (x1 - x0) / 2, unten - sum(rand) / len(rand)


def schatten(name):
    regel = vertrag["assets"][name]
    turm = Image.open(os.path.join(ATLAS, f"{name}.imageset", f"{name}@3x.png")).convert("RGBA")
    z = PT * 3  # Pixel je Zelle bei @3x
    mx, _, ha, hb = fuss(turm)
    anker = round(turm.height * (1 - regel["anker"]))
    wurzel = anker - hb  # Grundrissmitte im Turmbild
    seite = round(SCHATTEN_SEITE * z)
    mitte = seite // 2
    oben = round(mitte - hb)  # Grundrissmitte in der Schattenfläche
    # Schlagschatten: Umriss über der Grundrissmitte, nach unten geklappt, gestaucht
    # und geschert. Sein Anfang liegt unter dem Turm und tritt an dessen Fuß hervor.
    umriss = turm.getchannel("A").crop((0, 0, turm.width, round(wurzel))).transpose(Image.FLIP_TOP_BOTTOM)
    hoehe = max(1, round(wurzel * SCHATTEN_LAENGE))
    umriss = umriss.resize((turm.width, hoehe), Image.LANCZOS)
    maske = Image.new("L", (seite, seite), 0)
    maske.paste(umriss, (mitte - turm.width // 2, oben))
    maske = maske.transform(maske.size, Image.AFFINE, (1, -SCHATTEN_SCHERUNG, SCHATTEN_SCHERUNG * oben, 0, 1, 0))
    # Kontakthärtung: am Fuß scharf und dunkel, zur Spitze weich und heller.
    weg = Image.frombytes("L", (seite, seite), bytes(
        max(0, min(255, round(255 * (y - oben) / (hoehe + 1)))) for y in range(seite) for _ in range(seite)))
    maske = Image.composite(maske.filter(ImageFilter.GaussianBlur(SCHATTEN_WEICH * z)),
                            maske.filter(ImageFilter.GaussianBlur(SCHATTEN_SCHARF * z)), weg)
    deckung = weg.point(lambda v: round(255 * (SCHATTEN_DECKUNG_FUSS
                                               - (SCHATTEN_DECKUNG_FUSS - SCHATTEN_DECKUNG) * v / 255)))
    maske = ImageChops.multiply(maske, deckung)
    # Kontaktdunkel: Grundriss etwas größer, um seine Mitte. Vom Turm verdeckt bis auf
    # einen Saum, der die Fußlinie mit dem Boden verbindet.
    kontakt = Image.new("L", (seite, seite), 0)
    kx = mitte + (mx - turm.width / 2)
    ka, kb = ha * KONTAKT_UEBERSTAND, hb * KONTAKT_UEBERSTAND + KONTAKT_SAUM * z
    ImageDraw.Draw(kontakt).ellipse((kx - ka, oben - kb, kx + ka, oben + kb), fill=round(255 * KONTAKT_DECKUNG))
    kontakt = kontakt.filter(ImageFilter.GaussianBlur(KONTAKT_WEICH * z))
    bild = Image.new("RGBA", (seite, seite), SCHATTEN_FARBE + (0,))
    bild.putalpha(ImageChops.lighter(maske, kontakt))
    ablegen(bild, f"{name}_shadow", SCHATTEN_SEITE)


if __name__ == "__main__":
    for eintrag in sorted(os.listdir(ATLAS)):
        name = eintrag[: -len(".imageset")]
        if re.fullmatch(r"tower_[a-z]+(_(\d|[a-z]+))?", name) and not name.endswith("_shadow"):
            schatten(name)
