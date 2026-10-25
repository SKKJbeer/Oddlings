# Entscheidungsprotokoll

Eine Zeile je Entscheidung. Wird eine Entscheidung geändert, bekommt sie einen
neuen Eintrag, der den alten nennt; der alte bleibt stehen.

Status: **entschieden** · **gilt** (von Claude festgelegt, klein und umkehrbar; Einspruch jederzeit) · **vorgeschlagen** (wartet auf Steffen) · **verworfen**

**Nummern vergibt die Projektplanung zentral** (Thread „Roadmap und offene
Spielkonzepte führen"). Vergeben bzw. reserviert:

| Nummern | Thread |
|---|---|
| D-001 bis D-015 | Phase 0, Simulation |
| D-016 | AAA-Grafik (Grafikstil) |
| D-017 bis D-019 | Simulation (WP-12 bis WP-14) |
| D-020 bis D-029 | Projektplanung |
| D-030 bis D-039 | Spieloberfläche und Menüs |
| D-040 bis D-049 | AAA-Grafik |
| ab D-050 | frei, Block von zehn bei der Projektplanung anfragen |

Eine Nummer doppelt bricht den CI-Schritt `regeln` (`scripts/links-pruefen.py`).

| ID | Datum | Entscheidung | Status | Begründung / Optionen |
|---|---|---|---|---|
| D-001 | 25.10.2026 | Übergabe v0.1 ist der Designstand; ihre Festlegungen gelten als entschieden | entschieden | Übergabe |
| D-002 | 25.10.2026 | Stack Swift + SwiftUI + SpriteKit, vorbehaltlich Spike WP-01 | entschieden (Übergabe), Spike offen | [architecture.md](../technical/architecture.md) §1; Plan B Godot |
| D-003 | 25.10.2026 | Simulation als eigenes Swift-Paket `OddlingsCore` ohne UI-Importe; Befehle rein, Ereignisse raus, Zustand als Wert, fester Takt 30/s | vorgeschlagen | Testbarkeit, Determinismus, spätere Mehrspieler-Fähigkeit ohne Netzcode |
| D-004 | 25.10.2026 | **Querformat** | entschieden (Steffen, 25.10.2026) | Zellen ~43 pt statt ~24 pt im Hochformat; Wege lesbarer. Gegen: Einhandbedienung |
| D-005 | 25.10.2026 | **Platzierung im Raster innerhalb von Bauzonen**, ein Turm je Zelle | entschieden (Steffen, 25.10.2026) | Optionen A frei / B Raster / C feste Plätze, siehe [01](../game-design/01-core-gameplay.md). Präzisiert „frei platzierbar" aus der Übergabe |
| D-006 | 25.10.2026 | **iOS 17**, iPhone | entschieden (Steffen, 25.10.2026) | `@Observable`, alle iPhones ab XS/XR |
| D-007 | 25.10.2026 | Werte für Mission 1 laut `mvp-mission-01.json` (Paket-Ressource) | vorgeschlagen | [04](../game-design/04-economy-and-balance.md), grob geprüft, nicht spielgetestet |
| D-008 | 25.10.2026 | **Verkaufen im MVP (70 %), Upgrades nicht** | vorgeschlagen | Verkaufen ist billig und erlaubt Ausprobieren; Upgrades verdoppeln die Balancefläche |
| D-009 | 25.10.2026 | Wellentakt: nächste Welle 15 s nach dem letzten Erscheinen, früher abrufbar | vorgeschlagen | [01](../game-design/01-core-gameplay.md#wellentakt-vorschlag) |
| D-010 | 25.10.2026 | Zwergenbank: für alle oder nur für Zwerge? | offen, vor Phase 2 | Übergabe nennt sie Zwergen-Kennzeichen und zugleich Einzelspieler-Wirtschaftsturm |
| D-011 | 25.10.2026 | Dokumentstruktur weicht leicht ab: Weltkarte + Fortschritt in einer Datei (05), Völker + Avatar in einer (03), Monetarisierung ist 06 | vorgeschlagen | Keine leeren Dateien, keine doppelten Quellen |
| D-012 | 25.10.2026 | Phase-0-Arbeit kommt per Pull Request ins Repo | entschieden | Steffen, 25.10.2026 |
| D-014 | 25.10.2026 | Auf das Gerät über TestFlight: `.github/workflows/testflight.yml` bei jeder App-Änderung auf main und per Knopfdruck, interne Gruppe „Team" | entschieden (Steffen, 25.10.2026) | Signatur je Lauf per API (aus CardBeacon übernommen), Zugänge aus Zählora übertragen |
| D-013 | 25.10.2026 | Bundle-ID `de.skkjbeer.oddlings` | entschieden (Steffen, 25.10.2026) | Muster von Stack & Siege (`de.skkjbeer.stackandsiege`) |
| D-017 | 25.10.2026 | Vor jeder Umsetzung Konzept und Architektur in `docs/konzepte/` | entschieden (Steffen, 25.10.2026) | „wichtig ist dass davor immer auch konzepte und architekturen entworfen werden und dann die umsetzung“ |
| D-018 | 25.10.2026 | WP-12, WP-13 und WP-14 in einem PR (0.5.0) | entschieden | Steffen will so schnell wie möglich ein spielbares Spiel auf dem iPhone; einzeln wären es drei Bauten ohne spielbaren Zwischenstand |
| D-019 | 25.10.2026 | Mission läuft weiter, während das Baumenü offen ist | vorgeschlagen (Frage an Steffen offen) | Druck bleibt erhalten; Pause gibt es als eigenen Knopf. Gegen: Anfänger verlieren Zeit im Menü |
| D-015 | 25.10.2026 | Geschäftsmodell bevorzugt: **kostenlos anspielen (erste Region), Vollversion einmalig, später bezahlte Regionen**; Kosmetik als Zugabe. Endgültig in Phase 5 mit Daten | entschieden (Steffen, 25.10.2026) | [Marktanalyse](../game-design/market-analysis.md) E12; berührt die Leitplanke in [06](../game-design/06-monetization.md). Fairness-Leitplanken bleiben in jedem Fall |
| D-020 | 25.10.2026 | D-003 (Architektur des Simulationspakets), D-009 (Wellentakt) und D-011 (Dokumentstruktur) **gelten**: umgesetzt und durch Tests gedeckt (WP-02 bis WP-11). D-009 wird im Spieltest WP-15 mit geprüft | gilt (Claude) | Projektplanung; ändert nichts an Code oder Regeln |
| D-021 | 25.10.2026 | Ergänzt D-017: Konzepte für Phase 2 und 3, die auf Steffen warten, stehen in [phase-2-3.md](../konzepte/phase-2-3.md); nach der Entscheidung wandern sie ins Fachdokument. Offene Fragen im [Register](../production/offene-fragen.md), Stand für Steffen in [status.md](../production/status.md), nach jedem Meilenstein neu | gilt (Claude) | Eine Stelle je Entscheidung (CLAUDE.md) |
| D-022 | 25.10.2026 | Speicherstand lokal: JSON mit Schemaversion, atomar geschrieben, vorige Fassung bleibt, beim Laden geprüft, Migration je Version mit Test; laufende Mission nur fortsetzen, wenn die Missionsdatei unverändert ist. Cloud offen bis Phase 4 | gilt (Claude) | [K6](../konzepte/phase-2-3.md#k6--speicherstand); setzt die Sicherheitsregel „Prüfen beim Laden" um |
| D-023 | 25.10.2026 | Reine Dokument-PRs heben die Version nicht und lösen keinen Bau aus; sie stehen im CHANGELOG als „Dokumente, kein Bau" | gilt (Claude) | Eine Version zählt, was in der App steckt; ein Bau ohne Änderung verbraucht eine Nummer |
| D-024 | 25.10.2026 | E-1: Aufwertungen in Phase 2 mit zwei Stufen und einer Gabelung je Turm, Zielwahl ab Stufe 2 | vorgeschlagen | [K1](../konzepte/phase-2-3.md#k1--aufwertungen-mit-einer-gabelung-je-turm); Marktanalyse E5, E6 |
| D-025 | 25.10.2026 | E-2: eine aktive Festungsfähigkeit in Phase 2 (Steinregen); ab Phase 3 bestimmt das Volk die Fähigkeit und einen kleinen passiven Zug, kein volkseigener Turm vor dem Release | vorgeschlagen | [K2](../konzepte/phase-2-3.md#k2--festungsfähigkeit-und-völker); Marktanalyse E7; klärt das [OFFEN] in 03 |
| D-026 | 25.10.2026 | E-3 (zu D-010): Zwergenbank ist ein Grundturm für alle; Zwerge haben ihren Zug an der Bank | vorgeschlagen | [K3](../konzepte/phase-2-3.md#k3--zwergenbank) |
| D-027 | 25.10.2026 | E-4: kostenlose Region 1 mit sieben Haupt- und zwei Nebenmissionen, Gabelung, Boss; Völker am Ende von Region 1 frei; Fortschritt ohne Werteboni und ohne zweite Währung | vorgeschlagen | [K4](../konzepte/phase-2-3.md#k4--kampagne-und-regionen), [K5](../konzepte/phase-2-3.md#k5--fortschritt-und-freischaltungen); folgt aus D-015 |
