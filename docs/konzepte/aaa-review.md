# Review: Mechanik, Leveldesign und Grafik auf AAA-Niveau

Status: **[VORSCHLAG]**, Befunde gemessen · Stand 16.11.2026, Version 0.29.1 · Thread
„Spiel auf AAA-Niveau reviewen“ · Nummern D-140 bis D-149

Anlass: Steffen am 16.11.2026: „agiere als spieldesigner und grafik designer. mache ein
komplettes review über die bisherigen mechanismen, level designs und grafiken. erarbeite
konzepte und methoden, wie man das noch besser und professioneller darstellt, dass es
wirklich wie ein aaa titel ist. das laufen, die türme platzieren sieht noch nicht perfekt
aus. wie sich generell das stimmige überall. level designs inkl. mechaniken sind auch
wichtig für den weiteren verlauf, so dass es konzeptionell dastehen muss.“

Dieses Dokument ist der Befund und der Plan. Die Methoden stehen in zwei Konzepten:

- [Bewegung, Bauen, Stimmigkeit](aaa-bewegung-und-bauen.md): wie die Figuren laufen, wie
  ein Turm entsteht, wie Karte, Türme, Figuren und Oberfläche ein Bild werden.
- [Leveldesign](aaa-leveldesign.md): Grundsätze, Missionsblätter für Region 1, Bauinseln,
  Gegnerrollen, Wellendramaturgie und wie das Labor Leveldesign prüft.

Maßstab ist die Liste „AAA-Anmutung“ der [Marktanalyse](../game-design/market-analysis.md)
(Abschnitt 3) und die Säulen aus [00](../game-design/00-vision-and-pillars.md).

## Wie geprüft wurde

Nicht nur Code gelesen, sondern das Spiel angesehen:

- **22 Bilder aus dem Simulator** (CI-Artefakt `simulator-probe` vom 08.11.2026, Lauf auf
  0.29.1): Kampf in Mission 1, Bauen, Aufwerten, Spezialisierung, Boss, Menüs, Karte.
  Die markierten Ausschnitte liegen unter [`art/review/`](../../art/review/README.md).
- **Alle Kampfplätze** als Vorschau mit Türmen und Gegnern (Grafik 05 bis 10).
- **Bildfolgen** von Plünderer und Moorkönig, gegen die gemalten Vorlagen.
- **Alle neun Missionsdateien** ausgezählt: Raster, Weglänge, Ecken, Bauland, Wellen,
  Gegnermischung.
- **Darstellungscode**: `BattleScene.sync`, `EnemyNode`, `TowerNode`, `FxDirector.build`,
  `PathGeometry`, `MissionMap`.

## Urteil in drei Sätzen

Das Fundament ist stärker als bei den meisten Indie-TDs: deterministische Simulation,
Effekte an Ereignissen, Tests auf jeder Ebene, ein Labor, das Balance misst, gemalte
Figuren mit Charakter und eine Oberfläche, die Werte zeigt. **Was fehlt, ist ein gemeinsamer
Raum:** Karte, Türme und Figuren sind aus drei Blickwinkeln, in zwei Malweisen und ohne
gemeinsamen Maßstab gebaut, deshalb wirkt alles einzeln gut und zusammen wie Aufkleber auf
einem Foto. **Und das Leveldesign hat noch keine Gestalt:** Neun Missionen sind dieselbe
Wiese mit einem anderen Sandweg, auf der fast jedes Feld bebaubar ist; die Entscheidung
„wo baue ich“ läuft überall auf „an die innere Kehre“ hinaus.

## Befunde, nach Gewicht

Gewicht: **A** bricht den AAA-Eindruck in jeder Sekunde · **B** fällt jedem Spieler
mehrmals auf · **C** fällt Kennern auf.

### Stimmigkeit (Grafik)

