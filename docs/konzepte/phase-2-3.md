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

Übergabe Nr. 7 · Marktanalyse E6, E5 · berührt D-008 (keine Upgrades im MVP, bleibt)

**Warum überhaupt.** Alle Marktführer leben von Aufwertungen. Ohne sie gibt es
ab der Mitte einer Mission nur noch eine Frage, „wohin der nächste Turm", und
bei 114 Bauplätzen ist die schnell beantwortet. Aufwertungen bringen die zweite
Frage dazu: verbreitern (neuer Turm, mehr Abdeckung) oder vertiefen (bestehender
Turm, mehr Wirkung an einer Stelle).

**Aufbau.** Drei Stufen, eine Wahl.

| Stufe | Wie man hinkommt | Was sie tut |
|---|---|---|
| 1 | Bauen | Grundturm wie im MVP |
| 2 | Aufwerten, Gold | Gleiche Rolle, spürbar stärker; schaltet die Zielwahl frei (E5) |
| 3 | Spezialisieren, Gold, **eine von zwei** | Verstärkt je eine andere Synergie; die andere ist für diesen Turm weg |

Die Wahl gilt je Turm und je Mission. Zwei Blitztürme dürfen verschieden
spezialisiert sein. Das ist die eigentliche Tiefe: dieselbe Karte wird mit einer
anderen Mischung anders gespielt.

**Spezialisierungen.** Jede stärkt eine Kombination, keine ist reiner Mehrschaden.

