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
  für App und Oberfläche. Das Repository ist öffentlich, macOS-Minuten kosten
  deshalb nichts (Stand 25.10.2026). Wird es privat, kosten sie ein
  Vielfaches; dann Oberflächentests nur noch bei Pull Requests.
- Seit WP-01 läuft `.github/workflows/ci.yml`: Prüfskript unter Linux, App-Bau
  und Probelauf im Simulator (starten, 20 s laufen lassen, Bild sichern) auf macOS.
- Seit WP-02 testet die CI OddlingsCore zweimal: unter Linux (Container
  `swift:6.2-noble`, fängt Apple-Importe sofort) und auf macOS vor dem App-Bau.
- **Cloud-Sitzungen** bekommen Swift für Linux über `scripts/swift-linux.sh`
  (Startup-Haken, gemessen am 25.10.2026: läuft, 46 Tests in unter einer
  Sekunde). Das deckt nur das Paket ab; App und Oberfläche baut allein die
  macOS-CI.
- Das Python-Prüfskript (`tools/balance-sim/`) ist Phase-0-Werkzeug und wird
  gelöscht, sobald die Balancetests in Swift es abdecken (WP-10).
