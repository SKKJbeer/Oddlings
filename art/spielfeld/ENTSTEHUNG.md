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
| `fortress` | a mighty dwarven-built stone fortress with a massive arched wooden gate, thick crenellated walls of warm grey stone, two round corner towers with pointed dark blue slate roofs, red and gold banners, glowing warm torches beside the gate, moss and ivy on the stones | **Seed 31** (Grafik 05, 26.10.2026; Seed 32 verworfen: Fass und Fackelständer als Fremdkörper). Vorher Seed 11 mit flachem Torhaus |
| `enemy_raider` | a small mischievous goblin raider with green skin and a brown leather hood, carrying a loot sack over the shoulder and a wooden club | gespiegelt: trotz „facing right" nach links gemalt |
| `enemy_runner` | a small skinny fast imp with orange skin, long pointy ears and a flowing red scarf, sprinting and leaning forward | gespiegelt |
| `enemy_brute` | a hulking armored beast, a bulky boar-like creature with tusks, curved horns and riveted iron armor plates | gespiegelt |

**Beobachtet:** „facing right" wirkt bei FLUX kaum; alle drei Gegner blickten
nach links. Spiegeln ist billiger als neu rechnen. Ein freier Kartenentwurf
(Bild-zu-Bild mit Stärke 0,7) wich vom Weg ab und wirkte flach; verworfen,
die Karte entsteht aus Texturen, siehe [karten/ENTSTEHUNG.md](../karten/ENTSTEHUNG.md).

## Schatten und Fundament der Türme (D-120, 0.29.1)

Gerechnet, nicht gemalt: `.claude/skills/spielgrafik/scripts/turmboden.py`, kein
Modell, fester Seed je Name. Konzept: [Türme in der Welt](../../docs/konzepte/grafik-10-tuerme-in-der-welt.md).

- Schatten `tower_watch_shadow`, `tower_watch_2_shadow`, `tower_lightning_shadow`,
  `tower_lightning_2_shadow`, `tower_spore_shadow`, `tower_spore_2_shadow`,
  `tower_bank_shadow`, seit A-5 auch `tower_watch_volley_shadow`, `tower_watch_falcon_shadow`,
  `tower_lightning_crown_shadow`, `tower_lightning_spark_shadow`, `tower_spore_moor_shadow`,
  `tower_spore_rot_shadow`: aus dem Umriss des jeweiligen Turmbildes, oberhalb des
  Fußes gespiegelt, auf 42 % gestaucht und nach rechts geschert (Licht von oben
  links), weich gezeichnet, dazu eine Kontaktellipse am Fuß. Neuer Turm oder neue
  Stufe: Skript erneut laufen lassen.
- Fundament `footing_mission01`, `footing_mission02`, `footing_mission03`,
  `footing_mission04`, `footing_mission05a`, `footing_mission05b`,
  `footing_mission06a`, `footing_mission06b`, `footing_mission07`: ein unregelmäßiger
  Fleck aus dem gemalten Weg der jeweiligen Karte (Mitte des längsten waagerechten
  Wegstücks), weicher Rand. Neuer Kampfplatz: Skript erneut laufen lassen.

## Pilzbalg und Sporling, gemalte Standbilder (0.41.0)

Für die Gegnerrolle Teiler (D-143, [Konzept](../../docs/konzepte/a-6-heiler-und-teiler.md)).
FLUX.1-schnell Q4_0 (Apache 2.0), euler, 4 Schritte, cfg 1,0, 512 × 512, freigestellt mit
`freistellen.py` (isnet-general-use, Kontur Standard), in den Atlas mit `atlas.py`
(Seite und Anker aus dem Vertrag). Die 3D-Figuren nach der Kette von A-3 folgen, sobald
das Rechenkontingent von TRELLIS wieder frei ist; bis dahin laufen beide mit der
Gangart aus `FxStyle`.

- `enemy_puffball` (`enemy_puffball-rohbild.png`, `enemy_puffball-frei.png`): Seed 11.
  Prompt: "a round fat puffball mushroom creature, its whole body is one big bloated pale
  beige mushroom ball with brown spots and cracks leaking faint green spore dust, a small
  grumpy face with tiny dark eyes in the front of the ball, short stubby legs and two tiny
  stubby arms, stylized 3D cartoon character render, hand-painted textures, chunky
  proportions, vibrant saturated colors, soft even studio light, highly detailed, no
  outlines, full body, standing straight, three-quarter view, arms held slightly away from
  the body, centered, on a plain flat light grey background, no ground, no shadow, no
  text, no letters". Seed 12 verworfen: Gesicht weicher, weniger Flecken.
- `enemy_sporeling` (`enemy_sporeling-rohbild.png`, `enemy_sporeling-frei.png`): Seed 12.
  Prompt: "a tiny mischievous mushroom sprite, a small pale beige mushroom cap with brown
  spots on a thin white stalk body, skinny little arms and legs, a small grinning face
  with two black dot eyes under the cap", dann derselbe Stilteil wie beim Pilzbalg.
  Seed 11 verworfen: langer dünner Stiel, Arme vor dem Bauch, das Gesicht sitzt klein auf
  dem Hut. Gleiche Kappe wie der Pilzbalg, damit man sieht, woher er kommt.
