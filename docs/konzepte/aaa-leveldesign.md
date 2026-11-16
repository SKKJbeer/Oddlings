# Konzept: Leveldesign und Mechaniken für Region 1 und danach

Status: **[VORSCHLAG]** · Stand 16.11.2026 · Thread „Spiel auf AAA-Niveau reviewen“
Grundlage: [Review](aaa-review.md) (Befunde L1 bis L6, G2, G8), D-005 Bauzonen,
D-027 Region 1, D-071 Monokultur verliert, D-073 Labor,
[05 Kampagne](../game-design/05-campaign-and-progression.md),
[02 Kampf](../game-design/02-combat-and-towers.md),
[Marktanalyse](../game-design/market-analysis.md) E6, E9, E11.

Region 1 muss als kostenlose Region allein überzeugen (D-015, D-027). Heute trägt sie das
mit ihren Regeln (Bank, Aufwerten, Spezialisierungen, Boss), aber nicht mit ihren Orten:
Jede Mission ist dieselbe Wiese mit einem anderen Weg. Dieses Konzept legt fest, wie eine
Mission gestaltet wird, und wendet es auf Region 1 an.

## Grundsätze

1. **Jede Mission stellt eine Frage und hat einen Moment.** Die Frage ist das, was der
   Spieler lernt oder neu entscheiden muss. Der Moment ist die Stelle, an die er sich
   danach erinnert (eine Welle, ein Ort, ein Auftritt). Ohne beides wird nicht gebaut.
2. **Bauland ist Gestaltung, nicht Rest.** Wo man bauen darf, ist die wichtigste
   Leveldesign-Entscheidung im Tower Defense. Es gibt wenige, unterschiedlich gute
   Bauinseln statt einer Wiese (D-141).
3. **Mehr als eine gute Antwort.** Jede Mission hat mindestens zwei verschiedene Bauorte,
   von denen aus man gewinnt. Das Labor misst es (siehe unten).
4. **Eine Neuheit je Mission.** Neue Regel, neuer Gegner oder neues Gelände, nie zwei auf
   einmal. Was neu ist, wird in der Mission ohne Text vorgeführt (wie der Sporenfunke).
5. **Ort trägt die Regel.** Gelände sieht aus, wie es wirkt: Wo der Boden nass ist, springt
   der Blitz weiter; wo eine Anhöhe ist, sieht der Turm weiter. Keine unsichtbaren Zahlen.
6. **Spannungsbogen statt Takt.** Wellen haben Rollen: Einführung, Probe, Atempause,
   Spitze, Finale. Nicht jede Mission hat zehn Wellen.

## Bauinseln (D-141)

D-005 hat „Zonen aus Rasterzellen“ entschieden; die Missionsdateien kennen aber nur einen
Mindestabstand zum Weg, also eine einzige Zone, die ganze Karte (104 bis 120 von 144
Feldern). Bauinseln setzen D-005 erst um.

**Regel [VORSCHLAG]:** Eine Karte hat 4 bis 7 Inseln mit zusammen etwa 35 bis 50 Feldern.
Innerhalb einer Insel ist jedes freie Feld bebaubar (Raster bleibt, wie D-005). Außerhalb
ist Landschaft: Wald, Wasser, Fels, Böschung, Ruinen. Inseln sind unterschiedlich:

| Insel-Art | Lage | Wozu |
|---|---|---|
| **Kehre** | innen an einer Wegkehre, sieht zwei oder drei Wegstücke | der starke Ort, eng (2 bis 4 Felder), umkämpft |
| **Lange Seite** | an einer langen Geraden | viel Platz, sieht wenig Weg je Turm, gut für Sporen und Bank |
| **Vorposten** | nahe am Eingang | früh treffen, wenig Zeit im Bereich |
| **Letzte Linie** | vor der Festung | Sicherheit, wenn vorne etwas durchbricht |
| **Anhöhe** (Gelände, ab M4) | erhöht | Reichweite +20 %, nur 1 bis 2 Felder |

