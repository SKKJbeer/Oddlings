# Türme zielen (A-5 Teil 3) — Entstehung

Konzept: [a-5-tuerme-zielen.md](../../docs/konzepte/a-5-tuerme-zielen.md). Werkzeug wie in
[art/phase-2/ENTSTEHUNG.md](../phase-2/ENTSTEHUNG.md): FLUX.1-schnell GGUF Q4_0 (Apache 2.0)
über stable-diffusion.cpp, 4 Schritte, 512 × 512; freigestellt mit rembg isnet-general-use
(Apache 2.0, `freistellen.py`), in den Atlas mit `atlas.py <frei> <name> 1.9 0.2`, Schatten
neu mit `turmboden.py`.

## Wachtürme ohne Armbrust (D-185)

Der Schütze steht jetzt als eigene Figur auf der Plattform; die gemalte Armbrust musste aus
dem Bild. Maskiertes Bild-zu-Bild aus dem bisherigen Rohbild: Die Maske deckt nur die
Plattform mit der Armbrust (Rechteck im 512er-Rohbild), Stärke 0,85, Seed 11. Alles außerhalb
der Maske bleibt das alte Bild, Maßstab und Fuß ändern sich nicht (gleiche Freistellgröße).
Prompt: Stil wie Phase 2, dazu der Turm mit „empty round wooden platform … nothing standing
on the platform“. Dateien `<name>-rohbild.png`, `<name>-frei.png` hier.

| Name | Vorlage | Maske (x0, y0, x1, y1) |
|---|---|---|
| `tower_watch` | art/spielfeld/tower_watch-rohbild.png | 194, 60, 313, 142 |
| `tower_watch_2` | art/phase-2/tower_watch_2-rohbild.png | 176, 76, 314, 156 |
| `tower_watch_volley` | art/phase-2/tower_watch_volley-rohbild.png | 174, 125, 355, 205 |
| `tower_watch_falcon` | art/phase-2/tower_watch_falcon-rohbild.png | 170, 22, 348, 156 |

`tower_watch` hat dabei eine zweite, kleine Fahne bekommen; sie bleibt, der Turm liest sich
damit eher besser. `tower_watch_2` hat statt der Plattform jetzt einen eingetieften Wehrgang;
der Schütze steht darin hinter der Brüstung (Fußpunkt in `App/Battle/turmkronen.json`).
