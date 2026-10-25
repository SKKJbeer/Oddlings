#!/usr/bin/env python3
"""Prüft relative Verweise in den Markdown-Dokumenten: Datei vorhanden, Anker vorhanden.

Die Dokumente verweisen aufeinander statt sich zu wiederholen (CLAUDE.md, „eine
Stelle je Entscheidung"). Ein toter Verweis heißt dann, dass eine Entscheidung
nicht mehr auffindbar ist. Anker werden wie bei GitHub gebildet.
"""
import os
import re
import subprocess
import sys

VERWEIS = re.compile(r"\]\(([^)#\s]*)(#[^)\s]*)?\)")
CODEBLOCK = re.compile(r"```.*?```", re.S)


def anker(ueberschrift: str) -> str:
    text = ueberschrift.strip().lower()
    text = re.sub(r"[^\w\- ]", "", text)
    return text.replace(" ", "-")


def anker_von(pfad: str) -> set:
    text = CODEBLOCK.sub("", open(pfad, encoding="utf-8").read())
    return {anker(z.lstrip("#")) for z in text.splitlines() if z.startswith("#")}


def main() -> int:
    dateien = subprocess.run(["git", "ls-files", "*.md"], capture_output=True,
                             text=True, check=True).stdout.split()
    fehler = []
    for datei in dateien:
        text = CODEBLOCK.sub("", open(datei, encoding="utf-8").read())
        for treffer in VERWEIS.finditer(text):
            pfad, ziel_anker = treffer.group(1), treffer.group(2)
            if re.match(r"^[a-z]+:", pfad):
                continue
            ziel = os.path.normpath(os.path.join(os.path.dirname(datei), pfad)) if pfad else datei
            if not os.path.exists(ziel):
                fehler.append(f"{datei}: Datei fehlt: {pfad}")
            elif ziel_anker and ziel.endswith(".md") and ziel_anker[1:] not in anker_von(ziel):
                fehler.append(f"{datei}: Anker fehlt: {pfad}{ziel_anker}")
    for f in fehler:
        print(f"✗ {f}")
    return 1 if fehler else 0


if __name__ == "__main__":
    sys.exit(main())
