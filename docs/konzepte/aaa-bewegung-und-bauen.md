# Konzept: Bewegung, Bauen und Stimmigkeit (AAA-Schnitt A-1 bis A-5)

Status: **[VORSCHLAG]** · Stand 16.11.2026 · Thread „Spiel auf AAA-Niveau reviewen“
Grundlage: [Review](aaa-review.md) (Befunde G1 bis G9, B1 bis B5, P1 bis P5, R1 bis R3),
D-016 Stil, D-050 Effekte an Ereignissen, D-051 3D zu Bildfolgen, D-120 Ortslicht,
D-121 Bauplätze nur beim Bauen, [Marktanalyse](../game-design/market-analysis.md) Abschnitt 3.

## Ziel

Ein Spieler, der Mission 1 eine Minute lang ansieht, soll einen Ort sehen, in dem Figuren
gehen und Türme gebaut werden, nicht Bilder, die über eine Karte geschoben werden. Messbar:

- Jede Figur schaut dorthin, wohin sie geht, in jeder Wegrichtung.
- Keine Figur wechselt die Richtung in einem einzigen Bild.
- Zwei Gegner liegen nie deckungsgleich übereinander.
- Vor dem Kauf steht der Turm sichtbar an seinem Platz.
- Kein Element auf der Karte ist eine Vektorlinie oder aus einer anderen Kamera.

## Grenzen für alle Pakete

- **Die Simulation bleibt unberührt** (A-1 bis A-5). Sie rechnet weiter auf der Linie aus
  Strecken (`PathGeometry`), mit denselben Reichweiten, Zeiten und Prüfsummen. Alles hier
  ist Darstellung über Ereignisse und Zustand (Architekturregeln 2 und 3). Erst A-6
  (Leveldesign) ändert Regeln und Daten.
- **Keine Zahl im Code** (Regel 7): Darstellungswerte wie Kurvenradius oder Spurbreite
  stehen in `FxStyle`/`BattleStyle` als benannte Konstanten mit Begründung, wie bisher.
- **Bewegung reduzieren** gilt weiter: Mit „Bewegung reduzieren“ fallen Staub, Neigung und
  Wackeln weg, Laufen und Blickrichtung bleiben.

## A-1 Laufen

### Kurve statt Knick (B3)

Die Darstellung legt über jede Ecke des Wegs einen Kreisbogen mit dem Radius des
gemalten Wegs (eine Konstante je Karte aus dem Wegwerkzeug, heute 0,5 Felder). Die Figur
läuft auf dem Bogen; die Abweichung von der Simulationsposition ist höchstens
`r · (√2 − 1)`, also 0,21 Felder an der Spitze der Ecke, und nur dort.

- **Warum nur Darstellung:** Reichweite und Treffer bleiben in der Simulation exakt, das
  Labor rechnet weiter dieselben Ergebnisse. 0,21 Felder an einer Ecke sind kleiner als die
  Figur selbst; ein Spieler sieht keinen Treffer, der „daneben“ geht.
- **Wo:** neuer Typ `PathView` in `App/Battle` (nicht im Paket, weil er nur zeichnet):
  bekommt die Punkte des Wegs und den Radius, liefert für eine Strecke im Weg
  Position, Richtung und Krümmung. `BattleScene.sync` fragt ihn statt
  `path.position(at:)`.
- **Gleiche Strecke:** Der Bogen ist kürzer als die Ecke. `PathView` bildet die
  Simulationsstrecke auf seine eigene Strecke ab (Anteil je Abschnitt), damit eine Figur
  nie hinter oder vor ihrer Regelposition herläuft und an derselben Stelle stirbt.

### Spuren statt Gänsemarsch (B4)

Jeder Gegner bekommt aus seiner ID einen festen seitlichen Versatz quer zur Laufrichtung
(gleichverteilt in ±0,18 Feldern, bei der Panzerbestie ±0,08, beim Boss 0). Der Versatz
folgt der Kurve mit, damit die Spuren innen kürzer werden wie bei echten Läufern.

- Deterministisch aus der ID wie schon `FxMath.phase(forID:)`, kein Zufall.
- Zeichenreihenfolge weiter nach Bildschirmhöhe; mit Versatz entsteht Tiefe.
- Weg bleibt 1 Feld breit, die Spur bleibt sichtbar auf dem Sand.

### Drehen statt Spiegeln, drei Blickrichtungen (B2)

Jede Figur hat drei Bildfolgen aus demselben 3D-Modell: **seitlich** (für links
gespiegelt), **schräg von vorn** (läuft auf den Betrachter zu, auf dem Bildschirm nach
unten) und **schräg von hinten** (läuft weg, nach oben). Die Richtung kommt aus der
Tangente von `PathView`:

