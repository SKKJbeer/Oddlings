# Entscheidungsprotokoll

Eine Zeile je Entscheidung. Wird eine Entscheidung geändert, bekommt sie einen
neuen Eintrag, der den alten nennt; der alte bleibt stehen.

Status: **entschieden** · **vorgeschlagen** (wartet auf Steffen) · **verworfen**

| ID | Datum | Entscheidung | Status | Begründung / Optionen |
|---|---|---|---|---|
| D-001 | 25.10.2026 | Übergabe v0.1 ist der Designstand; ihre Festlegungen gelten als entschieden | entschieden | Übergabe |
| D-002 | 25.10.2026 | Stack Swift + SwiftUI + SpriteKit, vorbehaltlich Spike WP-01 | entschieden (Übergabe), Spike offen | [architecture.md](../technical/architecture.md) §1; Plan B Godot |
| D-003 | 25.10.2026 | Simulation als eigenes Swift-Paket `OddlingsCore` ohne UI-Importe; Befehle rein, Ereignisse raus, Zustand als Wert, fester Takt 30/s | vorgeschlagen | Testbarkeit, Determinismus, spätere Mehrspieler-Fähigkeit ohne Netzcode |
| D-004 | 25.10.2026 | **Querformat** | entschieden (Steffen, 25.10.2026) | Zellen ~43 pt statt ~24 pt im Hochformat; Wege lesbarer. Gegen: Einhandbedienung |
| D-005 | 25.10.2026 | **Platzierung im Raster innerhalb von Bauzonen**, ein Turm je Zelle | entschieden (Steffen, 25.10.2026) | Optionen A frei / B Raster / C feste Plätze, siehe [01](../game-design/01-core-gameplay.md). Präzisiert „frei platzierbar" aus der Übergabe |
| D-006 | 25.10.2026 | **iOS 17**, iPhone | entschieden (Steffen, 25.10.2026) | `@Observable`, alle iPhones ab XS/XR |
| D-007 | 25.10.2026 | Werte für Mission 1 laut `config/balance/mvp-mission-01.json` | vorgeschlagen | [04](../game-design/04-economy-and-balance.md), grob geprüft, nicht spielgetestet |
| D-008 | 25.10.2026 | **Verkaufen im MVP (70 %), Upgrades nicht** | vorgeschlagen | Verkaufen ist billig und erlaubt Ausprobieren; Upgrades verdoppeln die Balancefläche |
| D-009 | 25.10.2026 | Wellentakt: nächste Welle 15 s nach dem letzten Erscheinen, früher abrufbar | vorgeschlagen | [01](../game-design/01-core-gameplay.md#wellentakt-vorschlag) |
| D-010 | 25.10.2026 | Zwergenbank: für alle oder nur für Zwerge? | offen, vor Phase 2 | Übergabe nennt sie Zwergen-Kennzeichen und zugleich Einzelspieler-Wirtschaftsturm |
| D-011 | 25.10.2026 | Dokumentstruktur weicht leicht ab: Weltkarte + Fortschritt in einer Datei (05), Völker + Avatar in einer (03), Monetarisierung ist 06 | vorgeschlagen | Keine leeren Dateien, keine doppelten Quellen |
| D-012 | 25.10.2026 | Phase-0-Arbeit kommt per Pull Request ins Repo | entschieden | Steffen, 25.10.2026 |
| D-013 | 25.10.2026 | Bundle-ID `de.skkjbeer.oddlings` | entschieden (Steffen, 25.10.2026) | Muster von Stack & Siege (`de.skkjbeer.stackandsiege`) |