| # | Gew. | Befund | Beleg | Ursache |
|---|---|---|---|---|
| G1 | A | **Mehrere Blickwinkel in einem Bild.** Weg und Wiese sind senkrecht von oben gemalt, Bäume und Deko leicht schräg, Türme in etwa 45°, Figuren aus dem 3D-Werkzeug in 25 bis 35°. Figuren laufen „auf einem Foto“, statt in einem Ort zu stehen. | [Bild e](../../art/review/e-blickwinkel.jpg), art-direction.md verlangt „eine Kamera für alles, etwa 45°“ | Kampfplätze entstehen als FLUX-Bild von oben (`kampfplatz.py`), Figuren in Blender mit eigener Kamera; nichts gleicht die Blickwinkel ab |
| G2 | A | **Leere Wiese.** Zwischen Weg und Waldrand liegt in jeder Mission eine gleichförmige Rasenfläche ohne Gelände, Höhe, Wasser oder Wegmarken. Die Deko steht nur am Rand, wie ein Bilderrahmen. | [Bild a](../../art/review/a-kampf-mission-1.jpg), alle Kampfplätze | Bauland ist alles außer dem Weg (G2 ist die Bildseite von L1) |
| G3 | A | **Zwei Malweisen bei den Gegnern.** Plünderer und Moorkönig sind gerenderte 3D-Figuren (weicher, dunkler, Augen und Hutform verloren gegenüber der Vorlage), Flitzer und Panzerbestie gemalte Standbilder mit scharfer Kontur. Nebeneinander auf dem Weg sieht man zwei Spiele. | `fx-02/raider-v2-folge.jpg`, `moorkoenig/szene-0.28.2.jpg` | FX 02 hat nach dem Plünderer angehalten (Roadmap Paket 6 wartet auf Steffens Urteil) |
| G4 | B | **Kein gemeinsamer Maßstab.** Plünderer und Flitzer 0,9 Felder hoch, Panzerbestie 1,2, Turm 1,1, Boss 2,3, Festung als Bild 2,4 (sichtbar etwa 2). Der Boss ist so groß wie die Festung, die er stürmen soll; ein Turm ist kaum größer als ein Plünderer, und Flitzer und Plünderer sind gleich groß. | `BattleStyle.enemyHeight`, `towerHeight`, Bilder | Größen sind je Paket festgelegt worden, nie als Satz |
| G5 | B | **Vektorformen in der gemalten Welt.** Auswahlrahmen, Reichweitenring, Stufenschild „II/III“, Lebensleisten sind `SKShapeNode`-Linien und Flächen. Neben gemalten Türmen wirken sie wie Entwicklerwerkzeug. | [Bild b](../../art/review/b-bauen.jpg), `BattleScene.showSelection`, `TowerNode.showLevel` | Darstellung zuerst funktional gebaut, Malerei nie nachgezogen |
| G6 | B | **Die Oberfläche hat zwei Materialien.** Kopfleiste als flaches grünes Band über der ganzen Breite, Tafeln und Knöpfe aus dunklem Holz mit Goldrand. Das Band schneidet die Karte ab und passt zu nichts. | [Bild a](../../art/review/a-kampf-mission-1.jpg) | Band stammt aus UI-01 und wurde nie gestaltet |
| G7 | B | **Spezialisierungen sehen aus wie Stufe 2.** Salve, Falkenhorst, Gewitterkrone, Funkensäule, Moorherz, Fäulnis tragen das Bild der Stufe 2 plus Schild „III“. Die größte Entscheidung des Spiels ist auf dem Feld unsichtbar. | `BattleSprites.shadowNameAvailable`, Atlas ohne `tower_*_volley` usw. | Bilder aus Grafik 02 kamen nie in den Atlas |
| G8 | B | **Kampfplätze haben keine eigene Gestalt.** Wiese (M1), Pilzhain (M3), Sumpfpfad (M5a) und Tiefes Moor (M6a) unterscheiden sich vor allem durch Helligkeit; der Sumpf ist grüner Rasen. | Kampfplatz-Bilder M1 bis M7 | Gleicher Prompt-Aufbau, Thema nur im Rand |
| G9 | C | **Türme sind tot.** Kein Turm dreht sich zum Ziel, kein Schütze, keine Ladebewegung; die Steintürme „atmen“ (senkrechtes Strecken), was Stein nicht tut. | `TowerNode.idle` | FX 01 hat Schüsse und Treffer gemacht, nicht den Turm selbst |

### Bewegung („das Laufen“)

