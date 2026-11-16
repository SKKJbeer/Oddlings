# Konzept: Gamedesign als Gesamtbild

Status: Abschnitte 1 bis 5 **[VORSCHLAG]**, Kurve, Wege und Stufen **[ENTSCHIEDEN]** (D-146 bis D-148) · Stand 16.11.2026, Version 0.29.1 · Thread „Spiel auf AAA-Niveau reviewen“
Übersichtsseite mit Kurven und Karten: <https://claude.ai/artifact/L4XKJaog56HrA1pGN2BoC7>
Grundlage: [05 Kampagne](../game-design/05-campaign-and-progression.md),
[04 Balance](../game-design/04-economy-and-balance.md), [Leveldesign](aaa-leveldesign.md),
[Review](aaa-review.md), Missionsdateien in `Packages/OddlingsCore/.../Resources/Balance/`.

Dieses Dokument bindet Kampagne, Schwierigkeit, Wege und Komplexität zusammen. Regeln einzelner
Missionen stehen weiter in [aaa-leveldesign.md](aaa-leveldesign.md) (Missionsblätter), Zahlen
nur in den Missionsdateien.

## 1 Kampagne in drei Regionen

Jede Region bringt ein Thema: genau eine neue Gegnerart als Hauptthema, höchstens zwei
Geländeregeln, eine neue Wegart, einen Boss. Türme kommen nicht je Region dazu, sondern als
Spezialisierungen und später als volkseigene Türme (Erweiterungen, D-015).

| Region | Thema | Gegner | Gelände | Wege | Boss | Stand |
|---|---|---|---|---|---|---|
| 1 Flüsterwald | lernen, was welcher Turm kann | Plünderer, Flitzer, Panzerbestie, Moorhexe, Pilzbalg (D-143) | Anhöhe, Furt | ein Weg bis M5, ab M6 zwei Eingänge und Kreuzung (D-147) | Moorkönig | gebaut bis auf Gelände, Inseln, neue Gegner, Wege |
| 2 Eisengipfel | Höhe und Luft | Schattenflieger (D-027), später Schildträger | Eis, Schneewehe | Serpentinen über Höhenstufen, Lawine sperrt einen Weg | Eisriese, zerschlägt je Phase einen Turm | [VORSCHLAG] |
| 3 Sturmklamm | Wetter und Wege, die sich ändern | Gräber, Sturmrufer | Wind, Gewitter | umlegbare Tore | Sturmdrache, wechselt den Eingang | [VORSCHLAG] |

## 2 Komplexitätsleiter

Gezählt werden die Dinge, die ein Spieler im Kopf haben muss (Türme, Gegnerarten, Regeln,
Spezialisierungen, Gelände, Wegarten).

| | M1 | M2 | M3 | M4 | M5 | M6 | M7 | N |
|---|---|---|---|---|---|---|---|---|
| heute | 8 | 10 | 12 | 13 | 16 | 19 | 20 | 20 |
| mit Vorschlag | 8 | 10 | 12 | 14 | 17 | 22 | 24 | 25 |

Heute bleibt die Leiter ab M5 fast stehen. Mit Gelände, Heiler und Teiler sowie mehreren
Wegen steigt sie bis zum Ende, ohne dass eine Mission mehr als zwei Dinge bringt.

Jede Neuheit läuft durch drei Schritte: **kennenlernen** (leichte Welle, ohne Text vorgeführt),
**prüfen** (Spitze, die man ohne sie verliert), **verbinden** (nächste Mission, zusammen mit
etwas Bekanntem).

## 3 Schwierigkeit

Maß ist die Reserve aus dem Labor (D-073): der größte Faktor auf das Leben aller Gegner, bei
dem die beste Bauweise noch gewinnt.

| | M1 | M2 | M3 | M4 | M5a | M5b | M6a | M6b | M7 |
|---|---|---|---|---|---|---|---|---|---|
| gemessen, beste Bauweise | 1,36 | 1,19 | 1,35 | 1,25 | 1,57 | 1,40 | 1,38 | 1,28 | 1,48 |
| Ziel [HYPOTHESE] | 1,45 | 1,32 | 1,34 | 1,24 | 1,30 | 1,30 | 1,20 | 1,20 | 1,12 |

