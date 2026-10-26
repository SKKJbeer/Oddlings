# Spielrahmen — Entstehung

Konzept: [grafik-02-phase-2.md](../../docs/konzepte/grafik-02-phase-2.md). Werkzeug wie in
[art/spielfeld/ENTSTEHUNG.md](../spielfeld/ENTSTEHUNG.md): FLUX.1-schnell GGUF Q4_0
(Apache 2.0) über stable-diffusion.cpp, 4 Schritte, 512 × 512. Freigestellt mit rembg,
Modell isnet-general-use (Apache 2.0), Kontur 0,9 % in #22160F (`freistellen.py`).
Bild-zu-Bild: Vorlage ist das Rohbild des Grundturms aus `art/spielfeld/`, Stärke wie angegeben.

Dateien: `<name>-rohbild.png` (wie gemalt), `<name>-frei.png` (freigestellt). In den Katalog
kommen sie mit dem Arbeitspaket, das sie anzeigt.

| Name | Seed | Vorlage, Stärke | Prompt |
|---|---|---|---|
| `banner_race_dwarves` | 11 | – | mobile strategy game key art, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, highly detailed, a hanging heraldic cloth banner on a wooden pole, deep red and brass, embroidered with a stylized anvil and a crossed hammer, gold trim and tassels, single isolated object centered, on a plain flat light grey background, no text, no letters |
| `banner_race_elves` | 41 | – | mobile strategy game key art, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, highly detailed, a hanging heraldic cloth banner on a carved wooden pole, deep forest green and silver, embroidered with a silver stylized oak tree whose branches form a circle, silver trim and tassels, single isolated object centered, on a plain flat light grey background, no text, no letters |

**Verworfen:** `banner_race_elves` erste Fassung (weiße Mondsichel auf Grün, zu nah an einer religiösen Flagge). Neu mit Eichenbaum im Kreis.
