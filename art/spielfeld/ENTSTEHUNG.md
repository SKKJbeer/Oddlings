# Spielfeld-Assets — Entstehung

Stil D-016 („Stylized 3D"), Konzept je Figur in
[docs/art/figuren.md](../../docs/art/figuren.md). Werkzeug
`.claude/skills/spielgrafik`: FLUX.1-schnell GGUF Q4_0 (Apache 2.0) über
stable-diffusion.cpp, `--cfg-scale 1.0 --sampling-method euler --steps 4`,
512 × 512, **Seed 11**. Freigestellt mit rembg, Modell isnet-general-use
(Apache 2.0), Kontur 0,9 % der Bildhöhe in #22160F (`freistellen.py`).
In den Atlas mit `atlas.py` (Höhe in Zellen laut `art/asset-vertrag.json`).

Dateien: `<name>-rohbild.png` (wie gemalt), `<name>-frei.png` (freigestellt,
Quelle des Atlas).

Gemeinsamer Stil-Teil:

```
mobile strategy game asset, stylized 3D cartoon render, hand-painted textures, chunky proportions, bold dark outlines, vibrant saturated colors, warm rim light, light from top left, highly detailed
```

Türme und Festung enden mit:
```
single isolated object centered in frame, seen from above at a 45 degree three-quarter angle, on a plain flat light grey background, small soft contact shadow, no ground, no text, no letters
```

Gegner enden mit:
```
single isolated full body character centered in frame, side three-quarter view from slightly above, facing right, walking, on a plain flat light grey background, small soft contact shadow, no ground, no text, no letters
```

| Name | Motiv-Teil | Nachbearbeitung |
|---|---|---|
| `tower_watch` | a sturdy round watchtower of warm grey stone with a wooden archer platform on top, a mounted crossbow and a red pennant flag | – |
| `tower_lightning` | a slender round stone tower with copper rings, crowned by a large floating glowing blue crystal with crackling electric sparks | Funken oberhalb des Kupferrings (Bildzeilen 0–199) von Orange (Farbton 0,02–0,18, s > 0,25, v > 0,5) auf Blau 0,53 gedreht: Blitz ist in der Farbwelt blau |
| `tower_spore` | a giant mushroom tower with a big purple cap covered in glowing green spots, a chubby cream stem with a small round wooden door, puffs of glowing green spores rising | – |
| `fortress` | a small sturdy fortress gatehouse of grey stone and dark wood with two red banners and a big closed wooden gate | – |
| `enemy_raider` | a small mischievous goblin raider with green skin and a brown leather hood, carrying a loot sack over the shoulder and a wooden club | gespiegelt: trotz „facing right" nach links gemalt |
| `enemy_runner` | a small skinny fast imp with orange skin, long pointy ears and a flowing red scarf, sprinting and leaning forward | gespiegelt |
| `enemy_brute` | a hulking armored beast, a bulky boar-like creature with tusks, curved horns and riveted iron armor plates | gespiegelt |

**Beobachtet:** „facing right" wirkt bei FLUX kaum; alle drei Gegner blickten
nach links. Spiegeln ist billiger als neu rechnen. Ein freier Kartenentwurf
(Bild-zu-Bild mit Stärke 0,7) wich vom Weg ab und wirkte flach; verworfen,
die Karte entsteht aus Texturen, siehe [karten/ENTSTEHUNG.md](../karten/ENTSTEHUNG.md).
