# Konzept: Spielbare Mission 1 (WP-12 bis WP-14)

Stand 25.10.2026 · Version 0.5.0 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)

## Ziel

Steffen öffnet die App aus TestFlight und spielt Mission 1 von vorne bis zum
Ergebnis: Türme bauen und verkaufen, Wellen rufen, gewinnen oder verlieren,
neu anfangen. Grafik bleibt Platzhalter, bis die Assets aus dem Grafik-Thread
unter ihren Namen im Katalog liegen (Asset-Vertrag des Grafik-Threads).

## Umfang

| Paket | Inhalt |
|---|---|
| WP-12 | Zelle antippen → Baumenü an der Zelle mit Preisen; erster Tipp auf einen Turm zeigt die Reichweite, zweiter baut. Turm antippen → Name und „Verkaufen +Erstattung“. Abgelehnte Befehle erscheinen als Text an der Stelle. |
| WP-13 | Kopfleiste: Zurück, Gold, Leben, Welle n/m, „Nächste Welle · s“, 1×/2×, Pause. |
| WP-14 | Ergebnistafel Sieg oder Niederlage mit Leben, „Nochmal“ und „Zurück“. |
| Einstieg | Startbildschirm mit großem „Spielen“; Vorführung und Leistungsprobe klein darunter. |

Nicht drin: Upgrades, Speichern, Ton, Einstellungen, Dauer der Runde in der
Ergebnistafel (kommt mit WP-15, wenn klar ist, ob sie Spieler interessiert).

## Architektur

```
Tippen ─▶ BattleScene.touchesEnded ─▶ BoardLayout.cell(atScene:) ─▶ BattleController.tap
SwiftUI-Knöpfe (BattleMenu, BattleTopBar, BattleOverlay) ─▶ BattleController
BattleController ─▶ BattleModel.enqueue(Command) ─▶ nächster fester Schritt ─▶ Simulation
Simulation ─▶ Events ─▶ BattleScene (Effekte)   GameState ─▶ BattleController.afterFrame (Kopien)
```

- **Befehle, nie Zustand** (Architekturregel 2). Der Controller entscheidet
  nicht, ob ein Bau gelingt; das sagt die Simulation im nächsten Schritt, eine
  Ablehnung kommt als Ereignis zurück.
- **Eingaben an Taktgrenzen.** `BattleModel` sammelt Befehle und gibt sie dem
  nächsten Schritt mit. Ein Spiel bleibt so aus seiner Befehlsfolge genau
  wiederholbar.
- **Eine Lagerechnung.** `BoardLayout` (Seitenverhältnis einpassen, mittig)
  rechnen Szene, Baumenü und Oberflächentest gleich. Szene und Menü liegen im
  selben Rahmen.
- **Beobachtete Kopien.** Der Controller hält Gold, Leben, Welle, Sekunden bis
  zur Welle und Ergebnis als `@Observable`-Kopien und setzt sie nur bei
  Änderung. Sonst zeichnet SwiftUI 60-mal je Sekunde neu.
- **Pause und 2× sind Bedienung.** Pause hält die Uhr im `BattleModel` an, 2×
  rechnet doppelt so viele feste Schritte (Regel 5). Beides berührt den
  Zustand nicht und steht deshalb nicht in der Simulation.
- **Mitspieler-Modus.** Dieselbe Ansicht mit `interactive = false` und
  Autoplayer; Eingaben werden dort ignoriert.

## Bedienentscheidungen

- **[HYPOTHESE]** Die Kopfleiste liegt über der Karte, nicht darauf: Kein Knopf
  verdeckt eine Bauzelle. Preis: Die Zellen werden im Querformat etwa 38 statt
  43 pt groß ([D-004](../decisions/decision-log.md)). Fällt das im Spieltest
  (WP-15) als Fehltippen auf, wandern Anzeigen an die freien Seitenränder.
- **[ENTSCHIEDEN – D-019, 25.10.2026]** Die Mission läuft weiter, während das
  Baumenü offen ist. Wer Ruhe braucht, hat den Pausenknopf.
- Ablehnungen bleiben sichtbar, auch wenn das Menü leistbare Türme schon
  ausgraut, weil eine Zelle zwischen Tipp und Schritt belegt werden kann.

## Sicherheit

Keine neue Angriffsfläche: kein Netz, keine Speicherung, keine Eingabe außer
Tippen. Startargumente (`--play`, `--demo`) wählen nur den Bildschirm.

## Tests

| Ebene | Datei | Prüft |
|---|---|---|
| Einheit | `AppTests/BattleControllerTests.swift` | Auswahl öffnen und schließen, Weg öffnet nichts, Vorschau baut nicht, zweiter Tipp baut und zieht Gold ab, Verkaufen erstattet, nicht leistbare Türme, Zuschauen nimmt keine Eingaben, Welle rufen, Countdown aus der Missionsdatei, Pause, 2×, Niederlage zeigt die Tafel, Neustart setzt alles zurück |
| Oberfläche | `AppUITests/BuildAndSellUITests.swift` | Mit echtem Tippen bauen, Turm wählen, verkaufen, Zelle wieder frei; Kopfleiste vorhanden, Pause zeigt „Angehalten“ |
| CI | `ci.yml`, Schritt „App testen“ | Beide Ebenen auf dem iPhone-Simulator |
