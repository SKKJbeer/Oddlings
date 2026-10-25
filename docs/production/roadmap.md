# Roadmap

Reihenfolge von Zielen, **keine Zeitplanung**. Eine Phase ist fertig, wenn ihre
Abnahme erfüllt ist, nicht wenn Code existiert.

| Phase | Ziel | Abnahme | Arbeitspakete |
|---|---|---|---|
| **0 – Design und Planung** | Konsistenter Designstand, MVP abgegrenzt, Backlog | Steffen gibt Dokumente und offene Entscheidungen B1–B4 frei | WP-00 |
| **1 – Spielbarer Kampfprototyp** | Eine Karte, ein Weg, drei Türme, zwei bis drei Gegner, Gold, Wellen, Sieg/Niederlage, Neustart, Tests | Mission 1 ist auf einem echten iPhone von Anfang bis Ende spielbar, ohne Absturz; Regeltests grün; mindestens drei Personen haben gespielt, Protokoll liegt vor | WP-01 … WP-15 |
| **2 – Vertical Slice** | Zwergenbank, spürbare Synergie, Ton, Animation, Grafikstil, Menüs, Fortsetzen nach App-Ende | Eine Mission wirkt wie das fertige Spiel; Spieltest bestätigt, dass Spieler die Synergie ohne Erklärung finden | wird nach Phase 1 geschnitten |
| **3 – Kleine Kampagne** | Kampagnenkarte, 6–8 Missionen, Gabelung, zwei Völker, erste Freischaltungen | Spieler wollen nach Mission 1 weiterspielen (gemessen, nicht vermutet) | – |
| **4 – Qualität und Balancing** | Echte Geräte, Leistung, Bedienung, externe Spieltests | Absturzfrei, 60 Bilder/s auf dem ältesten Zielgerät, Balancetests und Spieltests stimmen überein | – |
| **5 – Produktentscheidung** | Weiter investieren? Monetarisierung? Koop? | Entscheidung mit Daten aus Phase 4 | – |

Erst nach Phase 1 wird Phase 2 endgültig in Arbeitspakete zerlegt. Was Phase 1
lehrt, verändert Phase 2 sicher. Der Entwurf unten zeigt die Reihenfolge, damit
die Threads wissen, was nach ihnen kommt; er ist kein Auftrag.

Stand für Steffen in Kurzform: [status.md](status.md). Offene Fragen:
[offene-fragen.md](offene-fragen.md). Konzepte für Phase 2 und 3:
[konzepte/phase-2-3.md](../konzepte/phase-2-3.md).

## Meilensteine Phase 1

| | Meilenstein | Pakete | Stand |
|---|---|---|---|
| M1.1 | Regeln von Mission 1 vollständig und getestet | WP-02 … WP-10 | ✓ 25.10.2026 |
| M1.2 | Die App zeigt die laufende Simulation | WP-01, WP-11 | ✓ 25.10.2026 (0.4.0) |
| M1.3 | **Ein Mensch spielt Mission 1 auf dem iPhone** | WP-12, WP-13, WP-14 | ✓ 25.10.2026 (0.5.0, ein PR nach D-018); Bau in TestFlight wird nachgetragen |
| M1.4 | Spieltest mit drei Personen, Leistung auf dem Gerät gemessen | WP-15, Messung WP-01 | **als Nächstes** |

Kritischer Pfad: Bau 0.5.0 VALID in TestFlight → WP-15. Alles
andere läuft daneben und darf diesen Pfad nicht aufhalten. Steffens Vorgabe
(25.10.2026): erst spielbar in TestFlight, dann Grafik einbauen.

## Entwurf Phase 2 [VORSCHLAG]

Reihenfolge nach Abhängigkeit und Risiko: zuerst, was das Spielgefühl am
stärksten hebt und was andere Pakete brauchen; Inhalte zuletzt. Abnahme der
Phase wie oben: Eine Mission wirkt wie das fertige Spiel.

