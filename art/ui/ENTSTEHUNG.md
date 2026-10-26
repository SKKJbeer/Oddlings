# UI-Symbole — Entstehung

Konzept: [grafik-02-phase-2.md](../../docs/konzepte/grafik-02-phase-2.md). Werkzeug wie in
[art/spielfeld/ENTSTEHUNG.md](../spielfeld/ENTSTEHUNG.md): FLUX.1-schnell GGUF Q4_0
(Apache 2.0) über stable-diffusion.cpp, 4 Schritte, 512 × 512. Freigestellt mit rembg,
Modell isnet-general-use (Apache 2.0), Kontur 0,9 % in #22160F (`freistellen.py`).
Bild-zu-Bild: Vorlage ist das Rohbild des Grundturms aus `art/spielfeld/`, Stärke wie angegeben.

Dateien: `<name>-rohbild.png` (wie gemalt), `<name>-frei.png` (freigestellt). In den Katalog
kommen sie mit dem Arbeitspaket, das sie anzeigt.

| Name | Seed | Vorlage, Stärke | Prompt |
|---|---|---|---|
| `ui_icon_heart` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, a chunky heart shaped red ruby gem set in a thick hammered gold frame with rivets |
| `ui_icon_gold` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, a heap of chunky raw gold nuggets with a few sparkles, no base, no plate |
| `ui_icon_sell` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, bright warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, a small cream white cloth coin sack tied with a red string, a few plain blank round gold coins spilling out |
| `ui_icon_wave` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, bright warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, a large bright red battle flag on a short pole crossed with a goblin war club with a grey iron spiked head |
| `ui_icon_pause` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, bright warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, two thick vertical rounded bars of polished bright gold side by side with small dark iron caps |
| `ui_icon_next_wave` | 41 | – | mobile strategy game UI icon, stylized 3D cartoon render, hand-painted textures with visible brush strokes, chunky shape, thick dark brown outline, vibrant saturated colors, bright warm rim light, light from top left, single isolated object centered, on a plain flat light grey background, no text, no letters, no numbers, no symbols, a curved ivory white war horn with polished gold bands and a red cord |

**Verworfen:** `ui_icon_pause`, `ui_icon_sell`, `ui_icon_wave`, `ui_icon_next_wave` erste Fassung (Seed 31 bzw. 41: Holz und Leder auf der dunklen Holzleiste kaum zu sehen; neu in Gold, Leinen, Rot und Elfenbein), `ui_icon_heart` erste Fassung (glattes Glanzherz ohne Malstruktur und Kontur, Stockbild-Optik), `ui_icon_gold` (Goldbarren auf einer Platte, las sich wie Schokolade), `ui_icon_sell` (Münzen mit Dollarzeichen; keine Währungszeichen im Spiel).

**Turmsymbole fürs Baumenü:** `ui_tower_watch`, `ui_tower_lightning`, `ui_tower_spore` sind keine
eigenen Bilder, sondern die freigestellten Turmbilder aus `art/spielfeld/` (`tower_<turm>-frei.png`),
mittig auf 40 pt gesetzt (`atlas.py … 40pt mitte`). Eine Quelle, damit Menü und Spielfeld nie
auseinanderlaufen.