Ab M5 mit Zwergen gemessen (aus [04](../game-design/04-economy-and-balance.md)), davor ohne Volk.

**Befund:** Die Kurve steigt nicht. M2 ist die schwerste Mission, der Boss hat die meiste Luft.
Alle neun Missionen haben denselben Wellentakt: zehn Wellen, Atempause in Welle 3 und 6,
Spitze in Welle 10 (gemessen am Gegnerleben je Welle).

**Ziel [ENTSCHIEDEN] (D-146, Steffen 16.11.2026):** ein fallender Sägezahn. Eine Mission mit Neuheit startet etwas
leichter, die nächste prüft. M7 ist die schwerste. Zweite Regel für das Labor: Die naive
Mischung ohne die Neuheit der Mission verliert ab M4. Schwierigkeit entsteht aus dem Zwang,
die Neuheit zu benutzen, nicht aus mehr Gegnerleben.

Wellenbogen je Mission (Rollen aus [aaa-leveldesign.md](aaa-leveldesign.md#wellendramaturgie)):
8 bis 15 Wellen, eine Atempause direkt vor der Spitze, Spitze bei etwa zwei Dritteln.

**Labor:** neue Prüfung `difficultyCurve` vergleicht die Reserve der besten Bauweise je
Mission mit der Zielkurve (Abweichung höchstens 0,08) und verlangt, dass die naive Mischung
ab M4 verliert.

## 4 Wege und Routen

Heute: jede Karte ein Weg mit 4 bis 8 Ecken, 26 bis 42 Felder lang, Bauland 104 bis 120 von
144 Feldern. Neu: Bauland nur auf Bauinseln (D-141) und ab M6 mehr als ein Weg ([ENTSCHIEDEN], D-147).

| Baustein | Wirkung | Ab |
|---|---|---|
| Gerade, Kehre | Zeit im Bereich; ein Ort sieht zwei Wegstücke | M1 |
| Schleife um eine Insel | eine kleine Insel sieht den Weg dreimal | M3 |
| Furt, Engpass | Gelände auf dem Weg | M5a, M5b |
| Zwei Eingänge | aufteilen oder am Treffpunkt bündeln | M6a |
| Kreuzung | ein Turm am Kreuz sieht zwei Richtungen | M6b |
| Wechselnder Eingang | Finale oder Boss von der anderen Seite, Festung in der Mitte | M7 |
| Gesperrter Weg, umlegbares Tor | der Weg wird Teil des Spiels | Region 2, 3 |

**Architektur für mehrere Wege:** `map.paths` (Liste von Polylinien, optional; fehlt es,
gilt `map.path`), jede Gruppe einer Welle nennt ihren Weg (`path`, Standard 0). Gegner
kennen ihren Weg über einen Index im Zustand. Bauland, Reichweite und Vorschau rechnen über
alle Wege. Das ist eine Simulationsänderung mit eigenem Paket, nach den Zonen aus A-4 und
nach Heiler und Teiler, nie parallel zu ihnen.

## 5 Wiederspielwert

| Baustein | Stand |
|---|---|
| Sterne (1, 2 ab 15 Leben, 3 bei 20) | gebaut |
| Gabelung Sumpf oder Ruinen | gebaut |
| Nebenmissionen N1, N2 | Konzept P3-5, Karten S21 bis S23 |
| Eisern nach dem ersten Sieg | geplant in 05 |
| Veteran-Stufe je Mission nach dem Sieg (mehr Gegner, eigene Sterne) | [ENTSCHIEDEN] D-148, Eisern bleibt dazu |
| Avatar, Ausrüstung, Schmiede (höchstens +10 % Reserve) | gebaut |

## Entscheidungen

| D | Frage | Entschieden (Steffen, 16.11.2026, Karten S30 bis S32) |
|---|---|---|
| D-146 | Schwierigkeitskurve | fallender Sägezahn, M7 am schwersten |
| D-147 | Mehrere Wege in Region 1 | ja, ab M6 (zwei Eingänge, Kreuzung, wechselnder Eingang in M7) |
| D-148 | Schwierigkeitsstufen | Veteran-Stufe je Mission nach dem ersten Sieg, eigene Sterne; Eisern bleibt |

Umsetzung: Roadmap, Block AAA-Schnitt, Pakete A-8 bis A-10.
