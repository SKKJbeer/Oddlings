# Teststrategie

Status: **[VORSCHLAG]**

## Ebenen

| Ebene | Was | Wo | Wann |
|---|---|---|---|
| Regeltests | Einzelregeln von `OddlingsCore`: Kosten, Zielwahl, Kette, Verlangsamung, Durchbruch, Sieg/Niederlage | `swift test` im Paket | bei jeder Änderung |
| Konfigurationstests | JSON lädt, Validierung greift, ungültige Werte werden abgewiesen | Paket | bei jeder Änderung |
| Determinismus | Gleiche Befehlsfolge → gleiche Prüfsumme des Endzustands; 1× = 2×; Speichern/Laden mitten in der Welle ändert das Ergebnis nicht | Paket | bei jeder Änderung |
| Balancetests | Bot-Bauweisen aus der Konfiguration: „Mischung gewinnt", „nur Sporen verliert", Reserve-Grenzen | Paket | bei jeder Änderung an Werten |
| Architekturtest | `OddlingsCore` importiert kein SpriteKit/SwiftUI/UIKit | Paket | bei jeder Änderung |
| Darstellung | Szene startet, Knotenzahl folgt dem Zustand | XCTest in der App | im CI auf macOS |
| Oberfläche | Mission starten, Turm bauen, Mission zu Ende spielen (2× Tempo, Bot-Befehle) | XCUITest | im CI, vor TestFlight |
| Spieltest | Menschen, echtes iPhone, Beobachtungsprotokoll | manuell | Ende jeder Phase |

## Regeln

1. **Ein Regeltest pro Regel, mit konstruiertem Fall.** Beispiel Kette: drei
   Gegner im Abstand 1,0, Radius 1,3, Sprünge 4 → genau drei Treffer in der
   Reihenfolge nach Nähe, Schaden 18 / 14,4 / 11,52.
2. **Jeder Test wird einmal rot gesehen.** Regel kurz kaputt machen, Test muss
   fehlschlagen. Ein Test, der nie rot war, beweist nichts.
3. **Balancetests prüfen Beziehungen, nicht exakte Zahlen.** „Blitz + Sporen
   Reserve > nur Blitz Reserve + 0,3" bleibt bei kleinen Wertänderungen stabil;
   „Reserve = 1,42" bricht bei jeder.
4. **Testkonfigurationen sind eigene kleine JSON-Dateien** in den Tests, nicht die
   Missionsdatei. Sonst bricht jede Balanceänderung Regeltests.

## Werkzeuge und Orte

- Swift Testing (`@Test`) oder XCTest im Paket; beides läuft mit `swift test`.
- **CI:** GitHub Actions auf macOS: `swift test` für das Paket, `xcodebuild test`
  für App und Oberfläche. **[OFFEN]** Ist das Repository privat, kosten
  macOS-Minuten bei GitHub ein Vielfaches; dann Oberflächentests nur bei Pull
  Requests und manuell.
- **Cloud-Sitzungen** haben derzeit kein Swift. Bis eine Linux-Toolchain
  eingerichtet ist (prüfen in WP-02), ist die CI die einzige Instanz, die Swift
  übersetzt. Eine Cloud-Sitzung behauptet nie, Swift-Tests seien grün, ohne
  CI-Lauf.
- Das Python-Prüfskript (`tools/balance-sim/`) ist Phase-0-Werkzeug und wird
  gelöscht, sobald die Balancetests in Swift es abdecken (WP-10).
