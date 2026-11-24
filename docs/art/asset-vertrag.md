# Asset-Vertrag zwischen Grafik und Szene

Status: **[VORSCHLAG]**, mit dem Simulations-Thread abgestimmt (25.10.2026).
Stil und Farbwelt stehen in [art-direction.md](art-direction.md); hier steht nur,
was die Szene (WP-11 ff.) über die Bilder wissen muss.

## Ablage

| Was | Wo |
|---|---|
| Spielfertige Bilder | `App/Assets.xcassets/Battle.spriteatlas/<name>.imageset`, PNG mit Alpha, @2x und @3x |
| Rohbilder, Prompts, Seeds | `art/<bereich>/`, je Bereich eine `ENTSTEHUNG.md`. Nicht im App-Bundle |
| Werkzeuge | `.claude/skills/spielgrafik/` (aus Fortress übernommen und angepasst) |

Die Szene kennt nur die Namen. Ein Austausch der Grafik ist ein Atlas-Wechsel,
keine Code- und keine Regeländerung.

## Namen

Sie folgen den IDs der Simulation.

| Name | Inhalt |
|---|---|
| `tower_watch`, `tower_lightning`, `tower_spore` | Türme, ganzer Körper |
| `tower_<id>_2` | Stufe 2 (Anbau auf dem Grundturm) |
| `tower_watch_volley`, `tower_watch_falcon`, `tower_lightning_crown`, `tower_lightning_spark`, `tower_spore_moor`, `tower_spore_rot` | Spezialisierungen (Stufe 3), aus dem Rohbild der Stufe 2 nachgemalt; fehlt eines, zeigt die Szene das Bild der Stufe darunter ([A-5](../konzepte/a-5-spezialisierungen-und-ringe.md), D-170) |
| `tower_<id>_top` | drehbares Oberteil, nur wo es eines gibt |
| `enemy_raider`, `enemy_runner`, `enemy_brute`, `enemy_moorKing` | Gegner, Blick nach rechts |
| `enemy_<art>_<folge>_NN` | Bildfolgen aus 3D ([FX 02](../konzepte/fx-02-figuren-in-3d.md)): `walk`, `hit`, `die`; der Moorkönig dazu `shield` und `summon` ([FX 03](../konzepte/fx-03-moorkoenig.md)). Anzahl je Folge im Feld `folge`. Blickrichtungen (A-3): `walkFront` (auf den Betrachter zu), `walkBack` (weg), gleiche Bildzahl, Größe und Anker wie `walk`, Fuß je Richtung auf dem Anker. Dazu oben im Vertrag `kamera`, `sonne` (D-140) und `konturPunkte` (Breite der Außenlinie jeder Bildfolge) Rückfall (A-1, D-150): fehlt `walkFront` oder `walkBack`, läuft die Seitenfolge `walk` |
| `fortress` | Torhaus der Torburg am Wegende, Quadrat 4,0 Zellen, Anker 0,34 = Mitte des Grundrisses (`grundriss`, nicht die unterste Zeile), in Vertragskamera gedreht (Gier aus `festung`); Mauern und Vorplatz liegen im Bodenbild (Grafik 11, D-191) |
| `map_mission01_ground` … `map_mission04_ground`, `map_mission05a_ground`, `map_mission05b_ground`, `map_mission06a_ground`, `map_mission06b_ground`, `map_mission07_ground` | Boden der ganzen Karte je Mission (Name aus der Missionskennung), Weg eingemalt; Geometrie je Bild in `art/asset-vertrag.json` unter `mission` ([Grafik 06](../konzepte/grafik-06-kampfplaetze-m2-m4.md), [Grafik 07](../konzepte/grafik-07-kampfplaetze-m5.md), [Grafik 08](../konzepte/grafik-08-kampfplaetze-m6.md), [Grafik 09](../konzepte/grafik-09-bosslichtung-m7.md)) |
| `buildzone_tile` | Markierung einer bebaubaren Zelle, Overlay (heute von der Szene gezeichnet, nur beim Bauen sichtbar, D-121) |
| `tower_guard_shoot<r>_NN`, `tower_guardElf_shoot<r>_NN` | Schütze auf dem Wachturm (A-5 Teil 3, D-185), Zwerg mit Armbrust bzw. Elf mit Bogen nach dem Volk des Avatars; fehlen die Elfenbilder, steht der Zwerg da: acht Richtungen `r = 0…7` (0 = rechts, gegen den Uhrzeigersinn je 45°, die Figur gedreht vor fester Kamera und Sonne), je fünf Bilder; 00 ist der Anschlag, 01 bis 04 der Schuss. Quadrat 0,62 Zellen, Fuß bei 0,1, alle Richtungen mit gleichem Vertrag. Wo er auf dem Turmbild steht und wo der Pilzhut ansetzt, steht in `App/Battle/turmkronen.json` |
| `tower_<name>_shadow` | Schatten je Turmbild, Quadrat 2,4 Zellen, Fuß in der Mitte, gerechnet von `turmboden.py` (D-120) |
| `footing_<mission>` | Fundament unter jedem Turm, Quadrat 1,2 Zellen, Fuß in der Mitte, Erde aus dem Weg der Karte (D-120); nur noch Rückfall, wenn `tower_plinth` fehlt |
| `tower_plinth` | Steinsockel unter jedem Turm, Quadrat 1,5 Zellen, Mitte der Platte in der Bildmitte; aus `tools/kampfplatz-3d/bauten.py sockel`, übermalt (Grafik 11, D-190) |
| `fortress_shadow` | Schlagschatten der Torburg, gleiches Quadrat und gleicher Anker wie `fortress`, liegt unter ihm; aus dem Schattenfänger von `bauten.py` (`bau_freistellen.py`, D-191) |
| `tower_contact` | Kontaktdunkel unter dem Fuß, Quadrat 1,4 Zellen, nur Alpha (Mitte 72 %), gerechnet von `turmboden.py` (D-193) |
| `fx_glow`, `fx_spark`, `fx_ring`, `fx_puff`, `fx_coin`, `fx_arrow`, `fx_bolt`, `fx_confetti`, `fx_star`, `fx_stone`, `fx_wall`, `fx_hand` | Effekte, siehe „Effekte“ unten |
| `icon_slowed` | Zustandssymbol über dem Gegner (E3) |
| `mark_ring` | gemalter Streifen 1536 × 96 px (@3x), oben Außenkante, waagerecht kachelbar; die Szene wickelt ihn um Auswahl und Reichweite (`GroundMarks`, D-171) |

