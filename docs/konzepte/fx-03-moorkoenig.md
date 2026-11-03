# Konzept: Der Moorkönig als 3D-Figur (FX 03)

Stand 03.11.2026 · Thread „Moorkönig als 3D-Boss bauen“ · Kennzeichnung nach
[CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: [FX 02](fx-02-figuren-in-3d.md) (Werkzeugkette, D-051, D-068),
[P3-4 Mission 7](p3-4-mission-7-boss.md) (Bossregel, D-090), D-016 (Stylized 3D),
[Figurenblätter](../art/figuren.md), [Asset-Vertrag](../art/asset-vertrag.md),
[Marktanalyse](../game-design/market-analysis.md) Abschnitt 3 („Gegner mit
Persönlichkeit“, „Bosse als Auftritt“).

## Ziel

Der Boss von Region 1 bekommt ein eigenes Gesicht. Bis 0.28.0 steht für ihn eine
große, grün eingefärbte Panzerbestie (`BattleSprites.standIn`). Ab 0.28.2 ist er
eine eigene Figur, die man auf den ersten Blick als König des Moores liest, und
seine zwei Momente spielt er selbst: Bei halbem Leben hebt er den Schild, und
während der Schild steht, ruft er mit dem Stab die Flitzer herbei.

## Figur [VORSCHLAG, Gestalt auf Entscheidungskarte]

| | |
|---|---|
| Rolle | Boss, langsam, gepanzert, bei halbem Leben Schild und Ruf (D-090) |
| Persönlichkeit | alt, schwer, mürrisch, herrscht über alles, was im Moor kriecht |
| Silhouette | breiter, gebückter Moortroll, doppelt so hoch wie die Panzerbestie wirkt sie nicht, aber breiter; Krone aus Wurzeln und kleinem Geweih, langer Bart aus Moos, Stab mit grüner Laterne in einer Hand, runder Schild aus Rinde und Panzer am anderen Arm |
| Farben | dunkles Moosgrün, Rindenbraun, ein leuchtendes Giftgrün nur an Laterne, Augen und Kronensteinen; damit grenzt er sich von der Panzerbestie (Eisen, Dunkelbraun) und vom Flitzer (Orange) ab |
| Nicht | Totenköpfe, Blut, Feuer (gehört dem Tempelplatz), Blau (gehört dem Blitz) |

Warum Stab und Schild als Gegenstände: Die Bossregel hat genau zwei Handlungen, und
jede bekommt ein Ding in der Hand, das man aus der Entfernung sieht. Der Schild im
Spiel bleibt die Kuppel aus 0.28.0; der gehobene Schild an der Figur sagt, woher sie
kommt.

## Werkzeugkette (wie beim Plünderer)

```
FLUX.1-schnell (lokal, Skill spielgrafik)  →  art/figuren-3d/enemy_moorKing/vorlage.png
        │ freistellen.py, Kontur 0
        ▼
TRELLIS (Hugging Face Space, MIT, Token HF_TOKEN)  →  modell.glb
        │ rig.json: Gelenkpunkte von Hand, Folgen als Schlüsselbilder
        ▼
tools/figuren-3d/figur.py (Blender als Python-Paket, Cycles CPU)
        │ angleichen.py gegen die eigene Standansicht (Farbe), folge.py (ein Maßstab)
        ▼
Battle.spriteatlas: enemy_moorKing (Standbild) und die Folgen unten
```

Hochladen zu TRELLIS ist durch Weg A (D-051, Steffen 26.10.2026) freigegeben; die
Vorlage ist ein eigenes Bild und liegt ohnehin im öffentlichen Repo.

## Bildfolgen

| Folge | Bilder | Wann | Bewegung |
|---|---|---|---|
| `walk` | 8 | läuft | schweres Stapfen, Becken sinkt tief, Stab setzt mit dem rechten Fuß auf |
| `hit` | 3 | Treffer außerhalb des Schilds | Rumpf knickt kurz weg |
| `die` | 8 | Tod | sinkt auf die Knie, kippt nach hinten (zwei Bilder mehr als ein normaler Gegner: ein Boss fällt langsamer) |
| `shield` | 4 | `bossShieldRaised` | Schildarm vor die Brust, Knie beugen, Kopf zieht ein; letztes Bild bleibt stehen, solange der Schild steht. Beim Fallen (`bossShieldDropped`) rückwärts |
| `summon` | 5 | jedes `bossSummoned` | aus der Schildhaltung den Stab hoch und auf den Boden; endet wieder in der Schildhaltung |

Alle Folgen beginnen oder enden in einer Haltung, aus der die nächste ohne Sprung
weitergeht. Das Standbild `enemy_moorKing` ist `walk_00`, damit Szenen ohne
Bildfolge (Kampagnenkarte, Vorschau) dieselbe Figur zeigen.

Größe: 28 Bilder in @2x und @3x bei 1,9 Feldern (245 px @3x), je etwa 60 KB,
zusammen rund 2,5 MB. Vertretbar für den einzigen Boss der Region; der Atlas liegt
heute bei etwa 6 MB.

## Asset-Vertrag

`enemy_moorKing` mit `seiteZellen` 1,9 und `anker` 0,1 (wie im Mission-Thread
vereinbart, `BattleStyle.enemyHeight`), dazu `enemy_moorKing_walk` (folge 8),
`_hit` (3), `_die` (8), `_shield` (4), `_summon` (5). `check_assets.py` prüft
Vollständigkeit, Größe und Herkunft wie beim Plünderer.

## Einbau in die App

| Baustein | Darf | Darf nicht |
|---|---|---|
| `EnemyMotion` | bekommt `shield` und `summon` | |
| `EnemyNode` | lädt beide Folgen; `guardPose` hält das letzte Schildbild, `release()` kehrt dorthin zurück statt zum Laufbild | Zustand ändern |
| `FxDirector.raiseShield/lowerShield/summon` | spielt die Folgen unter demselben Schlüssel wie Treffer und Sturz (ein neuer Treffer-Zucker kann die Haltung nicht zurücksetzen) | Zeit oder Zufall der Simulation lesen |
| `BattleScene` | ruft sie an `bossShieldRaised`, `bossSummoned`, `bossShieldDropped` (Regel 3) | |
| `BattleSprites.standIn` | entfällt, sobald das Bild im Atlas liegt; die Prüfung in `BattleSpritesTests`, die nur dem Boss eine Ersatzfigur erlaubt, fällt mit | |

Fehlen die Schild- und Ruffolgen (alte Figur, Ersatzbild), bleibt alles wie in
0.28.0: Kuppel und Dunst tragen den Moment allein. Die Simulation ändert sich nicht.

## Sicherheit und Lizenzen

Wie FX 02: eigene Vorlage (FLUX.1-schnell, Apache 2.0), TRELLIS (MIT), Blender nur
als Werkzeug (GPL, berührt die Bilder nicht). Herkunft mit Prompt, Seed und
Nacharbeit in `art/figuren-3d/enemy_moorKing/ENTSTEHUNG.md`. Nichts wird zur
Laufzeit geladen. Der Token für Hugging Face steht nur in der Umgebung, nie im Repo.

## Testplan

| Ebene | Test |
|---|---|
| Atlas | `check_assets.py`: alle fünf Folgen lückenlos, gleich groß, Herkunft genannt |
| App | `BattleSpritesTests`: jede Gegnerart hat ein eigenes Bild, keine Ersatzfigur mehr; Moorkönig hat Schild- und Ruffolge |
| App | `BossAppTests` (neu: Haltung): Schild hebt → Figur hält das letzte Schildbild; Ruf spielt die Ruffolge und endet in der Schildhaltung; Schild fällt → Laufbild; Treffer-Zucker während des Schilds ändert die Haltung nicht |
| E2E | `BossE2ETests` bleibt: Bosswelle mit Leiste und Kuppel, jetzt mit eigenem Bild |
| Auge | Szene mit Kampfplatz Bosslichtung, Türmen, Flitzern und Panzerbestie zusammensetzen und neben die übrigen Figuren legen, bevor es in den Atlas geht |

## Risiken

- TRELLIS trennt dünne Teile (Stab) vom Körper oder verschmilzt sie. Gegenmittel wie
  beim Plünderer: mehrere Seeds, notfalls Stab als eigenes Requisit am Handknochen.
- Ein so breiter Körper verdeckt beim Schild den Kopf. Kamera wie beim Plünderer
  (12° von oben), Schildarm nur bis zur Brust.
- Die Figur ist groß: Kontur und Farbangleich sind auf ihr gut zu sehen. Darum wird
  gegen eine gemalte Standansicht derselben Vorlage angeglichen, nicht gegen die
  Panzerbestie.
