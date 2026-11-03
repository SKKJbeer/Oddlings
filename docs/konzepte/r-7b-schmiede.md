# R-7b: Schmiede mit Spielwährung

Status: **umgesetzt in 0.21.0 mit den drei Empfehlungen** (D-072): Erz aus jedem Sieg,
neue Sterne geben mehr; die Schmiede hebt vorhandene Stücke auf Stufe II und III; die
Währung heißt Erz. Die drei Karten an Steffen (S9) sind noch offen; entscheidet er
anders, wird umgebaut. Werte [HYPOTHESE] bis zum Spieltest. Vorgänger: [R-7a feste Belohnungen](r-7-ausruestung.md), 0.19.0.
Grundlage: D-066, D-069 (+10 % höchstens), D-070 (Schmiede, nie gegen Echtgeld,
keine Zufallstruhen), D-071. Reihenfolge: nach Mission 3 in offener Reihenfolge (D-085).

## Ziel

Der Avatar soll über viele Missionen wachsen („einen coolen und wertvollen Charakter
erbauen“). Die festen Belohnungen aus R-7a geben je Platz zwei Stücke. Die Schmiede
gibt dem Spieler eine eigene Entscheidung: Er sammelt Material aus Missionen und
entscheidet selbst, welches Stück er zuerst verbessert. Die Gesamtstärke bleibt unter
der Obergrenze aus D-069, wie viel er schmiedet.

Die Marktanalyse stützt das: Die Marktführer leben von Fortschritt zwischen den
Missionen (KR-Sterne für Verbesserungen), Fairness verlangt aber, dass nichts davon
gekauft wird (E13, E15, Säule 5).

## Umfang

**Drin:** eine Spielwährung, ihr Erwerb in Missionen, ein Schmiede-Reiter im
Avatar-Menü, Ausgaben laut Entscheidung 2, Anzeige des Bestands, Prüfung beim Laden.

**Nicht drin:** Kauf mit Echtgeld, Zufall, Handel, tägliche Belohnungen, Zeitsperren,
neue Ausrüstungsplätze.

## Offene Entscheidungen (Karten an Steffen)

1. **Woher kommt die Währung?** **[OFFEN]**
   - A. Nur aus neuen Sternen. Jeder Stern gibt einmal eine feste Menge. Der Bestand
     wird aus dem Fortschritt gerechnet, Farmen ist unmöglich, ein veränderter
     Spielstand bringt nichts. Gesamtmenge der Region steht fest.
   - B. **Aus jedem Sieg, neue Sterne geben deutlich mehr (Empfehlung).** Wiederholen
     lohnt sich ein wenig, wie bei den Vorbildern, und wer an einer Mission hängt,
     kann sich vorbereiten. Der Bestand muss gespeichert werden.
   - C. Aus jedem Sieg, gleich viel. Einfach, aber wer eine leichte Mission oft spielt,
     kommt am schnellsten voran.
2. **Was macht die Schmiede?** **[OFFEN]**
   - A. **Vorhandene Stücke in Stufen verbessern (Empfehlung).** Jedes Stück aus R-7a
     hat Stufe I bis III, jede Stufe mehr Bonus. Wenige neue Bilder, klarer Weg, und
     die Obergrenze gilt einfach für Stufe III.
   - B. Neue Stücke herstellen, die es nur in der Schmiede gibt. Mehr Vielfalt, mehr
     Bilder und mehr Balancearbeit je Stück.
   - C. Beides.
3. **Wie heißt die Währung?** **[OFFEN]** Vorschläge: **Erz** (Empfehlung, passt zu Zwergen,
   Stollen und Schmiede, kurz), Runensplitter, Glimmer.

## Architektur (unter Annahme der Empfehlungen)

- **Daten:** alles in `Balance/equipment.json`, damit Stücke und ihre Stufen an einer
  Stelle stehen: je Stück `levels` (Bonus von Stufe II und III), dazu ein Block `forge`
  mit `winOre`, `newStarOre`, `maxOre` und `levelCosts`. Keine Zahl im Code. (Im
  Entwurf stand eine eigene `forge.json`; eine zweite Datei hätte die Stufen von ihren
  Stücken getrennt.)
- **Kern:** `ForgeConfig.ore` rechnet den Ertrag, `EquipmentTable` Kosten, Stufen und
  Schmieden (`upgrade`, `credit`). `EquipmentTable.effective` nimmt die
  Stufe je Stück. Eine Stufe gilt nur, wenn das Stück besessen wird.
- **Spielstand:** `Avatar.forge { ore, levels: [EquipmentLevel { piece, level }] }`,
  sortiert, ohne Wörterbuch. Schema bleibt 2, Feld optional.
- **Schutz gegen veränderte Spielstände:** Das Spiel ist offline und allein, ein
  Betrug schadet nur dem Betrüger. Der Schutz zielt deshalb auf Unsinn, nicht auf
  Angreifer. Beim Laden gilt: Der Bestand ist eine ganze Zahl ≥ 0 und höchstens die
  Obergrenze aus `forge.json`, Stufen nur für bekannte Stücke und nur im erlaubten
  Bereich. Was nicht passt, wird einzeln verworfen (Stufe I, Bestand 0), nie der
  Fortschritt. Bei Option 1A entfällt der gespeicherte Bestand ganz.
- **Ertrag:** Den Ertrag rechnet `AppFlow.finish` aus dem Ergebnis, wie die Sterne. Er
  ist ein Befehl an den Spielstand, nie eine Rechnung der Darstellung.
- **App:** dritter Reiter „Schmiede“ im Avatar-Menü. Jedes Stück zeigt Stufe, Bonus
  jetzt und nach der nächsten Stufe, Preis. Bestand im Kopf des Menüs und auf der
  Ergebnistafel („+12 Erz“).

## Balance

- Stärkste Belegung mit Stufe III bleibt bei höchstens +10 % Reserve (D-069); Stufe I
  entspricht R-7a.
- Monokultur verliert beim ersten Spielen, mit dem Erz, das man bis dahin
  bekommen kann, wenn man jede frühere Mission dreimal gewinnt (D-071).
- Ertrag so, dass man ohne Wiederholen am Ende der Region etwa zwei Drittel aller
  Stufen hat. Wer wiederholt, hat alle, aber nicht schneller als durch neue Sterne.
  Werte [HYPOTHESE] bis zum Spieltest.

## Tests

- Kern: Ertrag je Ergebnis, Kosten, Stufe nur bei Besitz, Prüfung beim Laden mit
  kaputtem Bestand und kaputten Stufen, Obergrenze mit Stufe III je Volk und Talentwahl,
  Monokultur beim ersten Spielen.
- App: Schmieden zieht ab und speichert, zu wenig Erz sperrt den Knopf, Ergebnistafel
  zeigt den Ertrag, die Mission trägt die Stufe.
- E2E: Reiter „Schmiede“, ein Stück verbessern, Neustart behält Stufe und Bestand,
  Überlappungsprobe.
- Jeder neue Test wird einmal rot gesehen.

## Risiken

- Wiederholen wird zur Pflicht, wenn der Ertrag zu knapp ist. Gegenmittel: neue Sterne
  geben den Großteil, die Balance prüft Missionen ohne Ausrüstung.
- Zu viele Menüs: Die Schmiede bleibt ein Reiter, kein eigener Bildschirm.