**Daten:** `map.zones` als Liste von Rechtecken in Feldern (optional). Fehlt das Feld, gilt
der Mindestabstand wie heute, alte Spielstände und Tests bleiben gültig. `MissionMap`
schneidet die Rechtecke mit dem Mindestabstand. Prüfung beim Laden: Rechtecke innerhalb
der Karte, mindestens ein Feld, keine Überschneidung mit dem Weg.

**Bild:** Inseln sind im Diorama als begehbarer Grund gebaut (Erde, Steinplatten,
gemähte Lichtung, Ruinenfundament je Ort), Landschaft drumherum. Beim Bauen leuchten nur
sie auf. Damit verschwindet auch das Kachelraster über der ganzen Karte (P2).

## Weg-Grammatik

Region 1 benutzt bisher nur Kehren und Schleifen auf einem Weg. Bausteine, aus denen
Missionen zusammengesetzt werden:

| Baustein | Wirkung | Erste Mission (Vorschlag) |
|---|---|---|
| Gerade | Zeit im Bereich, wenig Überdeckung | M1 |
| Kehre | ein Ort sieht zwei Wegstücke | M1 |
| Schleife um eine Insel | eine Insel sieht den Weg dreimal: starker, teurer Ort | M3 |
| Engpass (Brücke, Felsspalt) | Weg schmal, Gegner drängen sich: Gruppenschaden lohnt | M5b |
| Furt | Gegner im Wasser langsamer und „nass“ (siehe Gelände) | M5a |
| Zweiter Eingang | zwei Wege laufen zusammen: Verteidigung aufteilen oder am Treffpunkt bündeln | M6a oder M6b |
| Kreuzung | zwei Wege kreuzen sich, ein Turm am Kreuz sieht beide | M7 |

Zweiter Eingang und Kreuzung brauchen in der Simulation mehrere Wege (`map.paths`, Welle
nennt den Weg). Das ist eine Regeländerung mit eigenem Paket und Tests, kommt nicht vor M6.

## Gelände, das etwas tut

Sparsam: je Region höchstens zwei Geländeregeln, beide sichtbar und aus Daten.

| Gelände | Regel [VORSCHLAG] | Synergie (Säule 1) |
|---|---|---|
| **Anhöhe** | Turm auf einer Anhöhe-Insel hat +20 % Reichweite | macht wenige Felder wertvoll, Kehre gegen Anhöhe wird eine Entscheidung |
| **Furt / nasser Boden** | Gegner auf nassen Wegstücken sind 15 % langsamer, und Blitze springen dort 30 % weiter | Blitz plus Furt ist die Ortsfassung des Sporenfunkens: eine Synergie, die der Ort anbietet |

Beides sind Faktoren in der Missionsdatei (`terrain`) und Regeln in `OddlingsCore`, mit
Tests und Labor, und kommen einzeln (Anhöhe mit M4, Furt mit M5a).

## Gegnerrollen (D-143)

Heute drei Rollen, gelöst bis M4. Rolle und Antwort als Matrix:

| Rolle | Gegner | Fordert | Antwort |
|---|---|---|---|
| Masse | Plünderer | Gruppenschaden | Blitzturm |
| Tempo | Flitzer | Bremsen | Sporenturm |
| Panzer | Panzerbestie | hohen Einzelschaden | Wachturm II, Falkenhorst, Steinregen |
| **Heiler** [VORSCHLAG] | **Moorhexe**: heilt Gegner im Umkreis von 1 Feld alle 2 s um 6 % | Fokus: zuerst sie | Zielwahl „Stärkster“ oder ein eigener Schwerpunkt-Turm, Steinregen; Fäulnis verstärkt |
| **Teiler** [VORSCHLAG] | **Pilzbalg**: zerfällt beim Tod in drei kleine Sporlinge | Schaden nach dem Tod, an einer zweiten Stelle | Blitzkette über die Sporlinge, Sporenturm hinter dem ersten Ort |
| Flieger (Region 2, D-027) | Schattenflieger | Treffer aus der Luft | Wach- und Blitzturm, Sporenturm nicht |

