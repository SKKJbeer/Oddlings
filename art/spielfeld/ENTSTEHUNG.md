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
| `fortress` (bis 0.45.0) | a mighty dwarven-built stone fortress with a massive arched wooden gate, thick crenellated walls of warm grey stone, two round corner towers with pointed dark blue slate roofs, red and gold banners, glowing warm torches beside the gate, moss and ivy on the stones | **Seed 31** (Grafik 05, 26.10.2026; Seed 32 verworfen: Fass und Fackelständer als Fremdkörper). Vorher Seed 11 mit flachem Torhaus |
| `enemy_raider` | a small mischievous goblin raider with green skin and a brown leather hood, carrying a loot sack over the shoulder and a wooden club | gespiegelt: trotz „facing right" nach links gemalt |
| `enemy_runner` | a small skinny fast imp with orange skin, long pointy ears and a flowing red scarf, sprinting and leaning forward | gespiegelt |
| `enemy_brute` | a hulking armored beast, a bulky boar-like creature with tusks, curved horns and riveted iron armor plates | gespiegelt |

**Beobachtet:** „facing right" wirkt bei FLUX kaum; alle drei Gegner blickten
nach links. Spiegeln ist billiger als neu rechnen. Ein freier Kartenentwurf
(Bild-zu-Bild mit Stärke 0,7) wich vom Weg ab und wirkte flach; verworfen,
die Karte entsteht aus Texturen, siehe [karten/ENTSTEHUNG.md](../karten/ENTSTEHUNG.md).

## Schatten der Türme (D-120, 0.29.1; seit 0.49.0 am Grundriss, D-196)

Gerechnet, nicht gemalt: `.claude/skills/spielgrafik/scripts/turmboden.py`, kein
Modell, fester Seed je Name. Konzept: [Türme in der Welt](../../docs/konzepte/grafik-10-tuerme-in-der-welt.md).

- Schatten `tower_watch_shadow`, `tower_watch_2_shadow`, `tower_lightning_shadow`,
  `tower_lightning_2_shadow`, `tower_spore_shadow`, `tower_spore_2_shadow`,
  `tower_bank_shadow`, seit A-5 auch `tower_watch_volley_shadow`, `tower_watch_falcon_shadow`,
  `tower_lightning_crown_shadow`, `tower_lightning_spark_shadow`, `tower_spore_moor_shadow`,
  `tower_spore_rot_shadow`: aus dem Umriss des jeweiligen Turmbildes. Seit 0.49.0 misst
  das Skript zuerst den Grundriss im Bild (halbe Breite, halbe Tiefe aus der Krümmung der
  Fußlinie). Der Umriss über der Grundrissmitte wird nach unten geklappt, auf 42 %
  gestaucht und um 45° nach rechts geschert (wie der Schatten der Torburg aus Blender),
  am Fuß scharf und mit 62 % Deckung, zur Spitze weich mit 40 % (Kontakthärtung). Dazu
  ein Kontaktdunkel in Größe des Grundrisses (× 1,12, 85 %), um dessen Mitte: Vom Turm
  verdeckt bis auf einen Saum an der Fußlinie. Bis 0.47.0 saßen Ellipse und Schatten am
  Anker, dem vordersten Punkt; das dunkle Band davor ließ den Turm schweben. Neuer Turm
  oder neue Stufe: Skript erneut laufen lassen.
- Fundament `footing_<mission>` (0.29.1 bis 0.45.0): Fleck Erde aus dem Weg der Karte;
  mit D-196 entfernt.

## Pilzbalg und Sporling, gemalte Vorlagen (0.42.0, seit 0.43.0 Vorlage der 3D-Figuren)

