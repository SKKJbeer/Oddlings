#!/usr/bin/env python3
"""Kontaktabzug (D-145, docs/konzepte/a-1-laufen.md): setzt die Bilder, die die
CI je Mission im Simulator aufnimmt, zu einem Blatt je Mission und einer
Übersicht zusammen und prüft die Messung der App (kontaktabzug-<mission>.json).

Aufruf: kontaktabzug.py <ordner>
  <ordner>/<mission>/bild-1.png … bild-5.png   Bildschirmfotos der CI
  <ordner>/<mission>/kontaktabzug-<mission>.json  Messung der App
Schreibt <ordner>/blatt-<mission>.jpg, <ordner>/uebersicht.jpg und
<ordner>/bericht.md. Grenzen überschritten: Zeile ::warning:: für GitHub,
Rückgabe 0. Der Abzug ist zum Ansehen; hart prüfen die App-Tests.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

# Grenzen der Messung. Abweichung: Bogen r·(√2−1) = 0,21 plus breiteste Spur 0,18
# (FxStyle). Deckungsgleich (ein Paar länger als 0,5 s zusammen, FxStyle.stackedHold):
# höchstens 1 % der Bilder. WalkSceneTests verlangt für Mission 1 keines.
GRENZE_ABWEICHUNG = 0.40
GRENZE_DECKUNG = 0.01
# Verdeckt (D-184): Bilder, in denen ein Gegner unter einer Wolke über ihm steht.
# Seit 0.45.0 liegen alle Wolken unter den Figuren; 2 % lässt Platz für Funken.
GRENZE_VERDECKT = 0.02
# Ein Schütze, der mit Ziel länger woanders hinsieht, wirkt abwesend (A-5 Teil 3, D-189).
GRENZE_DANEBEN_S = 0.6
BREITE_BILD = 480
RAND = 12
# Bildschirmfotos kommen hochkant aus dem Simulator; die App steht quer
# (LandscapeLeft zuerst in project.yml): um 90° gegen den Uhrzeigersinn drehen.
DREHUNG = 90


def aufrecht(bild: Image.Image) -> Image.Image:
    if bild.height > bild.width:
        bild = bild.rotate(DREHUNG, expand=True)
    return bild.convert("RGB")


def verkleinert(bild: Image.Image, breite: int) -> Image.Image:
    hoehe = round(bild.height * breite / bild.width)
    return bild.resize((breite, hoehe), Image.LANCZOS)


def blatt(mission: str, bilder: list[Path], zeile: str) -> Image.Image | None:
    teile = [verkleinert(aufrecht(Image.open(p)), BREITE_BILD) for p in bilder]
    if not teile:
        return None
    hoehe = max(t.height for t in teile)
    kopf = 28
    bogen = Image.new("RGB", (len(teile) * (BREITE_BILD + RAND) + RAND, hoehe + kopf + 2 * RAND), (24, 22, 28))
    zeichnen = ImageDraw.Draw(bogen)
    zeichnen.text((RAND, RAND), f"{mission}   {zeile}", fill=(235, 228, 210))
    for i, teil in enumerate(teile):
        bogen.paste(teil, (RAND + i * (BREITE_BILD + RAND), RAND + kopf))
    return bogen


def bewerten(messung: dict) -> tuple[str, list[str]]:
    warnungen = []
    bilder = max(int(messung.get("frames", 0)), 1)
    deckung = int(messung.get("stackedFrames", 0)) / bilder
    abweichung = float(messung.get("maxDeviationFields", 0))
    if abweichung > GRENZE_ABWEICHUNG:
        warnungen.append(f"Abweichung von der Regel {abweichung:.2f} Felder (Grenze {GRENZE_ABWEICHUNG})")
    if deckung > GRENZE_DECKUNG:
        warnungen.append(f"deckungsgleiche Gegner in {deckung:.1%} der Bilder (Grenze {GRENZE_DECKUNG:.0%})")
    verdeckt = int(messung.get("occludedFrames", 0)) / bilder
    if verdeckt > GRENZE_VERDECKT:
        warnungen.append(f"Gegner unter Effekten in {verdeckt:.1%} der Bilder (Grenze {GRENZE_VERDECKT:.0%})")
    daneben = float(messung.get("longestOffTargetSeconds", 0))
    if daneben > GRENZE_DANEBEN_S:
        warnungen.append(f"Schütze sah {daneben:.2f} s am Ziel vorbei (Grenze {GRENZE_DANEBEN_S} s)")
    if int(messung.get("maxEnemies", 0)) > 0 and int(messung.get("bends", 0)) == 0:
        warnungen.append("kein Gegner lief durch einen Eckbogen")
    zeile = (f"Gegner bis {messung.get('maxEnemies', 0)} · Bögen {messung.get('bends', 0)} · "
             f"Staub {messung.get('footfalls', 0)} · Abweichung {abweichung:.2f} · Deckung {deckung:.1%} · "
             f"verdeckt {verdeckt:.1%} · gedämpft {messung.get('dampedClouds', 0)} · Gold gebündelt {messung.get('mergedGold', 0)} · "
             f"Schüsse {messung.get('shots', 0)} · daneben bis {daneben:.2f} s")
    return zeile, warnungen


def main(ordner: Path) -> int:
    missionen = sorted(p for p in ordner.iterdir() if p.is_dir())
    blaetter = []
    bericht = ["| Mission | Messung | Befund |", "|---|---|---|"]
    for mappe in missionen:
        mission = mappe.name
        dateien = sorted(mappe.glob("kontaktabzug-*.json"))
        if dateien:
            zeile, warnungen = bewerten(json.loads(dateien[0].read_text()))
        else:
            zeile, warnungen = "keine Messung", ["Die App hat keine Messung geschrieben"]
        for warnung in warnungen:
            print(f"::warning::Kontaktabzug {mission}: {warnung}")
        bericht.append(f"| {mission} | {zeile} | {'; '.join(warnungen) or 'in Ordnung'} |")
        bogen = blatt(mission, sorted(mappe.glob("bild-*.png")), zeile)
        if bogen:
            bogen.save(ordner / f"blatt-{mission}.jpg", quality=85)
            blaetter.append(bogen)
    if blaetter:
        breite = max(b.width for b in blaetter)
        gesamt = Image.new("RGB", (breite, sum(b.height for b in blaetter)), (24, 22, 28))
        y = 0
        for bogen in blaetter:
            gesamt.paste(bogen, (0, y))
            y += bogen.height
        verkleinert(gesamt, min(breite, 1800)).save(ordner / "uebersicht.jpg", quality=80)
    (ordner / "bericht.md").write_text("## Kontaktabzug\n\n" + "\n".join(bericht) + "\n")
    print("\n".join(bericht))
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.exit(main(Path(sys.argv[1])))