## Kamera, Licht, Maße

- **Eine Kamera für alles (D-165):** orthografisch, 40° über dem Boden, ohne
  Gierwinkel; Werte in `art/asset-vertrag.json` unter `kamera`. Damit das Raster der
  Simulation quadratisch bleibt, streckt das Diorama die Tiefe der Szene um 1/sin 40°
  (Kabinettprojektion): Eine Bodenzelle ist im Bild quadratisch, alles mit Höhe zeigt
  seine Seite. Figuren dürfen bis `figurenSpielraum` Grad flacher gerendert sein.
- **Sonne (D-165):** Azimut 135° (links hinten), 45° hoch, unter `sonne`; Schatten
  fallen nach unten rechts. Lichtfarbe je Ort in `App/Battle/kampfplatzlicht.json`.
- **Zielmaßstab (D-166):** `massstab` nennt die sichtbare Höhe in Feldern (Flitzer 0,7 ·
  Plünderer 0,8 · Panzerbestie 1,15 · Turm 1,4 · Boss 2,0 · Festung 2,6). Bilder werden
  von den Paketen umgestellt, die sie malen; `art-check` hält die Reihenfolge.
- **Lage der Festung (D-191):** `festung` nennt `tor` (Zellen hinter dem Kartenrand auf dem
  Weg), `torAbstand` (Fuß hinter dem Tor) und `gier` (Drehung, 0 = Tor zum Betrachter).
  `plan.py` und `FortressPlacement` rechnen damit; `art-check` hält App und Vertrag gleich.
- Maßeinheit ist die Zelle (≈ 43 pt im Querformat, D-004).
- **Figuren sind Quadrate.** Die Szene setzt jedes Bild als Quadrat mit festem
  `anchorPoint`; die Figur steht mittig, ihr Fuß (unterste deckende Zeile) liegt
  auf Höhe des Ankers. Maße in `art/asset-vertrag.json`, `atlas.py` setzt sie,
  die CI prüft Größe und Fußhöhe.
- **Türme:** Seite 1,9 Zellen, Anker (0.5, 0.2). Fußpunkt = Zellmitte; sichtbar
  ist der Turm etwa 1,5 Zellen hoch, der Sockel etwa eine Zelle breit.
- **Festung:** Seite 2,4 Zellen, Anker (0.5, 0.15), am Wegende, um 0,3 Seiten
  nach innen gerückt, damit sie ganz im Bild steht.
- **Gegner:** Blick nach rechts, für Lauf nach links `xScale = -1`.
  Seite 0,9 Zellen (Panzerbestie 1,2), Anker (0.5, 0.1).
- **Karte:** ein Bild für das ganze Feld (16 × 9 Zellen). Koordinaten wie in der
  Simulation: Ursprung oben links, y wächst nach unten. Der Weg (`map.path` in
  `mvp-mission-01.json`) beginnt bei x = −1 und endet bei x = 17, er läuft im
  Bild also bis an beide Ränder. Das Bild entsteht aus einer Vorlage, die aus
  genau dieser Geometrie gezeichnet und dann übermalt wird; deshalb deckt sich
  der gemalte Weg mit dem gerechneten.

## Effekte

Seit FX 01 ([Konzept](../konzepte/fx-01-bewegung-und-effekte.md)) zeichnet die
Szene jede Effekttextur selbst, solange kein Bild im Atlas liegt. Liegt eines
unter dem Namen, nimmt sie das Bild. Alle außer `fx_coin` und `fx_arrow` sind
**weiß bzw. grau** gemalt; die Szene färbt sie ein (Blitzblau, Sporengrün,
Staub, Gegnerfarbe), damit ein Bild für alle Farben reicht.

