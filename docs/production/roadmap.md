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

**Stand: 27.10.2026** · neueste Version 0.12.0 (Bau läuft), neuester VALID-Bau 32 (0.11.1)

## Phasen

| Phase | Ziel | Abnahme | Stand |
|---|---|---|---|
| **0 – Design und Planung** | Konsistenter Designstand, MVP abgegrenzt, Backlog | Steffen gibt Dokumente und offene Entscheidungen frei | ✓ 25.10.2026 |
| **1 – Spielbarer Kampfprototyp** | Eine Karte, ein Weg, drei Türme, Gegner, Gold, Wellen, Sieg/Niederlage, Neustart, Tests | Mission 1 auf dem iPhone spielbar, Regeltests grün, drei Personen haben gespielt | Technik ✓, **Spieltest WP-15 offen** |
| **Spielrahmen (vorgezogen, D-060)** | Hauptmenü, Kampagnenkarte, Festungsfähigkeit, Völker, Avatar | Pakete R-1 bis R-6 in TestFlight | ✓ bis R-6 (0.12.0), R-7 Ausrüstung folgt |
| **2 – Vertical Slice** | Zwergenbank, spürbare Synergie, Ton, Animation, Grafik, Fortsetzen | Eine Mission wirkt wie das fertige Spiel; Spieler finden die Synergie ohne Erklärung | Grafik und Effekte laufen, Rest wartet auf den Schnitt nach WP-15 |
| **3 – Kleine Kampagne** | Region 1 mit sieben Haupt- und zwei Nebenmissionen, Boss | Spieler wollen nach Mission 1 weiterspielen (gemessen) | Karte steht, Missionen 2 bis 7 fehlen |
| **4 – Qualität und Balancing** | Echte Geräte, Leistung, externe Spieltests, Balance-Labor | Absturzfrei, 60 Bilder/s auf dem ältesten Zielgerät | – |
| **5 – Produktentscheidung** | Weiter investieren? Monetarisierung? Koop? | Entscheidung mit Daten aus Phase 4 | – |

## Wartet auf Steffen

| # | Was | Wo | Blockiert | Empfehlung |
|---|---|---|---|---|
| S1 | **Darf der neue 3D-Plünderer ins Spiel?** (Entscheidungskarte seit 26.10.) | Thread „Plünderer-3D-Modell mit Token erzeugen“ | FX 02 komplett | Ja, einbauen |
| S2 | Volk wechseln, bevor es eine Spielwährung gibt (Entscheidungskarte seit 26.10.) | Thread „Oddlings-Designstand und MVP-Plan aufsetzen“ | nichts, die Empfehlung gilt bis zur Antwort | Gar nicht |
| S3 | **Spieltest mit drei Personen** auf dem neuesten Bau, [Beobachtungsbogen](playtests/beobachtungsbogen.md) | WP-15 | Abschluss Phase 1, Schnitt Phase 2, D-030, Werte D-007 | so bald wie möglich |
| S4 | Leistung des Spikes auf dem iPhone messen | WP-01 | nichts Akutes; D-002 gilt bis dahin | ohne Eile |
| S5 | Kommt mit R-7: Herkunft der Ausrüstung und Obergrenze der Boni (Karten folgen) | Haupt-Thread | R-7 Umsetzung | – |

## Als Nächstes

Reihenfolge **[VORSCHLAG]**; was davor steht, wird zuerst gebaut. Steffen kann
umsortieren.

| # | Paket | Thread | Abh. | Stand |
|---|---|---|---|---|
| 1 | 0.12.0 Bau in TestFlight, Baunummer eintragen | Haupt-Thread | – | läuft |
| 2 | **FX 02 Plünderer mit Gliedmaßen** einbauen ([Konzept](../konzepte/fx-02-figuren-in-3d.md)) | Plünderer-3D-Modell | S1 | fertig bis auf die Freigabe |
| 3 | **R-7 Ausrüstung** im Avatar-Menü (D-066): Konzept, Karten, Umsetzung | Haupt-Thread | R-6, S5 | Konzept als Nächstes |
| 4 | **WP-15 Spieltest**, danach Phase 2 schneiden | Steffen | S3 | wartet |
| 5 | P2-5 **Mission 2 mit Zwergenbank** (Knoten M2 der Karte); erster Talentrang wird erreichbar | – | WP-15 (Balance) | Konzept K3 steht |
| 6 | P2-3 **Ton und Musik** (K9) | neuer Thread | – | Weg offen |
| 7 | FX 02 Flitzer und Panzerbestie | Plünderer-3D-Modell | 2 und Steffens Urteil am Bild | – |
| 8 | P2-6 Mission 3 mit Aufwertungen, P2-6b Balance-Labor, P2-2 Fortsetzen, P2-8 Synergie sichtbar, P2-9 Abstimmung | – | 5 | Konzepte K1, K6, K8, K11 |

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
| R-6: Avatarrang, Talente, Avatar-Menü (D-064, D-065) | 0.12.0 | läuft | [Konzept](../konzepte/r-6-avatarrang.md) |

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
| R-7 | **Ausrüstung mit kleinen Boni** im Avatar-Menü (D-066) | R-6, S5 | Konzept als Nächstes |

## Parallel: Grafik und Bewegung

| Paket | Stand |
|---|---|
| Grafik 01 bis 05 (Figuren, Symbole, Titelbild, Kampagnenkarte, Kampfplatz, Festung, Porträts) | ✓ 0.5.2 bis 0.11.1 |
| FX 01 Bewegung und Effekte an Ereignissen (D-050) | ✓ 0.10.0 |
| FX 02 Gegner mit Gliedmaßen aus 3D (D-051): Plünderer | fertig, wartet auf S1 |
| FX 02 Flitzer, Panzerbestie | nach dem Plünderer, Freigabe am Bild |

## Entwurf Phase 2 [VORSCHLAG]

Reihenfolge nach Abhängigkeit und Risiko: zuerst, was das Spielgefühl am
stärksten hebt und was andere Pakete brauchen; Inhalte zuletzt. Abnahme der
Phase wie oben: Eine Mission wirkt wie das fertige Spiel.

| # | Paket | Abh. | Konzept | Entscheidung |
|---|---|---|---|---|
| P2-1 | Grafik einbauen: Atlas ✓ 0.5.2, Effekte ✓ 0.10.0 (FX 01), Laufzyklen aus 3D in Arbeit (FX 02) | M1.3, Atlas aus dem Grafik-Thread | Art-Direction | D-016 |
| P2-2 | Fortsetzen einer laufenden Mission nach App-Ende (Speicherstand selbst kommt mit R-1) | R-1 | K6 | D-022 |
| P2-3 | Ton und Haptik | P2-1 (Rückmeldeliste) | K9 | Weg offen, neuer Thread |
| P2-4 | Menüs, Pause, Einstellungen, Ergebnis im Stil: ✓ 0.6.0 und 0.7.0 | M1.3, Oberflächen-Thread | [07](../game-design/07-ui-ux.md) | D-031, D-032 |
| P2-5 | Zwergenbank und Bonus für frühes Rufen | M1.4 (Balance aus dem Spieltest) | K3 | D-026 |
| P2-6 | Aufwertungen mit Gabelung, Zielwahl | P2-5 (gleiche Wirtschaftsrechnung) | K1 | D-024 |
| P2-6b | **Balance-Labor, Grundstock:** Lauf-Werkzeug, Zufalls- und Menschenbot, Zielwerte, PR-Stufe in der CI | P2-5, P2-6 | K11 | D-028 |
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
