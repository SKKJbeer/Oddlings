# P2-6b: Balance-Labor, Grundstock

Status: **[VORSCHLAG]**, Richtung entschieden (D-028, Steffen 25.10.2026), Ausbau nach
[K11](phase-2-3.md#k11--balance-labor-automatisierte-balance--und-stresstests). Eine
Frage an Steffen (Karte): wie schwer Mission 1 bis 4 beim ersten Versuch sein sollen.
Gebaut wird mit der Empfehlung, die Zielwerte bleiben bis zum Spieltest [HYPOTHESE].

## Ziel

Seit Bank, Aufwertungen, Rüstung, Völkern, Talenten und Ausrüstung gibt es mehr
Möglichkeiten, als ein Mensch oder die sieben festen Bauweisen der `BalanceTests`
überblicken. Das Labor spielt viele leicht verschiedene Spieler durch alle vier
Missionen und sagt nach jeder Änderung, ob etwas kaputt, dominant oder zu schwer ist.
Es sagt nicht, ob es Spaß macht; das bleibt Aufgabe der Spieltests.

## Umfang

**Drin (Grundstock laut K11):**

- Lauf-Werkzeug `oddlings-balance` im Paket, nur Foundation, läuft unter Linux.
- Bot-Familie: der heutige gierige Bot (aus den Tests ins Labor umgezogen, keine zweite
  Umsetzung), ein **Zufallsbot** (gesät, mischt gültige Bauweisen) und ein
  **Menschenbot** (zögert, platziert ungenau, nutzt die Fähigkeit spät).
- Kennzahlen je Lauf: Sieg, Leben übrig, Durchbrüche je Welle, Reserve, gebaute Türme
  je Art, Gold am Ende, Dauer.
- Bot-Eigenschaften und Zielwerte in `Sources/OddlingsLab/Resources/labor.json`, keine Zahl im Code.
- Bericht als Markdown und CSV.
- **PR-Stufe** in der CI: kleiner Satz, ein paar Minuten, rot bei verletztem Zielwert.
  Bericht als Artefakt.

**Nicht drin (später laut K11):** Sucher, nächtlicher großer Lauf, Vergleich mit dem
letzten Lauf auf `main`, Zehntausende-Stresstest, Abgleich mit Spieltests. Keine
Wertänderung an den Missionen: Das Labor misst zuerst.

## Offene Entscheidung (Karte an Steffen)

**Wie schwer sollen Mission 1 bis 4 beim ersten Versuch sein?** Gemessen als Siegquote
des Menschenbots mit dem, was ein Spieler vor der Mission hat (D-071).

- A. Sanft: jede Mission ≥ 85 %. Wer spielt, kommt durch; Sterne sind die Herausforderung.
- **B. Steigend (Empfehlung):** M1 ≥ 90 %, M2 ≥ 75 %, M3 ≥ 60 %, M4 ≥ 50 %. Der Einstieg
  verzeiht alles, später lohnt Nachdenken und manchmal ein zweiter Versuch. So machen
  es die Marktführer in der ersten Region.
- C. Fordernd: M1 ≥ 80 %, M4 um 30 %. Für Kenner, schreckt Gelegenheitsspieler ab
  (Säule „kurz spielbar“).

Bis zum Spieltest prüft die CI die Siegquote nur als Warnung im Bericht, nicht als
Rot: Der Menschenbot ist eine Annahme über Menschen, keine Messung.

## Architektur

```
Packages/OddlingsCore
├── Sources/OddlingsCore      Regeln (unverändert, nur Foundation)
├── Sources/OddlingsLab       Bots, Lauf, Kennzahlen, Zielwerte, Bericht (nur Foundation)
├── Sources/oddlings-balance  Kommandozeile: liest Argumente, ruft OddlingsLab, schreibt Dateien
└── Tests/OddlingsCoreTests   BalanceTests nutzen OddlingsLab statt eines eigenen Bots
```

- **OddlingsLab** hängt von OddlingsCore ab, nie umgekehrt; die App bindet es nicht
  ein. Bots schicken Befehle (`build`, `upgrade`, `useAbility` …) wie ein Spieler und
  ändern den Zustand nie selbst (Regel 2).
- **Zufall nur gesät** (Regel 6): Jeder Bot bekommt einen eigenen `SplitMix64` aus dem
  Startwert des Laufs. Die Mission selbst bleibt ohne Zufall.
- **Keine Zahl im Code** (Regel 7): Gewichte und Eigenschaften der Bots (Zögern in
  Ticks, Streuung der Platzierung, Anteil der Fähigkeit) und alle Zielwerte stehen in
  `labor.json`. `LabConfig.issues()` prüft die Datei beim Laden, eine fehlerhafte Datei
  bricht den Lauf ab (Rückgabewert 2).
- **Parallel**: Läufe sind unabhängig und werden über alle Kerne verteilt; das Ergebnis
  ist nach Lauf-Kennung sortiert und deshalb gleich, egal in welcher Reihenfolge die
  Kerne fertig werden. Zwei Läufe mit denselben Argumenten schreiben dieselbe Datei.
- **Erster Versuch** (D-071): Für Mission N rechnet der Lauf mit Rang, Talenten und
  Ausrüstung, die drei Sterne in allen Missionen davor geben, Schmiede auf Stufe I.

### Zielwerte im Grundstock

| Ziel | Rot oder Warnung |
|---|---|
| Keine Bauweise des gierigen Bots liegt mehr als ein Grenzwert vor der zweitbesten | rot |
| Monokultur aus Blitz oder Sporen verliert beim ersten Spielen jeder Mission (Säule 1) | rot |
| Jeder Turm wird vom Zufallsbot in gewonnenen Läufen gebaut, keiner ist nutzlos | rot |
| Siegquote des Menschenbots je Mission (Karte oben) | Warnung bis zum Spieltest |
| Invarianten über alle Läufe: Gold nie negativ, höchstens ein Turm je Zelle, Mission endet genau einmal, Leben nie unter 0 | rot |

### Bekannte Befunde

Ein Zielwert, der beim ersten Lauf schon verletzt ist, wird nicht aufgeweicht. Er steht
in `labor.json` unter `known` mit Kennung und Grund, erscheint im Bericht als „bekannt“
und hält die CI nicht auf. Jede **neue** Verletzung bleibt rot. Hält ein bekannter Befund
wieder, meldet der Bericht eine Warnung: Dann gehört der Eintrag gestrichen. Die Liste
kann so nur schrumpfen (Sperrklinke); ein neuer Eintrag braucht einen Eintrag im
Entscheidungsprotokoll.

### Kommandozeile

```
swift run -c release --package-path Packages/OddlingsCore oddlings-balance \
  --stufe pr --ausgabe build/balance
```

`--stufe pr` nimmt den kleinen Satz aus `labor.json`, `--stufe gross` den großen
(für später), `--mission m3` und `--volk elves` schränken ein. Ausgabe: `bericht.md`,
`laeufe.csv`, Rückgabewert ≠ 0 bei rotem Ziel.

## Sicherheit

Das Werkzeug liest nur Dateien aus dem Paket und schreibt nur in das angegebene
Ausgabeverzeichnis; kein Netz, keine Fremdbibliothek. Argumente werden geprüft, ein
unbekanntes Argument bricht ab. Die CI-Stufe läuft mit `permissions: contents: read`.

## Tests

- Bots: gleicher Startwert gleiche Befehle, anderer Startwert andere; der Menschenbot
  baut später und ungenauer als der gierige.
- Lauf: parallel und nacheinander liefern denselben Bericht.
- Zielwerte: eine künstlich kaputte Mission (Blitz übermächtig) macht das Ziel rot,
  eine Zieldatei mit Unsinn wird beim Laden abgewiesen.
- Invarianten: eine Stichprobe zufälliger, auch ungültiger Befehlsfolgen.
- `BalanceTests` laufen weiter grün, jetzt mit dem Bot aus dem Labor.
- CI: Schritt „Balance-Labor (Stufe pr)“ im Job `core-linux` ruft das Werkzeug auf,
  schreibt den Bericht in die Zusammenfassung und lädt ihn als Artefakt hoch.
- Jeder neue Test wird einmal rot gesehen.

## Risiken

- Laufzeit der PR-Stufe: Der kleine Satz muss in wenigen Minuten bleiben. Gegenmittel:
  Größe in der Zieldatei, Messung im Bericht.
- Der Menschenbot ist eine Annahme. Erst der Spieltest sagt, ob er Menschen ähnelt;
  bis dahin warnt die Siegquote nur.

## Erster Lauf (03.11.2026, Stufe pr, 164 Läufe, etwa 25 Sekunden)

- **Blitz-Monokultur gewinnt Mission 2 und 3 beim ersten Spielen**, bei Zwergen und
  Elfen. Mission 2 schon ohne Volk (Reserve 1,18), Mission 3 erst mit Volk und Talent
  (bis 1,14, ohne Volk 0,96). Das widerspricht D-071. Behebung als eigenes Paket, Karte
  an Steffen.
- **Mission 1, Elfen:** Blitz + Sporen liegt 0,49 Reserve vor der zweitbesten Bauweise
  (Grenze 0,35). Das Mondmal verstärkt genau die Kernsynergie.
- Diese fünf stehen als bekannte Befunde in `labor.json`.
- Menschenbot gewinnt M1 100 %, M2 92 %, M3 100 %, M4 92 % (Ziel B: 90/75/60/50). Alle
  Missionen sind für ihn eher zu leicht; das passt zum Befund oben.
- Der Zufallsbot gewinnt Mission 3 (Zwerge) und Mission 4 nie: Wer dort wahllos baut,
  verliert. Warnung, kein Rot.
- Keine Invariante verletzt.
