# Konzept A-2: Bauen und Tafeln

Status: **[VORSCHLAG]** · Stand 16.11.2026 · Thread „Türme bauen hochwertig inszenieren“
Zielversion 0.37.0 · D-Block D-155 bis D-159
Grundlage: [AAA-Review](aaa-review.md) Befunde P1, P2, P3, P4, P5, R2;
[Bewegung und Bauen](aaa-bewegung-und-bauen.md#a-2-bauen-und-tafeln); D-121 (Bauplätze nur beim
Bauen), D-130 bis D-132 (Turmwerte), D-141 (Bauinseln, baut A-4).

## Ziel

Steffens Befund: „Das Platzieren der Türme sieht noch nicht perfekt aus.“ Nach A-2 gilt:

1. **Vor dem Kauf steht der Turm sichtbar an seinem Platz**, halb durchsichtig, und man
   sieht, wie viel Weg er abdeckt (P1).
2. **Die Malerei bleibt beim Bauen sichtbar**: Bauplätze nur um den Finger, weich
   auslaufend, statt 104 bis 120 Kacheln über der ganzen Karte (P2).
3. **Ein Turm wird errichtet, nicht abgeworfen**; Aufwerten und Spezialisieren haben je
   einen eigenen Auftritt (P3).
4. **Tafel und Bogen kennen die Lage**: Die Tafel liegt nie auf der Festung und nur dann
   auf dem Weg, wenn es keine freie Lage gibt; sie liegt nie unter dem Fähigkeitsknopf;
   kein Text wird abgeschnitten (P4, P5).
5. **Man sieht, was kommt**: Unter „Welle n“ stehen die Gegner der nächsten Welle mit
   Anzahl, neue Arten markiert (R2).

## Umfang

| Teil | Drin | Nicht drin (Grund) |
|---|---|---|
| Vorschau | Halb durchsichtiger Turm am Feld, Reichweite als Wegabdeckung, beim Aufwerten das Bild der nächsten Stufe | Gemalter Ring statt Linie (A-5) |
| Bauplätze | Umkreis um die gewählte Zelle, weich auslaufend; vor der ersten Welle alle, aber gedämpft | Bauinseln (A-4, D-141) |
| Auftritte | Errichten, Aufwerten, Spezialisieren | Neue Bilder für Stufe 3 (A-5) |
| Tafel | Strafe für Weg, Festung und feste Ecken; Texte, die passen | Kopfleiste als Schilder (A-5) |
| Wellenvorschau | Zettel unter dem Knopf „Welle n“ | Gegnerlexikon, Wellenplan der ganzen Mission |

Die Simulation bleibt unberührt (Grenze aller Pakete A-1 bis A-5).

## Architektur

```
BalanceConfig.waves ──► WaveForecast (App, rein) ──► BattleController.forecast ──► WaveForecastTag (SwiftUI)
MissionMap.path ──► HudLayout.Avoid (Wegzellen, Festung, feste Ecken) ──► HudLayout.panel / statPanel
BattleController.selection ──► BattleScene.showSelection ──► Vorschau-Turm (TowerNode), Wegabdeckung
                           └─► BattleScene.showBuildZones ──► Alpha je Bauplatz (BuildZoneFocus, rein)
Event.towerBuilt / towerUpgraded ──► FxDirector.erect / upgrade / specialize
```

Wer was darf:

- **`WaveForecast`** (neu, `App/Battle/WaveForecast.swift`): reine Rechnung aus der
  Missionsdatei. Fasst die Gruppen einer Welle je Gegnerart zusammen, in der Reihenfolge
  ihres ersten Auftretens, höchstens drei Arten; markiert Arten, die in keiner früheren
  Welle vorkamen. Liest keinen Zustand, nur `config.waves`.
- **`BattleController.forecast`**: die Vorschau der nächsten Welle, nil, wenn keine mehr
  kommt. Nur eine Kopie wie Gold und Leben; der Knopf zeichnet sie.
- **`HudLayout.Avoid`** (neu): was die Tafel nicht verdecken soll, in Ansichtskoordinaten:
  Wegzellen (aus `MissionMap.path`), das Rechteck der Festung und feste Ecken
  (Fähigkeitsknopf unten rechts, Wellenvorschau oben rechts). Feste Ecken sind hart wie
  Zelle und Knöpfe; Weg und Festung kosten Strafpunkte. `HudLayout` wählt unter allen
  freien Lagen die mit der kleinsten Strafe, bei Gleichstand die bisherige Reihenfolge
  (weg von der Zelle). Rechnet weiter nur auf `BoardLayout`, ohne Ansicht.
- **`BuildZoneFocus`** (neu, rein): Deckkraft eines Bauplatzes aus seinem Abstand zur
  gewählten Zelle. Die Szene setzt sie, wenn sich die Auswahl ändert, nicht je Bild.