**Empfehlung für D-143:** Heiler und Teiler in Region 1, beide mit 3D-Figur. Begründung:
Region 1 muss überzeugen (D-027), und nach M4 fehlt jede neue Frage. Zwei Rollen geben
den Spezialisierungen einen Grund: Salve und Gewitterkrone gegen Teiler, Falkenhorst und
Fäulnis gegen Heiler. Aufwand je Gegner: Regel und Tests 1 Tag, Figur 1 bis 2 Tage, Labor
und Werte 1 Tag.

## Wellendramaturgie

Jede Welle bekommt eine Rolle in der Missionsdatei (`role`, nur zur Beschreibung und
Prüfung, keine Regel):

| Rolle | Was | Beispiel |
|---|---|---|
| Einführung | eine Art, wenige, langsam | Welle 1 |
| Probe | eine neue Mischung, mittel | Welle 2 bis 4 |
| Atempause | wenig Gegner, Zeit zum Ausbauen | vor der Spitze |
| Spitze | die Frage der Mission in voller Härte | etwa zwei Drittel |
| Finale | alles Gelernte, oder der Boss | letzte Welle |

- **Wellenzahl je Mission** zwischen 8 und 15 statt immer 10: M1 kurz (8), Boss-Mission
  lang (12 bis 15). Säule 4 (5 bis 12 Minuten) bleibt die Grenze.
- **Wellenvorschau** am Knopf (A-2), damit Planung möglich ist.
- **Labor** prüft, dass jede Mission genau eine Spitze hat (größte Gefahr je Welle aus den
  Bots) und keine Welle vor der Spitze schwerer ist als sie.

## Missionsblätter Region 1

Format für jede Mission ab jetzt (vor dem Bau ausgefüllt, im Konzept des Pakets):

```
Mission · Ort · Frage · Moment · Neuheit (genau eine)
Weg (Bausteine) · Bauinseln (Art, Felder) · Gelände
Gegner (Rollen) · Wellenbogen (Zahl, Spitze bei Welle n)
Sterne/Eisern · Kampfplatz (Bodenart, Licht, Deko, Wegmarken)
```

Vorschlag für Region 1 (heute → neu). Nichts davon ist entschieden; die Blätter sind die
Grundlage für A-6 und werden Mission für Mission mit Steffen abgenommen.