| Laufrichtung auf dem Bildschirm | Bildfolge |
|---|---|
| waagerecht (±35°) | seitlich, gespiegelt nach Richtung |
| nach unten | vorn, bei schräger Richtung leicht gespiegelt |
| nach oben | hinten |

Am Wechsel blendet die Figur über 0,12 s von einer Folge zur anderen, statt hart zu
springen; der Laufschritt läuft durch (gleicher Index, gleiche Phase). Kosten: 8 Bilder je
Folge × 3 Folgen × 4 Gegner = 96 Laufbilder statt 16, in 256 px rund 6 MB im Atlas; die
Werkzeugkette rendert sie in Minuten (`folge.py`, Kamera je Folge gedreht, Figur gleich).

### Gewicht (B5)

| Was | Wie | Je Gegner |
|---|---|---|
| Fußkontakt | Schatten wird beim Aufsetzen kurz breiter, beim Abheben schmaler | alle |
| Staub | kleine Wölkchen beim Aufsetzen, nur auf Sand, höchstens 3 je Figur gleichzeitig | Flitzer häufig, Panzerbestie groß und selten |
| Neigung | in Kurven zur Innenseite, aus der Krümmung von `PathView` | Flitzer stark, Plünderer leicht, Panzerbestie kaum |
| Wanken | Panzerbestie schwankt seitlich im Schritt, Kamera bebt beim Boss leicht | Panzerbestie, Boss |
| Anlaufen | beim Erscheinen aus der Höhle 0,4 s Beschleunigung in der Bildfolge, nicht in der Regel | alle |

### Tests (A-1)

- `PathViewTests`: Bogen bleibt innerhalb 0,21 Feldern um die Regelposition; Strecke
  ist monoton; Endpunkte stimmen mit der Simulation überein; Richtung stetig (kein Sprung
  größer als der Bogen erlaubt). Einmal rot gesehen mit Radius 0.
- `EnemyLaneTests`: gleicher Versatz für gleiche ID, Gegner mit gleicher Strecke liegen
  nie auf demselben Punkt, Versatz im Band.
- `FacingTests`: auf jedem Abschnitt jeder Missionsdatei die erwartete Bildfolge.
- E2E (`BattleE2ETests`): Mission 1 im Zeitraffer, Figurenknoten tragen die erwartete
  Folge an einer senkrechten Stelle.
- Bewegungsclip im Kontaktabzug (siehe unten) zum Ansehen.

## A-2 Bauen und Tafeln

### Vorschau vor dem Kauf (P1)

Erstes Tippen auf ein freies Feld: Feld, Bogen und **der zuletzt gebaute Turm halb
durchsichtig auf dem Feld** samt Reichweite. Tippen auf einen anderen Turm im Bogen
tauscht die Vorschau. Zweites Tippen baut. So steht in 07-ui-ux.md schon („Vorschau des
Turms auf dem Feld“), gebaut war es nie.

- Vorschau ist ein `TowerNode` mit Alpha 0,55 und ohne Schatten, kein zweites Bild.
- Reichweite: Fläche, die vom Weg abgedeckt wird, hell auf dem Weg (aus
  `PathGeometry.coverage`), statt eines Kreises über der Wiese. Das zeigt, was zählt:
  wie viel Weg der Turm sieht.

### Bauplätze gezielt statt Raster (P2)

Bis Bauinseln kommen (D-141): Beim Bauen nur die Felder im Umkreis von drei Feldern um den
Finger, weich auslaufend, statt aller 104 bis 120 Felder. Mit Bauinseln: die gemalten
Inseln leuchten leicht auf, außerhalb gibt es nichts zu zeigen.

### Errichten statt Abwerfen (P3)

| Ereignis | Auftritt | Dauer |
|---|---|---|
| Bauen | Erdfleck erscheint, Gerüst aus drei Balken, Turm wächst von unten, Banner springt hoch, Hammerschlag, leichte Haptik | 0,55 s |
| Aufwerten | Lichtsäule aus dem Turm, Turm streckt sich, neues Bild, Funken in Turmfarbe | 0,45 s |
| Spezialisieren | Turm sinkt kurz in einen Wirbel seiner Farbe, kommt als neue Gestalt hoch, Ring über den Boden | 0,7 s |
| Verkaufen | wie heute (versinkt, Münzen) | 0,4 s |

Der Turm ist während des Auftritts schon in der Simulation da (Regel unverändert). Der
Auftritt muss deshalb kurz bleiben; der erste Schuss darf ihn abbrechen.

### Tafel und Bogen kennen die Lage (P4, P5)

- **Bogen** rückt am Rand nach innen und unter der Kopfleiste weg; die Auswahl wird nie
  abgeschnitten. Turmbilder statt Symbole in den Knöpfen; Preis darunter, Beschriftung
  „Bauen“ als eigenes Schild, nie über einem Bild.
