#!/usr/bin/env python3
"""Baut die Tondateien der App aus art/ton/klaenge.json (P2-3).

Lädt jede Quelle, prüft ihre Prüfsumme, schneidet und gleicht an und schreibt
das Ergebnis nach App/Audio/Sounds. Wer einen Klang tauscht, ändert die JSON
und ruft das Skript erneut auf; so bleibt jede Datei im Repo nachvollziehbar.

    python3 tools/ton/ton_bauen.py            # alles
    python3 tools/ton/ton_bauen.py hit_1.caf  # nur diese Datei

Braucht ffmpeg. Läuft nicht in der CI: Dort prüft ton_pruefen.py nur, dass
Dateien und Liste zusammenpassen, ohne Netz.
"""
import hashlib
import json
import pathlib
import subprocess
import sys
import tempfile
import urllib.request
import zipfile

WURZEL = pathlib.Path(__file__).resolve().parents[2]
LISTE = WURZEL / "art/ton/klaenge.json"
ZIEL = WURZEL / "App/Audio/Sounds"
ZWISCHEN = pathlib.Path(tempfile.gettempdir()) / "oddlings-ton"

# Klänge kommen mit Spitze -1 dBFS; die Mischung je Klang steht in AudioStyle.swift.
# So kann man eine Datei tauschen, ohne die Lautstärke im Spiel neu abzustimmen.
SPITZE_DB = -1.0
AUSBLENDEN_S = 0.015
# Musik auf eine gemeinsame Lautheit, damit beim Wechsel nichts springt.
MUSIK_LUFS = -16


def laden(quelle: dict) -> pathlib.Path:
    ZWISCHEN.mkdir(parents=True, exist_ok=True)
    datei = ZWISCHEN / quelle["datei"].rsplit("/", 1)[-1]
    if not datei.exists():
        anfrage = urllib.request.Request(quelle["datei"], headers={"User-Agent": "oddlings-ton"})
        datei.write_bytes(urllib.request.urlopen(anfrage, timeout=120).read())
    summe = hashlib.sha256(datei.read_bytes()).hexdigest()
    if summe != quelle["sha256"]:
        datei.unlink()
        raise SystemExit(f"Prüfsumme stimmt nicht: {quelle['datei']} ({summe})")
    return datei


def auspacken(archiv: pathlib.Path, pfad: str) -> pathlib.Path:
    if not pfad:
        return archiv
    ziel = ZWISCHEN / archiv.stem / pfad
    if not ziel.exists():
        with zipfile.ZipFile(archiv) as zf:
            zf.extract(pfad, ZWISCHEN / archiv.stem)
    return ziel


def spitze(datei: pathlib.Path, filter_: str) -> float:
    aus = subprocess.run(
        ["ffmpeg", "-hide_banner", "-i", str(datei), "-af", f"{filter_},volumedetect", "-f", "null", "-"],
        capture_output=True, text=True, check=True).stderr
    zeile = next(z for z in aus.splitlines() if "max_volume" in z)
    return float(zeile.split("max_volume:")[1].split("dB")[0])


def klang(eintrag: dict, quelle: pathlib.Path) -> None:
    filter_ = "silenceremove=start_periods=1:start_threshold=-50dB"
    if "dauer" in eintrag:
        filter_ += f",atrim=0:{eintrag['dauer']}"
        filter_ += f",afade=t=out:st={max(0, eintrag['dauer'] - AUSBLENDEN_S * 4)}:d={AUSBLENDEN_S * 4}"
    filter_ += ",aresample=44100,pan=mono|c0=0.5*c0+0.5*c1" if kanaele(quelle) > 1 else ",aresample=44100"
    anheben = SPITZE_DB - spitze(quelle, filter_)
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(quelle),
         "-af", f"{filter_},volume={anheben:.2f}dB", "-c:a", "pcm_s16le", "-f", "caf",
         str(ZIEL / eintrag["datei"])], check=True)


def musik(eintrag: dict, quelle: pathlib.Path) -> None:
    filter_ = f"loudnorm=I={MUSIK_LUFS}:TP=-1.5:LRA=11,aresample=44100"
    if "dauer" in eintrag:
        filter_ = f"atrim=0:{eintrag['dauer']},afade=t=out:st={eintrag['dauer'] - 2}:d=2," + filter_
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(quelle), "-af", filter_,
         "-c:a", "aac", "-b:a", "128k", "-ac", "2", "-movflags", "+faststart",
         str(ZIEL / eintrag["datei"])], check=True)


def kanaele(datei: pathlib.Path) -> int:
    aus = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0", "-show_entries",
                          "stream=channels", "-of", "csv=p=0", str(datei)],
                         capture_output=True, text=True, check=True).stdout
    return int(aus.strip())


def main(nur: list[str]) -> None:
    liste = json.loads(LISTE.read_text())
    ZIEL.mkdir(parents=True, exist_ok=True)
    for art, bauen in (("klaenge", klang), ("musik", musik)):
        for eintrag in liste[art]:
            if nur and eintrag["datei"] not in nur:
                continue
            quelle = liste["quellen"][eintrag["quelle"]]
            datei = laden(quelle)
            if datei.suffix == ".zip":
                datei = auspacken(datei, eintrag["pfad"])
            bauen(eintrag, datei)
            print("✓", eintrag["datei"])


if __name__ == "__main__":
    main(sys.argv[1:])
