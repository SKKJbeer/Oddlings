# Konzept: Figuren vollständig (AAA-Schnitt A-3)

Status: **Teil 1 ausgeliefert** (0.32.0: Werkzeug, Plünderer, Moorkönig; D-160), **Flitzer** (0.39.0, D-161) · Stand 16.11.2026 · Thread „Gegnerfiguren in 3D vervollständigen“
Grundlage: [AAA-Review](aaa-review.md) (B1, B2, G3), [Bewegung und Bauen](aaa-bewegung-und-bauen.md#a-3-figuren-vollständig),
[FX 02](fx-02-figuren-in-3d.md), [FX 03](fx-03-moorkoenig.md), D-016 Stylized 3D, D-051 3D zu
Bildfolgen, D-052 Werkzeuge, D-068 Comic-Look, D-140 eine Kamera.

## Ziel

Alle vier Gegner sehen aus wie aus einem Spiel: Sie bewegen Arme und Beine, schauen dorthin,
wohin sie gehen, und tragen dieselbe Malweise und dieselbe Kontur. Messbar:

- Jeder Gegner hat `walk`, `hit`, `die`; dazu `walkFront` und `walkBack` (A-1 wählt nach
  Laufrichtung). Kein Gegner ist mehr ein starres Bild mit Hüpfer.
- Neben der gemalten Vorlage in Spielgröße erkennt man dieselbe Figur (Abnahme am Bildpaar).
- Die Kontur ist bei allen vier Gegnern gleich breit, gemessen in Punkten auf dem Schirm.

## Umfang

| Teil | Was | Reihenfolge |
|---|---|---|
| Werkzeug | `figur.py` rendert Blickrichtungen (`ansichten` in `rig.json`), `folge.py` legt einen einheitlichen Konturpass um jedes Bild | zuerst, ein PR |
| Plünderer | `walkFront`, `walkBack` aus dem vorhandenen Modell | mit dem Werkzeug |
| Flitzer | neue Vorlage (FLUX), TRELLIS, Skelett, alle fünf Folgen | eigener PR |
| Panzerbestie | wie Flitzer; vierbeinig | eigener PR |
| Moorkönig | `walkFront`, `walkBack` aus dem vorhandenen Modell | mit dem Werkzeug |
| Moorhexe, Pilzbalg (D-143) | nur wenn Luft ist: Vorlage und Modell, noch nicht im Atlas | später |

Nicht dabei: Spielregeln, Maßstab der Figuren (kommt mit A-4 in den Vertrag), Lauf-Code
(A-1), Kampfplatz (A-4).

## Namens- und Atlasvertrag (mit A-1 abgestimmt, 16.11.2026)

| Folge | Bilder | Blick beim Rendern | Wann A-1 sie zeigt |
|---|---|---|---|
| `enemy_<art>_walk_00..07` | 8 | Dreiviertel nach rechts (wie bisher) | waagerecht, für links gespiegelt |
| `enemy_<art>_walkFront_00..07` | 8 | auf den Betrachter zu, leicht nach rechts unten | Laufrichtung nach unten |
| `enemy_<art>_walkBack_00..07` | 8 | vom Betrachter weg, leicht nach rechts oben | Laufrichtung nach oben |
| `enemy_<art>_hit_00..02`, `_die_00..05` | 3, 6 | wie `walk` | nur seitlich |

- Gleiche Bildzahl und gleiche Schrittphase in allen drei Laufrichtungen: Bild *n* vorn ist
  dieselbe Beinstellung wie Bild *n* seitlich, damit A-1 beim Wechsel über 0,12 s überblenden
  kann, ohne dass der Schritt springt.
- Ein Maßstab und ein Fußanker (0,1) je Figur über **alle** Folgen (`folge.py` rechnet einmal),
  damit die Figur beim Wechsel der Blickrichtung nicht wächst oder hüpft.
- Fehlt eine Folge, fällt A-1 auf `walk` zurück. Darum kann jede Figur einzeln kommen.
- In Swift: `EnemyMotion.walkFront`, `.walkBack`; der `rawValue` hängt direkt am Namen.

## Werkzeug

### Blickrichtungen (`ansichten` in `rig.json`)

```json
"ansichten": {"walkFront": {"folge": "walk", "blick": 12}, "walkBack": {"folge": "walk", "blick": 168}}
```

`figur.py` rendert für jede Ansicht dieselben Schlüsselbilder wie die genannte Folge, nur mit
anderer Drehung der Figur vor der Kamera. Kamera und Licht bleiben stehen, wie bei einer
Figur, die sich auf dem Platz umdreht. **Warum nicht die Kamera drehen:** Licht von links oben
muss auf allen Ansichten von derselben Seite kommen (D-140, ein Licht), sonst wäre die Figur von
hinten von der falschen Seite beleuchtet.

### Konturpass (`folge.py`)

Jedes Bild bekommt nach dem Einpassen eine dunkle Außenlinie aus der Silhouette: Alphakante
um `konturPunkte` erweitert, Farbe 34/22/18 wie `freistellen.py`. Breite in Punkten aus dem
Vertrag, nicht in Bildpixeln, damit Flitzer (klein) und Moorkönig (groß) auf dem Schirm dieselbe
Linie tragen. Die Innenkonturen (Arm vor dem Bauch) zeichnet weiter die Hülle in `figur.py`.

- **Warum nach dem Verkleinern:** Eine Kontur vor dem Verkleinern wird je Figur unterschiedlich
  dünn, weil jede Figur anders skaliert wird.
- **Warum zusätzlich zur Hülle:** Die Hülle ist eine Linie im Modell, ihre Breite auf dem Schirm
  hängt von Modellgröße und Kamera ab; sie franst an dünnen Teilen (Ohren, Keule) aus.

### Rendern in doppelter Größe

Bleibt wie bisher: `figur.py` mit 512 px, die Atlasbilder sind 116 bis 300 px. Das ist mehr als
doppelt; ein eigener Schritt ist nicht nötig.

### Gesichtsplatte

Erst, wenn das Bildpaar des Flitzers oder der Panzerbestie das Gesicht verliert. Der Plünderer
ist freigegeben (D-068). Wird sie nötig, ist sie ein eigenes Requisit (`requisiten` in
`rig.json`), das am Kopfknochen hängt; die Werkzeugkette kann das schon.

## Flitzer und Panzerbestie

| | Flitzer | Panzerbestie |
|---|---|---|
| Vorlage | schmal, orange Haut, lange Fühlerohren, roter Schal hängend, Rucksack, Arme vom Körper | Keiler auf vier Beinen, Hauer, Hörner, Panzerplatten in Stahlblau mit goldener Schulter |
| Skelett | wie Plünderer; der Schal liegt eng am Hals und braucht keinen eigenen Knochen (D-161) | Becken, Rumpf, Kopf, vier Beine |
| Laufen | schnell, flach, stark vorgekippt, Schal schwingt nach | schwer, Beine diagonal paarweise, Kopf nickt |
| Treffer | Rumpf knickt zurück | Kopf ruckt hoch |
| Sturz | fällt vornüber | kippt auf die Seite |

Ablauf je Figur wie beim Plünderer (`ENTSTEHUNG.md` nennt Prompt, Seed, Modell, Schritte):
FLUX.1-schnell drei Seeds, Auswahl am Bild; TRELLIS (Hochladen der eigenen Vorlage ist seit FX 02
freigegeben); Gelenkpunkte aus Vorder- und Seitenansicht; Probe `NUR=walk`; alle Folgen;
`angleichen.py` gegen das Gemälde; `folge.py`. Das alte Standbild bleibt im Atlas als Rückfall.

## Kamera und Licht (D-140)

Festgelegt von A-4 (16.11.2026), im Vertrag unter `kamera` und `sonne`: orthografisch,
**40° über dem Boden**, kein Gierwinkel; für Figuren Spielraum bis 30°, wenn sonst das Gesicht
verschwindet. Sonne Azimut 135° (links hinten), Höhe 45°. `figur.py` liest beides aus dem
Vertrag, statt eigene Werte je Figur zu haben; `rig.json` darf die Kamerahöhe nur innerhalb des
Spielraums wählen (`art-check` prüft das). Die Folge: Der Plünderer wird von 12° auf mindestens
30° umgestellt. Dabei droht die Mütze das Gesicht zu verdecken (der Grund für 12° in FX 02);
das ist der erste Prüfstein für die Gesichtsplatte. Ein Neurendern aller vier Figuren dauert
etwa 10 Minuten.

Die neuen Zielhöhen (Flitzer 0,7, Plünderer 0,8, Panzerbestie 1,15, Boss 2,0 Felder) trägt A-4
unter `massstab` ein; A-3 stellt die `seiteZellen` der Gegner darauf um, sobald die Figuren
kommen, damit Bild und Maßstab zusammen wechseln.

## Sicherheit

Keine App-Logik, kein Netz in der App. Hochgeladen wird nur die eigene Vorlage an TRELLIS
(MIT), wie bei Plünderer und Moorkönig. Blender und FLUX bleiben Werkzeuge außerhalb der App.

## Tests

- `tools/art-check`: Folgen lückenlos (vorhanden), neu: alle Folgen einer Figur gleich groß
  und Fußanker von `walk_00`, `walkFront_00`, `walkBack_00` auf derselben Höhe; Kontur am Rand
  vorhanden (dunkle Randpixel). Einmal rot gesehen.
- `tools/figuren-3d/tests`: Konturpass erweitert die Silhouette um die verlangte Breite und
  färbt nur außen; `ansichten` erzeugt dieselben Bildnummern wie die Quellfolge.
- App-Tests: `EnemyMotion` lädt `walkFront`/`walkBack` für jede Figur mit 8 Bildern
  (`BattleSpritesTests`), Rückfall ohne Folge (kommt mit A-1).
- E2E: Mission 1 im Zeitraffer läuft mit den neuen Bildern (bestehender Probelauf); Abnahme am
  Bildpaar und am Kontaktabzug im PR.
