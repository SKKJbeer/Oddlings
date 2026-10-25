# Konzepte für Phase 2 und 3

Stand: 25.10.2026 · Verfasser: Claude (Projektplanung) · Status aller Abschnitte:
**[VORSCHLAG]**, soweit nicht anders markiert.

Hier stehen die ausgearbeiteten Antworten auf die offenen Fragen der Übergabe
(Abschnitt 18) und des [Entscheidungsprotokolls](../decisions/decision-log.md),
die für die nächsten Phasen gebraucht werden. Welche Frage wo steht und wer sie
entscheidet: [Register offener Fragen](../production/offene-fragen.md).

**Regel für diese Datei (D-021, ergänzt D-017):** Ein Konzept steht hier, bis Steffen es
entschieden hat. Dann wandert die entschiedene Fassung in ihr Fachdokument
(02 bis 06), hier bleibt ein Verweis. So steht jede Entscheidung an genau einer
Stelle. Zahlen hier sind Zielgrößen für die erste Rechnung; die Werte selbst
kommen wie immer in die Missionsdatei und werden mit den `BalanceTests` geprüft.

Jedes Konzept wird gegen die fünf [Säulen](../game-design/00-vision-and-pillars.md) und die
[Marktanalyse](../game-design/market-analysis.md) (Abschnitt 7) geprüft.

---

## K1 · Aufwertungen mit einer Gabelung je Turm

**Entschieden** (D-024, Steffen, 25.10.2026). Steht jetzt in [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2).

---

## K2 · Festungsfähigkeit und Völker

