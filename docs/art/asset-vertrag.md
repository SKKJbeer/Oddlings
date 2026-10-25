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
| `fx_bolt`, `fx_spore_cloud`, `fx_hit`, `fx_spark_combo` | Effekte |
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

## Bewegung

Gegner haben **keine gemalten Laufzyklen**. Ein Bildgenerator kann dieselbe Figur
nicht Bild für Bild gleich malen; ein Zyklus aus solchen Bildern flackert.
Bewegung entsteht in der Szene: Hüpfen und Squash-and-Stretch im Lauftakt,
leichtes Kippen, Schatten-Ellipse darunter. Dafür hat jeder Gegner eine
Körper-Node über einer Schatten-Node. Wenn das im Spieltest (WP-15) nicht
genügt, ist der nächste Schritt eine Zerlegung in Teile (Kopf, Körper, Beine)
mit Skelettanimation, nicht ein gemalter Zyklus.

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