- **`BattleScene`**: zeigt Vorschau-Turm und Wegabdeckung in der Auswahlebene. Der
  Vorschau-Turm ist ein `TowerNode` ohne Schatten mit Deckkraft 0,55; kein zweites Bild,
  keine zweite Rechnung. Die Wegabdeckung kommt aus `PathGeometry` (Stücke des Wegs im
  Kreis), dieselbe Rechnung wie `coverage`.
- **`FxDirector`**: `build` wird „Errichten“; neu `specialize`. Der Turm steht während des
  Auftritts schon in der Simulation; der erste Schuss bricht den Auftritt nicht ab, aber der
  Auftritt bleibt kürzer als ein Schusstakt (0,55 s).

### Errichten statt Abwerfen

| Ereignis | Auftritt | Dauer |
|---|---|---|
| Bauen | Erdfleck dunkelt auf, drei Balken stehen als Gerüst, der Turm wächst von unten aus dem Boden (Maske über die Höhe), zwei Hammerschläge als Funken und Staub, beim letzten ein leichtes Nachfedern; kein Sturz, kein Wackeln des Bildes | 0,55 s |
| Aufwerten | Lichtsäule in Turmfarbe aus dem Fuß, der Turm streckt sich, das neue Bild kommt im hellsten Moment, Funken | 0,45 s |
| Spezialisieren | Wirbel in Turmfarbe am Boden, der Turm sinkt kurz hinein und kommt mit dem neuen Bild hoch, Ring über den Boden | 0,7 s |
| Verkaufen | unverändert | 0,4 s |

„Bewegung reduzieren“: kein Gerüst, kein Wachsen; der Turm blendet ein, ein Ring bleibt.

### Vorschau vor dem Kauf (D-155, entschieden)

Steffen hat am 16.11.2026 auf Karte S33 **drei Tipps mit Vorschau** gewählt. Erstes Tippen aufs Feld
öffnet den Bogen, zweites Tippen auf einen Turm stellt ihn halb durchsichtig aufs Feld
und zeigt seine Wegabdeckung und Werte, drittes Tippen auf denselben baut. Ein anderer Turm
im Bogen tauscht die Vorschau. Beim ersten Tippen auf Aufwerten zeigt der Turm am Platz das
Bild der nächsten Stufe halb durchsichtig über dem alten, wo es eins gibt.

Verworfen: zwei Tipps mit vorgewähltem letztem Turm (schneller, aber ein Fehltipp kostet
Gold).

### Reichweite als Wegabdeckung (D-156)

Heute zeigt ein heller Kreis über der Wiese die Reichweite. Was zählt, ist der Weg im
Kreis. Neu leuchtet **der Weg im Kreis** in der Auswahlfarbe, der Kreis selbst bleibt nur
als feine Linie. Die Zahl dazu („deckt 4,2 Felder Weg“) steht nicht in der Tafel: Die
Tafel trägt schon vier Kacheln, und das Bild sagt es.

### Bauplätze um den Finger (D-157)

| Lage | Bauplätze |
|---|---|
| Vor der ersten Welle, nichts gewählt | alle, mit Deckkraft 0,45 statt 1 (die Karte bleibt lesbar, man sieht trotzdem, wo man bauen kann) |
| Freie Zelle gewählt | Umkreis von drei Feldern um die Zelle, voll bis 1,5 Felder, dann weich auf 0 |
| Sonst | keine |

Mit Bauinseln (A-4) leuchten statt der Kacheln die Inseln; dann entfällt der Umkreis.

### Tafel kennt die Lage (D-158)

- Lagen: die vier Ecken, Mitte oben und unten, dazu Mitte links und rechts.
- Hart verboten: gewählte Zelle, Knöpfe des Bogens, feste Ecken (Fähigkeitsknopf,
  Wellenvorschau).
- Strafe: je Wegzelle unter der Tafel 1 Punkt, die Festung 100 Punkte. Die Tafel mit der
  kleinsten Strafe gewinnt, bei Gleichstand die bisherige Reihenfolge.
- Die Festung ist das Rechteck ihres Bilds (`BattleStyle.fortressSpriteSide`, um
  `fortressOffset` verschoben) und die zwei Wegzellen davor: Dort kommen die Gegner an.
- Der Bogen meidet die festen Ecken ebenso; er rückt als Ganzes, wie bisher.

### Text passt immer

Jeder Text der Tafel wird im App-Test mit der echten Schrift gemessen
(`TextFitTests`, UIFont aus `AppFonts`), mit den längsten Zahlen, die vorkommen.
Was nicht passt, wird umformuliert. Gemessen (Nunito/Lilita, längste Preise aller Missionen):

