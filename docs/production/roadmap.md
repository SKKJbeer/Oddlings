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

## Gilt für jedes Paket ab jetzt

- **Ende-zu-Ende-Test** für jeden neuen Ablauf mit Bedienung, in der CI grün vor
  dem Zusammenführen (D-029, [Teststrategie](../technical/testing-strategy.md#ende-zu-ende-tests-d-029)).
- **Balance-Bericht** für jede Wertänderung, sobald das Balance-Labor steht (D-028).
- Konzept vor der Umsetzung (D-017), Tests, Eintrag im CHANGELOG.

## Meilensteine Phase 1

| | Meilenstein | Pakete | Stand |
|---|---|---|---|
| M1.1 | Regeln von Mission 1 vollständig und getestet | WP-02 … WP-10 | ✓ 25.10.2026 |
| M1.2 | Die App zeigt die laufende Simulation | WP-01, WP-11 | ✓ 25.10.2026 (0.4.0) |
| M1.3 | **Ein Mensch spielt Mission 1 auf dem iPhone** | WP-12, WP-13, WP-14 | ✓ 25.10.2026 (0.5.0, ein PR nach D-018), Bau 19 VALID |
| M1.4 | Spieltest mit drei Personen, Leistung auf dem Gerät gemessen; Ende-zu-Ende-Tests decken Mission 1 vollständig ab (Bauen, Verkaufen, Pause, Tempo, Sieg, Niederlage, Neustart) | Neue Oberfläche (P2-4 für Mission 1 vorgezogen), WP-15, Messung WP-01, E2E-Grundlage | E2E ✓ (0.5.1); erste Grafik im Spiel (0.5.2, Bau 21 VALID); **neue Oberfläche läuft, danach Spieltest** |

Kritischer Pfad: neue Oberfläche für Mission 1 (Kreismenü D-031, Schriften D-032) →
Bau in TestFlight → WP-15 (Spieltest mit drei Personen) → Phase 2 schneiden. Steffen,
25.10.2026: die Oberfläche kommt vor dem Spieltest. Alles andere läuft daneben und
darf diesen Pfad nicht aufhalten. Steffens Vorgabe
(25.10.2026): erst spielbar in TestFlight, dann Grafik einbauen.

## Vorgezogen: Spielrahmen (D-060)

Steffen, 25.10.2026: Hauptmenü, Weltkarte und Völker wie im Konzept sollen jetzt
kommen, nicht erst in Phase 3. Damit ist die MVP-Grenze für diese drei Stücke
aufgehoben (D-060). Der Rest von Phase 2 und 3 bleibt, wie er ist.

| # | Paket | Abh. | Code | Oberfläche | Grafik | Animation |
|---|---|---|---|---|---|---|
| R-1 | **Hauptmenü, Einstellungen, Speicherstand** | neue Oberfläche für Mission 1 | Schirmfolge, Speicherstand nach D-022 | [Hauptmenü](../game-design/07-ui-ux.md#hauptmenü) im Stil | Menühintergrund, Arbeitstitel-Schriftzug | Übergänge zwischen Schirmen |
| R-2 | **Kampagnenkarte Region 1** „Flüsterwald“ nach [05](../game-design/05-campaign-and-progression.md#region-1-und-die-vollversion): Knotenkarte M1 bis M7, N1, N2; M1 spielbar, die übrigen sichtbar und gesperrt; Sterne aus M1 | R-1 (Speicherstand) | Kartendaten, Fortschritt, Sterne | [Kampagnenkarte](../game-design/07-ui-ux.md#kampagnenkarte-phase-3-richtung) | gemalte Karte der Region | Weg zum nächsten Knoten, Freischalten |
| R-3 | **Festungsfähigkeit Steinregen** (P2-7 vorgezogen) | neue Oberfläche (Knopf, D-033) | Befehl `useAbility`, Abklingzeit | [Fähigkeitsknopf](../game-design/07-ui-ux.md#festungsfähigkeit-steinregen) | Symbol | Steinregen-Effekt |
| R-4 | **Völkerwahl** Zwerge und Elfen nach [03](../game-design/03-races-and-avatar.md#wie-ein-volk-wirkt-phase-3): wählbar vor jeder Mission, Volk bestimmt die Fähigkeit (Bollwerk, Mondmal) und einen kleinen Zug | R-1, R-3 | Volk im Speicherstand und in der Missionsdatei, zwei Fähigkeiten | Wahl im Avatar oder vor der Mission | Wappen, Porträts | Effekte beider Fähigkeiten |

**[VORSCHLAG]** Solange nur M1 spielbar ist, sind beide Völker von Anfang an
wählbar. Die Freischaltung am Ende von Region 1 (D-027) greift, sobald M7 steht.
Der Zug der Zwerge an der Bank wirkt erst mit P2-5; bis dahin zeigt die Wahl ihn
als „kommt mit der Zwergenbank“.

**Reihenfolge.** R-1 und R-3 können parallel laufen, R-2 braucht R-1, R-4 braucht
beide. Der Spieltest WP-15 wartet nicht darauf: Er prüft Mission 1 mit der neuen
Oberfläche, wie entschieden. Jedes Paket bringt seine Ende-zu-Ende-Abläufe mit (D-029).

## Entwurf Phase 2 [VORSCHLAG]

Reihenfolge nach Abhängigkeit und Risiko: zuerst, was das Spielgefühl am
stärksten hebt und was andere Pakete brauchen; Inhalte zuletzt. Abnahme der
Phase wie oben: Eine Mission wirkt wie das fertige Spiel.

| # | Paket | Abh. | Konzept | Entscheidung |
|---|---|---|---|---|
| P2-1 | Grafik einbauen: Atlas (Standbilder ✓ in 0.5.2), Laufzyklen, Treffereffekte nach Rückmeldeliste (E1, E3) | M1.3, Atlas aus dem Grafik-Thread | Art-Direction | D-016 |
| P2-2 | Fortsetzen einer laufenden Mission nach App-Ende (Speicherstand selbst kommt mit R-1) | R-1 | K6 | D-022 |
| P2-3 | Ton und Haptik | P2-1 (Rückmeldeliste) | K9 | Weg offen, neuer Thread |
| P2-4 | Menüs, Pause, Einstellungen, Ergebnis im Stil (Teil für Mission 1 vorgezogen vor WP-15) | M1.3, Oberflächen-Thread | [07](../game-design/07-ui-ux.md) | D-031, D-032 |
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
Eisern-Modus, Freischaltung der Völker (R-4), Fortschritt (K5),
Kartenwerkzeug. Jede Mission läuft vor der Auslieferung durch den großen
Balance-Lauf (K11). Richtung entschieden (D-025, D-027). Name und Marke werden hier
entschieden (K10).

## Ausblick Phase 4 [VORSCHLAG]

| | Meilenstein | Konzept |
|---|---|---|
| M4.1 | **Balance-Labor voll ausgebaut:** Sucher-Bot, nächtlicher Lauf mit allen Missionen, Völkern und Startwerten, Stresstests, Bericht mit Vergleich zu `main`, Abgleich mit Spieltests | [K11](../konzepte/phase-2-3.md#k11--balance-labor-automatisierte-balance--und-stresstests), D-028 |
| M4.2 | Leistung auf dem ältesten Zielgerät, absturzfrei | E4, WP-01 |
| M4.3 | Externe Spieltests, Werte und Spieltest stimmen überein | Abnahme Phase 4 |

## Abhängigkeiten zwischen den Threads

| Liefert | an | Was | Wann gebraucht |
|---|---|---|---|
| Grafik | Code | Atlas nach Asset-Vertrag (`docs/art/asset-vertrag.md`) | P2-1, darf M1.3 nicht aufhalten |
| Oberfläche | Code | HUD-Layout, Baumenü, Turmmenü, Ergebnis | WP-12/WP-13 nutzen Platzhalter, Stil folgt in P2-4 |
| Grafik ↔ Oberfläche | beide | Farben, Symbole, Schrift (D-016) | vor P2-4 |
| Projektplanung | Grafik | Konzepte für Zwergenbank, Völker, Spezialisierungen, Boss (K1–K3, K7) | entschieden (D-024 bis D-026), Assets ab jetzt möglich |
| Projektplanung | Oberfläche | Turmmenü mit Aufwerten und Zielwahl (K1), Fähigkeitsknopf (K2a), Kampagnenkarte (K4) | Entwürfe ab jetzt, Umsetzung Phase 2/3 |
| Code | alle | Ereignisliste der Simulation | steht (WP-11) |
| Oberfläche | Code | Hauptmenü, Kampagnenkarte, Völkerwahl als Entwurf | vor R-1, R-2, R-4 |
| Grafik | Code | Menühintergrund, Karte Flüsterwald, Wappen und Porträts | R-1, R-2, R-4; Platzhalter erlaubt, damit Code nicht wartet |
| Animation | Code | Effekt-Uhr (D-050), Steinregen, Mondmal, Bollwerk, Kartenübergänge | R-3, R-4, R-2 |
| Code | Animation | Ereignisse für Fähigkeiten und Kartenfortschritt | mit R-2, R-3 |

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
