# Konzept A-5 Teil 2: Kopfleiste als Schilder, Effektbudget

Status: **ausgeliefert (0.45.0)** · Plan [AAA-Schnitt](aaa-review.md#plan), Paket A-5 ·
Maßnahmen aus [aaa-bewegung-und-bauen.md](aaa-bewegung-und-bauen.md#a-5-eine-malweise-in-der-welt)
Befunde: G6 (zwei Materialien, grünes Band), R1 (Effekte verdecken die Gegner)
Entscheidungen: [D-180 bis D-184](../decisions/decision-log.md)
Vorgänger: [A-5 Teil 1](a-5-spezialisierungen-und-ringe.md) (0.34.0), [A-2](a-2-bauen-und-tafeln.md) (0.44.0)

## Ziel

Mission 1 sieht aus einem Guss aus: Die Karte reicht bis an den Bildschirmrand, darüber
schweben Schilder aus demselben Holz wie Tafeln und Kreismenü, mit den gemalten Symbolen
aus dem Katalog. Im dichtesten Kampf am Turmhaufen sieht man jeden Gegner; Gold kommt als
eine lesbare Zahl, nicht als Haufen kleiner Zahlen. Säule 2: „in jeder Sekunde sehen, was
passiert“.

## Umfang

| Drin | Nicht drin |
|---|---|
| Kopfleiste ohne Band: einzelne Holzschilder mit weichem Schatten über dem gemalten Rand der Karte | Türme zielen (G9): Schütze, Ladebewegung, Hut; braucht neue Bildfolgen je Turm, eigenes Paket A-5 Teil 3 |
| Gemalte Symbole `ui_icon_heart`, `_gold`, `_wave`, `_pause`, `_next_wave` (lagen seit Grafik 01 im Katalog, unbenutzt) | Neue Malerei für Schilder; die Form wird gezeichnet wie `WoodBackground`, ein Bild `ui_plaque` ersetzt sie später |
| Effektbudget je Bereich für große Wolken | Kantenlicht auf Figuren (Licht-Paket) |
| Bodenwolken unter den Figuren | |
| Gold bündeln | |
| Messung „verdeckte Gegner“ im Kontaktabzug | |

## Kopfleiste (D-180)

Heute: `VStack { BattleTopBar; Szene }` auf grünem Grund. Der Streifen über der Karte ist
`BattleStyle.background`, ein flaches Grün, das zu nichts passt (Review Bild a, Marke 4).

Neu:

- Die `SpriteView` füllt den ganzen Bildschirm. Das Raster bleibt **genau dort, wo es war**:
  `BoardLayout` bekommt oben einen Rand `BattleStyle.boardTop` (Leistenhöhe plus zwei
  Abstände), in den es nicht rechnet. Darüber liegt der gemalte Überstand des Kampfplatzes
  (`groundMargin` = 2 Felder je Seite, also mindestens 75 pt; der Rand braucht 52 pt).
  Kein Bauplatz, kein Wegstück und keine Festung rückt unter ein Schild, also ändert sich
  am Spiel nichts, und D-030 (HUD-Ecken als Nicht-Bauplätze) bleibt unberührt.
- Eine Rechnung, drei Aufrufer: `BoardLayout.battle(size:map:)` setzt den Rand. Szene,
  Kreismenü (`RingMenu`) und der E2E-Helfer `E2EApp.tap` rechnen damit; der Rand geht
  als oberer Inset an `HudLayout`, damit Bogen und Tafel nie unter ein Schild rutschen.
  Die Wellenvorschau sitzt unter dem Rand (`forecastRect.y = insets.top`).
- **Schilder** (`HudPlaque`): Holzfläche mit hellerer Oberkante, innerer Rand in
  `woodRim`, Kontur `outline`, harter Schlagschatten 3 pt wie die Tafeln, dazu ein
  weicher Schatten auf die Karte (Radius 5, 35 %). Jeder Wert ist ein eigenes Schild;
  das gemalte Symbol sitzt größer als das Schild auf dessen linkem Ende, wie ein
  aufgelegtes Siegel. Runde Knöpfe (Zurück, Tempo, Pause) haben dieselbe Haut wie die
  Knöpfe des Kreismenüs (`RingButtonFace`). „Welle rufen“ ist ein goldenes Schild mit
  dem Horn `ui_icon_next_wave` und dem ablaufenden Ring.
- Fehlt ein Symbol im Katalog, steht das SF-Symbol von vorher da (Rückfall, im Test rot).
- Kennungen (`hud.lives`, `hud.gold`, `hud.wave`, `hud.nextWave`, `hud.speed`,
  `hud.pause`, `hud.back`) und alle Bewegungen (Wackeln beim Leck, Warnung bei zu wenig
  Gold, „+7“ beim frühen Rufen) bleiben.

## Effektbudget (D-181 bis D-183)

Ursache von R1, nachgezählt im Code: Ein Sporenstoß legt 12 Wolken (`sporePuffs`) mit
0,35 bis 0,55 Feldern und 75 % Deckkraft **über** die Gegnerebene (Effektebene z 30,
Gegner z 20). Vier Türme auf engem Raum stoßen versetzt aus, dazu Rauch beim Zerplatzen
(6 Wolken je Gegner) und je Tod drei Münzen und eine Zahl. Die bestehende Grenze
`maxSprites` zählt nur die Menge im ganzen Bild, nicht, wo sie liegt.

1. **Höchstens zwei große Wolken übereinander (D-181).** `FxAreaBudget` (rein, ohne
   SpriteKit) führt die laufenden Wolken mit Mitte, Radius und Ende. Will eine neue
   Wolke dort hin, wo sich schon `cloudsPerArea` (2) überlappen, spielt sie gedämpft:
   ein Drittel der Teilchen, halbe Deckkraft (`cloudDampedShare`, `cloudDampedAlpha`).
   Gemessen wird in Feldern, abgelaufene Einträge fallen beim nächsten Fragen heraus.
   Gilt für Sporenstoß, Sporenfunke und Rauch beim Zerplatzen.
2. **Bodenwolken unter den Figuren (D-182).** Sporenwolke, Funkenwolke und Rauch liegen
   auf `FxStyle.groundCloudZ` (−12 in der Effektebene, also 18: über den Türmen, unter
   den Gegnern). Ring, Blitz, Pfeil, Funken und Zahlen bleiben darüber. So deckt keine
   Wolke einen Gegner, gleich wie viele es sind.
3. **Gold bündeln (D-183).** Fällt ein Gegner innerhalb `goldMergeWindow` (0,4 s) und
   `goldMergeRadius` (1,2 Felder) von einer noch steigenden Goldzahl, zählt sie seinen
   Lohn dazu („+4“ wird „+8“), springt kurz wieder auf und beginnt ihren Weg neu; statt
   drei Münzen kommt eine. Die Summe stimmt immer mit dem Gold in der Kopfleiste.

## Messung (D-184)

`FxDirector.occludedEnemies(_:)` zählt Gegner, deren Körpermitte in einer großen
Effektwolke **über** ihnen liegt (Wolke ab 0,3 Feldern, Deckkraft ab 35 %). Die Szene
meldet den Anteil je Bild an den Kontaktabzug (`occludedFrames`, `maxOccluded`);
`kontaktabzug.py` zeigt „verdeckt“ und warnt über 2 % der Bilder. Hart prüft der App-Test.

## Architektur und Datenfluss

- Nur Darstellung, keine Änderung an `OddlingsCore`, keine Zahl aus dem Spiel.
- `BoardLayout.battle(size:map:)` ist die eine Stelle für den oberen Rand.
- `FxAreaBudget` gehört dem `FxDirector`, läuft auf dessen Uhr (D-050) und wird mit ihm
  zurückgesetzt. Die Szene fragt nichts davon ab; sie meldet weiter nur Ereignisse.
- Alle neuen Werte in `FxStyle` und `BattleStyle` (Architekturregel 7).

## Sicherheit

Keine neue Eingabe von außen, kein Netz, keine neuen Bilder. Die Symbole kommen aus dem
eigenen Katalog; fehlt eines, gibt es den Rückfall, keinen Absturz.

## Tests

- `FxAreaBudgetTests`: frei, voll, gedämpft; Abstand in Feldern; abgelaufene Wolken
  zählen nicht; Zurücksetzen.
- `FxDirectorTests`: Sporen- und Rauchwolken liegen unter den Gegnern; dichter Turmhaufen
  spielt gedämpft (`stats.damped`); zwei nahe Tode ergeben eine Zahl mit der Summe;
  ferne Tode zwei Zahlen; eine ganze Mission mit vier Sporentürmen am Haufen hat keinen
  verdeckten Gegner.
- `HudLayoutTests`: Raster mit Rand liegt wie vorher unter der Leiste, nur verschoben;
  Bogen und Tafel bleiben unter dem Rand.
- `UIArtTests`: alle Symbole der Kopfleiste im Katalog.
- E2E `HUDE2ETests.testBoardReachesUnderThePlaques`: die Karte beginnt oben am
  Bildschirm, die Schilder liegen auf ihr, Bauen trifft weiter die Zelle (alle Bau-Tests
  rechnen mit dem Rand).
- Kontaktabzug: Spalte „verdeckt“ je Mission.