| # | Gew. | Befund | Beleg | Ursache |
|---|---|---|---|---|
| B1 | A | **Der häufigste Gegner läuft nicht.** Flitzer (in M5a 224, in M6a 268 Stück) und Panzerbestie gleiten als starres Bild mit Hüpfer über den Weg. Nur Plünderer und Boss bewegen Arme und Beine. | Atlas: `enemy_runner`, `enemy_brute` ohne `_walk_*` | FX 02 angehalten (G3) |
| B2 | A | **Nur eine Blickrichtung.** Jede Figur ist von der Seite gerendert und wird für links gespiegelt. Auf senkrechten Wegstücken läuft sie seitwärts nach oben oder unten, der Blick behält die letzte Richtung. Etwa die Hälfte jedes Wegs ist senkrecht. | `BattleScene.sync` (`facing` nur bei waagerechtem Anteil), Missionsdateien | Ein Blickwinkel je Bildfolge |
| B3 | A | **Knick statt Kurve.** Der Weg ist in der Simulation eine Linie aus Strecken; die Figur ändert an jeder Ecke die Richtung im selben Bild und dreht sich durch Spiegeln. Der gemalte Weg hat runde Ecken. | `PathGeometry.position(at:)` | Darstellung nimmt die Simulationsposition ohne Glättung |
| B4 | A | **Gänsemarsch auf der Mittellinie.** Alle Gegner laufen genau auf derselben Linie; gleich schnelle Gegner liegen exakt übereinander. Eine Welle Panzerbestien ist ein Klumpen, keine Truppe. | [Bild d](../../art/review/d-boss-gaensemarsch.jpg) | Kein seitlicher Versatz in der Darstellung |
| B5 | B | **Kein Gewicht.** Kein Staub, kein Fußkontakt, kein Neigen in der Kurve, kein Abbremsen oder Anlaufen. Die Panzerbestie wiegt so viel wie der Flitzer. | FX 01, `FxStyle.gait` | Bewegung als Hüpfkurve, nicht als Gewicht |

### Bauen („die Türme platzieren“)

| # | Gew. | Befund | Beleg | Ursache |
|---|---|---|---|---|
| P1 | A | **Kein Turm vor dem Bauen.** 07-ui-ux.md verspricht „Vorschau des Turms auf dem Feld“; gebaut ist ein gelbes Quadrat plus Reichweitenlinie. Der Spieler sieht erst nach dem Kauf, wie der Turm dort steht. | [Bild b](../../art/review/b-bauen.jpg), `BattleScene.showSelection` | Nie umgesetzt |
| P2 | A | **Kachelraster über der ganzen Karte.** Vor der ersten Welle und bei jeder Auswahl liegen 104 bis 120 helle Quadrate über der Malerei. Der Ort verschwindet genau in dem Moment, in dem der Spieler ihn lesen will. D-121 hat das Dauer-Raster entfernt, nicht das Bild beim Bauen. | [Bild b](../../art/review/b-bauen.jpg) | Bauland ist überall (L1), also gibt es nichts Gezieltes zu zeigen |
| P3 | B | **Der Turm fällt vom Himmel.** Bauen ist ein Sturz mit Federn, Staubring und Wackeln. Das liest sich als „Gegenstand abgeworfen“, nicht als „gebaut“. Aufwerten und Spezialisieren haben keinen eigenen Auftritt. | `FxDirector.build` | FX 01 hat einen Effekt für alle Bauarten |
| P4 | B | **Tafel und Kreismenü kennen die Lage nicht.** Am oberen Rand ist der Bogen abgeschnitten und der Turm halb unter der Kopfleiste; die Werte-Tafel legt sich auf Weg und Festung, wo die Gegner ankommen; Text ist abgeschnitten („Stärkst…“, „aufwerten für 35…“); der Fähigkeitsknopf liegt auf der Tafel. | [Bild c](../../art/review/c-tafel.jpg) | `HudLayout` misst Platz, nicht Bedeutung (Weg, Festung) |
| P5 | C | **Turmsymbole statt Türme im Bogen.** Der Bogen zeigt kleine Symbole auf runden Knöpfen; die Beschriftung „Bauen“ überlagert das obere Symbol. | [Bild b](../../art/review/b-bauen.jpg) | UI-01 |

### Lesbarkeit im Kampf

| # | Gew. | Befund | Beleg |
|---|---|---|---|
| R1 | A | **Effekte verdecken die Gegner.** Bei vier Türmen auf engem Raum (die typische Bauweise, siehe L2) stapeln sich Sporenwolke, Blitz, Münzen und Zahlen; die Gegner darin sind nicht zu sehen. Säule 2 („in jeder Sekunde sehen, was passiert“) ist an der wichtigsten Stelle verletzt. | [Bild a](../../art/review/a-kampf-mission-1.jpg) |
| R2 | B | **Keine Wellenvorschau.** Der Knopf „Welle 1“ zeigt den Bonus, nicht, was kommt. Wer Flitzer oder Panzerbestien erst sieht, wenn sie laufen, kann nicht planen (Säule 3). | Bilder b, c |
| R3 | C | **Die Kamerainsel des iPhones liegt im Spielbild**, direkt unter dem Eingang der Gegner. | [Bild a](../../art/review/a-kampf-mission-1.jpg) |