- **Tafel** bekommt in `HudLayout` eine Strafe für jedes Wegfeld und die Festung, die sie
  verdeckt, und wählt die Lage mit der kleinsten Strafe. Heute zählt nur, ob sie passt.
- **Text** wird nie abgeschnitten: Jede Tafel wird im Test mit dem längsten möglichen Text
  gemessen; was nicht passt, wird umformuliert oder bricht um.
- **Fähigkeitsknopf** gehört zur Kopfleiste oder zu einer festen Ecke, die keine Tafel
  belegt.

### Wellenvorschau (R2)

Der Knopf „Welle n“ zeigt bis zu drei Gegnersymbole der nächsten Welle mit Anzahl
(„12 Flitzer, 2 Panzerbestien“), neue Arten mit Ausrufezeichen. Daten kommen aus der
Missionsdatei, gezeigt wird über `BattleController`.

### Tests (A-2)

- `BuildPreviewTests`: Vorschau erscheint beim ersten Tippen, verschwindet beim Abbruch,
  kostet nichts.
- `HudLayoutTests`: neue Prüfung „Tafel verdeckt kein Wegfeld und nicht die Festung, wo
  es eine freie Lage gibt“ für alle Felder aller Missionen und vier iPhones; „Bogen
  innerhalb des sicheren Bereichs“; „längster Text passt“.
- E2E: Bauen mit Vorschau (erster Tipp zeigt Vorschauknoten), Wellenvorschau zeigt die
  Gegner der Missionsdatei.

## A-3 Figuren vollständig

- **Flitzer und Panzerbestie in 3D** (FX 02, Paket 6 der Roadmap), mit derselben
  Werkzeugkette wie Plünderer und Moorkönig: FLUX-Vorlage, TRELLIS, Skelett, Bildfolgen.
- **Renderweg nachschärfen** (G3): Heute verliert das 3D-Bild gegenüber der gemalten
  Vorlage Kontur und Gesicht. Drei Schritte, jeder einzeln am Bildpaar geprüft:
  1. In doppelter Größe rendern und verkleinern (schärfere Kanten).
  2. Konturpass: dunkle Außenlinie aus der Silhouette (Alpha-Kante erweitern), Breite
     wie die gemalten Figuren, damit alle vier Gegner dieselbe Kontur tragen.
  3. Gesicht aus der Vorlage: Augen und Mund als eigenes Bild auf den Kopfknochen
     („Gesichtsplatte“), damit der Charakter nicht in der Textur verschwimmt.
- **Drei Blickrichtungen** für alle vier Gegner (siehe A-1).
- **Abnahme am Bildpaar**: gemalte Vorlage links, Bildfolge rechts, auf dem Kampfplatz in
  Spielgröße. Fällt das Paar durch, wird nachgearbeitet, nicht ausgeliefert.

## A-4 Ein Ort: Kampfplatz in der Kamera der Türme

Hängt an **D-140** (wie) und **D-141** (Bauinseln). Optionen für D-140:

| Option | Was | Für | Gegen |
|---|---|---|---|
| **A: 3D-Diorama, gemalt überarbeitet (Empfehlung)** | Gelände, Weg, Bäume, Felsen, Wasser und Bauinseln als einfache 3D-Szene in Blender, gerendert mit **derselben Kamera und demselben Licht wie Türme und Figuren**; danach mit FLUX Bild-zu-Bild im Stil übermalt (Stärke niedrig, Formen bleiben). | Kamera, Licht, Schatten und Maßstab stimmen von selbst; Weg und Bauinseln liegen genau, weil sie aus den Daten gebaut werden; Höhe (Hänge, Brücken) wird möglich; jede Karte aus demselben Baukasten | Neues Werkzeug (Baukasten aus Formen, etwa 2 bis 3 Arbeitstage); Übermalen braucht Feinabstimmung |
| B: FLUX in Schrägsicht neu malen | Wie heute, aber Prompt und Vorlage aus 45° | Wenig neues Werkzeug | FLUX hält Blickwinkel und Wegverlauf schlecht genau (Erfahrung aus Grafik 06 bis 09: Wege wandern, Objekte landen auf dem Feld); jede Karte bleibt ein Einzelstück |
| C: Karte bleibt von oben, Figuren und Türme steiler | Figuren und Türme aus fast senkrechter Kamera rendern | Karten bleiben | Figuren verlieren Gesicht und Charakter, Türme werden Dächer; widerspricht D-016 |

**Warum A:** Die Werkzeugkette für 3D läuft schon im Container (Blender als Python-Paket,
gemessen 26.10.2026). Was Türme und Figuren stimmig macht, ist dieselbe Kamera; die Karte
in dieselbe Szene zu stellen, ist der direkte Weg zu G1. Dass das Diorama aus den Daten
gebaut wird, löst nebenbei das Wandern der Wege und macht Bauinseln präzise.

