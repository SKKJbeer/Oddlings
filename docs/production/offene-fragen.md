# Register offener Fragen

Eine Zeile je Frage: woher sie kommt, wann sie gebraucht wird, wo das Konzept
steht und wer entscheidet. Gepflegt von der Projektplanung; wird eine Frage
entschieden, steht die Entscheidung im [Entscheidungsprotokoll](../decisions/decision-log.md)
und hier nur noch ihr Status.

Stand: 25.10.2026

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
| 7 | Turmwerte und **Aufwertungen** | Phase 2 | [K1](../konzepte/phase-2-3.md#k1--aufwertungen-mit-einer-gabelung-je-turm) | S | **E-1 liegt Steffen vor** |
| 8 | Zwergenbank: Mechanik, Werte, für wen | Phase 2 | [K3](../konzepte/phase-2-3.md#k3--zwergenbank) | S | **E-3 liegt Steffen vor** (D-010) |
| 9 | Völker und Fähigkeiten | Phase 2 (Fähigkeit), 3 (Völker) | [K2](../konzepte/phase-2-3.md#k2--festungsfähigkeit-und-völker) | S | **E-2 liegt Steffen vor** |
| 10 | Kampagne und Fortschritt | Phase 3 | [K4](../konzepte/phase-2-3.md#k4--kampagne-und-regionen), [K5](../konzepte/phase-2-3.md#k5--fortschritt-und-freischaltungen) | S | **E-4 liegt Steffen vor** |
| 11 | Speicherstand, Cloud | Phase 2 | [K6](../konzepte/phase-2-3.md#k6--speicherstand) | C (lokal), S (Cloud) | lokal festgelegt D-022, Cloud Phase 4 |
| 12 | Multiplayer-Architektur | Phase 5 | [architecture.md](../technical/architecture.md) §4 | S | geparkt, Vorleistung steht |
| 13 | Release, Preis, Monetarisierung | Phase 5 | [06](../game-design/06-monetization.md) | S | Richtung entschieden D-015 |

## Aus dem Entscheidungsprotokoll und der Marktanalyse

| Frage | Gebraucht in | Konzept | Wer | Stand |
|---|---|---|---|---|
| D-003 Architektur des Simulationspakets | Phase 1 | [architecture.md](../technical/architecture.md) | C | gilt, umgesetzt WP-02 bis WP-11 (D-020) |
| D-007 Werte Mission 1 | Phase 1 | [04](../game-design/04-economy-and-balance.md) | S | nach WP-15 |
| D-008 Verkaufen ja, Upgrades nicht im MVP | Phase 1 | [K1](../konzepte/phase-2-3.md#k1--aufwertungen-mit-einer-gabelung-je-turm) | S | gilt für den MVP; Phase 2 über E-1 |
| D-009 Wellentakt, Bonus für frühes Rufen (E8) | Phase 2 | [K3](../konzepte/phase-2-3.md#bonus-für-frühes-rufen-d-009-e8) | C | Takt gilt (D-020), Bonus rechnet mit der Bank |
| D-011 Dokumentstruktur | – | – | C | gilt (D-020) |
| Festungsfähigkeit (E7) | Phase 2 | [K2a](../konzepte/phase-2-3.md#k2a--eine-aktive-festungsfähigkeit-phase-2) | S | in E-2 |
| Zielwahl je Turm (E5) | Phase 2 | [K1](../konzepte/phase-2-3.md#k1--aufwertungen-mit-einer-gabelung-je-turm) | S | in E-1 (ab Stufe 2) |
| Sterne und Eisern-Modus (E9) | Phase 3 | [K4](../konzepte/phase-2-3.md#sterne-und-herausforderungen-e9) | S | in E-4 |
| Tägliche Herausforderung (E10) | nach Release | [K5](../konzepte/phase-2-3.md#k5--fortschritt-und-freischaltungen) | S | Scope-Verbot, nicht vorgelegt |
| Bestiarium (E11) | Phase 2–3 | [K5](../konzepte/phase-2-3.md#k5--fortschritt-und-freischaltungen) | C | mit E-4 |
| Rüstung, Immunität, Bosse, Schattenflieger | Phase 3 | [K7](../konzepte/phase-2-3.md#k7--gegner-bosse-rüstung) | S | Vorschlag, wird mit Phase 3 vorgelegt |
| Einstieg ohne Erklärtext | Phase 2 | [K8](../konzepte/phase-2-3.md#k8--einstieg-ohne-erklärtext) | C | Vorschlag, Abstimmung mit Oberflächen-Thread |
| Ton und Haptik: Weg und Herkunft | Phase 2 | [K9](../konzepte/phase-2-3.md#k9--ton-und-haptik) | S | Vorschlag, neuer Thread zu Beginn Phase 2 |
| Automatisierte Balance- und Stresstests | Phase 2 (Grundstock), Phase 4 (voll) | [K11](../konzepte/phase-2-3.md#k11--balance-labor-automatisierte-balance--und-stresstests) | S (Richtung), C (Umsetzung) | Richtung entschieden D-028 |