Für die Gegnerrolle Teiler (D-143, [Konzept](../../docs/konzepte/a-6-heiler-und-teiler.md)).
FLUX.1-schnell Q4_0 (Apache 2.0), euler, 4 Schritte, cfg 1,0, 512 × 512, freigestellt mit
`freistellen.py` (isnet-general-use, Kontur Standard). In 0.42.0 standen sie als
Standbilder im Atlas; seit 0.43.0 sind sie die Vorlagen der 3D-Figuren
([Pilzbalg](../figuren-3d/enemy_puffball/ENTSTEHUNG.md),
[Sporling](../figuren-3d/enemy_sporeling/ENTSTEHUNG.md)), die Standbilder kommen von dort.

- Pilzbalg (`enemy_puffball-rohbild.png`, `enemy_puffball-frei.png`): Seed 11.
  Prompt: "a round fat puffball mushroom creature, its whole body is one big bloated pale
  beige mushroom ball with brown spots and cracks leaking faint green spore dust, a small
  grumpy face with tiny dark eyes in the front of the ball, short stubby legs and two tiny
  stubby arms, stylized 3D cartoon character render, hand-painted textures, chunky
  proportions, vibrant saturated colors, soft even studio light, highly detailed, no
  outlines, full body, standing straight, three-quarter view, arms held slightly away from
  the body, centered, on a plain flat light grey background, no ground, no shadow, no
  text, no letters". Seed 12 verworfen: Gesicht weicher, weniger Flecken.
- Sporling (`enemy_sporeling-rohbild.png`, `enemy_sporeling-frei.png`): Seed 12.
  Prompt: "a tiny mischievous mushroom sprite, a small pale beige mushroom cap with brown
  spots on a thin white stalk body, skinny little arms and legs, a small grinning face
  with two black dot eyes under the cap", dann derselbe Stilteil wie beim Pilzbalg.
  Seed 11 verworfen: langer dünner Stiel, Arme vor dem Bauch, das Gesicht sitzt klein auf
  dem Hut. Gleiche Kappe wie der Pilzbalg, damit man sieht, woher er kommt.


## Grafik 11: Torburg (24.11.2026, 0.47.0; Sockel und Kontakt bis 0.47.0)

Konzept: [Grafik 11](../../docs/konzepte/grafik-11-kampfplatz-in-der-welt.md), D-190, D-191,
D-193. Nicht mehr frei gemalt, sondern zuerst in Blender gebaut
(`tools/kampfplatz-3d/bauten.py`, Vertragskamera 40°, Sonne 135°/45°, Rahmen und Anker
aus dem Vertrag), dann mit FLUX.1-schnell Bild-zu-Bild übermalt (512 × 512, 4 Schritte,
euler, cfg 1,0) und mit `bau_freistellen.py` freigestellt: Form und Schatten aus Blender,
Farbe aus FLUX. In den Atlas mit `atlas.py … rahmen` (nur skaliert, nicht zugeschnitten).
Quellen in `bauten/` (`*-blender.png` Render, `*-rohbild.png` übermalt). Sockel
(`tower_plinth`, Seed 3) und Kontakt (`tower_contact`) gab es nur in 0.47.0; mit D-196
sind sie entfernt, ihre Quellen bleiben in `bauten/` als Beleg.

| Name | Prompt | Einstellungen |
|---|---|---|
| `fortress` | hand-painted mobile strategy game building asset, a small grey stone dwarf fortress gatehouse with two round towers with blue slate cone roofs and red flags, battlements, an arched wooden gate with two burning torches and a red banner above it, stone base with grass tufts, seen from above at a 40 degree angle, stylized 3D, warm afternoon light from the top left, rich painterly textures, high detail, plain flat light grey background, no text, no characters | **Seed 8**, Stärke 0,5; Rahmen 4,0 Zellen, Anker 0,34 = Mitte des Grundrisses. Erster Rahmen (3,6/0,2) schnitt die Sockelecke ab, neu gerendert; Seed 3 nicht fertig (Speicher) |
| `fortress_shadow` | – | Schattenfänger desselben Renders, schwarz mit 80 % der Deckung, am Bildrand ausgeblendet, nur der am Bau hängende Teil |
