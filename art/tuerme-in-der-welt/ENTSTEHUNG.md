# Türme im Licht der Welt (D-200 bis D-203, 0.49.0)

Rechnet `.claude/skills/spielgrafik/scripts/turmlicht.py` aus der unveränderten Malerei in
`quelle/` (Stand 0.48.0, aus dem Atlas übernommen). Kein Modell, kein Zufall außer festem Samen
je Name.

- **Turmbilder im Atlas** sind seitdem abgeleitet: Schattenseite (rechts dunkler, links heller,
  Zylinder je Zeile) und Fußdunkel. Umriss und Alpha gleich der Quelle. Wer ein Turmbild neu
  malt, legt es nach `quelle/` und ruft erst `turmlicht.py`, dann `turmboden.py`.
- **Grasmasken** `tower_<name>_grass`: weiß mit Alpha, Boden vor dem vorderen Bogen des
  Grundrisses mit einer Kante aus Halmen. Die Szene zeigt darin den gemalten Boden des
  Kampfplatzes samt Schatten über dem Fuß.

| Maske | Turmbild |
|---|---|
| `tower_bank_grass` | `tower_bank` |
| `tower_lightning_grass` | `tower_lightning` |
| `tower_lightning_2_grass` | `tower_lightning_2` |
| `tower_lightning_crown_grass` | `tower_lightning_crown` |
| `tower_lightning_spark_grass` | `tower_lightning_spark` |
| `tower_spore_grass` | `tower_spore` |
| `tower_spore_2_grass` | `tower_spore_2` |
| `tower_spore_moor_grass` | `tower_spore_moor` |
| `tower_spore_rot_grass` | `tower_spore_rot` |
| `tower_watch_grass` | `tower_watch` |
| `tower_watch_2_grass` | `tower_watch_2` |
| `tower_watch_falcon_grass` | `tower_watch_falcon` |
| `tower_watch_volley_grass` | `tower_watch_volley` |

Verworfen: Türme über TRELLIS in 3D (wie die Gegner). Die Texturen kamen für Türme zu dunkel
und matschig heraus (Probe Wachturm und Pilz, 24.11.2026); bei Gegnern fällt das klein nicht auf,
bei Türmen schon.
