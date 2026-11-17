"""Erzeugt ein GLB aus einer freigestellten Figurenvorlage über die Space trellis-community/TRELLIS.

Aufruf: python -I trellis.py <vorlage.png> <modell.glb> [seed]
Der Zugang kommt aus HF_TOKEN; ohne ihn ist das ZeroGPU-Kontingent dieser Umgebung 0.
"""
import os
import shutil
import sys

import httpx

from gradio_client import Client, handle_file

SPACE = "trellis-community/TRELLIS"


def main() -> None:
    vorlage, ziel = sys.argv[1], sys.argv[2]
    seed = int(sys.argv[3]) if len(sys.argv) > 3 else 1
    token = os.environ.get("HF_TOKEN") or None
    # Nur das GLB laden: Die Space liefert das Vorschauvideo inzwischen mit 403 aus,
    # und das automatische Herunterladen aller Ausgaben bräche daran ab.
    client = Client(SPACE, token=token, download_files=False)
    # Die Space legt je Sitzung ein Arbeitsverzeichnis an; ohne diesen Aufruf fehlt es.
    client.predict(api_name="/start_session")
    ergebnis = client.predict(
        image=handle_file(vorlage),
        multiimages=[],
        seed=seed,
        ss_guidance_strength=7.5,
        ss_sampling_steps=12,
        slat_guidance_strength=3,
        slat_sampling_steps=12,
        multiimage_algo="stochastic",
        mesh_simplify=0.95,
        texture_size=1024,
        api_name="/generate_and_extract_glb",
    )
    glb = next(p for p in _pfade(ergebnis) if p.endswith(".glb") and (p.startswith("http") or os.path.exists(p)))
    if os.path.exists(glb):
        shutil.copyfile(glb, ziel)
    else:
        kopf = {"Authorization": f"Bearer {token}"} if token else {}
        with httpx.stream("GET", glb, headers=kopf, follow_redirects=True, timeout=300) as antwort:
            antwort.raise_for_status()
            with open(ziel, "wb") as datei:
                for stueck in antwort.iter_bytes():
                    datei.write(stueck)
    print(ziel)


def _pfade(wert):
    if isinstance(wert, (list, tuple)):
        for teil in wert:
            yield from _pfade(teil)
    elif isinstance(wert, dict):
        for teil in wert.values():
            yield from _pfade(teil)
    elif isinstance(wert, str):
        yield wert


if __name__ == "__main__":
    main()