### Mechanik und Leveldesign

| # | Gew. | Befund | Beleg |
|---|---|---|---|
| L1 | A | **Bauland ist fast alles.** In jeder Mission sind 104 bis 120 von 144 Feldern bebaubar (alles mit 0,9 Feldern Abstand zum Weg). D-005 hat „Zonen aus Rasterzellen“ entschieden; gebaut ist eine einzige Zone, die ganze Karte. Damit gibt es keine Bauplatz-Entscheidung außer „nah an der Kehre“. | `MissionMap.buildableCells`, Auszählung aller Missionsdateien |
| L2 | A | **Eine Lösung je Karte.** Reichweiten 2,2 bis 2,5 Felder auf einem 16×9-Raster: Wer gewinnt, baut einen Haufen an die Stelle, wo der Weg sich am häufigsten nähert. Das Labor bestätigt Mischung statt Monokultur (D-071), misst aber nicht, ob es mehr als einen Ort gibt, an dem sie gewinnt. | Missionsdateien, Bilder a, d |
| L3 | A | **Neun Missionen, eine Form.** Alle: 16×9, ein Weg, ein Eingang, ein Ausgang, 10 Wellen, dieselben drei Gegnerarten (ab M7 der Boss). Unterschiede: Wegform (4 bis 8 Ecken, nur Kehren und Schleifen) und Wellenmischung. Kein zweiter Eingang, keine Kreuzung, kein Gelände, das etwas tut. | Auszählung unten |
| L4 | B | **Drei Gegnerrollen, gelöst bis Mission 4.** Masse (Plünderer → Blitz), Tempo (Flitzer → Sporen), Panzer (Bestie → Wachturm II). Danach bringt nichts mehr eine neue Frage, nur mehr vom Selben; Spezialisierungen sind Antworten ohne neue Fragen. Marktführer bringen in der ersten Region fünf bis acht Gegnerarten. | Missionsdateien, [Marktanalyse](../game-design/market-analysis.md) |
| L5 | B | **Keine Dramaturgie in der Mission.** Jede Mission hat 10 Wellen im selben Takt (15 s Pause). Es gibt keinen Höhepunkt, keine Atempause, keinen Moment, an den man sich erinnert, außer dem Boss in M7. | Missionsdateien |
| L6 | C | **Der Bosskampf endet wie jede Niederlage.** Kein Auftritt des Moorkönigs an der Festung, keine eigene Musik (Paket offen beim Ton-Thread), dieselbe Tafel. | [Bild d](../../art/review/d-boss-gaensemarsch.jpg) |

Auszählung aller Missionsdateien (16×9-Raster, Bauland = Felder mit Mindestabstand zum Weg):

| Mission | Weglänge | Ecken | Bauland | Wellen | Gegner gesamt (Plünderer / Flitzer / Panzerbestie) |
|---|---|---|---|---|---|
| M1 | 32 | 6 | 114 | 10 | 125 / 84 / 9 |
| M2 | 30 | 6 | 116 | 10 | 164 / 113 / 14 |
| M3 | 38 | 6 | 108 | 10 | 180 / 125 / 16 |
| M4 | 28 | 4 | 118 | 10 | 151 / 100 / 41 |
| M5a | 36 | 8 | 110 | 10 | 126 / 224 / 19 |
| M5b | 26 | 4 | 120 | 10 | 110 / 88 / 73 |
| M6a | 34 | 6 | 112 | 10 | 106 / 268 / 40 |
| M6b | 42 | 4 | 104 | 10 | 58 / 96 / 107 |
| M7 | 30 | 4 | 116 | 10 | 60 / 200 / 76, dazu der Boss |

### Was gut ist und bleibt

Damit der Umbau nichts Gutes mitreißt:

- **Synergie als Kern** (Säule 1), sichtbar gemacht durch den Sporenfunken (P2-8). Das ist
  die eigene Stimme des Spiels und bleibt der Maßstab für jede neue Regel.
- **Wertetafel mit Vergleich** (UI-02). Kein Marktführer zeigt so klar, was eine
  Aufwertung bringt; für Steffen und datenliebende Spieler ein Merkmal.
