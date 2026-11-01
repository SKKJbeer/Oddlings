# Register offener Fragen

Eine Zeile je Frage: woher sie kommt, wann sie gebraucht wird, wo das Konzept
steht und wer entscheidet. Gepflegt von der Projektplanung; wird eine Frage
entschieden, steht die Entscheidung im [Entscheidungsprotokoll](../decisions/decision-log.md)
und hier nur noch ihr Status.

Stand: 27.10.2026. Was davon gerade auf Steffen wartet, steht zusätzlich oben in der
[Roadmap](roadmap.md#wartet-auf-steffen).

**Wer:** S = Steffen (Design, Feature, Architektur, Geld) · C = Claude
entscheidet selbst und hält es fest (klein, technisch, umkehrbar).

## Aus der Übergabe, Abschnitt 18

| # | Frage | Gebraucht in | Konzept | Wer | Stand |
|---|---|---|---|---|---|
| 1 | Name und Marke | Phase 3 | [K10](../konzepte/phase-2-3.md#k10--was-bewusst-später-entschieden-wird) | S | später, Ablauf vorgeschlagen |
| 2 | Stil und Asset-Weg | Phase 2 | Art-Direction-Thread | S | **entschieden** D-016 (Stylized 3D) |
| 3 | Zielgeräte, iOS-Version | Phase 1 | [architecture.md](../technical/architecture.md) §7 | S | **entschieden** D-006 |
| 4 | Spielregeln, Balancewerte | Phase 1 | [02](../game-design/02-combat-and-towers.md), [04](../game-design/04-economy-and-balance.md) | S | Mission 1 vorgeschlagen (D-007), bestätigt der Spieltest WP-15 |
| 5 | Wellenzahl, Missionsdauer | Phase 1 | [04](../game-design/04-economy-and-balance.md) | S | wie 4 |
| 6 | Startgold, Belohnung, Festungsleben | Phase 1 | [04](../game-design/04-economy-and-balance.md) | S | wie 4 |
| 7 | Turmwerte und **Aufwertungen** | Phase 2 | [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2) | S | **entschieden** D-024 |
| 8 | Zwergenbank: Mechanik, Werte, für wen | Phase 2 | [04](../game-design/04-economy-and-balance.md#zwergenbank-phase-2) | S | **entschieden** D-026 (klärt D-010) |
| 9 | Völker und Fähigkeiten | Phase 2 (Fähigkeit), 3 (Völker) | [03](../game-design/03-races-and-avatar.md#festungsfähigkeit-und-wie-ein-volk-wirkt) | S | **entschieden** D-025 |
| 10 | Kampagne und Fortschritt | Phase 3 | [05](../game-design/05-campaign-and-progression.md#region-1-und-die-vollversion) | S | **entschieden** D-027 |
| 11 | Speicherstand, Cloud | Phase 2 | [K6](../konzepte/phase-2-3.md#k6--speicherstand) | C (lokal), S (Cloud) | lokal festgelegt D-022, Cloud Phase 4 |
| 12 | Multiplayer-Architektur | Phase 5 | [architecture.md](../technical/architecture.md) §4 | S | geparkt, Vorleistung steht |
| 13 | Release, Preis, Monetarisierung | Phase 5 | [06](../game-design/06-monetization.md) | S | Richtung entschieden D-015 |

## Aus dem Entscheidungsprotokoll und der Marktanalyse

| Frage | Gebraucht in | Konzept | Wer | Stand |
|---|---|---|---|---|
| D-003 Architektur des Simulationspakets | Phase 1 | [architecture.md](../technical/architecture.md) | C | gilt, umgesetzt WP-02 bis WP-11 (D-020) |
| D-007 Werte Mission 1 | Phase 1 | [04](../game-design/04-economy-and-balance.md) | S | nach WP-15 |
| D-008 Verkaufen ja, Upgrades nicht im MVP | Phase 1 | [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2) | S | gilt für den MVP; Phase 2 entschieden D-024 |
| D-009 Wellentakt, Bonus für frühes Rufen (E8) | Phase 2 | [04](../game-design/04-economy-and-balance.md#bonus-für-frühes-rufen-d-009-e8) | C | Takt gilt (D-020), Bonus rechnet mit der Bank |
| D-011 Dokumentstruktur | – | – | C | gilt (D-020) |
| Festungsfähigkeit (E7) | Phase 2 | [03](../game-design/03-races-and-avatar.md#eine-aktive-festungsfähigkeit-phase-2) | S | entschieden D-025 |
| Zielwahl je Turm (E5) | Phase 2 | [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2) | S | entschieden D-024 (ab Stufe 2) |
| Sterne und Eisern-Modus (E9) | Phase 3 | [05](../game-design/05-campaign-and-progression.md#sterne-und-herausforderungen-e9) | S | entschieden D-027 |
| Tägliche Herausforderung (E10) | nach Release | [05](../game-design/05-campaign-and-progression.md#fortschritt) | S | Scope-Verbot, nicht vorgelegt |
| Bestiarium (E11) | Phase 2–3 | [05](../game-design/05-campaign-and-progression.md#fortschritt) | C | mit D-027 entschieden |
| Rüstung, Immunität, Bosse, Schattenflieger | Phase 3 | [K7](../konzepte/phase-2-3.md#k7--gegner-bosse-rüstung) | S | Vorschlag, wird mit Phase 3 vorgelegt |
| Einstieg ohne Erklärtext | Phase 2 | [K8](../konzepte/phase-2-3.md#k8--einstieg-ohne-erklärtext) | C | Vorschlag, Abstimmung mit Oberflächen-Thread |
| Ton und Haptik: Weg und Herkunft | Phase 2 | [K9](../konzepte/phase-2-3.md#k9--ton-und-haptik) | S | Vorschlag, neuer Thread zu Beginn Phase 2 |
| Automatisierte Balance- und Stresstests | Phase 2 (Grundstock), Phase 4 (voll) | [K11](../konzepte/phase-2-3.md#k11--balance-labor-automatisierte-balance--und-stresstests) | S (Richtung), C (Umsetzung) | Richtung entschieden D-028 |
| Ende-zu-Ende-Tests über die ganze App | ab WP-15 | [Teststrategie](../technical/testing-strategy.md#ende-zu-ende-tests-d-029) | S | entschieden D-029 |

## Seit dem Spielrahmen (26. und 27.10.2026)

| Frage | Gebraucht in | Konzept | Wer | Stand |
|---|---|---|---|---|
| Volk wechseln, bevor es eine Spielwährung gibt | R-5 | [R-5](../konzepte/r-5-avatar.md) | S | **Karte offen** seit 26.10.; bis dahin gilt „gar nicht“ (D-063) |
| Darf der 3D-Plünderer ins Spiel (Aussehen) | FX 02 | [FX 02](../konzepte/fx-02-figuren-in-3d.md) | S | **Karte offen** seit 26.10.; blockiert FX 02 |
| Flitzer und Panzerbestie ebenfalls in 3D | FX 02 | [FX 02](../konzepte/fx-02-figuren-in-3d.md) | S | nach dem Plünderer, Urteil am Bild |
| Ausrüstung: woher die Gegenstände kommen | R-7 | [03](../game-design/03-races-and-avatar.md#avatar-entschieden) | S | Richtung entschieden D-066, Karte folgt mit dem Konzept |
| Ausrüstung: Obergrenze der Boni, Balancetests mit stärkster Ausrüstung | R-7 | [05](../game-design/05-campaign-and-progression.md#fortschritt) | S (Grenze), C (Tests) | Karte folgt mit dem Konzept |
| Reservierte HUD-Ecken (D-030) | nach WP-15 | [07](../game-design/07-ui-ux.md#2-raster-und-bildschirm) | S | zurückgestellt bis zum Spieltest |
| Mission hält im Hintergrund an (D-034) | Phase 1 | [07](../game-design/07-ui-ux.md#pause) | S | vorgeschlagen, umgesetzt seit 0.5.1 |
| Doku bei jeder Auslieferung, Karten nie unbemerkt | immer | [D-067](../decisions/decision-log.md) | S | **entschieden** D-067 |