| Name | Inhalt | Form |
|---|---|---|
| `fx_glow` | weicher Lichtpunkt, auch Schatten unter Gegnern | Quadrat, Mitte hell |
| `fx_spark` | Funke, in Flugrichtung gestreckt | etwa 4,5 : 1, Spitze rechts |
| `fx_ring` | Druckwelle, Sporenring, Staubring | Quadrat, Ring außen, innen weich |
| `fx_puff` | Rauch- und Staubwölkchen, Licht von oben | Quadrat |
| `fx_coin` | Goldmünze ohne Währungszeichen, farbig | Quadrat |
| `fx_arrow` | Pfeil nach rechts, Holz, Eisen, rote Federn, farbig | etwa 4,4 : 1 |
| `fx_bolt` | Querschnitt eines Strahls, wird in die Länge gezogen | hoch, Mitte hell |
| `fx_confetti` | Splitter und Konfetti | etwa 3 : 2 |
| `fx_star` | Betäubungssternchen, farbig mit Kontur | 1 : 1 |
| `fx_stone` | Fels und Splitter des Steinregens, grau, wird getönt | 1 : 1 |
| `fx_wall` | Bollwerk von oben, Länge quer zum Weg senkrecht | etwa 2 : 7 |
| `fx_hand` | Zeigende Hand des Einstiegs (P2-8), cremefarben mit dunkler Kontur, Fingerspitze oben links bei etwa (28 %, 8 %) | Quadrat, farbig |

## Bewegung

Gegner haben **keine gemalten Laufzyklen**. Ein Bildgenerator kann dieselbe Figur
nicht Bild für Bild gleich malen; ein Zyklus aus solchen Bildern flackert.
Bewegung entsteht in der Szene: Hüpfen und Squash-and-Stretch im Lauftakt,
leichtes Kippen, Schatten-Ellipse darunter. Dafür hat jeder Gegner eine
Körper-Node über einer Schatten-Node. Umgesetzt in FX 01 (Gangart je Gegner in
`FxStyle.gait`). Der nächste Schritt für echte Gliedmaßen ist eine Zerlegung in
Teile mit Gelenken, nicht ein gemalter Zyklus; der Weg liegt Steffen als D-051 vor.

Seit A-1 (0.41.0, [Konzept](../konzepte/a-1-laufen.md)) laufen Gegner an Ecken einen
Bogen statt eines Knicks, jeder auf seiner eigenen Spur quer zum Weg, mit Blickrichtung
aus der Laufrichtung (seitlich bis 35°, sonst vorn oder hinten, sobald die Bilder da
sind), Staub beim Aufsetzen, Neigung in die Kurve und Anlaufen beim Erscheinen. Die
Simulation bleibt auf der Linie (D-144).

## Oberfläche (HUD und Menüs)

Wunschliste aus dem Oberflächen-Thread, Stand 25.10.2026. Diese Bilder sind
SwiftUI-Bilder, keine Sprites: Ablage `App/Assets.xcassets/UI/<name>.imageset`,
PNG mit Alpha, @2x und @3x. Schrift: Lilita One (Titel, Zahlen), Nunito (Text).

| Name | Größe (pt) | Anmerkung |
|---|---|---|
| `ui_icon_heart`, `ui_icon_gold`, `ui_icon_wave` | 24 | Gold ohne Währungszeichen (Nuggets/Funken) |
| `ui_icon_sell`, `ui_icon_pause`, `ui_icon_next_wave` | 24 | |
| `ui_tower_watch`, `ui_tower_lightning`, `ui_tower_spore` | 40 | aus den Turmbildern abgeleitet, eine Quelle |
| `ui_panel_wood` | dehnbar, Ecken 22 | 9-teilig, `capInsets` im Asset-Katalog |
| `ui_button_gold`, `ui_button_wood` | dehnbar, Ecken 16 | 9-teilig, je mit `_pressed` |
| `ui_banner_victory` | 260 × 62 | rotes Band |
| `ui_banner_defeat` | 380 × 62 | graues Band |
| `ui_keyart_menu` | 2796 × 1290 px | rechtes Drittel ruhig für Knöpfe |
| Regionskarte Flüsterwald | – | Phase 3, Scope-Verbot bis Freigabe |

### Phase 2 (D-024 bis D-026, noch nicht im Atlas)

Bedarf laut [07-ui-ux.md](../game-design/07-ui-ux.md), Abschnitt 8. Namen werden
festgelegt, wenn das Konzeptblatt in [figuren.md](figuren.md) steht.

- Symbole (30 pt im 54-pt-Knopf): sechs Spezialisierungen (Falkenhorst, Salve,
  Gewitterkrone, Funkensäule, Moorherz, Fäulnis), Zielwahl (Erster, Letzter,
  Stärkster), Steinregen (später Bollwerk, Mondmal), Aufwerten, Bank.
- Feld: Stufe-2-Anbau je Turm, sechs Spezialisierungsansichten, Zwergenbank voll
  und leer, Steinregen-Schatten und Einschlag.
