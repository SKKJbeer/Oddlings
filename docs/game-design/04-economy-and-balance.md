# 04 – Wirtschaft und Balance

Status aller Zahlen: **[VORSCHLAG]**, grob durchgerechnet, **nicht spielgetestet**.

**Eine Quelle:** Alle Werte stehen in
[`config/balance/mvp-mission-01.json`](../../config/balance/mvp-mission-01.json).
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

[`tools/balance-sim/sim.py`](../../tools/balance-sim/sim.py) liest dieselbe
JSON-Datei, simuliert die Mission mit 30 Schritten je Sekunde und lässt sieben
Bauweisen gegeneinander antreten. Ein einfacher Bot baut, sobald das Gold reicht,
den nächsten Turm seiner Liste auf den Platz mit der größten Wegabdeckung;
Sporen setzt er dorthin, wo die meisten anderen Türme schießen, Blitze in die
Nähe der Sporen.

Gemessen wird die **Reserve**: der größte Faktor auf das Leben aller Gegner, bei
dem die Bauweise noch gewinnt. 1,35 heißt: Die Gegner dürften 35 % mehr Leben
haben, und es reichte noch.

```
python3 tools/balance-sim/sim.py --reserve
```

### Ergebnis der Prüfung

| Bauweise | Ergebnis | Reserve |
|---|---|---|
| Blitz + Sporen, keine Wachtürme | Sieg | **1,42** |
| Mischung aus allen dreien | Sieg | 1,35 |
| Wachturm + Blitz | Sieg | 1,20 |
| Wachturm + Sporen | Sieg | 1,14 |
| Nur Wachtürme | Sieg | 1,10 |
| Nur Blitztürme | Niederlage in Welle 6 | 0,86 |
| Nur Sporentürme | Niederlage in Welle 4 | 0 |

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

### Grenzen der Rechnung

- Keine Menschen: perfekte Platzierung, keine Reaktionszeit, kein Verkaufen.
- Bot kauft nur nach fester Liste.
- Keine Ziellogik-Varianten; Zielwahl ist immer „erster".
- Eine Karte, ein Weg.

Sobald der Swift-Kern rechnet (Backlog WP-10), ersetzen Balancetests in Swift
dieses Skript, damit es nicht zwei Wahrheiten gibt.

## Zwergenbank (Phase 2)

**[ENTSCHIEDEN]** Kein Kampfschaden, kostet beim Bau, erträgt nach Verzögerung,
konkurriert mit Verteidigung.

**[VORSCHLAG] – Startwerte zur ersten Rechnung in Phase 2**, nicht für den MVP:

| Wert | Startpunkt | Gedanke |
|---|---|---|
| Kosten | 100 | Zwei Wachtürme Verzicht |
| Verzögerung | 20 s | Spürbar ungeschützter Moment |
| Ertrag | 5 Gold je 4 s | 75 Gold/Minute |
| Amortisation | 20 s + 80 s ≈ **100 s** | Etwa ein Drittel von Mission 1: lohnt früh gebaut, nicht mehr spät |
| Höchstzahl | 2 je Spieler | Gegen Schneeball |
| Ertrag pro Bank gedeckelt | 300 Gold | Zweite Bremse; prüfen, ob nötig |

Die Kennzahl, auf die alles zielt: **Eine Bank in Welle 1 soll sich etwa ab
Welle 4 rechnen und in der Summe ungefähr so viel bringen, wie zwei Wachtürme an
Durchbrüchen verhindert hätten.** Geprüft wird das mit derselben Simulation:
Bauweise mit Bank gegen ohne, Reserve vergleichen.

## Koop-Ressourcen [HYPOTHESE]

Persönliches Gold, gemeinsame Teamressource, Kampagnenfortschritt. Nicht vor
einer Koop-Phase präzisieren.