| Mission | Ort | Frage | Moment | Neuheit | Weg und Inseln |
|---|---|---|---|---|---|
| **M1** | Waldlichtung vor der Zwergenfeste, Nachmittag | Welcher Turm gegen welchen Gegner? | Erster Sporenfunke, Flitzerrudel in Welle 6 | drei Türme | zwei Kehren, 5 Inseln (Kehre ×2, lange Seite, Vorposten, letzte Linie), 8 Wellen |
| **M2** | Zwergenstollen, Lorenschienen, Fackeln | Ernten oder verteidigen? | Bank zahlt, während die Spitze anrollt | Zwergenbank | Weg am Stollen entlang, eine große sichere Insel für die Bank, Kehre weit weg |
| **M3** | Pilzhain, Riesenpilze als Landschaft | Vertiefen statt verbreitern | ein aufgewerteter Turm hält eine Schleife allein | Aufwerten, Zielwahl | Schleife um eine kleine Insel (2 Felder), sonst lange Seiten |
| **M4** | Ruinenrand, Hang mit Mauerresten | Wie knackt man Rüstung? | Panzerbestien-Kolonne am Hang | Panzerbestie, **Anhöhe** | Anhöhe auf altem Turmstumpf (2 Felder) gegen Kehre unten |
| **M5a** | Sumpfpfad, Stege und Furten | Schnell und viele | Flitzerwelle durch die Furt, Blitz springt übers Wasser | **Furt**, Spezialisierung | Furt in der Mitte, Inseln auf Stegen |
| **M5b** | Ruinenhof, Säulen, Brücke | Zäh und wenige | Panzerbestien drängen über die Brücke | Engpass, Spezialisierung | Brücke als Engpass, Ruinenfundamente als Inseln |
| **M6a** | Tiefes Moor | Heilung brechen | Moorhexen hinter einer Flitzerwand | **Heiler**, Wahl zwischen Spezialisierungen | zweiter Eingang aus dem Moor, Wege laufen zusammen |
| **M6b** | Tempelplatz | Zerfall beherrschen | Pilzbälge platzen in der Engstelle | **Teiler**, Wahl zwischen Spezialisierungen | Kreuzung am Tempel |
| **M7** | Bosslichtung | Alles zusammen | Der Moorkönig hebt den Schild, ruft, kommt an die Festung | Boss | Hufeisen mit Furt und Anhöhe, 12 bis 15 Wellen |
| **N1** | Lichtung von M1, anderer Weg | Zwei Türme (S21) | – | Sonderregel | aus P3-5 |
| **N2** | Pilzhain von M3, anderer Weg | Leere Kasse (S21) | – | Sonderregel | aus P3-5 |

Heute stehen M2 bis M7 gebaut; die Tabelle schlägt vor, was sich je Mission ändert.
Wege und Werte ändern sich dadurch; der Spielstand bleibt gültig (Sterne gehören zur
Mission-ID, nicht zum Weg).

## Wie das Labor Leveldesign prüft

Neue Kennzahlen im Balance-Labor (D-073), je Mission:

| Kennzahl | Was | Ziel [HYPOTHESE] |
|---|---|---|
| **Lösungsvielfalt** | Zahl der Bauinseln, auf die ein siegreicher Bot mindestens ein Drittel seines Goldes setzt, über alle Bauweisen | mindestens 2 verschiedene Schwerpunkte gewinnen |
| **Inselnutzung** | Anteil der Inseln, die in Siegen überhaupt bebaut werden | mindestens 60 % |
| **Spitze** | Welle mit der höchsten Gefahr (Leben verloren, knappste Bots) | genau die Welle mit Rolle „Spitze“ |
| **Neuheit wirkt** | Bauweise, die die Neuheit ignoriert, verliert öfter als die, die sie nutzt | ja |

Der Sucher-Bot aus Phase 4 (M4.1) braucht dafür Bauweisen „je Insel“; der Grundstock aus
P2-6b kann mit festen Inseln anfangen.

## Architektur (für A-6)

- `MapConfig` bekommt optional `zones` (Rechtecke) und später `terrain` (Rechtecke mit
  Art) und `paths`. Fehlende Felder bedeuten das heutige Verhalten; geprüft beim Laden
  in `ConfigValidation`.
- Gelände wirkt als Faktor in denselben Rechnungen wie Volk und Ausrüstung
  (`BalanceConfig.stats(of:)`), damit die Wertetafel (UI-02) die Wirkung sofort zeigt
  („Reichweite 2,5 → 3,0, Anhöhe“).
- Neue Gegnerrollen sind neue Felder in `EnemyConfig` (`heal`, `split`), keine
  Sonderfälle je Art im Code.
- Alles deterministisch, keine Iteration über Dictionary, Regeln mit Tests vor den Werten.

## Was dieses Konzept nicht tut

- Keine neuen Türme in Region 1 (drei Türme plus Bank und Spezialisierungen reichen).
- Kein Held, kein freies Bauen auf dem Weg, kein Labyrinthbau.
- Keine Region 2: Schattenflieger und neuer Boss bleiben dort (D-027).
- Keine Umsetzung vor Steffens Karten D-141 und D-143 und dem Urteil am Vertikalschnitt.
