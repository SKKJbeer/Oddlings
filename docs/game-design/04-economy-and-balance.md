# 04 – Wirtschaft und Balance

Status aller Zahlen: **[VORSCHLAG]**, grob durchgerechnet, **nicht spielgetestet**.

**Eine Quelle:** Alle Werte stehen in
[`mvp-mission-01.json`](../../Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json).
Diese Tabelle hier ist eine Lesehilfe; weicht sie ab, gilt die Datei.

## Einheiten

- **Strecke:** Felder (eine Zelle des Bauraster). Karte 16 × 9 Felder.
- **Zeit:** Sekunden. Simulation mit 30 Schritten je Sekunde.
- **Geschwindigkeit:** Felder pro Sekunde.

## Mission 1 – Werte

### Mission

| Wert | Vorschlag | Begründung |
|---|---|---|
| Festungsleben | 20 | Übliche Größenordnung; jeder Durchbruch ist spürbar (5 %), ein einzelner Fehler beendet die Mission nicht |
| Startgold | 150 | Reicht für drei Wachtürme **oder** Wachturm + Blitz **oder** Wachturm + Sporen + Rest. Die erste Entscheidung fällt sofort |
| Aufbauzeit vor Welle 1 | 20 s | Zeit zum Lesen der Karte |
| Takt zwischen Wellen | 15 s nach dem letzten Erscheinen | siehe [01](01-core-gameplay.md#wellentakt-vorschlag) |
| Wellen | 10 | Ergibt in der Rechnung ~5 Minuten, unteres Ende der Hypothese; passt zu einer ersten Mission |
| Erstattung beim Verkauf | 70 % | Experimentieren erlaubt, Hin- und Herbauen kostet aber |
| Weg | 32 Felder, sechs Kurven | Kurven sind die guten Bauplätze; das lehrt Platzierung |

### Türme

| Turm | Kosten | Reichweite | Schaden | Takt | Besonderes | Schaden/s je Ziel | je 100 Gold |
|---|---|---|---|---|---|---|---|
| Wachturm | 50 | 2,5 | 12 | 0,8 s | Einzelziel | 15 | **30** |
| Blitzturm | 80 | 2,2 | 18 | 1,2 s | 4 Sprünge, Radius 1,3, je Sprung ×0,8 | 15 (ein Ziel) / bis 50 (fünf Ziele) | 19 / **63** |
| Sporenturm | 50 | 2,2 | 1 (Puls an alle) | 1,0 s | Tempo ×0,5 für 1,5 s, stapelt nicht | 1 | 2 (+ Wirkung über andere) |

Lesart: Gegen Einzelziele ist der Wachturm am günstigsten. Ab etwa drei Gegnern
in Sprungweite überholt ihn der Blitz deutlich. Der Sporenturm lohnt sich nur
über die Türme, die er unterstützt: Halbe Geschwindigkeit heißt doppelte
Verweildauer in allen Reichweiten, die er überdeckt, und halber Abstand
zwischen den Gegnern.

### Gegner

| Gegner | Leben | Tempo | Gold | Festungsschaden | Zeit für 32 Felder |
|---|---|---|---|---|---|
| Plünderer | 70 | 1,0 | 5 | 1 | 32 s |
| Flitzer | 52 | 2,2 | 4 | 1 | 15 s |
| Panzerbestie | 370 | 0,6 | 20 | 3 | 53 s |

Spätere Wellen multiplizieren das Leben (`hpScale` 1,0 bis 1,6); die Belohnung
bleibt gleich. So wächst der Druck, ohne dass die Wirtschaft mitskaliert.

### Wellen

| Welle | Inhalt | Leben gesamt | Gold | Gold kumuliert | Lehrt |
|---|---|---|---|---|---|
| 1 | 8 Plünderer | 560 | 40 | 190 | Grundlagen |
| 2 | 12 Plünderer | 840 | 60 | 250 | Ausbauen |
| 3 | 10 Flitzer | 520 | 40 | 290 | Abdeckung, Tempo |
| 4 | 14 Plünderer + 6 Flitzer | 1 421 | 94 | 384 | Mischung |
| 5 | 20 Plünderer, dicht | 1 610 | 100 | 484 | **Blitz** |
| 6 | 16 Flitzer, dicht | 998 | 64 | 548 | **Sporen** |
| 7 | 2 Panzerbestien + 16 Plünderer | 2 418 | 120 | 668 | Zähe Ziele |
| 8 | 25 Plünderer + 12 Flitzer | 3 324 | 173 | 841 | Druck |
| 9 | 4 Panzerbestien + 20 Flitzer | 3 780 | 160 | 1 001 | Tempo gegen Zähigkeit |
| 10 | 30 Plünderer + 20 Flitzer + 3 Panzerbestien | 6 800 | 290 | 1 291 | Finale |

Gold gesamt in der Mission: 1 291. Das reicht für rund 20 Türme.

### Sieg und Niederlage

- **Sieg:** Alle zehn Wellen sind erschienen, kein Gegner lebt, Festung > 0.
- **Niederlage:** Festungsleben ≤ 0, sofort.
- **[VORSCHLAG]** Bewertung mit Sternen nach verbleibendem Leben (z. B. 20 / ≥ 15 /
  ≥ 1) erst ab Phase 3, wenn es eine Kampagne gibt, in der sie etwas bedeuten.

## Wie die Werte geprüft wurden

Die Balancetests im Simulationspaket
([`BalanceTests`](../../Packages/OddlingsCore/Tests/OddlingsCoreTests/BalanceTests.swift),
Bot in [`BalanceBot`](../../Packages/OddlingsCore/Tests/OddlingsCoreTests/BalanceBot.swift))
spielen Mission 1 mit der echten Simulation und lassen sieben
Bauweisen gegeneinander antreten. Ein einfacher Bot baut, sobald das Gold reicht,
den nächsten Turm seiner Liste auf den Platz mit der größten Wegabdeckung;
Sporen setzt er dorthin, wo die meisten anderen Türme schießen, Blitze in die
Nähe der Sporen.

Gemessen wird die **Reserve**: der größte Faktor auf das Leben aller Gegner, bei
dem die Bauweise noch gewinnt. 1,35 heißt: Die Gegner dürften 35 % mehr Leben
haben, und es reichte noch.

```
swift test -c release -Xswiftc -enable-testing --package-path Packages/OddlingsCore --filter BalanceTests
```

Die Tests prüfen Beziehungen (Blitz + Sporen mehr als 0,3 vor Blitz allein,
Mischung mehr als 0,1 vor nur Wachtürmen, nur Wachtürme über 1,0), keine genauen
Zahlen. Die Bauweisen stehen unter `simStrategies` in der Missionsdatei.

### Ergebnis der Prüfung

Bis WP-10 rechnete ein Python-Skript (Phase 0) mit eigener, vereinfachter
Nachbildung der Regeln. Seit WP-10 rechnet die echte Simulation (25.10.2026):

| Bauweise | Ergebnis (Swift) | Reserve Swift | Reserve Phase 0 |
|---|---|---|---|
| Blitz + Sporen, keine Wachtürme | Sieg | **1,36** | 1,42 |
| Mischung aus allen dreien | Sieg | 1,35 | 1,35 |
| Wachturm + Blitz | Sieg | 1,20 | 1,20 |
| Wachturm + Sporen | Sieg | 1,19 | 1,14 |
| Nur Wachtürme | Sieg | 1,18 | 1,10 |
| Nur Blitztürme | Niederlage in Welle 6 | 0,86 | 0,86 |
| Nur Sporentürme | Niederlage in Welle 3 | 0,51 | 0 |

Die Rangfolge ist dieselbe (Abnahme WP-10). **Befund:** Die Abstände sind
kleiner geworden. Nur Wachtürme steigt von 1,10 auf 1,18, weil die Simulation
keine Schüsse an schon tödlich Getroffene verschwendet ([02](02-combat-and-towers.md));
das Skript tat das, und Einzelzieltürme litten am meisten darunter. Wachturm +
Sporen liegt nur noch 0,01 vor reinen Wachtürmen, Blitz + Sporen nur noch 0,01
vor der Mischung. Die Kernsynergie (Blitz mit Sporen gegen Blitz allein) trägt
weiter deutlich. Für Mission 1 ist das vertretbar; ob Sporen neben Wachtürmen
spürbar helfen, ist eine Frage an den Spieltest und an die Werte in Phase 2.

Was das sagt:

1. **Die Synergie trägt.** Blitz allein verliert, Blitz mit Sporen ist die
   stärkste Bauweise. Genau das soll das Spiel belohnen.
2. **Monokultur wird schwächer, scheitert aber noch nicht.** Nur Wachtürme
   gewinnt mit knapper Reserve. Für eine erste Mission ist das gewollt: Wer das
   Spiel nicht versteht, kommt trotzdem durch. Spätere Missionen sollen hier
   rot werden.
3. **Mission 1 ist für den Bot leicht.** Alle Siege ohne einen Durchbruch. Der
   Bot platziert aber mit voller Kenntnis der Karte; Menschen bauen schlechter.
   Ob die Schwierigkeit stimmt, sagt erst der Spieltest.

### Was in der Rechnung aufgefallen ist

Die ersten, naheliegenden Werte (Sporen 60 Gold, 3 Schaden, Tempo ×0,6; Blitz
14 Schaden, 3 Sprünge, ×0,7) machten den **Sporenturm schädlich**: Mischung mit
Sporen hatte weniger Reserve (1,05) als nur Wachtürme (1,28), und Sporen allein
gewannen wegen ihres Flächenschadens trotzdem fast. Daraus folgen die heutigen
Werte: kaum Eigenschaden, stärkere Verlangsamung, günstiger. Und eine Lehre fürs
Spiel: Unterstützende Türme müssen im Zweifel großzügig sein, weil ihr Nutzen
für Spieler schwer zu sehen ist (Risiko P1 in der
[Analyse](../production/phase-0-analyse.md)).

### Steinregen (R-3, 25.10.2026) [HYPOTHESE]

Prüfung aus [03](03-races-and-avatar.md#eine-aktive-festungsfähigkeit-phase-2):
Der Bot wirft, sobald der Stein bereit ist, auf die Stelle mit den meisten
Gegnern im Kreis (mindestens zwei, ohne vorauszuzielen). Die Reserve der
Mischung darf um höchstens 0,1 steigen. Gemessen mit der Mischung (ohne Stein
1,35):

| Schaden | Anhalten | Abklingzeit | Reserve mit Stein | Zuwachs |
|---|---|---|---|---|
| 40 | 1,0 s | 25 s | 1,64 | +0,29 |
| 20 | 1,0 s | 25 s | 1,50 | +0,15 |
| 30 | 1,0 s | 40 s | 1,47 | +0,12 |
| 20 | 0,5 s | 30 s | 1,42 | +0,07 |
| **20** | **1,0 s** | **35 s** | **1,42** | **+0,075** |

Die ersten, gerechneten Werte (40 / 1 s / 25 s) waren fast dreimal zu stark: Der
Stein trifft gerade dann, wenn sich Gegner vor den Türmen stauen, und das
Anhalten lässt sie länger im Feuer stehen. Gewählt ist die letzte Zeile: Ein
deutliches Anhalten fühlt sich besser an als ein kurzes, dafür kommt der Stein
etwa jede zweite Welle. `BalanceTests` hält die Grenze fest. Der Zuwachs springt
bei kleinen Änderungen (15 Schaden ergab mehr als 20), weil einzelne Würfe über
eine Welle entscheiden; deshalb liegt der Wert mit Abstand unter der Grenze.

### Völker Zwerge und Elfen (R-4, 26.10.2026) [HYPOTHESE]

Werte in `Balance/races.json`. Prüfung aus [03](03-races-and-avatar.md):
Völker verändern den Spielstil, sind aber nie Voraussetzung. Je Volk darf die
Reserve der Mischung mit Fähigkeit um höchstens 0,1 über der Mission ohne
Fähigkeit liegen (1,35), und Zwerge und Elfen dürfen höchstens 0,05
auseinanderliegen. Der Bot setzt das Bollwerk auf den Wegpunkt mit den meisten
Angriffstürmen in Reichweite, vor dem mindestens zwei Gegner auf drei Feldern
heranlaufen; das Mondmal wirft er wie den Stein. Gemessen mit Abklingzeit 35 s:

| Volk | Werte | Reserve | Zuwachs |
|---|---|---|---|
| Zwerge | Mauer 2 s | 1,35 | ±0 |
| Zwerge | Mauer 3 s | 1,35 | ±0 |
| **Zwerge** | **Mauer 4 s** | **1,40** | **+0,05** |
| Zwerge | Mauer 5 s | 1,33 | −0,02 |
| Elfen | Faktor 1,3, Mal 4 s, Sporen ×1,0 | 1,38 | +0,03 |
| Elfen | Faktor 1,3, Mal 4 s, Sporen ×1,1 | 1,37 | +0,02 |
| Elfen | Faktor 1,5, Mal 4 s, Sporen ×1,0 | 1,38 | +0,03 |
| **Elfen** | **Faktor 1,5, Mal 4 s, Sporen ×1,1** | **1,42** | **+0,07** |

Zum Vergleich der Steinregen ohne Volk: 1,42. Gewählt sind die fetten Zeilen,
Zwerge und Elfen liegen 0,02 auseinander. Zwei Befunde: Eine längere Mauer hilft
nicht von selbst (5 s war schwächer als 4 s), weil sich dahinter eine Traube
sammelt, die nach dem Fall auf einmal durchläuft. Und eine Mauer an der
dichtesten Traube statt vor den Türmen half gar nicht (erster Bot, 1,31 bis
1,36); das Bollwerk lohnt sich nur vor der eigenen Feuerlinie, das muss die
Oberfläche beim Zielen zeigen.

**Wachturm der Zwerge (D-062, 26.10.2026).** Die Zwerge zahlen für den Wachturm
10 % weniger (50 → 45 Gold). Nachgemessen mit derselben Rechnung:

| Bauweise | ohne Fähigkeit | Zwerge vorher | Zwerge mit 45 Gold | Elfen |
|---|---|---|---|---|
| Mischung | 1,35 | 1,40 | 1,40 | 1,42 |
| Nur Wachtürme | 1,18 | 1,10 | 1,31 | 1,18 |

In der Mischung ändert sich fast nichts, Zwerge und Elfen liegen 0,01 auseinander.
Die reine Wachturm-Bauweise gewinnt dagegen deutlich (+0,13 gegenüber ohne
Fähigkeit), weil jeder Turm früher steht. Sie bleibt aber hinter der Mischung
zurück (1,31 gegen 1,40). `BalanceTests.racesKeepMixAhead` hält fest, dass die
Mischung mit jedem Volk mindestens 0,05 vor der Monokultur liegt. Ob Zwerge im
Spieltest zum Wachturm-Spam verleiten, ist eine Frage für WP-15.

### Talente (R-6) [HYPOTHESE]

Faktoren in `Balance/races.json` (`talents`), Begründung im
[Konzept](../konzepte/r-6-avatarrang.md#talente-vorschlag-zahlen-hypothese).
`BalanceTests.talentsStayEven` rechnet jede spielbare Kombination (31 je Volk, vier
Reihen, D-065) mit den vier gewinnenden Mischungen und nimmt den Schnitt der Reserve.
Jede Kombination muss besser sein als ohne Fähigkeit, höchstens 0,06 von der Mitte
ihres Volks abweichen und die Mischung mehr als 0,05 vor „Nur Wachtürme“ lassen; die
Mitte darf höchstens 0,05 über der Grundform liegen. Gemessen am 27.10.2026:

| | Grundform | Mitte | größte Abweichung | kleinster Abstand Mischung |
|---|---|---|---|---|
| Zwerge | 1,353 | 1,381 | 0,054 | 0,062 |
| Elfen | 1,442 | 1,462 | 0,028 | 0,191 |

Die Streuung von etwa ±0,05 kommt aus der Rechnung selbst (ein Wurf, eine Welle
früher), nicht aus einem Talent. Die Balancetests laufen deshalb im Release-Bau:
Im Debug-Bau brauchten 62 Kombinationen über 20 Minuten.

### Grenzen der Rechnung

- Keine Menschen: perfekte Platzierung, keine Reaktionszeit, kein Verkaufen.
- Bot kauft nur nach fester Liste.
- Keine Ziellogik-Varianten; Zielwahl ist immer „erster".
- Eine Karte, ein Weg.

Seit WP-10 gibt es nur noch diese eine Rechnung; das Python-Skript ist gelöscht.

## Zwergenbank (Phase 2)

**[ENTSCHIEDEN D-026]** Steffen, 25.10.2026 (E-3). Zahlen sind Zielgrößen für die erste Rechnung; die Werte kommen in die Missionsdatei.

Herkunft: Übergabe Nr. 8, klärt D-010.

**[ENTSCHIEDEN]** Kein Kampfschaden, kostet beim Bau, erträgt nach Verzögerung,
konkurriert mit Verteidigung.

### Für wen (D-010)

Die Übergabe nennt die Bank zugleich „Zwergen-Kennzeichen" und Wirtschaftsturm
des Einzelspielers. **Die Bank ist ein Grundturm für alle** (der
vierte, ab Phase 2). Zwerge haben ihren passiven Zug an der Bank ([03](03-races-and-avatar.md#wie-ein-volk-wirkt-phase-3)) und die
Bank ist im Aussehen ein Zwergenbau. Grund: Die Bank trägt die Säule „Echte
Entscheidungen" (jetzt verteidigen oder später ernten). Diese Entscheidung soll
jeder Spieler haben, nicht nur wer Zwerge wählt.

### Regeln


- Kein Kampfschaden, belegt eine Zelle wie jeder Turm.
- Ertrag beginnt nach der Verzögerung, dann fester Betrag je Intervall, bis der
  Deckel erreicht ist. Danach steht sie leer da (sichtbar) und kann verkauft
  werden. Verkaufen erstattet 70 % der Baukosten, unabhängig vom Ertrag.
- Die Zeit läuft ab Bau, auch in der Aufbauzeit. Eine Bank im ersten Moment
  ist also zur ersten Welle bereit; das ist der Reiz und das Risiko zugleich,
  denn die 100 Gold fehlen in Welle 1 und 2.
- Höchstzahl je Mission.
- Jeder Ertrag ist ein Ereignis (`bankPaid`) mit sichtbarer Goldzahl an der Bank
  (E1). Die Bank hat keine Aufwertungen in der ersten Fassung.
- Keine Zinsen, kein Wachstum mit der Zeit. Beides schneeballt.

### Startwerte

**[VORSCHLAG] – Startwerte zur ersten Rechnung in Phase 2**, nicht für den MVP:

| Wert | Startpunkt | Gedanke |
|---|---|---|
| Kosten | 100 | Zwei Wachtürme Verzicht |
| Verzögerung | 20 s | Spürbar ungeschützter Moment |
| Ertrag | 5 Gold je 4 s | 75 Gold/Minute |
| Amortisation | 20 s + 80 s ≈ **100 s** | Etwa ein Drittel von Mission 1: lohnt früh gebaut, nicht mehr spät |
| Höchstzahl | 2 je Spieler | Gegen Schneeball |
| Ertrag pro Bank gedeckelt | 300 Gold | Zweite Bremse; prüfen, ob nötig |

### Kennzahl


Eine Bank in Welle 1 rechnet sich etwa ab Welle 4 und bringt
in Summe ungefähr so viel, wie zwei Wachtürme an Durchbrüchen verhindert hätten.
In den `BalanceTests` heißt das: Die beste Bauweise mit Bank liegt höchstens
0,05 Reserve über oder unter der besten ohne Bank. Liegt sie deutlich darüber,
ist die Bank Pflicht; deutlich darunter, ist sie bedeutungslos.

### Bonus für frühes Rufen (D-009, E8)


Gehört zur selben Wirtschaftsrunde und wird mit der Bank zusammen gerechnet:
Wer die nächste Welle früher ruft, bekommt einen kleinen Goldbetrag je
eingesparter Sekunde. Klein genug, dass Abwarten nie ein Fehler ist.

## Koop-Ressourcen [HYPOTHESE]

Persönliches Gold, gemeinsame Teamressource, Kampagnenfortschritt. Nicht vor
einer Koop-Phase präzisieren.
