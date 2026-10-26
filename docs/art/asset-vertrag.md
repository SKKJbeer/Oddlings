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
| `tower_<id>_top` | drehbares Oberteil, nur wo es eines gibt |
| `enemy_raider`, `enemy_runner`, `enemy_brute` | Gegner, Blick nach rechts |
| `fortress` | Festung am Wegende |
| `map_mission01_ground` | Boden der ganzen Karte, Weg eingemalt |
| `buildzone_tile` | Markierung einer bebaubaren Zelle, Overlay |
| `fx_glow`, `fx_spark`, `fx_ring`, `fx_puff`, `fx_coin`, `fx_arrow`, `fx_bolt`, `fx_confetti`, `fx_star`, `fx_stone`, `fx_wall` | Effekte, siehe „Effekte“ unten |
| `icon_slowed` | Zustandssymbol über dem Gegner (E3) |

## Kamera, Licht, Maße

- Eine Kamera für alles: Aufsicht von schräg oben, etwa 45°. Licht von oben links,
  Schatten fallen nach unten rechts.
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

## Bewegung

Gegner haben **keine gemalten Laufzyklen**. Ein Bildgenerator kann dieselbe Figur
nicht Bild für Bild gleich malen; ein Zyklus aus solchen Bildern flackert.
Bewegung entsteht in der Szene: Hüpfen und Squash-and-Stretch im Lauftakt,
leichtes Kippen, Schatten-Ellipse darunter. Dafür hat jeder Gegner eine
Körper-Node über einer Schatten-Node. Umgesetzt in FX 01 (Gangart je Gegner in
`FxStyle.gait`). Der nächste Schritt für echte Gliedmaßen ist eine Zerlegung in
Teile mit Gelenken, nicht ein gemalter Zyklus; der Weg liegt Steffen als D-051 vor.

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
