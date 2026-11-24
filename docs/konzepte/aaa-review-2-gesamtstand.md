# Review 2: Gesamtstand nach Mission 1 auf AAA-Niveau

Status: **[VORSCHLAG]**, Grundsatzfrage als Karte S38 (D-210) · Stand 24.11.2026 · Thread
„Ganzes Spiel auf einheitlichen AAA-Stand bringen“ · Nummern D-210 bis D-229
Grundlage: [Review 1](aaa-review.md) (16.11.), [Grafik 11](grafik-11-kampfplatz-in-der-welt.md),
[Leveldesign](aaa-leveldesign.md), Skill `aaa-pruefung`.

Auftrag (Steffen, 24.11.2026): „mache anschließend ein komplettes Review auf den aktuellen
Stand und passe alles an, dass es den gleichen Stand hat. Mache auch sonstigen Review auf
UI und Grafiken und verbessere, wo Bedarf ist.“

## Wie geprüft wurde

- Kontaktabzug aller neun Missionen und alle 23 Oberflächenbilder des Probelaufs vom
  24.11.2026 15:33 UTC (Stand 0.48.0 mit A-5 Teil 3, Lauf auf dem Zweig von PR #117), dazu
  die Missionsdateien ausgezählt.
- Markiertes Bild: [f-stand-region-1.jpg](../../art/review/f-stand-region-1.jpg)
  (Mission 1 als Soll, M3, M5a, M7 heute, rote Nummern = Befunde unten).
- Gewicht wie in Review 1: **A** bricht den Eindruck in jeder Sekunde, **B** fällt jedem
  Spieler mehrmals auf, **C** fällt Kennern auf.

## Urteil in drei Sätzen

Mission 1 ist ein Ort: Diorama aus der gemeinsamen Kamera, Bauinseln als Grashügel,
Torburg am Wegende, Türme mit Schützen, Gegner mit Gewicht. **Die übrigen acht
Kampfplätze stehen noch auf dem Stand vor Review 1:** von oben gemalte Wiese, Bauen
überall, Türme auf Rasen ohne Erdung, die alte Frontfestung im Lichthof. Wer Mission 1
gewinnt, spielt danach ein anderes, älteres Spiel; die Oberfläche hat daneben eine Reihe
kleiner Brüche (Text, Ränder, Platzhalter), die einzeln wenig, zusammen viel kosten.

## Befunde

### Kampfplätze M2 bis M7

| # | Gew. | Befund | Beleg | Ursache |
|---|---|---|---|---|
| K1 | A | **Zwei Kameras in einer Kampagne.** M1 ist 40°-Diorama, M2 bis M7 sind senkrecht von oben gemalt; Türme und Figuren kommen aus 40°. Der Bruch fällt beim ersten Wechsel M1 → M2 auf. | Bild f, Kontaktabzug alle Missionen | A-7 wartete auf das Urteil zu Mission 1 (D-142) |
| K2 | A | **Bauen überall, leere Wiese.** Ohne `map.zones` sind 104 bis 120 von 144 Feldern bebaubar; die Mitte ist gleichförmiger Rasen (Bild f, 2). Die Bauplatz-Entscheidung aus Mission 1 verschwindet wieder. | Missionsdateien: nur `mission-01` hat `zones` | L1 aus Review 1, nur für M1 gelöst |
| K3 | A | **Türme schweben auf Rasen.** Kein Hügel, keine Mauer, kein Kontakt; der Fuß endet als Kontur auf Gras (Bild f, 1). | Bild f | Erdung (D-192 bis D-196) gilt nur, wo Inseln liegen |
| K4 | A | **Alte Festung.** M2 bis M7 zeigen die Frontansicht im Lichthof, nicht die Torburg; der Weg endet daneben (Bild f, 3). | Bild f, Kontaktabzug | Torburg (D-191) ist ins Bodenbild von M1 gerendert |
| K5 | B | **Türme ragen in den Weg.** Ein Turm am Wegrand überdeckt mit seinem Körper den Weg dahinter (Bild f, 7); in M1 verhindern das die Inseln. | Bild f | wie K2 |
| K6 | B | **Zwergenbank in alter Malweise**, ohne Erdung, frei auf Gras (Bild f, 4 und 6). | Bild f, M3, M5a | Bild aus P2-5, nie nachgezogen |
| K7 | B | **Orte unterscheiden sich kaum.** Pilzhain, Sumpf, Ruinen und Moor sind gleich grüner Rasen; das Thema steht nur im Rand (G8 aus Review 1, unverändert). | Kontaktabzug M3 bis M7 | Gleicher Aufbau je Kampfplatz |

### Oberfläche

| # | Gew. | Befund | Beleg | Ursache |
|---|---|---|---|---|
| U1 | A | **Wellenschild wird braun und matschig.** „Welle n von 10“ ist beim Ein- und Ausblenden dunkelbraun statt weiß mit Kontur (Bild f, 5; M4, M6b). | Kontaktabzug M5a, M6b; `p2-10-panzerung.png` | `FxDirector.outlinedLabel` stapelt fünf dunkle Kopien unter die weiße Schrift; SpriteKit blendet jede Kopie einzeln aus, die dunklen scheinen durch. Betrifft auch schwebende Goldzahlen |
| U2 | B | **Weltkarte als kleines Bild im Dunkel.** Die Regionskarte füllt nur zwei Drittel der Höhe, links, unten und rechts liegt leeres Dunkelgrün; „Menü“ klebt auf der Kartenkante. | `5-weltkarte.png` | `CampaignMapView` setzt die Karte mit festem Seitenverhältnis |
| U3 | B | **Abgeschnittener Text auf der Weltkarte.** Die Zeile über „Mission 1“ ist oben angeschnitten, die Avatar-Fähigkeit endet mit „…“. | `5-weltkarte.png` | Seitentafel ohne sichere Ränder; Text auf eine Zeile begrenzt |
| U4 | B | **Türme unter der Kopfleiste und im gemalten Wald.** Ohne Inseln darf man in M2 bis M7 auf Zelle (0, 0) bauen: Der Turm steht halb unter dem Lebensschild und im Waldrand, sein Ring liegt über dem Zurück-Knopf. Die Knöpfe selbst weichen richtig aus. | `d-130-vergleich.png`, `p2-6`, `p3-1`, `p3-2` | Bauland überall (K2); Mission 1 hat dort keine Insel |
| U5 | C | **„Leistungsprobe“ im Hauptmenü.** Ein Entwicklerknopf steht gleichrangig neben „Spielen“. | `0-hauptmenue.png` | bleibt bis zur Messung S4; gehört in die Einstellungen |
| U6 | C | **Avatar- und Schmiede-Tafeln sind flaches Braun.** Hauptmenü und Weltkarte sind gemalt, Avatar, Talente, Ausrüstung und Schmiede sind Farbflächen ohne Holz, ohne Licht. | `6-avatar.png`, `8`, `9`, `10` | gebaut vor D-180, Haut der Tafeln nie übertragen |
| U7 | C | **Ergebnistafel ohne Ort.** Niederlage und Sieg legen dieselbe Tafel über ein abgedunkeltes Bild; der Titel steht auf einem grauen Schild, das zu keinem anderen Schild passt. | `4-niederlage.png`, `p3-4-moorkoenig.png` | UI-01 |

### Was gut ist und bleiben muss

- Mission 1 als Maßstab: Diorama, Inseln, Torburg, Waldrand als Rahmen, Licht von links
  hinten.
- Gegner: drei Blickrichtungen, Bögen, Spuren, Staub; Kontaktabzug misst null verdeckte
  Gegner in allen neun Missionen.
- Kopfleiste als Holzschilder, Wellenvorschau, Werte-Tafel mit Vergleich.
- Hauptmenü mit gemaltem Bild, Weltkarte als gemalte Region.

## Maßnahmen

| Paket | Was | Befunde | Version |
|---|---|---|---|
| **R2-1 Oberfläche** | Wellenschild und Zahlen als ein Bild ausblenden (U1); Weltkarte füllt den Schirm, Tafel passt ganz (U2, U3); „Leistungsprobe“ in die Einstellungen (U5) | U1 bis U3, U5 | 0.50.0, sofort, berührt keine Kampfplätze |
| **R2-2 Kampfplätze** | M2 bis M7 als Diorama aus derselben Kamera wie M1, mit Bauinseln (Grashügel), Torburg am Wegende und eigenem Ort je Mission (Stollen, Pilzhain, Ruinenrand, Sumpfpfad, Ruinenhof, Moor, Tempel, Bosslichtung). Inseln je Mission erst ins Labor, dann ins Bild (Regel aus A-4) | K1 bis K5, K7, U4 | nach Merge von PR #119; je zwei Missionen ein PR |
| **R2-3 Bauten** | Zwergenbank in die Kamera und Malweise der Türme, mit Kontakt | K6 | mit dem PR, der M2 umstellt |
| **R2-4 Tafeln** | Avatar, Talente, Ausrüstung, Schmiede und Ergebnistafel in die Haut der Holzschilder | U6, U7 | nach R2-2 |

Grundsatzfrage S38 (D-210): **wie weit „gleicher Stand“ für M2 bis M7 geht.** Empfehlung:
Bildstand von Mission 1 (Diorama, Inseln, Torburg, eigener Ort), Wege bleiben; Gelände
mit Regeln (Anhöhe, Furt) und mehrere Wege (A-6 Rest, A-9) folgen danach. Bis zur Antwort
wird die Empfehlung vorbereitet.

## Architektur

- **Kampfplatz je Mission:** `tools/kampfplatz-3d/orte/mission-NN.json` (Ort, Licht,
  Farben, Landschaft) und `map.zones` in der Missionsdatei. `plan.py` und `diorama.py`
  bleiben eine Umsetzung für alle Missionen; was je Ort anders ist, steht in den Daten.
- **Die App kennt keinen Unterschied** zwischen Mission 1 und den übrigen: Festungslage,
  Inseln und Boden kommen aus Missionsdatei und Atlas. Wo heute Code `mission-01`
  besonders behandelt, wird daraus „Mission hat Inseln / Torburg“.
- **Wellenschild (U1):** `OutlinedText` zeichnet Schatten, Kontur (runde Ecken) und
  Füllung mit CoreText in **ein** Bild; die Deckkraft wirkt auf das Ganze. Goldzahlen
  zeichnen beim Bündeln neu. Keine neue Abhängigkeit.
- **Weltkarte (U2, U3):** Die Karte bleibt eingepasst (kein Knoten fehlt); dahinter füllt
  dasselbe Bild vergrößert, weich und abgedunkelt den Rest, die Kante der Karte läuft
  weich hinein. Die Tafel rechts ist knapper und wählt mit `ViewThatFits` die größte
  Fassung, die passt: erst ohne Zeile zum Volk, dann ohne Neuheit.
- **Türme unter der Kopfleiste (U4)** löst R2-2: Keine Inselzelle liegt unter einem Schild
  der Kopfleiste oder im gemalten Waldrand; ein Test prüft das je Mission.

## Sicherheit

Keine neue Eingabe von außen, kein Netz. Neue Missionsfelder (`zones`) laufen durch die
bestehende Prüfung beim Laden. Neue Bilder mit Herkunft in `art/karten/ENTSTEHUNG.md`.

## Tests

| Ebene | Test |
|---|---|
| Simulation | `ZoneTests` je Mission: Inseln gültig, je Insel ein freier Platz, Feldzahl im Rahmen; Balance- und Labortests mit Inseln |
| App | Wellenschild ist ein Bild ohne Kinder, Füllung hell (`FxDirectorTests`); Missionstafel passt für jede Mission auf 393 pt, knapp auf 375 pt (`CampaignPanelTests`); keine Inselzelle unter der Kopfleiste (mit R2-2) |
| E2E | Hauptmenü ohne Leistungsprobe-Knopf, Einstellungen mit ihm (`GuideE2ETests`); Art der Mission liegt ganz im Bild (`AvatarE2ETests`); Bauen auf Inselzellen in einer späteren Mission (mit R2-2) |
| Bild | `art-check` für jede Mission mit Inseln: Weg bis ins Tor, Inselmitten Gras, nichts Hohes auf Weg oder Insel; Kontaktabzug aller Missionen |
| Ansehen | Vorher-nachher je Mission im PR |

## Entscheidungen

| Nr. | Was | Stand |
|---|---|---|
| D-210 | Umfang „gleicher Stand“ für M2 bis M7 (Karte S38) | wartet auf Steffen, Empfehlung wird vorbereitet |
| D-211 | Wellenschild und schwebende Zahlen werden als ein Bild ausgeblendet | gilt (Claude, Darstellung) |
| D-212 | Keine Bauinsel unter der Kopfleiste oder im gemalten Waldrand (je Mission geprüft) | gilt (Claude, mit R2-2) |
| D-213 | Weltkarte füllt den Schirm (Bild weich ergänzt), Missionstafel passt ganz und lässt auf niedrigen Schirmen zuerst die Zeile zum Volk weg | gilt (Claude, Darstellung) |
| D-214 | „Leistungsprobe“ zieht vom Hauptmenü in die Einstellungen | gilt (Claude, bis S4 gemessen ist) |
