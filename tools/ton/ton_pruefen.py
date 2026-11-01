#!/usr/bin/env python3
"""Prüft Herkunft und Lizenz jeder Tondatei (P2-3, D-082). Läuft in der CI.

- Jede Datei unter App/Audio/Sounds steht in art/ton/klaenge.json, und jeder
  Eintrag dort hat seine Datei.
- Jede Quelle trägt eine erlaubte Lizenz (nur CC0), Seite, Download und SHA-256.
- Jede Datei, die AudioStyle.swift und SoundCue.swift verlangen, liegt vor.
- Klänge bleiben kurz und das Paket klein.

Ohne Netz und ohne ffmpeg: Gemessen wird nur die Dateigröße.
"""
import json
import pathlib
import re
import sys

WURZEL = pathlib.Path(__file__).resolve().parents[2]

# Ein Klang mit 44,1 kHz Mono, 16 Bit ist bei 2 s rund 176 KB groß.
KLANG_HOECHSTENS = 200_000
MUSIK_HOECHSTENS = 2_500_000
ALLES_HOECHSTENS = 10_000_000


def erwartete_dateien(audio: pathlib.Path) -> set[str]:
    """Liest Klangnamen, Fassungen und Musikdateien aus dem Swift-Quelltext."""
    cue = (audio / "SoundCue.swift").read_text()
    style = (audio / "AudioStyle.swift").read_text()
    faelle = re.search(r"enum SoundCue[^{]*\{(.*?)\n    ///", cue, re.S).group(1)
    namen = re.findall(r"\b([a-z][A-Za-z]*)\b", " ".join(re.findall(r"case ([^\n]+)", faelle)))
    fassungen = dict(re.findall(r"case \.(\w+): Mix\(variants: (\d+)", style))
    erwartet = set()
    for name in namen:
        if name not in fassungen:
            raise SystemExit(f"AudioStyle.swift: keine Mischung für {name}")
        stamm = re.sub(r"([A-Z])", lambda m: "_" + m.group(1).lower(), name)
        erwartet |= {f"{stamm}_{i}.caf" for i in range(1, int(fassungen[name]) + 1)}
    erwartet |= set(re.findall(r'"(music_\w+\.m4a)"', cue))
    return erwartet


def pruefen(wurzel: pathlib.Path) -> list[str]:
    fehler = []
    liste = json.loads((wurzel / "art/ton/klaenge.json").read_text())
    erlaubt = set(liste["erlaubte_lizenzen"])
    if erlaubt != {"CC0"}:
        fehler.append(f"erlaubte_lizenzen ist {sorted(erlaubt)}, entschieden ist nur CC0 (D-082)")
    for name, quelle in liste["quellen"].items():
        if quelle.get("lizenz") not in erlaubt:
            fehler.append(f"Quelle {name}: Lizenz {quelle.get('lizenz')!r} ist nicht erlaubt")
        for feld in ("titel", "autor", "seite", "datei"):
            if not quelle.get(feld):
                fehler.append(f"Quelle {name}: {feld} fehlt")
        if not re.fullmatch(r"[0-9a-f]{64}", quelle.get("sha256", "")):
            fehler.append(f"Quelle {name}: SHA-256 fehlt oder ist ungültig")
        if not quelle.get("seite", "").startswith("https://"):
            fehler.append(f"Quelle {name}: Seite ohne https")

    eintraege = liste["klaenge"] + liste["musik"]
    gelistet = [e["datei"] for e in eintraege]
    for doppelt in sorted({d for d in gelistet if gelistet.count(d) > 1}):
        fehler.append(f"{doppelt}: zweimal in der Liste")
    for eintrag in eintraege:
        if eintrag["quelle"] not in liste["quellen"]:
            fehler.append(f"{eintrag['datei']}: unbekannte Quelle {eintrag['quelle']}")

    ordner = wurzel / "App/Audio/Sounds"
    vorhanden = {p.name: p for p in ordner.iterdir() if p.is_file()} if ordner.exists() else {}
    for name in sorted(set(vorhanden) - set(gelistet)):
        fehler.append(f"{name}: liegt in App/Audio/Sounds, steht aber nicht in art/ton/klaenge.json")
    for name in sorted(set(gelistet) - set(vorhanden)):
        fehler.append(f"{name}: steht in der Liste, Datei fehlt (tools/ton/ton_bauen.py)")

    for name in sorted(erwartete_dateien(wurzel / "App/Audio") - set(vorhanden)):
        fehler.append(f"{name}: vom Spiel verlangt, aber nicht vorhanden")

    gesamt = 0
    for name, pfad in vorhanden.items():
        groesse = pfad.stat().st_size
        gesamt += groesse
        grenze = MUSIK_HOECHSTENS if name.endswith(".m4a") else KLANG_HOECHSTENS
        if groesse > grenze:
            fehler.append(f"{name}: {groesse} Bytes, höchstens {grenze}")
        if not name.endswith((".caf", ".m4a")):
            fehler.append(f"{name}: nur .caf (Klang) und .m4a (Musik) vorgesehen")
    if gesamt > ALLES_HOECHSTENS:
        fehler.append(f"Ton zusammen {gesamt} Bytes, höchstens {ALLES_HOECHSTENS}")

    entstehung = (wurzel / "art/ton/ENTSTEHUNG.md").read_text() if (wurzel / "art/ton/ENTSTEHUNG.md").exists() else ""
    for name in liste["quellen"].values():
        if name["seite"] not in entstehung:
            fehler.append(f"art/ton/ENTSTEHUNG.md: {name['seite']} fehlt")
    return fehler


def main() -> int:
    wurzel = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else WURZEL
    fehler = pruefen(wurzel)
    for zeile in fehler:
        print("✗", zeile)
    if not fehler:
        print("✓ Ton: jede Datei mit Herkunft und CC0-Lizenz")
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