**Werkzeug** (`tools/kampfplatz-3d/`, Skill `spielgrafik` erweitert):
`diorama.py` liest die Missionsdatei (Weg, Bauinseln, Gelände) und eine Ortsbeschreibung
(Bodenart, Bäume, Wasser, Licht), setzt Bausteine aus einem kleinen Satz Formen
(Boden, Weg, Böschung, Baum, Fels, Wasser, Steg, Ruine), rendert in Kartengröße mit der
Kamera aus `asset-vertrag.json` und übermalt mit FLUX. Herkunft in `art/karten/ENTSTEHUNG.md`.

**Maßstab** (G4), Vorschlag für den Asset-Vertrag, in Feldern Höhe:

| Ding | heute | neu | Begründung |
|---|---|---|---|
| Flitzer | 0,9 | 0,7 | klein und schnell, hebt sich vom Plünderer ab |
| Plünderer | 0,9 | 0,8 | Referenzgegner |
| Panzerbestie | 1,2 | 1,15 | schwer, aber kein Turm |
| Turm | 1,1 | 1,4 | Türme sind Bauwerke, sie müssen die Gegner überragen |
| Boss | 2,3 | 2,0 | größer als jeder Turm, kleiner als die Festung |
| Festung | etwa 2 | 2,6 (Bild 3 Felder) | das Größte auf der Karte, wie es sich für das Ziel gehört |

Die neuen Werte kommen mit A-4 in den Vertrag und werden dort von `art-check` geprüft.

## A-5 Eine Malweise in der Welt

| Befund | Maßnahme |
|---|---|
| G5 Vektorformen | Auswahlrahmen, Reichweitenfläche, Stufenschild und Lebensleisten als gemalte Texturen (Neunteiler aus dem Rahmen der Tafeln); `SKShapeNode` nur noch für Testhilfen |
| G6 Kopfleiste | Kein Band mehr: einzelne Schilder aus dem Holz der Tafeln, auf der Karte schwebend, mit weichem Schatten; die Karte reicht bis an den Rand |
| G7 Spezialisierungen | sechs eigene Turmbilder (Salve, Falkenhorst, Gewitterkrone, Funkensäule, Moorherz, Fäulnis) aus den Entwürfen in `art/phase-2`, nachgemalt in der neuen Kamera; Stufen als Bauzeichen am Turm (Banner, Ring, Krone) statt Schild „III“ |
| G9 Türme | Wachturm: Schütze mit Armbrust als eigenes Bild, dreht sich in acht Richtungen zum Ziel und schießt sichtbar; Blitzturm: Kristall lädt auf, bevor er springt; Sporenturm: Hut hebt sich beim Ausstoß. Kein senkrechtes „Atmen“ mehr bei Stein |
| R1 Effekte verdecken | Effektbudget je Bereich (höchstens zwei große Wolken übereinander), Gegner mit dünner Kontur über den Effekten, Goldzahlen bündeln („+12“ statt drei Mal „+4“) |
| Licht auf Figuren | Gegner bekommen statt Tönung ein Kantenlicht in der Lichtfarbe des Ortes; bleiben hell lesbar (art-direction: Lesbarkeit vor Pracht), stehen aber im selben Licht |

## Kontaktabzug

Methode für jedes Paket (D-145), gebaut mit A-1:

- Neuer Schritt in der CI nach dem Probelauf: Die App startet jede Mission im
  Vorführmodus (`--demo --mission <id> --e2e-zeitraffer 3`) und sichert fünf Bilder an
  festen Ticks (vor Welle 1, Bauen mit Vorschau, volle Welle, letzte Welle, Ergebnis) und
  einen Clip von 4 s aus der vollen Welle.
- `scripts/kontaktabzug.py` setzt die Bilder je Mission zu einem Blatt zusammen und legt
  es als Artefakt `kontaktabzug` ab; im PR steht der Link.
- Was sich davon prüfen lässt, prüft der Schritt selbst: Die App schreibt je Bild eine
  kleine Messung (Zahl der Gegner, die von Effekten verdeckt sind; überlappende Gegner;
  Tafel auf Wegfeldern), und der Schritt warnt bei Überschreitung.

## Sicherheit

Keine neue Eingabe von außen, kein Netz. Neue Bilder bekommen Herkunft in
`ENTSTEHUNG.md` (Prompt, Seed, Werkzeug) und gehen durch `art-check`. Das 3D-Werkzeug
läuft nur im Entwicklungscontainer, nie in der App.

## Reihenfolge und Versionen

A-1 und A-2 als je ein PR (0.30.0, 0.31.0), A-3 als ein PR je Figur, A-4 und A-5 nach den
Karten D-140 und D-141. Jede Auslieferung mit Kontaktabzug im PR.