- **Figurencharakter**: Plünderer, Flitzer, Panzerbestie, Moorkönig haben Silhouette und
  Farbe nach Rolle. Die Vorlagen sind gut, nur ihre Umsetzung ins Spiel ist uneinheitlich.
- **Titelbild und Hauptmenü** haben die Anmutung, die das ganze Spiel braucht: ein Ort,
  ein Licht, eine Kamera.
- **Technik**: Ereignisse, fester Takt, Determinismus, Labor, Tests. Fast alles unten ist
  Darstellung und Daten, nicht Regelumbau; das hält das Risiko klein.

## Leitbild: ein Ort, ein Licht, eine Kamera, ein Maßstab

Was die Marktführer hochwertig wirken lässt, ist kein einzelnes Bild, sondern dass jedes
Bild nach denselben Regeln entsteht. Daraus vier Regeln für alles, was ab jetzt gebaut
wird, prüfbar statt Geschmackssache:

1. **Eine Kamera.** Karte, Deko, Türme, Figuren, Festung und Effekte aus demselben
   Blickwinkel. Wird eine Grafik aus einer anderen Kamera gebraucht (Symbol, Porträt),
   lebt sie in der Oberfläche, nie auf der Karte.
2. **Ein Licht.** Ein Sonnenstand je Kampfplatz, auf Karte, Türme und Figuren gleich
   angewandt (D-120 ist der erste Schritt, die Figuren fehlen).
3. **Ein Maßstab.** Eine Größentabelle für alle Dinge auf der Karte, mit Verhältnissen,
   die der Spieler sofort versteht: Festung > Boss > Turm > Panzerbestie > Plünderer >
   Flitzer.
4. **Eine Malweise.** Alles auf der Karte ist gemalt oder gerendert und nachgemalt, mit
   derselben Kontur. Keine Vektorlinie, kein Standardknopf in der Welt.

Wie jede Regel umgesetzt und geprüft wird: [Bewegung, Bauen, Stimmigkeit](aaa-bewegung-und-bauen.md).

## Methoden, mit denen das professionell bleibt

Nicht nur einmal reparieren, sondern so arbeiten, dass es nicht wieder auseinanderläuft:

| Methode | Was | Warum |
|---|---|---|
| **Kontaktabzug aus der CI** | Jeder Lauf legt je Mission dieselben fünf Bilder ab (vor Welle 1, Bauen, volle Welle, Boss oder letzte Welle, Ergebnis) und einen Bewegungsclip von 4 s. Ein Blatt, nebeneinander. | Der Stand wird angesehen, nicht vermutet. Heute gibt es Bilder nur aus Mission 1 und zufälligen Testmomenten. |
| **Messblatt Stimmigkeit** | Für jedes neue Bild: Blickwinkel, Lichtrichtung, Größe in Feldern, Kontur. Teile davon prüft `art-check` (Größe aus Atlas und Vertrag, Kontur über Randhelligkeit). | Die vier Regeln oben sind dann Tests, keine Hoffnung. |
| **Vorher-nachher am echten Ort** | Jede Grafikänderung kommt als Bildpaar auf dem Kampfplatz in den PR, nicht als freigestelltes Einzelbild. | So hat Grafik 10 funktioniert; das wird Pflicht. |
| **Vertikalschnitt vor dem Ausrollen** | Neue Anmutung zuerst an Mission 1 vollständig, Steffen urteilt am Gerät, dann die anderen Missionen. | Ein Urteil an einem fertigen Stück ist billiger als neun halbe. |
| **Missionsblatt** | Jede Mission hat vor dem Bau ein Blatt: Frage, Moment, Bauinseln, Gelände, Gegner, Wellenbogen. | Leveldesign wird geplant, nicht aus Wegform und Wellenzahl abgeleitet. |
| **Labor misst Leveldesign** | Neue Kennzahlen: Zahl der verschiedenen Bauorte, die gewinnen; Anteil des Baulands, das in Siegen genutzt wird. | „Eine Lösung je Karte“ (L2) wird sichtbar, bevor ein Spieler es merkt. |

Ablauf für Reviews dieser Art: Skill [`aaa-pruefung`](../../.claude/skills/aaa-pruefung/SKILL.md).

## Plan