| Turm | A | B |
|---|---|---|
| Wachturm | **Falkenhorst:** große Reichweite, schwerer Schuss, langsamer. Gegen Panzerbestien und Bosse | **Salve:** trifft zwei Ziele je Schuss. Gegen Flitzerschwärme |
| Blitzturm | **Gewitterkrone:** zwei Sprünge mehr; Sprünge auf verlangsamte Gegner verlieren keinen Schaden. Verstärkt die Kernsynergie | **Funkensäule:** erster Treffer deutlich stärker, weniger Sprünge. Blitz auch gegen zähe Einzelziele |
| Sporenturm | **Moorherz:** größerer Radius, stärkere Verlangsamung. Reine Kontrolle | **Fäulnis:** verlangsamte Gegner nehmen von allen Türmen mehr Schaden. Macht Sporen neben Wachtürmen wertvoll (Befund aus WP-10, siehe [04](../game-design/04-economy-and-balance.md#ergebnis-der-prüfung)) |

Neue Regeln, die das braucht: ein Zustand „verwundbar" (Schadensfaktor mit
Dauer, wie die Verlangsamung, stapelt nicht), Mehrfachziel beim Wachturm,
Abfall abhängig vom Zustand des Ziels. Alle drei passen in die bestehende
Simulation (Ereignisse, Zustand als Wert); keine braucht Zufall.

**Wirtschaft.** Zielgröße: Stufe 2 kostet etwa 70 % des Grundturms und bringt
etwa 50 % mehr Wirkung, ist also je Gold leicht besser als ein zweiter Turm,
deckt aber keinen neuen Wegabschnitt ab. Spezialisierung kostet etwa so viel wie
ein Grundturm. Verkaufen erstattet 70 % von **allem**, was im Turm steckt
(`Tower.spent` gibt es schon).

**Bedienung.** Turm antippen → im Turmmenü aus WP-12 „Aufwerten (Preis)". Auf
Stufe 2 zeigt das Menü zwei Karten nebeneinander, je mit Symbol, einem Satz und
Preis. Zielwahl als Umschalter im selben Menü (erster / letzter / stärkster).
Abhängigkeit zum Thread „Spieloberfläche und Menüs".

**Grafik.** Je Turm Stufe 2 als Anbau am selben Bild, Stufe 3 je eigene Ansicht:
sechs neue Turmbilder. Abhängigkeit zum Thread „AAA-Grafik".

**Prüfung.** `BalanceTests` bekommen Bauweisen mit Aufwertungen. Erwartung:
Mischungen mit passenden Spezialisierungen haben die größte Reserve, und jede
der sechs Spezialisierungen ist in mindestens einer Bauweise die beste Wahl.
Ist eine nie die beste, ist sie falsch, nicht der Test.

**Freischaltung.** In Region 1 kommen Stufe 2 und die Spezialisierungen nach und
nach dazu (K4), damit Mission 1 so einfach bleibt, wie sie ist.

**Empfehlung:** so in Phase 2 einplanen. Alternative wäre eine lineare dritte
Stufe ohne Wahl: halb so viel Grafik, aber nur „mehr Zahl", das widerspricht
Säule 1 und 3. → Entscheidung Steffen (E-1).

---

## K2 · Festungsfähigkeit und Völker

Übergabe Nr. 9 · Marktanalyse E7 · offen in [03](../game-design/03-races-and-avatar.md)

### K2a · Eine aktive Festungsfähigkeit (Phase 2)

**Warum.** Steht die Verteidigung, hat der Spieler nichts zu tun außer
zuzusehen. Kingdom Rush löst das mit Zaubern und Helden. Ein Held ist bei uns
ausgeschlossen; eine Fähigkeit an der Festung schließt dieselbe Lücke, ohne
Figur, Steuerung und Wegfindung.

**Regel.** Ein Knopf im HUD. Antippen, dann eine Stelle am Weg antippen. Nach
kurzer Verzögerung (sichtbarer Schatten) trifft **Steinregen** alle Gegner im
Kreis: Schaden und ein kurzes Anhalten. Danach Abklingzeit. Kostet kein Gold,
ist ab der ersten Welle bereit.

Warum Steinregen: Er belohnt dieselbe Lage wie der Blitz (dichte, verlangsamte
Gruppen), stärkt also Säule 1, statt eine zweite Spielidee zu öffnen. Er ist
ein Befehl wie `build` (`useAbility(point)`), also determinierbar und testbar.

**Prüfung.** Der Balance-Bot setzt ihn auf die dichteste Stelle. Die Reserve
darf dadurch um höchstens etwa 0,1 steigen; sonst ersetzt die Fähigkeit Türme.

### K2b · Wie ein Volk wirkt (Phase 3)

[03](../game-design/03-races-and-avatar.md) nennt drei Möglichkeiten: passive Boni, eigener
Turm, aktive Volksfähigkeit. **Vorschlag: Ein Volk bestimmt die
Festungsfähigkeit und hat einen kleinen passiven Zug.** Kein eigener Turm vor
dem Release.

| Volk | Festungsfähigkeit | Passiver Zug | Spielstil |
|---|---|---|---|
| ohne Volk (Phase 2) | Steinregen | – | Grundspiel |
| Zwerge | **Bollwerk:** eine Mauer sperrt den Weg kurz, Gegner stauen sich | Zwergenbank mit höherem Ertragsdeckel | Wirtschaft, planen, stauen |
| Elfen | **Mondmal:** Gegner im Kreis sind kurz verwundbar | Sporentürme mit etwas mehr Reichweite | Kontrolle, Präzision |

Begründung:
- Spürbar verschieden, ohne die Grundtürme zu verändern. Die Grundsätze in 03
  („Grundrollen für alle", „keine Pflichtwahl") bleiben unberührt.
- Billig: eine Fähigkeit und ein Zahlenwert je Volk, statt eines Turms mit
  drei Stufen, zwei Spezialisierungen und Grafik.
- Testbar: Ein Volk ist eine zweite Konfiguration derselben Mission. Die
  Balancetests rechnen jede Mission mit jedem Volk; kein Volk darf mehr als
  etwa 0,05 Reserve vor dem anderen liegen.
- Mondmal nutzt denselben Zustand „verwundbar" wie die Spezialisierung Fäulnis
  (K1). Eine Regel, zwei Verwendungen.

**Wahl.** Das Volk gehört zum Avatar, lässt sich aber vor jeder Mission
wechseln. Fortschritt hängt nicht am Volk. So wird keins zur Pflicht, und wer
ausprobieren will, verliert nichts.

Ein volkseigener Turm (Möglichkeit 2) bleibt als Inhalt für eine spätere
Erweiterungsregion denkbar. Goblins und Arkanisten ebenso.

**Empfehlung:** K2a in Phase 2, K2b in Phase 3. → Entscheidung Steffen (E-2).

---

## K3 · Zwergenbank

Übergabe Nr. 8 · D-010 · Startwerte in [04](../game-design/04-economy-and-balance.md#zwergenbank-phase-2)

### Für wen (D-010)

Die Übergabe nennt die Bank zugleich „Zwergen-Kennzeichen" und Wirtschaftsturm
des Einzelspielers. **Vorschlag: Die Bank ist ein Grundturm für alle** (der
vierte, ab Phase 2). Zwerge haben ihren passiven Zug an der Bank (K2b) und die
Bank ist im Aussehen ein Zwergenbau. Grund: Die Bank trägt die Säule „Echte
Entscheidungen" (jetzt verteidigen oder später ernten). Diese Entscheidung soll
jeder Spieler haben, nicht nur wer Zwerge wählt. → Entscheidung Steffen (E-3).

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

### Kennzahl

Bleibt wie in 04: Eine Bank in Welle 1 rechnet sich etwa ab Welle 4 und bringt
in Summe ungefähr so viel, wie zwei Wachtürme an Durchbrüchen verhindert hätten.
In den `BalanceTests` heißt das: Die beste Bauweise mit Bank liegt höchstens
0,05 Reserve über oder unter der besten ohne Bank. Liegt sie deutlich darüber,
ist die Bank Pflicht; deutlich darunter, ist sie bedeutungslos.

### Bonus für frühes Rufen (D-009, E8)

Gehört zur selben Wirtschaftsrunde und wird mit der Bank zusammen gerechnet:
Wer die nächste Welle früher ruft, bekommt einen kleinen Goldbetrag je
eingesparter Sekunde. Klein genug, dass Abwarten nie ein Fehler ist.

---

## K4 · Kampagne und Regionen

Übergabe Nr. 10 · D-015 · Richtung in [05](../game-design/05-campaign-and-progression.md)

D-015 legt das Geschäftsmodell nahe: erste Region kostenlos, Vollversion
einmalig. Daraus folgt eine harte Anforderung an Region 1: **Sie muss allein
überzeugen** und lange genug sein, um ein Urteil zu tragen (Ziel: etwa eine bis
anderthalb Stunden), aber kurz genug, dass man das Ende sieht und mehr will.

### Region 1 „Flüsterwald" (kostenlos)

```
 M1 ─ M2 ─ M3 ─ M4 ─┬─ M5a Sumpfpfad ─ M6a ─┬─ M7 Boss
                    └─ M5b Ruinen ─── M6b ─┘
            N1 (ab 6 Sternen)      N2 (ab 15 Sternen)
```

| Mission | Neu | Lehrt |
|---|---|---|
| M1 | Wach-, Blitz-, Sporenturm; Plünderer, Flitzer | Grundspiel (heutige Mission 1) |
| M2 | Zwergenbank | Ernten oder verteidigen |
| M3 | Aufwerten Stufe 2, Zielwahl | Vertiefen statt verbreitern |
| M4 | Festungsfähigkeit; Panzerbestie | Aktiv eingreifen, zähe Ziele |
| M5a/b, M6a/b | Spezialisierungen (je Weg andere zuerst) | Gabelung: Sumpf schickt Flitzer, Ruinen schicken Panzerbestien |
| M7 | Boss | Alles zusammen |
| N1, N2 | Nebenmissionen mit Sonderregel | Wiederspielwert |

Beide Wege der Gabelung führen zum Boss. Wer will, spielt den anderen danach
nach. Am Ende von Region 1 sind beide Völker freigespielt (K2b), damit auch
wer nicht kauft das ganze Grundspiel kennt.

### Regionen der Vollversion

Region 2 „Eisengipfel" und Region 3 „Sturmklamm", je etwa acht Missionen. Jede
bringt **eine** neue Gegnerart (Region 2: Schattenflieger, nur von Wach- und
Blitzturm zu treffen), **einen** neuen Boss und eine neue Kartenoptik. Spätere
Erweiterungsregionen (D-015) dürfen einen volkseigenen Turm oder ein neues Volk
bringen.

### Sterne und Herausforderungen (E9)

- Sterne nach verbleibendem Leben: 1 (gewonnen), 2 (ab 15), 3 (alle 20). Die
  Grenzen stehen in der Missionsdatei.
- Sterne öffnen Nebenmissionen, nie Hauptmissionen. Niemand bleibt stecken.
- Je Mission ein **Eisern-Modus** nach dem ersten Sieg: eine Einschränkung
  („nur zwei Turmtypen", „Festung hat 1 Leben"). Gibt ein Abzeichen, keinen
  Spielvorteil.

### Aufwand, nüchtern

Eine Mission ist eine Wegführung, zehn Wellen in der Missionsdatei und eine
Kartenansicht. Wellen und Weg sind Daten; die Karte ist der teure Teil. Deshalb
teilt sich eine Region einen Kartenstil, und die Missionen unterscheiden sich
durch Wegführung, Bauzonen und Wellen. Ein Kartenwerkzeug, das Weg und Zonen
aus einer Datei vorzeichnet, spart hier viel und gehört in Phase 3.

**Empfehlung:** Region 1 wie oben (sieben Haupt-, zwei Nebenmissionen mit
Gabelung). Alternative: fünf Missionen, Rest in der Vollversion; billiger, aber
die freie Region zeigte dann weder Spezialisierungen noch Völker, also genau das
nicht, was Oddlings ausmacht. → Entscheidung Steffen (E-4).

---

## K5 · Fortschritt und Freischaltungen

Übergabe Nr. 10 · Kandidaten in [05](../game-design/05-campaign-and-progression.md#fortschritt-offen)

Was dauerhaft freigeschaltet wird:

| Freischaltung | Wodurch |
|---|---|
| Türme, Aufwertungen, Spezialisierungen, Festungsfähigkeit | Hauptmissionen (K4) |
| Völker | Ende Region 1 |
| Nebenmissionen | Sterne |
| Bestiarium und Turmbuch (E11): Eintrag mit Bild und Charaktertext | erste Begegnung |
| Abzeichen, Banner, Titel für den Avatar | Eisern-Modi, Bosse, alle Sterne einer Region |

Was es **nicht** gibt:
- Keine dauerhaften Werteboni („+5 % Schaden"). Jede Mission rechnet mit
  denselben Werten für jeden Spieler; nur so bleiben die Balancetests gültig.
  Das bestätigt den Vorschlag aus 05.
- Keine zweite Währung, keine Erfahrungspunkte, kein Ausdauerbalken. Säule 5.
- Keine täglichen Pflichtaufgaben im ersten Release. Die tägliche Herausforderung
  (E10) bleibt ein Kandidat für nach dem Release und braucht eine Freigabe.

Damit ist Fortschritt: mehr Möglichkeiten, nicht mehr Zahl. Der Spieler wird
besser, nicht sein Spielstand.

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
