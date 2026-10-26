# Plünderer: Vorlage für das 3D-Modell (FX 02)

Gemalt vom Grafik-Thread am 26.10.2026 als Eingang für TRELLIS. Nicht im Atlas.

**Figur** (`vorlage.png`, aus `vorlage-rohbild.png`): FLUX.1-schnell Q4_0
(Apache 2.0), euler, 4 Schritte, Seed 32, 576 × 1024. Prompt: "a small
mischievous goblin raider with green skin, big pointed ears, a big round nose and
two small lower fangs, wearing a brown leather pointed hood with a metal rivet, a
brown leather jerkin with a belt and buckle, short dark trousers and brown leather
boots, standing straight in a relaxed A-pose, legs slightly apart, arms held
slightly away from the body, open empty hands, no weapon, no sack, single isolated
full body character centered in frame, three-quarter front view, on a plain flat
light grey background, mobile strategy game asset, stylized 3D cartoon render,
hand-painted textures, chunky proportions, vibrant saturated colors, warm rim
light, light from top left, highly detailed, no ground, no text, no letters".
Freigestellt mit `freistellen.py` (isnet-general-use, Kontur 0), weil TRELLIS eine
Kontur in die Textur backen würde.

**Requisiten** (`requisit-keule.png`, `requisit-sack.png`, aus
`requisiten-rohbild.png`): gleiche Einstellungen, Seed 33, 768 × 512. Prompt: "two
separate game props side by side on a plain flat light grey background: a short
wooden club with an iron band, and a bulging brown burlap loot sack tied with
rope, <gleicher Stil>, each isolated, no ground, no text, no letters". Zerlegt mit
`zerlegen.py`.

**Abweichungen vom Spielbild:** Das Gesicht ist freundlicher als beim gemalten
Plünderer, die Keule ist ein dünner Stab statt der dunklen Keule mit Eisenband.
Farben werden nach dem Rendern mit `angleichen.py` an das Spielbild angeglichen.
