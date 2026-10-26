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

**Modell** (`modell.glb`, 26.10.2026): `tools/figuren-3d/trellis.py vorlage.png
modell.glb 1` gegen die Space `trellis-community/TRELLIS` (TRELLIS, Microsoft,
MIT-Lizenz), gradio_client 2.7.2, Seed 1, SS 7,5/12, SLat 3/12, mesh_simplify
0,95, Textur 1024. Hochladen der Vorlage von Steffen freigegeben. Ergebnis: ein
Netz mit 13 809 Punkten in 367 Inseln (Texturnähte), Material mit Metallic 1;
beides gleicht `figur.py` beim Laden aus (Verschweißen, Metallic 0).
Sack und Keule fehlen noch am Modell.

**Skelett** (`rig.json`): Gelenkpunkte von Hand aus vier Ansichten des Modells
gesetzt, Arme per `ruhe` 35° an den Körper gelegt, Licht heller als Standard,
weil die Textur dunkel ausfällt. Erster Render: `art/fx-02/raider-erster-render.jpg`
(Helligkeit 1,35, Sättigung 1,45 und Kontur nur für die Vorschau, der echte
Farbangleich kommt mit `angleichen.py`).
