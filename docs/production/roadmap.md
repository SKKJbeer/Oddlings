# Roadmap

Die gemeinsame Arbeitsliste von Steffen und Claude. Reihenfolge von Zielen, **keine
Zeitplanung**. Eine Phase ist fertig, wenn ihre Abnahme erfüllt ist, nicht wenn Code
existiert.

**So arbeiten wir damit.** Claude arbeitet „Als Nächstes“ von oben nach unten ab,
ein Paket je PR, und trägt den Stand nach jeder Auslieferung hier ein (D-067).
Steffen steuert, indem er eine Nummer nennt („erst P2-3“, „R-7 später“) oder eine
Entscheidungskarte beantwortet. Alles, was auf ihn wartet, steht unter
[Wartet auf Steffen](#wartet-auf-steffen); jede neue Karte meldet der Coordinator
zusätzlich im Projektchat. Kurzstand: [status.md](status.md), Pakete im Einzelnen:
[backlog.md](backlog.md), offene Fragen: [offene-fragen.md](offene-fragen.md).

**Stand: 03.11.2026** · neueste Version 0.22.0 (Fortsetzen nach Neustart, Bau 43), davor 0.21.1 (Balance-Labor, Bau 42), 0.21.0 (Schmiede, Bau 41), neuester VALID-Bau 43 (0.22.0)

## Phasen

| Phase | Ziel | Abnahme | Stand |
|---|---|---|---|
| **0 – Design und Planung** | Konsistenter Designstand, MVP abgegrenzt, Backlog | Steffen gibt Dokumente und offene Entscheidungen frei | ✓ 25.10.2026 |
| **1 – Spielbarer Kampfprototyp** | Eine Karte, ein Weg, drei Türme, Gegner, Gold, Wellen, Sieg/Niederlage, Neustart, Tests | Mission 1 auf dem iPhone spielbar, Regeltests grün, drei Personen haben gespielt | Technik ✓, **Spieltest WP-15 offen** |
| **Spielrahmen (vorgezogen, D-060)** | Hauptmenü, Kampagnenkarte, Festungsfähigkeit, Völker, Avatar | Pakete R-1 bis R-7 in TestFlight | ✓ bis R-7b (0.21.0) |
| **2 – Vertical Slice** | Zwergenbank, spürbare Synergie, Ton, Animation, Grafik, Fortsetzen | Eine Mission wirkt wie das fertige Spiel; Spieler finden die Synergie ohne Erklärung | Grafik und Effekte laufen, Rest wartet auf den Schnitt nach WP-15 |
| **3 – Kleine Kampagne** | Region 1 mit sieben Haupt- und zwei Nebenmissionen, Boss | Spieler wollen nach Mission 1 weiterspielen (gemessen) | Karte steht, Mission 2 und 3 gebaut, 4 bis 7 fehlen |
| **4 – Qualität und Balancing** | Echte Geräte, Leistung, externe Spieltests, Balance-Labor | Absturzfrei, 60 Bilder/s auf dem ältesten Zielgerät | – |
| **5 – Produktentscheidung** | Weiter investieren? Monetarisierung? Koop? | Entscheidung mit Daten aus Phase 4 | – |

## Wartet auf Steffen

| # | Was | Wo | Blockiert | Empfehlung |
|---|---|---|---|---|
| S2 | Volk wechseln, bevor es eine Spielwährung gibt (Entscheidungskarte seit 26.10.) | Thread „Oddlings-Designstand und MVP-Plan aufsetzen“ | nichts, die Empfehlung gilt bis zur Antwort | Gar nicht |
| S3 | **Spieltest mit drei Personen** auf dem neuesten Bau, [Beobachtungsbogen](playtests/beobachtungsbogen.md) | WP-15 | Abschluss Phase 1, Schnitt Phase 2, D-030, Werte D-007 | so bald wie möglich |
| S4 | Leistung des Spikes auf dem iPhone messen | WP-01 | nichts Akutes; D-002 gilt bis dahin | ohne Eile |
| S8 | Was Mission 4 Neues bringt (Entscheidungskarte seit 02.11.) | Thread „Mission 3 mit Aufwertungen bauen“ | nichts, Mission 4 wird mit der Empfehlung gebaut | Panzerbestie mit Rüstung als fester Abzug je Treffer |
| S9 | R-7b Schmiede: woher die Währung kommt, was die Schmiede macht, wie die Währung heißt (drei Karten seit 02.11.) | Haupt-Thread, [Konzept](../konzepte/r-7b-schmiede.md) | nichts, gebaut sind die Empfehlungen (D-072); eine andere Wahl wird umgebaut | Erz aus jedem Sieg, mehr für neue Sterne; Stufen I bis III; Name Erz |
| S10 | Wie schwer Mission 1 bis 4 beim ersten Versuch sein sollen (Entscheidungskarte seit 03.11.) | Haupt-Thread, [Konzept](../konzepte/p2-6b-balance-labor.md) | nichts, das Labor warnt nach der Empfehlung (D-073) | Steigend: M1 ≥ 90 %, M2 ≥ 75 %, M3 ≥ 60 %, M4 ≥ 50 % |
| S12 | Wo die App nach einem Neustart mitten in einer Mission öffnet (Entscheidungskarte seit 03.11.) | Thread „Fortsetzen nach App-Neustart bauen“, [Konzept](../konzepte/p2-2-fortsetzen.md) | nichts, gebaut ist die Empfehlung (D-074) | Direkt in der Mission, pausiert |
| S11 | Blitz allein gewinnt Mission 2 und 3 beim ersten Spielen: wann beheben (Entscheidungskarte seit 03.11.) | Haupt-Thread, [Labor](../konzepte/p2-6b-balance-labor.md#erster-lauf-03112026-stufe-pr-164-läufe-etwa-25-sekunden) | nichts, gebaut ist die Empfehlung (P2-11, D-075) | Jetzt, als eigenes Paket |

## Als Nächstes

Reihenfolge entschieden (D-080, Steffen 01.11.2026): Mission 2 kommt jetzt, der
Spieltest läuft parallel. Nach R-7a kommt Mission 3 mit Aufwertungen (D-085, 02.11.2026). Was davor steht, wird zuerst gebaut. Steffen kann umsortieren.

| # | Paket | Thread | Abh. | Stand |
|---|---|---|---|---|
| 1 | ~~FX 02 Plünderer mit Gliedmaßen~~ ([Konzept](../konzepte/fx-02-figuren-in-3d.md)) | Plünderer-3D-Modell | – | ✓ 0.13.0 |
| 2 | ~~P2-5 **Mission 2 mit Zwergenbank**~~ ([Konzept](../konzepte/p2-5-mission-2-zwergenbank.md)); Rang II und die erste Talentwahl werden spielbar. Werte [HYPOTHESE], nach WP-15 nachgezogen. Gemalter Boden kommt aus „Kampfplätze für Mission 2 bis 4 malen“ | Mission 2 mit Zwergenbank | – | ✓ 0.16.0 |
| 3 | ~~R-7a Ausrüstung~~ im Avatar-Menü (D-066, D-069, D-070, D-071), danach **R-7b Schmiede** mit Spielwährung: Konzept und Karten zur Währung | Haupt-Thread | R-6 | ✓ R-7a 0.19.0, R-7b 0.21.0 (Bau 41) |
| 4 | **WP-15 Spieltest** parallel, danach Werte von Mission 1 und 2 nachziehen und Phase 2 schneiden | Steffen | S3 | wartet |
| 5 | ~~P2-3 Ton und Musik~~ ([Konzept](../konzepte/p2-3-ton-und-musik.md)) | Ton und Musik | – | ✓ 0.15.0 |
| 6 | FX 02 Flitzer und Panzerbestie | Plünderer-3D-Modell | Steffens Urteil am Plünderer im Spiel | – |
| 7 | ~~P2-6 **Mission 3 mit Aufwertungen**~~ ([Konzept](../konzepte/p2-6-mission-3-aufwerten.md)): Stufe 2 und Zielwahl, Weg „Pilzhain“ (D-081, D-084); Mission 4 folgt danach, nicht parallel | Mission 3 mit Aufwertungen bauen | 2 | ✓ 0.18.0 |
| 8 | ~~P2-6b Balance-Labor~~, ~~P2-2 Fortsetzen~~, ~~P2-11 Blitz-Monokultur~~, P2-8 Synergie sichtbar, P2-9 Abstimmung | – | 2 | ✓ P2-6b 0.21.1, P2-2 0.22.0, P2-11 0.23.0; Konzepte K1, K6, K8 |
| 9 | ~~P2-10 **Mission 4 „Ruinenrand“**~~ ([Konzept](../konzepte/p2-10-mission-4-ruestung.md)): Panzerbestie mit Rüstung (K7, S8, D-087), Weg aus D-081 | Mission 3 mit Aufwertungen bauen | 7 | ✓ 0.20.0 |

## Ausgeliefert

Jede Zeile ist eine Version im [CHANGELOG](../../CHANGELOG.md).

| Paket | Version | Bau | Konzept |
|---|---|---|---|
| WP-02 … WP-10 Regeln von Mission 1 (M1.1) | 0.2.0 – 0.3.1 | – | [Backlog](backlog.md) |
| WP-11 Szene zeigt die Simulation (M1.2) | 0.4.0 | – | [Backlog](backlog.md) |
| WP-12 … WP-14 Mission spielbar (M1.3) | 0.5.0 | 19 | [Konzept](../konzepte/wp-12-14-spielbare-mission.md) |
| E2E-Grundlage (D-029) | 0.5.1 | 20 | [Konzept](../konzepte/e2e-tests.md) |
| Grafik 01: gemalte Figuren und Karte | 0.5.2 | 21 | [Konzept](../konzepte/grafik-01-spielfeld.md) |
| UI 01: Kreismenü, Tafeln, Haptik, Schriften | 0.6.0 | 22 | [Konzept](../konzepte/ui-01-hud-und-tafeln.md) |
| R-1/R-2: Hauptmenü, Einstellungen, Spielstand, Kampagnenkarte, Sterne | 0.7.0 | 23 | [Konzept](../konzepte/r-spielrahmen.md) |
| R-3: Steinregen | 0.8.0 | 24 | [Konzept](../konzepte/r-3-steinregen.md) |
| R-4: Zwerge (Bollwerk) und Elfen (Mondmal) | 0.9.0 | 25 | [Konzept](../konzepte/r-4-voelker.md) |
| Grafik 03: Titelbild, Turm- und HUD-Symbole | 0.9.1 | 26 | [Konzept](../konzepte/grafik-02-phase-2.md) |
| FX 01: Bewegung und Effekte (D-050) | 0.10.0 | 27 | [Konzept](../konzepte/fx-01-bewegung-und-effekte.md) |
| Zwerge bauen Wachtürme 10 % billiger (D-062) | 0.10.1 | 28 | [03](../game-design/03-races-and-avatar.md#wie-ein-volk-wirkt-phase-3) |
| Grafik 04: gemalte Kampagnenkarte | 0.10.2 | 29 | [Konzept](../konzepte/grafik-02-phase-2.md) |
| Fähigkeitstest unabhängig vom Läufer | 0.10.3 | 30 | – |
| R-5: Avatar einmal am Anfang (D-063) | 0.11.0 | 31 | [Konzept](../konzepte/r-5-avatar.md) |
| Grafik 05: Kampfplatz als Lichtung, Zwergenfeste, Porträts | 0.11.1 | 32 | [Konzept](../konzepte/grafik-05-kampfplatz.md) |
| R-6: Avatarrang, Talente, Avatar-Menü (D-064, D-065) | 0.12.0 | 33 | [Konzept](../konzepte/r-6-avatarrang.md) |
| FX 02: Plünderer mit Gliedmaßen aus 3D (D-051, D-052) | 0.13.0 | 34 | [Konzept](../konzepte/fx-02-figuren-in-3d.md) |
| P2-5: Mission 2 mit Zwergenbank und Bonus für frühes Rufen (D-026, D-083) | 0.16.0 | 36 | [Konzept](../konzepte/p2-5-mission-2-zwergenbank.md) |
| Grafik 06: gemalte Kampfplätze M2 (Zwergenstollen), M3 (Pilzhain), M4 (Ruinenrand), Wege M3/M4 als Vorschlag (D-081) | 0.16.1 | 37 | [Konzept](../konzepte/grafik-06-kampfplaetze-m2-m4.md) |
| P2-6: Mission 3 mit Aufwerten auf Stufe 2 und Zielwahl (D-024, D-084) | 0.18.0 | 38 | [Konzept](../konzepte/p2-6-mission-3-aufwerten.md) |
| P2-10: Mission 4 mit gepanzerter Panzerbestie (K7, D-087) | 0.20.0 | – | [Konzept](../konzepte/p2-10-mission-4-ruestung.md) |
| P2-3: Ton und Musik, nur CC0 (D-082) | 0.15.0 | 35 | [Konzept](../konzepte/p2-3-ton-und-musik.md) |
| R-7a: Ausrüstung aus festen Belohnungen (D-066, D-069 bis D-071) | 0.19.0 | 39 | [Konzept](../konzepte/r-7-ausruestung.md) |
| R-7b: Schmiede mit Erz, Stufen I bis III (D-070, D-072) | 0.21.0 | 41 | [Konzept](../konzepte/r-7b-schmiede.md) |
| P2-6b: Balance-Labor, Grundstock (D-028, D-073) | 0.21.1 | 42 | [Konzept](../konzepte/p2-6b-balance-labor.md) |
| P2-2: Fortsetzen nach App-Neustart (D-022, D-074) | 0.22.0 | 43 | [Konzept](../konzepte/p2-2-fortsetzen.md) |
| P2-11: Blitz allein verliert Mission 2 und 3 (D-071, D-075) | 0.23.0 | – | [Konzept](../konzepte/p2-11-blitz-monokultur.md) |

## Gilt für jedes Paket

- Konzept vor der Umsetzung (D-017), Tests auf jeder Ebene, Ende-zu-Ende-Test für
  jeden neuen Ablauf mit Bedienung (D-029), Eintrag im CHANGELOG.
- **Doku im selben PR (D-067):** Architektur, Datenmodelle, Teststrategie,
  Design- und Art-Dokumente, diese Roadmap und [status.md](status.md). Die CI prüft
  den Stand mit.
- **Entscheidungskarten** sofort an den Coordinator melden und hier unter
  „Wartet auf Steffen“ eintragen; beantwortet: ins Entscheidungsprotokoll.
- **Balance-Bericht** für jede Wertänderung, sobald das Balance-Labor steht (D-028).

## Meilensteine Phase 1

| | Meilenstein | Pakete | Stand |
|---|---|---|---|
| M1.1 | Regeln von Mission 1 vollständig und getestet | WP-02 … WP-10 | ✓ 25.10.2026 |
| M1.2 | Die App zeigt die laufende Simulation | WP-01, WP-11 | ✓ 25.10.2026 (0.4.0) |
| M1.3 | **Ein Mensch spielt Mission 1 auf dem iPhone** | WP-12, WP-13, WP-14 | ✓ 25.10.2026 (0.5.0, Bau 19) |
| M1.4 | Spieltest mit drei Personen, Leistung gemessen, E2E deckt Mission 1 ab | UI 01, WP-15, Messung WP-01, E2E | E2E ✓ (0.5.1), Oberfläche ✓ (0.6.0); **Spieltest und Messung offen (S3, S4)** |

## Vorgezogen: Spielrahmen (D-060)

Steffen, 25.10.2026: Hauptmenü, Weltkarte und Völker sollen jetzt kommen, nicht
erst in Phase 3. Damit ist die MVP-Grenze für diese Stücke aufgehoben (D-060). Der
Spieltest WP-15 wartet nicht darauf.

| # | Paket | Abh. | Stand |
|---|---|---|---|
| R-1 | Hauptmenü, Einstellungen, Speicherstand (D-022) | UI 01 | ✓ 0.7.0 |
| R-2 | Kampagnenkarte Region 1 „Flüsterwald“, M1 spielbar, Sterne | R-1 | ✓ 0.7.0, gemalt 0.10.2 |
| R-3 | Festungsfähigkeit Steinregen (P2-7 vorgezogen, D-033) | UI 01 | ✓ 0.8.0 |
| R-4 | Völker Zwerge (Bollwerk, Wachtürme billiger D-062) und Elfen (Mondmal) | R-1, R-3 | ✓ 0.9.0, 0.10.1 |
| R-5 | Avatar einmal am Anfang: Volk, Porträt, Name (D-063) | R-4 | ✓ 0.11.0, Porträts 0.11.1 |
| R-6 | Avatarrang mit Talentwahl, eigenes Avatar-Menü (D-064, D-065) | R-5 | ✓ 0.12.0 |
| R-7a | Ausrüstung mit kleinen Boni im Avatar-Menü, feste Belohnungen (D-066, D-069 bis D-071) | R-6 | ✓ 0.19.0 |
| R-7b | **Schmiede** mit Spielwährung im Avatar-Menü (D-070) | R-7a | ✓ 0.21.0 mit den Empfehlungen (D-072), S9 offen |

## Parallel: Grafik und Bewegung

| Paket | Stand |
|---|---|
| Grafik 01 bis 06 (Figuren, Symbole, Titelbild, Kampagnenkarte, Kampfplätze M1 bis M4, Festung, Porträts) | ✓ 0.5.2 bis 0.16.1 |
| FX 01 Bewegung und Effekte an Ereignissen (D-050) | ✓ 0.10.0 |
| FX 02 Gegner mit Gliedmaßen aus 3D (D-051): Plünderer | ✓ 0.13.0 |
| FX 02 Flitzer, Panzerbestie | nach dem Plünderer, Freigabe am Bild |

## Entwurf Phase 2 [VORSCHLAG]

Reihenfolge nach Abhängigkeit und Risiko: zuerst, was das Spielgefühl am
stärksten hebt und was andere Pakete brauchen; Inhalte zuletzt. Abnahme der
Phase wie oben: Eine Mission wirkt wie das fertige Spiel.

| # | Paket | Abh. | Konzept | Entscheidung |
|---|---|---|---|---|
| P2-1 | Grafik einbauen: Atlas ✓ 0.5.2, Effekte ✓ 0.10.0 (FX 01), Laufzyklen aus 3D in Arbeit (FX 02) | M1.3, Atlas aus dem Grafik-Thread | Art-Direction | D-016 |
| P2-2 | ✓ 0.22.0 Fortsetzen einer laufenden Mission nach App-Ende ([Konzept](../konzepte/p2-2-fortsetzen.md)) | R-1 | K6 | D-022, D-074 |
| P2-3 | Ton und Haptik: Klänge, Musik, Regler ✓ 0.15.0 (nur CC0, D-082) | P2-1 (Rückmeldeliste) | K9 | ✓ 0.15.0 |
| P2-4 | Menüs, Pause, Einstellungen, Ergebnis im Stil: ✓ 0.6.0 und 0.7.0 | M1.3, Oberflächen-Thread | [07](../game-design/07-ui-ux.md) | D-031, D-032 |
| P2-5 | Zwergenbank und Bonus für frühes Rufen: ✓ 0.16.0 (Mission 2) | – (D-080: startet vor dem Spieltest, Werte nach M1.4 nachziehen) | K3 | D-026, D-083 |
| P2-6 | Aufwertungen mit Gabelung, Zielwahl: Stufe 2 und Zielwahl ✓ 0.18.0 (Mission 3), Spezialisierungen mit M5/M6 | P2-5 (gleiche Wirtschaftsrechnung) | K1 | D-024, D-084 |
| P2-6b | **Balance-Labor, Grundstock:** Lauf-Werkzeug, Zufalls- und Menschenbot, Zielwerte, PR-Stufe in der CI | P2-5, P2-6 | K11 | D-028, D-073; ✓ 0.21.1 |
| P2-11 | **Blitz allein verliert Mission 2 und 3** beim ersten Spielen: Flitzer schneller, M2 etwas mehr Leben (Befund des Labors) | P2-6b | S11 | D-071, D-075; ✓ 0.23.0 |
| P2-7 | ~~Festungsfähigkeit Steinregen~~ vorgezogen als R-3 | – | K2a | D-025, D-060 |
| P2-8 | Synergie sichtbar („Sporenfunke", E2), Einstieg ohne Erklärtext | P2-1, P2-3 | K8 | – |
| P2-9 | Mission 1 neu abstimmen, Spieltest 2 | alle | – | Abnahme Phase 2 |

Panzerbestie und Rüstung (K7) kommen mit Phase 3, die Panzerbestie liegt in der
Missionsdatei schon bereit.

## Ausblick Phase 3 [VORSCHLAG]

Region 1 „Flüsterwald" nach [05](../game-design/05-campaign-and-progression.md#region-1-und-die-vollversion) (D-027):
die Missionen M2 bis M7, N1 und N2 auf der schon stehenden Karte (R-2), Boss,
Eisern-Modus, Fortschritt (K5); die Völker sind seit D-063 von Anfang an wählbar,
Kartenwerkzeug. Jede Mission läuft vor der Auslieferung durch den großen
Balance-Lauf (K11). Richtung entschieden (D-025, D-027). Name und Marke werden hier
entschieden (K10).

## Ausblick Phase 4 [VORSCHLAG]

| | Meilenstein | Konzept |
|---|---|---|
| M4.1 | **Balance-Labor voll ausgebaut:** Sucher-Bot, nächtlicher Lauf mit allen Missionen, Völkern und Startwerten, Stresstests, Bericht mit Vergleich zu `main`, Abgleich mit Spieltests | [K11](../konzepte/phase-2-3.md#k11--balance-labor-automatisierte-balance--und-stresstests), D-028 |
| M4.2 | Leistung auf dem ältesten Zielgerät, absturzfrei | E4, WP-01 |
| M4.3 | Externe Spieltests, Werte und Spieltest stimmen überein | Abnahme Phase 4 |

## Wer woran arbeitet

| Thread | Aufgabe | Liefert an |
|---|---|---|
| Oddlings-Designstand und MVP-Plan (Haupt-Thread) | Kern, App, E2E, Pakete R-x und P2-x | alle: Ereignisse, Testschalter, Bauten |
| Plünderer-3D-Modell mit Token erzeugen | FX 02: Modelle, Bildfolgen, Einbau | Haupt-Thread: Atlas mit Bildfolgen nach [Asset-Vertrag](../art/asset-vertrag.md) |
| Architektur, Doku und Roadmap nachziehen | Doku-Stand, diese Roadmap, Regel D-067 | alle |

Grafik-, Oberflächen- und Effekt-Threads sind abgeschlossen; neue Grafik entsteht
mit dem Skill `spielgrafik` im Thread des jeweiligen Pakets, ein eigener Thread nur
bei großen Arbeiten (z. B. Ton und Musik, P2-3).

## Kandidaten aus der Marktanalyse [VORSCHLAG]

Aus [market-analysis.md](../game-design/market-analysis.md), Abschnitt 7. Nichts
davon ist freigegeben; jeder Punkt wird beim Schneiden seiner Phase mit Steffen
entschieden. Die Begründungen stehen dort, hier nur die Einordnung.

| Phase | Empfehlung | Stand |
|---|---|---|
| 1 (Darstellung WP-11 ff.) | E1 Rückmeldeliste je Ereignis, E3 Zustände als Symbol, Lebensbalken nur bei Schaden | im MVP-Umfang, als Abnahme in WP-11/WP-13 übernommen |
| 1 (WP-01) | E4 Leistungsgrenze: späteste Welle bei 2× auf dem ältesten Zielgerät | in die Messung aufgenommen |
| 2 | E2 Synergie sichtbar („Sporenfunke", nur Darstellung) | Kandidat, Phase 2 „spürbare Synergie" |
| 2 | E6 Aufwertungen mit genau einer Gabelung je Turm | entschieden D-024; D-008 bleibt für den MVP |
| 2 | E7 Eine aktive Festungsfähigkeit mit Abklingzeit, kein Held | entschieden D-025 |
| 2 | E5 Zielwahl je Turm, E8 Goldbonus für frühes Rufen (D-009), E11 Bestiarium | Kandidaten |
| 3 | E9 Sterne plus ein Einschränkungsmodus je Mission | entschieden D-027 |
| 3 | E10 Tägliche Herausforderung mit festem Startwert, offline | Scope-Verbot: nur mit Freigabe |
| 4–5 | E12 Anspielen + Vollversion, E13 keine Helden/Türme gegen Geld, E14 Apple Arcade als zweiter Kanal, E15 kein PvP/keine Zufallskisten | E12 als bevorzugte Richtung entschieden (D-015); Phase 3 schneidet die Kampagne in Regionen passend dazu |