**Entschieden** (D-025, Steffen, 25.10.2026). Steht jetzt in [03](../game-design/03-races-and-avatar.md#festungsfähigkeit-und-wie-ein-volk-wirkt).

---

## K3 · Zwergenbank

**Entschieden** (D-026, Steffen, 25.10.2026). Steht jetzt in [04](../game-design/04-economy-and-balance.md#zwergenbank-phase-2).

---

## K4 · Kampagne und Regionen

**Entschieden** (D-027, Steffen, 25.10.2026). Steht jetzt in [05](../game-design/05-campaign-and-progression.md#region-1-und-die-vollversion).

---

## K5 · Fortschritt und Freischaltungen

**Entschieden** (D-027, Steffen, 25.10.2026). Steht jetzt in [05](../game-design/05-campaign-and-progression.md#fortschritt).

---

## K6 · Speicherstand

Übergabe Nr. 11 · Grundsätze als D-022 festgehalten (technisch, im Rahmen der
Architekturregeln; Einspruch jederzeit möglich)

- **Lokal**, eine JSON-Datei im Application-Support-Verzeichnis der App, mit
  `schemaVersion`. Aufbau wie in [data-models.md](../technical/data-models.md#speicherstand-phase-2).
- **Atomar schreiben** (temporäre Datei, dann ersetzen) und die vorige Fassung
  behalten. Ist die neue beim Laden beschädigt, gilt die vorige.
- **Beim Laden prüfen**, bevor etwas die Simulation erreicht (Regel aus
  CLAUDE.md, „Sicherheit"): Schema, Wertebereiche, bekannte Missions- und
  Turm-Kennungen. Unbekanntes wird verworfen, nicht geraten.
- **Migration** je Version als reine Funktion mit Test (alte Datei rein, neue raus).
- **Laufende Mission fortsetzen:** Beim Wechsel in den Hintergrund wird der
  `GameState` mitgeschrieben, zusammen mit einer Prüfsumme der Missionsdatei.
  Passt die Prüfsumme nach einem Update nicht mehr, wird die Mission nicht
  fortgesetzt, sondern neu gestartet, mit Hinweis. Ein alter Zustand unter neuen
  Regeln wäre ein Spiel, das so nie stattfand.
- **Einstellungen** (Ton, Haptik, Geschwindigkeit) getrennt in `UserDefaults`;
  sie gehören nicht zum Spielstand.
- **iCloud** später (Phase 4): Apples eigener Abgleich, kein eigenes Backend.
  Ob, entscheidet Steffen dann.

---

## K7 · Gegner, Bosse, Rüstung

Übergabe Nr. 4, Abschnitt 7 · offen in [02](../game-design/02-combat-and-towers.md)

- **Panzerbestie:** steht in der Missionsdatei ab Welle 7 bereit und ist in
  Region 1 ab M4 fest dabei.
- **Rüstung:** Vorschlag erst Phase 3, und dann als **fester Abzug je Treffer**.
  Das trifft viele kleine Treffer (Blitzsprünge, Sporenpuls) stärker als wenige
  große (Falkenhorst) und gibt der Spezialisierungswahl einen Gegner, ohne
  Schadenstypen einzuführen.
- **Immunität gegen Verlangsamung:** keine volle Immunität; Bosse halbieren die
  Wirkung. Sonst würde der Sporenturm in Bossmissionen wertlos, und das ist der
  Turm, den Spieler ohnehin am schwersten verstehen (Risiko P1).
- **Boss Region 1 „Moorkönig"** (Name Platzhalter): zwei Phasen. Bei halbem Leben
  bleibt er stehen und ruft Plünderer, bis eine Schildzeit abläuft. Prüft:
  Gruppenschaden (Blitz) und nachhaltigen Einzelschaden (Wachturm) zugleich.
- **Schattenflieger** (Region 2): fliegt eine eigene, kürzere Linie, wird nur von
  Wach- und Blitzturm getroffen, Sporen wirken nicht. Eine neue Regel, kein
  neues System.

---

## K8 · Einstieg ohne Erklärtext

Nicht in der Übergabe, aber Teil von „AAA-Anmutung" (Marktanalyse Abschnitt 3)
und Risiko P1/P2.

- Mission 1 erklärt nicht, sie zeigt: höchstens drei kurze Hinweise im Spiel
  (eine Hand, die auf eine Bauzelle tippt; ein Pfeil auf „Nächste Welle";
  ein Satz beim ersten verlangsamten Gegner, der vom Blitz getroffen wird).
- Jeder Hinweis erscheint einmal und lässt sich überspringen.
- Die Synergie lehrt die Rückmeldung (E2 „Sporenfunke"), nicht ein Text.
- Prüfen im Spieltest: Wird ohne Hinweis gebaut? Wird der Sporenturm gebaut?

Gehört zu Phase 2 (Menüs und Führung). Abhängigkeit zum Thread „Spieloberfläche".

---

## K9 · Ton und Haptik

Übergabe: Phase 2 „Soundeffekte und Animationen" · Marktanalyse E1, Abschnitt 3

**Lücke in der Planung:** Für Grafik gibt es einen Weg (D-016, Skill
`spielgrafik`), für Ton noch keinen. Vorschlag:
- Klänge aus lizenzfreien Sammlungen (CC0) als Grundstock, eigene Kennklänge je
  Turm über ein Klang-Werkzeug. Herkunft und Lizenz je Datei in einer
  `ENTSTEHUNG.md`, wie bei den Bildern; die CI prüft, dass jede Datei einen
  Eintrag hat.
- Höchstzahl gleichzeitiger Klänge je Art, damit Massen nicht übertönen.
- Haptik nur für Handlungen des Spielers und für Durchbrüche, nie für Treffer.
- Musik: ein ruhiges Stück je Region, eine Bossfassung.

Vorschlag für den Ablauf: ein eigener Thread „Ton und Haptik" zu Beginn von
Phase 2, sobald die Rückmeldeliste (E1) aus dem Grafik-Thread steht.

---

## K11 · Balance-Labor: automatisierte Balance- und Stresstests

Steffen, 25.10.2026: Balancing ist ein Kernpunkt des Spiels und muss später
ausgiebig und automatisiert getestet werden, mit vielen Stresstest-Läufen.
Richtung **[ENTSCHIEDEN D-028]**, Ausgestaltung **[VORSCHLAG]**.

**Ausgangslage.** Die Simulation läuft schon ohne Darstellung, deterministisch
und unter Linux (WP-10). Die `BalanceTests` spielen eine Mission mit sieben
Bauweisen eines einzigen Bots. Das reicht für Mission 1, nicht für Aufwertungen,
Bank, Völker und eine Kampagne: Mit jedem dieser Teile wächst die Zahl der
Möglichkeiten um eine Dimension.

**Bausteine**

| Baustein | Was er tut |
|---|---|
| Lauf-Werkzeug | Ein Kommandozeilenprogramm im Paket (`oddlings-balance`, nur Foundation): nimmt Missionen, Völker, Bauweisen, Startwerte und Lebensfaktoren und spielt alle Kombinationen ohne Darstellung, parallel auf allen Kernen |
| Bot-Familie | Neben dem heutigen gierigen Bot: **Zufallsbot** (gesät, baut zufällige gültige Bauweisen), **Menschenbot** (Reaktionszeit, ungenaue Platzierung, verkauft nicht), **Sucher** (verändert eine Bauweise schrittweise und behält, was mehr Reserve bringt). Der Sucher findet dominante Strategien, bevor Spieler sie finden |
| Startwerte | Die Mission selbst bleibt ohne Zufall. Gesät werden die Entscheidungen der Bots; viele Startwerte heißt viele leicht verschiedene Spieler |
| Kennzahlen | Reserve je Bauweise, Siegquote je Bot-Art, Durchbrüche je Welle, Gold- und Schadenskurve, Nutzung und Schaden je Gold jedes Turms und jeder Spezialisierung, Missionsdauer |
| Zielwerte | Eigene Datei neben der Missionsdatei (`balance-ziele.json`), keine Zahl im Code. Beispiele: keine Bauweise mehr als einen Grenzwert vor der zweitbesten; jede Spezialisierung ist mindestens einmal die beste Wahl; Monokultur verliert ab der mittleren Mission (Säule 1); der Menschenbot gewinnt Mission 1 fast immer, die Bossmission selten beim ersten Versuch |
| Stresstests | Zehntausende Missionen ohne Absturz; dieselbe Prüfsumme in getrennten Prozessen; zufällige Befehlsfolgen (gültig und ungültig) gegen Invarianten wie „Gold nie negativ“, „ein Turm je Zelle“, „Mission endet genau einmal“; Schritte je Sekunde bei der spätesten Welle mit Höchstzahl an Gegnern |
| Bericht | Markdown und CSV je Lauf, mit Vergleich zum letzten Lauf auf `main`: welche Kennzahl sich wie stark bewegt hat |

**CI in zwei Stufen**

1. **Bei jedem PR** (wie heute, Minuten): der kleine Satz Bauweisen je Mission,
   Invarianten-Stichprobe, Zielwerte. Rot bei Verletzung.
2. **Großer Lauf** nachts und per Knopf (Linux, Stunden erlaubt): ganze Matrix,
   alle Bot-Arten, viele Startwerte, Sucher, Stresstests. Bericht als Artefakt;
   rot, wenn ein Zielwert reißt oder eine Kennzahl ohne Balanceänderung mehr als
   eine Schwelle wandert. Eine Balanceänderung ohne Bericht im PR wird nicht
   zusammengeführt.

**Zeitpunkt.** Nicht jetzt: Für eine Mission mit drei Türmen reichen die
heutigen Tests, und Werte, die der Spieltest WP-15 ohnehin verschiebt, lohnt es
nicht groß zu vermessen.
- **Grundstock in Phase 2** (P2-6b), direkt nach Bank und Aufwertungen: Lauf-Werkzeug,
  Zufalls- und Menschenbot, Zielwerte, PR-Stufe. Ab da gibt es mehr Möglichkeiten,
  als ein Mensch überblickt.
- **Ausbau in Phase 3**: jede Mission der Region läuft im großen Lauf, bevor sie
  ausgeliefert wird; Völker als eigene Achse.
- **Vollausbau in Phase 4** (Meilenstein M4.1): Sucher, nächtlicher Lauf, Stresstests,
  Abgleich mit den Spieltests („Bot sagt leicht, Menschen scheitern“ ist ein Befund).

**Grenzen.** Bots sind keine Menschen. Das Labor sagt, ob etwas kaputt oder
dominant ist, nicht ob es Spaß macht. Das bleibt Aufgabe der Spieltests.

---

## K10 · Was bewusst später entschieden wird

| Frage | Übergabe | Wann | Warum nicht jetzt |
|---|---|---|---|
| Endgültiger Name und Marke | Nr. 1 | Phase 3, vor dem öffentlichen Store-Eintrag | Ein Name braucht Marken- und Store-Suche und sollte zum fertigen Stil passen. Vorschlag: drei Kandidaten in Phase 3, Prüfung beim DPMA/EUIPO und im App Store, Steffen wählt |
| Multiplayer-Architektur | Nr. 12 | Phase 5 | Vorleistung steht ([architecture.md](../technical/architecture.md) §4); mehr wäre Scope-Verbot |
| Preis, Release, Apple Arcade (E14) | Nr. 13 | Phase 5 | D-015 gibt die Richtung; der Preis braucht Daten aus Phase 4 |
| Cloud-Speicher | Nr. 11 | Phase 4 | K6 hält die lokale Seite so, dass er später passt |
