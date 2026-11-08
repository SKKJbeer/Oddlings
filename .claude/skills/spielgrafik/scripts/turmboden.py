#!/usr/bin/env python3
"""Schatten und Fundament der Türme (D-120), gerechnet statt gemalt.

turmboden.py [wurzel=.]

Legt in den Sprite-Atlas:
- `tower_<name>_shadow` je Turmbild: Kontaktschatten am Fuß und Schlagschatten
  nach unten rechts (Licht von oben links, art-direction.md). Aus dem Umriss des
  Turmbildes selbst, also passt er zu jeder Stufe und jedem neuen Turm.
- `footing_<mission>` je gemaltem Kampfplatz: ein Fleck festgetretene Erde, aus
  dem gemalten Weg derselben Karte geschnitten. So hat das Fundament immer die
  Farbe und den Pinselstrich des Ortes.

Beide sind Quadrate mit dem Fuß in der Mitte (Szene: anchorPoint 0,5/0,5). Kein
Modell, kein Zufall außer einem festen Seed je Name: gleiche Eingabe, gleiches Bild.
Werte (Längen in Zellen) stehen oben, damit Bild und Konzept dieselben nennen.
"""
import json, math, os, random, re, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

wurzel = sys.argv[1] if len(sys.argv) > 1 else "."
vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
PT = vertrag["punkteJeZelle"]
ATLAS = os.path.join(wurzel, vertrag["atlas"])
KARTEN = os.path.join(wurzel, "App/Assets.xcassets/Maps")
BALANCE = os.path.join(wurzel, "Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance")

SCHATTEN_SEITE = 2.4      # Zellen, Quadrat
SCHATTEN_LAENGE = 0.42    # Schlagschatten: Anteil der Turmhöhe
SCHATTEN_SCHERUNG = 1.0   # nach rechts je Länge nach unten
SCHATTEN_DECKUNG = 0.45
SCHATTEN_WEICH = 0.03     # Unschärfe in Zellen
KONTAKT = (0.95, 0.36)    # Ellipse am Fuß in Zellen
KONTAKT_DECKUNG = 0.67
SCHATTEN_FARBE = (18, 24, 18)
FUNDAMENT_SEITE = 1.2
FUNDAMENT = (1.05, 0.58)  # Fleck in Zellen
FUNDAMENT_DECKUNG = 0.85
RAND = 2                  # Rand der Karte um das Feld in Zellen (BattleStyle.groundMargin)
RAND_BREITE = 4


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


def schatten(name):
    regel = vertrag["assets"][name]
    turm = Image.open(os.path.join(ATLAS, f"{name}.imageset", f"{name}@3x.png")).convert("RGBA")
    z = PT * 3  # Pixel je Zelle bei @3x
    fuss = round(turm.height * (1 - regel["anker"]))
    umriss = turm.getchannel("A").crop((0, 0, turm.width, fuss)).transpose(Image.FLIP_TOP_BOTTOM)
    hoehe = max(1, round(fuss * SCHATTEN_LAENGE))
    umriss = umriss.resize((turm.width, hoehe), Image.LANCZOS)
    seite = round(SCHATTEN_SEITE * z)
    mitte = seite // 2
    maske = Image.new("L", (seite, seite), 0)
    maske.paste(umriss, (mitte - turm.width // 2, mitte))
    # Scherung um die Fußlinie: je tiefer, desto weiter rechts.
    maske = maske.transform(maske.size, Image.AFFINE, (1, -SCHATTEN_SCHERUNG, SCHATTEN_SCHERUNG * mitte, 0, 1, 0))
    maske = maske.filter(ImageFilter.GaussianBlur(SCHATTEN_WEICH * z)).point(lambda v: round(v * SCHATTEN_DECKUNG))
    kontakt = Image.new("L", (seite, seite), 0)
    kb, kh = KONTAKT[0] * z, KONTAKT[1] * z
    ImageDraw.Draw(kontakt).ellipse((mitte - kb / 2, mitte - kh / 2, mitte + kb / 2, mitte + kh / 2),
                                    fill=round(255 * KONTAKT_DECKUNG))
    kontakt = kontakt.filter(ImageFilter.GaussianBlur(0.05 * z))
    alpha = ImageChops.lighter(maske, kontakt)
    bild = Image.new("RGBA", (seite, seite), SCHATTEN_FARBE + (0,))
    bild.putalpha(alpha)
    ablegen(bild, f"{name}_shadow", SCHATTEN_SEITE)


def fleck(b, h, seed):
    maske = Image.new("L", (b, h), 0)
    zufall = random.Random(seed)
    punkte = []
    for i in range(24):
        t = 2 * math.pi * i / 24
        k = 1 + zufall.uniform(-0.16, 0.08)
        punkte.append((b / 2 + math.cos(t) * b * 0.44 * k, h / 2 + math.sin(t) * h * 0.44 * k))
    ImageDraw.Draw(maske).polygon(punkte, fill=255)
    return maske


def fundament(boden_name):
    m = re.fullmatch(r"map_mission(\w+)_ground", boden_name)
    mission = m.group(1)
    datei = "mvp-mission-01.json" if mission == "01" else f"mission-{mission}.json"
    weg = json.load(open(os.path.join(BALANCE, datei)))["map"]["path"]
    boden = Image.open(os.path.join(KARTEN, f"{boden_name}.imageset", f"{boden_name}@3x.jpg")).convert("RGB")
    zb = boden.width / (json.load(open(os.path.join(BALANCE, datei)))["map"]["width"] + 2 * RAND_BREITE)
    # Erde aus der Mitte des längsten waagerechten Wegstücks: Quer zum Weg läge
    # der Fleck halb im Gras.
    stuecke = [(a, b) for a, b in zip(weg, weg[1:]) if a[1] == b[1]]
    a, b = max(stuecke, key=lambda s: abs(s[1][0] - s[0][0]))
    mx, my = ((a[0] + b[0]) / 2 + RAND_BREITE) * zb, (a[1] + RAND) * zb
    fb, fh = round(FUNDAMENT[0] * zb), round(FUNDAMENT[1] * zb)
    erde = boden.crop((round(mx - fb / 2), round(my - fh / 2), round(mx - fb / 2) + fb, round(my - fh / 2) + fh))
    maske = fleck(fb, fh, sum(map(ord, boden_name))).filter(ImageFilter.GaussianBlur(0.06 * zb))
    erde = erde.convert("RGBA")
    erde.putalpha(maske.point(lambda v: round(v * FUNDAMENT_DECKUNG)))
    z = PT * 3
    seite = round(FUNDAMENT_SEITE * z)
    erde = erde.resize((round(fb * z / zb), round(fh * z / zb)), Image.LANCZOS)
    bild = Image.new("RGBA", (seite, seite), (0, 0, 0, 0))
    bild.alpha_composite(erde, ((seite - erde.width) // 2, (seite - erde.height) // 2))
    ablegen(bild, f"footing_mission{mission}", FUNDAMENT_SEITE)


if __name__ == "__main__":
    for eintrag in sorted(os.listdir(ATLAS)):
        name = eintrag[: -len(".imageset")]
        if re.fullmatch(r"tower_[a-z]+(_\d)?", name):
            schatten(name)
    for eintrag in sorted(os.listdir(KARTEN)):
        if re.fullmatch(r"map_mission\w+_ground\.imageset", eintrag):
            fundament(eintrag[: -len(".imageset")])