| Heute | Neu | Grund |
|---|---|---|
| „Nochmal tippen: aufwerten für 75 Gold“ | „Nochmal tippen: aufwerten (75)“ | den Preis zeigt schon der Knopf |
| „Nochmal tippen: Gewitterkrone für 55 Gold“ (275 pt) | „Nochmal tippen: Gewitterkrone (55)“ | über 236 pt |
| „Endgültig, nur Verkaufen nimmt es zurück.“ (242 pt) | „Endgültig, nur Verkaufen hebt es auf.“ | über 236 pt |
| „Die 100 Gold fehlen dir in den nächsten Wellen.“ (289 pt) | „100 Gold fehlen dir vorerst.“ | lief bei der Bank über |
| Wirkung der Spezialisierungen, bis 382 pt | je ein kurzer Satz (z. B. „Sieht weit, durchschlägt Rüstung.“) | die Kacheln zeigen die Zahlen |
| kleine Tafel 214 pt breit | 240 pt | „Ab 20 s alle 4 s +5, bis 300 Gold“ passte nicht |

„Neu: Zielwahl (Erster, Letzter, Stärkster)“ passt mit 225 von 236 pt und bleibt.
`minimumScaleFactor` bleibt als Sicherheitsnetz, darf aber laut Test nicht nötig sein.

### Wellenvorschau (D-159)

Ein Zettel hängt unter dem Knopf „Welle n“ (rechts oben, auf der Karte): je Gegnerart ein
Bild aus dem Atlas und die Anzahl, höchstens drei Arten, neue Arten mit einem roten
Ausrufezeichen. In der Kopfleiste selbst ist kein Platz: Auf dem iPhone SE fehlen dort
rund 110 Punkte. Der Zettel ist eine feste Ecke für Tafel und Bogen. VoiceOver liest
„Nächste Welle: 8 Plünderer, 4 Flitzer, neu“.

## Bedienentscheidungen

| Nr | Frage | Gebaut | Wer |
|---|---|---|---|
| D-155 | Wie viele Tipps zum Bauen? | drei, mit Vorschau | **entschieden**, Steffen, Karte S33 |
| D-156 | Reichweite als Kreis oder als Weg im Kreis? | Weg im Kreis, Kreis als feine Linie | Claude, umkehrbar |
| D-157 | Bauplätze beim Bauen | Umkreis um die Zelle; vor Welle 1 alle gedämpft | Claude, folgt D-121 |
| D-158 | Wohin die Tafel? | kleinste Strafe für Weg und Festung, feste Ecken frei | Claude, folgt dem Review |
| D-159 | Wo steht die Wellenvorschau? | Zettel unter „Welle n“ | Claude, umkehrbar |

## Sicherheit

Keine neue Eingabe von außen, kein Netz, kein neuer Spielstand. Die Wellenvorschau liest die
Missionsdatei, die beim Laden schon geprüft ist. Keine neuen Bilder: Vorschau und Auftritte
nutzen Atlas und `FxTextures`.

## Testplan

| Test | Was | Rot gesehen mit |
|---|---|---|
| `BuildAidsTests` (App): Wellenvorschau | Zusammenfassen je Art, Reihenfolge, höchstens drei, neue Arten, letzte Welle → nil | „neu“ ohne Blick auf frühere Wellen |
| `HudLayoutTests` | Tafel nie auf Festung, Fähigkeitsknopf oder Zettel; nie mehr Wegzellen als die beste freie Lage; Bogen meidet feste Ecken; alte Prüfungen weiter | Strafe 0 |
| `BuildAidsTests`: Bauplätze, Weg im Kreis (Länge = Simulation) | Deckkraft 1 an der Zelle, 0 ab drei Feldern, stetig fallend | Radius 0 |
| `TextFitTests` (App) | jeder Tafeltext mit echter Schrift in seiner Breite | alter Text „Neu: Zielwahl (…)“ |
| `BattleSceneTests` | Vorschau-Turm erscheint bei gewähltem Turm, kostet nichts, verschwindet beim Abbruch und nach dem Bau; Wegabdeckung vorhanden | Vorschau nicht entfernt |
| `FxDirectorTests` | Errichten, Aufwerten, Spezialisieren enden sauber (keine laufenden Tweens, Turm voll sichtbar, Maßstab 1) | Maske bleibt stehen |
| E2E `HUDE2ETests` | Wellenvorschau zeigt die Gegner der ersten Welle aus der Missionsdatei, nach dem Rufen Welle 2 | – |
| E2E `BankE2ETests` | neue Warnzeile der Bank | – |

Die Vorschau des Turms prüft `BattleSceneTests` an der Szene selbst; ein eigener
Bedienungshaken nur dafür wäre Code allein für den Test.

## Risiken

- **Der Auftritt verdeckt den ersten Schuss.** Gegenmittel: 0,55 s, der Turm ist ab 60 %
  voll sichtbar.
- **Der Zettel verdeckt den Kartenrand oben rechts.** In Mission 1 bis 7 liegt dort kein
  Eingang; die Tafel weicht ihm aus. Sonst kleiner machen oder in die Kopfleiste ziehen,
  sobald A-5 die Leiste in Schilder teilt.
- **Parallel zu A-1** (Laufen, ebenfalls `BattleScene`): kleine Schritte, vor jedem Push
  `main` einmischen.
