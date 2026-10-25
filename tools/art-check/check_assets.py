#!/usr/bin/env python3
"""Prueft den Sprite-Atlas gegen den Asset-Vertrag (art/asset-vertrag.json).

check_assets.py [repo-wurzel]   Exit 0 = in Ordnung, 1 = Verstoesse (aufgelistet)

Warum als Test: Die Szene kennt nur Namen und Ankerpunkte. Ein falsch
benanntes, zu kleines oder undurchsichtiges Bild faellt sonst erst auf dem
Geraet auf — oder gar nicht, weil SpriteKit fehlende Texturen still als
rotes Kreuz zeichnet. Ausserdem muss jedes Bild seine Herkunft belegen
(Prompt, Seed, Modell), sonst ist es weder reproduzierbar noch lizenzrechtlich
nachvollziehbar.
"""
import json, os, re, sys
from PIL import Image

# Nur kommerziell nutzbare Modelle (siehe .claude/skills/spielgrafik/SKILL.md).
VERBOTENE_MODELLE = re.compile(r"FLUX\.1-dev|SDXL-Turbo|SD-Turbo|RMBG", re.I)


def pruefe(wurzel):
    fehler = []
    vertrag = json.load(open(os.path.join(wurzel, "art/asset-vertrag.json")))
    atlas = os.path.join(wurzel, vertrag["atlas"])
    pt = vertrag["punkteJeZelle"]
    # Bilder ausserhalb des Sprite-Atlas (Boden als JPEG, eigener Ordner).
    ordner_je_name = {n: os.path.join(wurzel, r["ordner"]) for n, r in vertrag["assets"].items() if "ordner" in r}

    herkunft = ""
    for ordner, _, dateien in os.walk(os.path.join(wurzel, "art")):
        for d in dateien:
            if d == "ENTSTEHUNG.md":
                herkunft += open(os.path.join(ordner, d), encoding="utf-8").read()
    if VERBOTENE_MODELLE.search(herkunft):
        fehler.append("ENTSTEHUNG nennt ein Modell mit nicht-kommerzieller Lizenz")

    eintraege = []
    for basis in sorted({atlas, *ordner_je_name.values()}):
        if os.path.isdir(basis):
            eintraege += [(basis, e) for e in sorted(os.listdir(basis)) if e.endswith(".imageset")]
    for basis, eintrag in eintraege:
        name = eintrag[: -len(".imageset")]
        regel = vertrag["assets"].get(name)
        if regel is None:
            fehler.append(f"{name}: steht nicht im Vertrag (Tippfehler? Die Szene fände es nie)")
            continue
        if ordner_je_name.get(name, atlas) != basis:
            fehler.append(f"{name}: liegt in {os.path.relpath(basis, wurzel)}, Vertrag sagt {os.path.relpath(ordner_je_name.get(name, atlas), wurzel)}")
            continue
        if f"`{name}`" not in herkunft:
            fehler.append(f"{name}: keine Herkunft in art/**/ENTSTEHUNG.md (Name in Backticks)")
        ordner = os.path.join(basis, eintrag)
        endung = regel.get("format", "png")
        for f in (2, 3):
            pfad = os.path.join(ordner, f"{name}@{f}x.{endung}")
            if not os.path.exists(pfad):
                fehler.append(f"{name}: @{f}x fehlt")
                continue
            if os.path.getsize(pfad) > vertrag["maxBytesJeDatei"]:
                fehler.append(f"{name}@{f}x: {os.path.getsize(pfad)} Bytes, Grenze {vertrag['maxBytesJeDatei']}")
            bild = Image.open(pfad)
            if "seiteZellen" in regel:
                soll = round(regel["seiteZellen"] * pt * f)
                if bild.size != (soll, soll):
                    fehler.append(f"{name}@{f}x: Groesse {bild.size}, Vertrag Quadrat {soll}px")
                elif bild.mode == "RGBA":
                    # Fuss = unterste deckende Zeile; die Szene setzt anchorPoint.y = anker.
                    box = bild.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
                    if box:
                        fuss = (bild.height - box[3]) / bild.height
                        if abs(fuss - regel["anker"]) > 0.03:
                            fehler.append(f"{name}@{f}x: Fuss bei {fuss:.2f}, Vertrag {regel['anker']}")
            if "zellen" in regel:
                soll = (round(regel["zellen"][0] * pt * f), round(regel["zellen"][1] * pt * f))
                if bild.size != soll:
                    fehler.append(f"{name}@{f}x: Groesse {bild.size}, Vertrag {soll}")
            hat_alpha = bild.mode in ("RGBA", "LA") and bild.getchannel("A").getextrema()[0] < 255
            if regel["alpha"] and not hat_alpha:
                fehler.append(f"{name}@{f}x: nicht freigestellt (kein transparenter Pixel)")
            if regel["alpha"] and hat_alpha:
                a = bild.getchannel("A")
                ecken = [a.getpixel(p) for p in ((0, 0), (bild.width - 1, 0), (0, bild.height - 1), (bild.width - 1, bild.height - 1))]
                if max(ecken) > 16:
                    fehler.append(f"{name}@{f}x: Ecken nicht transparent — Hintergrund steht noch")
            if not regel["alpha"] and bild.mode == "RGBA" and bild.getchannel("A").getextrema()[0] < 255:
                fehler.append(f"{name}@{f}x: Boden darf keine Loecher haben")
        if not os.path.exists(os.path.join(ordner, "Contents.json")):
            fehler.append(f"{name}: Contents.json fehlt")
    return fehler


if __name__ == "__main__":
    f = pruefe(sys.argv[1] if len(sys.argv) > 1 else ".")
    for z in f:
        print("✗", z)
    print("Assets in Ordnung" if not f else f"{len(f)} Verstoesse")
    sys.exit(1 if f else 0)