Reihenfolge nach Wirkung je Aufwand und nach Abhängigkeit. Die Pakete stehen in der
[Roadmap](../production/roadmap.md#aaa-schnitt-d-140-bis-d-149) unter „AAA-Schnitt“.

| # | Paket | Befunde | Hängt an | Inhalt |
|---|---|---|---|---|
| A-1 | **Laufen** | B2 bis B5, R3 | – | Kurven statt Knick, Spuren statt Gänsemarsch, Drehen statt Spiegeln, Staub und Gewicht. Nur Darstellung (D-144). |
| A-2 | **Bauen und Tafeln** | P1, P3 bis P5, R2 | – | Turm-Vorschau vor dem Kauf, Errichtung statt Sturz, eigener Auftritt für Aufwerten und Spezialisieren, Tafel weicht Weg und Festung, Text nie abgeschnitten, Wellenvorschau. |
| A-3 | **Figuren vollständig** | B1, G3 | – | Flitzer und Panzerbestie in 3D mit Laufzyklus, alle vier Gegner in drei Blickrichtungen, Renderweg mit Konturpass, damit 3D aussieht wie die Vorlage. |
| A-4 | **Kampfplatz Mission 1 neu** | G1, G2, G4, G8, L1, P2 | D-140, D-141 | Karte in der Kamera der Türme, mit Gelände und Bauinseln; Maßstab für alles. |
| A-5 | **Eine Malweise in der Welt** | G5, G6, G7, G9, R1 | A-4 | Gemalte Auswahl, Ringe, Schilder; Kopfleiste im Material der Tafeln; sechs Spezialisierungsbilder; Türme zielen; Effekte lassen Gegner frei. |
| – | **Urteil Steffen am Vertikalschnitt** | | A-1 bis A-5 | Mission 1 auf dem Gerät. |
| A-6 | **Leveldesign Region 1** | L1 bis L6 | D-141, D-143, Urteil | Missionsblätter umsetzen: Bauinseln und Gelände je Karte, neue Gegnerrollen, Wellenbogen, Labor-Kennzahlen. Mission für Mission, nicht parallel. |
| A-7 | **Kampfplätze M2 bis M7 neu** | G1, G2, G8 | A-6 je Mission | Gleicher Weg wie A-4, Karte für Karte mit ihrem Missionsblatt. |

A-1 und A-2 hängen an keiner Entscheidung und können sofort beginnen. A-3 setzt FX 02 fort,
das auf Steffens Urteil am Plünderer gewartet hat; dieses Review ist das Urteil („das laufen
sieht noch nicht perfekt aus“), deshalb wird A-3 zusammen mit den Blickrichtungen gebaut.

## Entscheidungen

| Nr. | Frage | Empfehlung | Stand |
|---|---|---|---|
| D-140 | Wie die Kampfplätze in dieselbe Kamera kommen | 3D-Diorama mit Kamera der Türme, gemalt überarbeitet | Karte an Steffen |
| D-141 | Bauland: überall oder gestaltete Bauinseln | Bauinseln (D-005 wird endlich als Zonen gebaut) | Karte an Steffen |
| D-142 | Reihenfolge des Umbaus | Vertikalschnitt an Mission 1, dann ausrollen | Karte an Steffen |
| D-143 | Neue Gegnerrollen in Region 1 | zwei neue Arten (Heiler, Teiler) | Karte an Steffen |
| D-144 | Bewegung glätten nur in der Darstellung | gilt (Claude, umkehrbar) | [Konzept](aaa-bewegung-und-bauen.md#a-1-laufen) |
| D-145 | Kontaktabzug je Mission aus der CI als Prüfmethode | gilt (Claude, Werkzeug) | [Konzept](aaa-bewegung-und-bauen.md#kontaktabzug) |

Die Optionen und Begründungen stehen in den beiden Konzepten und im
[Entscheidungsprotokoll](../decisions/decision-log.md).

## Risiken

- **Neubemalung aller Kampfplätze** (A-4, A-7) ist der größte Brocken. Der Vertikalschnitt
  (D-142) begrenzt ihn, bis feststeht, dass der Weg trägt.
- **Bauinseln ändern die Balance** jeder Mission. Jede Karte geht deshalb durch das Labor,
  bevor sie ausgeliefert wird; Werte bleiben [HYPOTHESE] bis zum Spieltest.
- **Neue Gegner sind neue Regeln** in der Simulation. Sie kommen nacheinander, mit Tests
  und Labor, nicht parallel (Erfahrung aus M3/M4).
- **Der Spieltest WP-15 fehlt weiter.** Dieses Review ersetzt ihn nicht; es sagt, was ein
  erfahrenes Auge sieht. Was Spieler tatsächlich stört, misst erst der Test.