| # | Paket | Abh. | Konzept | Entscheidung |
|---|---|---|---|---|
| P2-1 | Grafik einbauen: Atlas, Laufzyklen, Treffereffekte nach Rückmeldeliste (E1, E3) | M1.3, Atlas aus dem Grafik-Thread | Art-Direction | D-016 |
| P2-2 | Fortsetzen nach App-Ende, Speicherstand | M1.3 | K6 | D-022 |
| P2-3 | Ton und Haptik | P2-1 (Rückmeldeliste) | K9 | Weg offen, neuer Thread |
| P2-4 | Menüs, Pause, Einstellungen, Ergebnis im Stil | M1.3, Oberflächen-Thread | UI-Konzept | – |
| P2-5 | Zwergenbank und Bonus für frühes Rufen | M1.4 (Balance aus dem Spieltest) | K3 | **E-3** |
| P2-6 | Aufwertungen mit Gabelung, Zielwahl | P2-5 (gleiche Wirtschaftsrechnung) | K1 | **E-1** |
| P2-7 | Festungsfähigkeit Steinregen | P2-4 (Knopf im HUD) | K2a | **E-2** |
| P2-8 | Synergie sichtbar („Sporenfunke", E2), Einstieg ohne Erklärtext | P2-1, P2-3 | K8 | – |
| P2-9 | Mission 1 neu abstimmen, Spieltest 2 | alle | – | Abnahme Phase 2 |

Panzerbestie und Rüstung (K7) kommen mit Phase 3, die Panzerbestie liegt in der
Missionsdatei schon bereit.

## Ausblick Phase 3 [VORSCHLAG]

Region 1 „Flüsterwald" nach [K4](../konzepte/phase-2-3.md#k4--kampagne-und-regionen):
Kampagnenkarte, sieben Haupt- und zwei Nebenmissionen mit Gabelung, Boss,
Sterne und Eisern-Modus, Völker Zwerge und Elfen (K2b), Fortschritt (K5),
Kartenwerkzeug. Hängt an **E-2** und **E-4**. Name und Marke werden hier
entschieden (K10).

## Abhängigkeiten zwischen den Threads

| Liefert | an | Was | Wann gebraucht |
|---|---|---|---|
| Grafik | Code | Atlas nach Asset-Vertrag (`docs/art/asset-vertrag.md`) | P2-1, darf M1.3 nicht aufhalten |
| Oberfläche | Code | HUD-Layout, Baumenü, Turmmenü, Ergebnis | WP-12/WP-13 nutzen Platzhalter, Stil folgt in P2-4 |
| Grafik ↔ Oberfläche | beide | Farben, Symbole, Schrift (D-016) | vor P2-4 |
| Projektplanung | Grafik | Konzepte für Zwergenbank, Völker, Spezialisierungen, Boss (K1–K3, K7) | Konzeptbilder ab jetzt, Assets erst nach E-1 bis E-3 |
| Projektplanung | Oberfläche | Turmmenü mit Aufwerten und Zielwahl (K1), Fähigkeitsknopf (K2a), Kampagnenkarte (K4) | Entwürfe ab jetzt, Umsetzung Phase 2/3 |
| Code | alle | Ereignisliste der Simulation | steht (WP-11) |

## Kandidaten aus der Marktanalyse [VORSCHLAG]

Aus [market-analysis.md](../game-design/market-analysis.md), Abschnitt 7. Nichts
davon ist freigegeben; jeder Punkt wird beim Schneiden seiner Phase mit Steffen
entschieden. Die Begründungen stehen dort, hier nur die Einordnung.

| Phase | Empfehlung | Stand |
|---|---|---|
| 1 (Darstellung WP-11 ff.) | E1 Rückmeldeliste je Ereignis, E3 Zustände als Symbol, Lebensbalken nur bei Schaden | im MVP-Umfang, als Abnahme in WP-11/WP-13 übernommen |
| 1 (WP-01) | E4 Leistungsgrenze: späteste Welle bei 2× auf dem ältesten Zielgerät | in die Messung aufgenommen |
| 2 | E2 Synergie sichtbar („Sporenfunke", nur Darstellung) | Kandidat, Phase 2 „spürbare Synergie" |
| 2 | E6 Aufwertungen mit genau einer Gabelung je Turm | ausgearbeitet in K1, liegt Steffen vor (E-1); D-008 bleibt für den MVP |
| 2 | E7 Eine aktive Festungsfähigkeit mit Abklingzeit, kein Held | ausgearbeitet in K2a, liegt Steffen vor (E-2) |
| 2 | E5 Zielwahl je Turm, E8 Goldbonus für frühes Rufen (D-009), E11 Bestiarium | Kandidaten |
| 3 | E9 Sterne plus ein Einschränkungsmodus je Mission | ausgearbeitet in K4, liegt Steffen vor (E-4) |
| 3 | E10 Tägliche Herausforderung mit festem Startwert, offline | Scope-Verbot: nur mit Freigabe |
| 4–5 | E12 Anspielen + Vollversion, E13 keine Helden/Türme gegen Geld, E14 Apple Arcade als zweiter Kanal, E15 kein PvP/keine Zufallskisten | E12 als bevorzugte Richtung entschieden (D-015); Phase 3 schneidet die Kampagne in Regionen passend dazu |
