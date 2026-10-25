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

Erst nach Phase 1 wird Phase 2 in Arbeitspakete zerlegt. Was Phase 1 lehrt,
verändert Phase 2 sicher.

## Kandidaten aus der Marktanalyse [VORSCHLAG]

Aus [market-analysis.md](../game-design/market-analysis.md), Abschnitt 7. Nichts
davon ist freigegeben; jeder Punkt wird beim Schneiden seiner Phase mit Steffen
entschieden. Die Begründungen stehen dort, hier nur die Einordnung.

| Phase | Empfehlung | Stand |
|---|---|---|
| 1 (Darstellung WP-11 ff.) | E1 Rückmeldeliste je Ereignis, E3 Zustände als Symbol, Lebensbalken nur bei Schaden | im MVP-Umfang, als Abnahme in WP-11/WP-13 übernommen |
| 1 (WP-01) | E4 Leistungsgrenze: späteste Welle bei 2× auf dem ältesten Zielgerät | in die Messung aufgenommen |
| 2 | E2 Synergie sichtbar („Sporenfunke", nur Darstellung) | Kandidat, Phase 2 „spürbare Synergie" |
| 2 | E6 Aufwertungen mit genau einer Gabelung je Turm | Kandidat; D-008 (keine Upgrades im MVP) bleibt |
| 2 | E7 Eine aktive Festungsfähigkeit mit Abklingzeit, kein Held | Kandidat, braucht Freigabe (neues Feature) |
| 2 | E5 Zielwahl je Turm, E8 Goldbonus für frühes Rufen (D-009), E11 Bestiarium | Kandidaten |
| 3 | E9 Sterne plus ein Einschränkungsmodus je Mission | Kandidat |
| 3 | E10 Tägliche Herausforderung mit festem Startwert, offline | Scope-Verbot: nur mit Freigabe |
| 4–5 | E12 Anspielen + Vollversion, E13 keine Helden/Türme gegen Geld, E14 Apple Arcade als zweiter Kanal, E15 kein PvP/keine Zufallskisten | E12 als bevorzugte Richtung entschieden (D-015); Phase 3 schneidet die Kampagne in Regionen passend dazu |
