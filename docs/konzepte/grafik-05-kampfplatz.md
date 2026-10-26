# Konzept: Kampfplatz und Festung (Grafik 05)

Status: **[VORSCHLAG]** · Stil D-016 · Thread „AAA-Grafik und Art-Direction"
Anlass: Steffen, 26.10.2026: „der hintergrund und das ziel sieht noch billig und
nicht abgestimmt mit dem rest aus. das muss sich richtig professionell kommen."

## Befund (Simulator-Probelauf zu 0.10.2)

1. **Die Festung ist nicht zu sehen.** `SpriteView` läuft mit
   `ignoresSiblingOrder`; Bodenbild und Festung hängen beide mit `zPosition` 0 an
   `ground`. Die Reihenfolge ist damit undefiniert, und im Probelauf liegt der
   Boden oben. Ein Fehler, keine Geschmacksfrage.
2. **Der Boden ist eine flache Wiese** mit rechtwinkligem Sandband und harten
   Kanten. Kein Wald, keine Tiefe, kein Licht. Er teilt mit der Kampagnenkarte
   (Flüsterwald) weder Gras noch Weg noch Bäume.
3. **Leere Streifen.** Die Karte ist 16 × 9 Zellen (1,78:1), das iPhone ist
   etwa 2,17:1. Links und rechts bleibt je rund 1,8 Zellen Hintergrundfarbe; auf
   dem iPad oben und unten rund 1,5.
4. **Die Festung** ist eine flache Frontansicht wie eine Clip-Art, kleiner als
   ein Turm in Wirkung und aus einer anderen Perspektive als Türme und Gegner.

Maßstab ist die Liste „AAA-Anmutung" der Marktanalyse (Abschnitt 3): ein Ort
statt einer Fläche, Rahmen um das Spielfeld, Licht, eine eindeutige Bedrohung
(woher die Gegner kommen) und ein eindeutiges Ziel (was ich schütze).

## Ziel

Der Kampfplatz ist eine Lichtung im Flüsterwald, dieselbe Welt wie die
Kampagnenkarte. Wald rahmt das Feld bis an den Bildschirmrand, links kommen die
Gegner aus der Goblinhöhle (dieselbe wie auf der Karte), rechts steht eine
Festung, die man schützen will.

## Umfang

| Teil | Was |
|---|---|
| Fehler | Bodenbild unter alles (`zPosition` −1), Festung über Boden und Bauzonen |
| Boden mit Rand | `map_mission01_ground` deckt das Feld **plus 2 Zellen Rand** je Seite: 20 × 13 Zellen, 130 px je Zelle (2600 × 1690). Der Rand ist Wald und reicht für iPhone-Breite und iPad-Höhe |
| Boden gemalt | Collage wie die Kampagnenkarte (`regionscollage.py`-Weg): Gras- und Wegtextur, Bäume und Höhle aus `art/karten/region01`. Weg mit runden Ecken und dunklerer Furche, Lichtflecken, Baumschatten, warmes Licht |
| Festung | neu gemalt, Perspektive und Stil der Türme (45° von oben, Konturen), Tor nach links zum Weg, größer (3 Zellen) und ganz im rechten Rand, damit sie keine Bauzelle verdeckt |

**Nicht drin:** Bäume oder Steine auf Bauzellen (das Feld ist bis auf den Weg
überall bebaubar; Deko dort würde lügen), animiertes Laub, weitere Missionen.

## Architektur

- `BattleStyle.groundMargin` (Zellen) ist die eine Stelle für den Rand. Der
  Asset-Vertrag nennt `zellen: [20, 13]` und `rand: 2`; die Kunstprüfung hält
  beide zusammen.
- `BattleSprites.ground` legt das Bild von Zelle (−Rand, −Rand) bis
  (Breite + Rand, Höhe + Rand). `BoardLayout` bleibt unverändert: Eingabe und
  Zellen rechnen weiter nur mit dem Feld.
- Festung: Lage aus dem Wegende wie bisher (`gate`), Bild rückt um
  `BattleStyle.fortressOffset` Zellen nach rechts in den Rand.
- Die Simulation ändert sich nicht.

## Tests

- `BattleSceneTests`: Festung liegt über dem Boden (`zPosition`), Bodenbild
  deckt die ganze Szene für iPhone- und iPad-Seitenverhältnis, Festungsbild
  überdeckt keine Bauzelle. Jeder Test einmal rot.
- `tools/art-check`: Vertrag (Größe 20 × 13 Zellen), Weg im Bild liegt auf der
  Weggeometrie (wie bisher, um den Rand verschoben), Rand ist dunkler als das
  Feld (Wald).
- Simulator-Probelauf: Bildschirmfotos der Mission ansehen, bevor ausgeliefert
  wird.

## Risiken

- **Speicher:** 2600 × 1690 JPEG sind dekomprimiert etwa 17 MB. Vertretbar für
  ein Bild je Mission.
- **Bäume am Rand verdecken Gegner am Wegeingang.** Der Weg beginnt bei x = −1;
  der Waldrand bekommt dort eine Lücke mit der Höhle, Bäume halten Abstand vom Weg.
