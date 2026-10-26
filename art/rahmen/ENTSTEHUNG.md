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

## Titelbild Hauptmenü

`ui_keyart_menu` (2796 × 1290 px, JPEG, Ordner UI) ist zusammengesetzt, nicht in einem Stück gemalt.
Hintergrund `ui_keyart_menu-hintergrund.png`: FLUX.1-schnell, Seed 11, 1024 × 576, Prompt
„stylized 3D cartoon fantasy landscape key art for a mobile strategy game, hand-painted textures,
vibrant saturated colors, golden hour, warm sunlight from the right, volumetric light rays, a lush
whispering fairy forest with giant glowing mushrooms in the background, a winding dirt road climbing
from the lower left to an empty grassy hilltop on the right, soft glowing spores in the air, dramatic
clouds, deep perspective, no characters, no buildings, no towers, no text, no letters“, mit Real-ESRGAN
x4 (anime 6B, BSD-3) hochgerechnet. Darauf die Spielfiguren aus `art/spielfeld/` (`*-frei.png`, ebenfalls
x4 hochgerechnet, Alpha aus dem Original): Festung auf dem Hügel, drei Türme am Weg, Plünderer,
Panzerbestie und Flitzer im Anmarsch. Lage, Kontaktschatten, warmes Licht und Dunst setzt
`.claude/skills/spielgrafik/scripts/titelbild.py`. Rechts liegt in der App die Holzblende mit den Knöpfen
(`MainMenuView`), deshalb steht alles Wichtige in der linken Hälfte.

**Verworfen:** erste Fassung frei gemalt (andere Figuren, anderer Stil als im Spiel); zweite per
Bild-zu-Bild über eine flache Vorlage (Flash-Optik); dritte per Bild-zu-Bild über die Montage bei
Stärke 0,3 und 0,4 (beide gleich, das Modell malte eine eigene Szene mit einem Troll statt unserer Figuren).
