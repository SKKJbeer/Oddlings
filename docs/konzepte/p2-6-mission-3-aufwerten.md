# Konzept: Mission 3 mit Aufwertung und Zielwahl (P2-6, erster Teil)

Stand 02.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-024 (Aufwertungen mit zwei Stufen und einer Gabelung, Zielwahl ab
Stufe 2, Regeln in [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2)),
D-027 (Region 1, M3 lehrt „vertiefen statt verbreitern“,
[05](../game-design/05-campaign-and-progression.md#region-1-flüsterwald-kostenlos)),
D-081 (Weg aus dem Vorschlag des Grafik-Threads), D-080 (Missionen vor dem
Spieltest, Werte danach). Bedienung nach [07](../game-design/07-ui-ux.md#8-phase-2-aufwerten-fähigkeit-bank).

## Ziel

Mission 3 bringt die zweite Frage, die jedes große Tower Defense trägt: **noch
ein Turm oder den guten Turm besser machen?** Ein Turm auf Stufe 2 kostet etwa
70 % eines neuen und wirkt etwa 50 % stärker, deckt aber keinen neuen Weg ab. Der
Weg von M3 ist so gelegt, dass wenige Plätze viel Weg sehen: Dort lohnt das
Vertiefen. Mit Stufe 2 schaltet der Turm die Zielwahl frei (erster, letzter,
stärkster), damit ein Spieler einen starken Turm gezielt auf Panzerbestien
richten kann.

## Umfang

| Teil | Inhalt |
|---|---|
| Regel Aufwerten | Befehl `upgrade(towerID:)`: Stufe 1 → 2, Gold aus `upgrades.<turm>.cost`, Werte mal `scale`. Ereignis `towerUpgraded`. Verkaufen erstattet 70 % von allem, was im Turm steckt |
| Regel Zielwahl | Befehl `setTargetMode(towerID:, mode)`: erster, letzter, stärkster. Erst ab Stufe 2 und nur für Türme mit Einzelziel (Wach- und Blitzturm). Kostet nichts. Ereignis `targetModeChanged` |
| Mission 3 | `mission-03.json` „Pilzhain“: Weg aus dem Vorschlag D-081 unverändert, 10 Wellen, Aufwertungen, Bank und Bonus für frühes Rufen wie in M2 (Entscheidungskarte, Empfehlung). Alle Werte **[HYPOTHESE]** bis nach WP-15 |
| Kampagne | Knoten `m3` bekommt seine Missionsdatei und ist nach M2 spielbar |
| Bedienung | Turmmenü: Aufwerten oben (Preis, zweimal tippen), Verkaufen, ab Stufe 2 Zielwahl an der Seite. Schild „II“ am Turm, Stufe-2-Bild, Hinweis beim Wechsel der Zielwahl |
| Grafik | Die drei Stufe-2-Türme liegen gemalt und freigestellt in `art/phase-2` (`tower_*_2-frei.png`, Grafik 02). Sie kommen über `atlas.py` in den Atlas; der gemalte Kampfplatz `map_mission03_ground` liegt seit 0.16.1 bereit |
| Ton | Aufwerten: Bauklang höher (07, Rückmeldeliste), Zielwahl: Klicken. Nur vorhandene CC0-Klänge (D-082) |
| Tests | Regeln im Paket, Darstellung in `AppTests`, Ende-zu-Ende: M3 von der Karte, Turm bauen, aufwerten, Zielwahl umschalten |

**Nicht drin:** Spezialisierungen (Stufe 3, Gabelung A/B) kommen mit M5/M6
(05), Mission 4 mit Panzerbestie und Fähigkeit als Neuheit (danach, nicht
parallel: beide ändern die Simulation). Mission 1 und 2 bleiben **unverändert**:
M1 ist die Mission des Spieltests, M2 wurde ohne Aufwertung abgestimmt. Ob
Aufwerten später in M1/M2 kommt, entscheidet die Auswertung von WP-15.

## Regel Aufwerten

Die Missionsdatei trägt einen Abschnitt `upgrades`, je Kampfturm Preis und
Faktoren auf die Werte der Stufe 1. Fehlt der Abschnitt, gibt es keine
Aufwertung (M1, M2), und die Simulation lehnt den Befehl ab.

```json
"upgrades": {
  "watch":     { "cost": 35, "scale": { "damage": 1.5 } },
  "lightning": { "cost": 56, "scale": { "damage": 1.5 } },
  "spore":     { "cost": 35, "scale": { "range": 1.15, "slowFactor": 0.8 } }
}
```

- **Faktoren statt fester Werte.** Volk (Reichweite der Elfen) und Ausrüstung
  (R-7a, Schaden und Reichweite) ändern die Werte der Stufe 1. Stufe 2 rechnet
  von dort aus weiter, damit Boni nicht beim Aufwerten verloren gehen. **[gilt]**
- **Erste Werte [HYPOTHESE]:** Preis 70 % des Grundturms (02). Wachturm und
  Blitzturm +50 % Schaden; Sporenturm 15 % mehr Reichweite und Verlangsamung von
  0,5 auf 0,4 der Geschwindigkeit. Sein Schaden ist absichtlich klein, seine
  Wirkung ist die Kontrolle.
- Der Preis der Aufwertung folgt dem Volk nicht: Der Zwergenrabatt (D-062) gilt
  für den Bau von Wachtürmen, so steht es in 03.
- Höchste Stufe ist 2. Eine Bank wird nie aufgewertet (04).
- Der Takt des Turms läuft weiter; die Aufwertung setzt ihn nicht zurück. Sonst
  wäre Aufwerten mitten im Kampf ein Schussverlust.
- `Tower.spent` wächst um den Preis. Verkaufen erstattet `sellRefundRate` von
  allem (02, „Wirtschaft“).

## Regel Zielwahl

**[VORSCHLAG]** Drei Arten, nach 07: Der Knopf schaltet bei jedem Tippen weiter.

| Art | Wen der Turm nimmt | Bei Gleichstand |
|---|---|---|
| Erster | am weitesten auf dem Weg (wie bisher) | der ältere |
| Letzter | am wenigsten weit auf dem Weg | der ältere |
| Stärkster | das größte Höchstleben (`maxHP`), also die zäheste Art einer Welle | der weiter vorne, dann der ältere |

- „Stärkster“ nach Höchstleben, nicht nach Restleben: Ein Turm soll an der
  Panzerbestie bleiben, statt bei jedem Treffer auf den nächsten vollen
  Plünderer zu springen. Das ist die Absicht des Spielers, wenn er „stärkster“
  wählt.
- Gilt für das erste Ziel. Beim Blitzturm springt die Kette danach wie bisher.
- Der Sporenturm trifft alle in Reichweite, für ihn gibt es keine Wahl.
- Die Wahl bleibt beim späteren Spezialisieren erhalten (07).
- Wie bisher zählen schon tödlich Getroffene nicht.

## Mission 3 „Pilzhain“

- **Karte:** 16 × 9 wie M1 und M2. Weg aus dem Vorschlag D-081 unverändert:
  `[[-1,1.5],[7.5,1.5],[7.5,4.5],[2.5,4.5],[2.5,7.5],[13.5,7.5],[13.5,3.5],[17,3.5]]`.
  Die Haarnadel links oben gibt Plätzen zwischen den Bahnen drei Wegstücke. Der
  gemalte Kampfplatz passt dazu, die Kunstprüfung hält beides zusammen.
- **Wellen:** 10, Plünderer, Flitzer und ab Welle 6 Panzerbestien in kleiner
  Zahl. Die Gegner kommen dichter und zäher als in M2, damit eine Mission ohne
  Aufwertung knapper wird, nicht unmöglich. **[VORSCHLAG]**
- **Bank und Bonus** wie in M2 (**[ENTSCHIEDEN D-085]**, Steffen 02.11.2026,
  Entscheidungskarte S5). So stehen drei Anlagen nebeneinander: neuer Turm, Aufwertung, Bank.
- **Startgold** 200, erste Welle nach 25 s.
- **Zielgröße Balance** (neu in 04): Die beste Bauweise mit Aufwertungen hat
  mehr Reserve als dieselbe ohne, aber höchstens 0,15 mehr: Vertiefen soll sich
  lohnen und nie Pflicht sein. Nur Wachtürme verliert weiterhin. `BalanceTests`
  rechnet das für M3, Ergebnis in 04.

## Architektur

```
Turmmenü ─▶ Controller.upgrade() (zweimal tippen) ─▶ enqueue(.upgrade(id))
         ─▶ Controller.cycleTargetMode()          ─▶ enqueue(.setTargetMode(id, next))
Simulation.step: apply(…) prüft Mission, Stufe, Gold
                 fireTowers nimmt config.stats(of: tower) und tower.targetMode
Szene ◀── towerUpgraded (Bild tauschen, „II“, Aufbau-Effekt), targetModeChanged (Hinweis)
```

- **Eigener Abschnitt `upgrades`** (`BalanceConfig.upgrades: [TowerKind: UpgradeConfig]?`),
  nicht in `TowerConfig`: Dieselbe Begründung wie bei der Bank (D-083). Eine
  Mission ohne Abschnitt bleibt Byte für Byte, wie sie ist. `UpgradeConfig` hat
  `cost` und `scale: [TowerStat: Double]` (Schlüssel: `range`, `damage`,
  `attackInterval`, `chainRadius`, `slowFactor`, `slowDuration`). Eintrag
  D-084 im Entscheidungsprotokoll.
- **Werte eines Turms nur über `BalanceConfig.stats(of:)`.** Die Simulation, der
  Bot und die App fragen dort, nie `towers[kind]` direkt, sobald ein Turm im
  Spiel ist. So gibt es eine Stelle, die Stufe 2 rechnet.
- **Zustand:** `Tower` bekommt `level` (Vorgabe 1) und `targetMode` (Vorgabe
  `first`), beide mit Vorgabe beim Lesen, alte Zustände bleiben lesbar
  (Architekturregel 4).
- **Befehle:** `upgrade(towerID:)`, `setTargetMode(towerID:, TargetMode)`.
  Ablehnungen `notUpgradable` (Mission ohne Abschnitt, Bank, schon Stufe 2) und
  `targetModeLocked` (Stufe 1 oder Turm ohne Einzelziel).
- **Ereignisse:** `towerUpgraded(id:, level:)`, `targetModeChanged(id:, mode:)`.
  Effekte und Ton hängen daran (Architekturregel 3).
- **Reihenfolge im Tick** unverändert; die neuen Befehle laufen bei den Befehlen.
- **Bauweisen der Balancetests:** `simStrategies` bekommt Schritte statt nur
  Turmarten. `"watch"` baut wie bisher, `"watch+"` wertet den ältesten
  Wachturm auf Stufe 1 auf. Alte Dateien bleiben gültig. Die Prüfung beim Laden
  lehnt `+` ab, wenn die Mission keine Aufwertungen hat.
- **Kampagne:** `region-01.json`, Knoten `m3` bekommt `"mission": "mission-03"`.

## Bedienung

Nach 07, Abschnitt 8. Für M3 gilt nur Stufe 1 und 2:

- **Turm antippen** (Stufe 1, Mission mit Aufwertung): zwei Knöpfe im Bogen,
  oben **Aufwerten** mit Bild der Stufe 2 und Preis, unten Verkaufen. Erstes
  Tippen auf Aufwerten zeigt die Infotafel „Stufe 2: gleiche Rolle, spürbar
  stärker. Schaltet die Zielwahl frei.“ und die neue Reichweite als Kreis,
  zweites Tippen kauft. Fehlt Gold, wie beim Bauen: gedimmt, „−12“ im Schild,
  Goldanzeige blinkt.
- **Stufe 2:** Verkaufen und an der Seite die **Zielwahl**: Ein Knopf mit
  Symbol und Schild („Erster“), jedes Tippen schaltet weiter, ohne zweites
  Tippen (kostet nichts). Kurzer Hinweis über dem Turm. Der Sporenturm zeigt
  keine Zielwahl.
- **Am Turm:** Stufe-2-Bild, kleines Schild „II“ oben rechts. Beim Aufwerten
  wächst der Turm kurz und setzt sich (07, Rückmeldeliste: „Turm wächst ein
  Stück, Schild springt auf“), Klang höher als beim Bau, Stoß mittel.
- **Infotafel** eines Turms auf Stufe 2: Name mit „II“, Rolle, Zielwahl.

## Sicherheit

Die neue Datei läuft durch dieselbe Prüfung wie M1 und M2, bevor sie die
Simulation erreicht: `upgrades` nur für Kampftürme, Preis positiv, jeder Faktor
positiv und nur für Werte, die der Turm hat (`slowFactor` nur beim
Sporenturm), Verlangsamung danach weiter zwischen 0 und 1, Abfall des Blitzes
höchstens 1. Strategien mit `+` nur, wenn es Aufwertungen gibt. Kein Netz, keine
neue Bibliothek.

## Testplan

| Ebene | Was |
|---|---|
| Paket | `UpgradeTests`: Aufwerten kostet und erhöht `spent`, Schaden/Reichweite der Stufe 2 aus den Faktoren, zweites Aufwerten und Bank abgelehnt, Mission ohne Abschnitt lehnt ab, zu wenig Gold, Takt läuft weiter, Verkaufen erstattet alles, Faktoren wirken auf Volk und Ausrüstung. `TargetModeTests`: erster/letzter/stärkster mit Gleichständen, Stufe 1 und Sporenturm abgelehnt, Blitzkette beginnt am gewählten Ziel. `ConfigValidation` für `upgrades` und `+`-Schritte. Alte Zustände ohne `level` lesbar. `MissionThreeTests`: Datei gültig, Weg = Vorschlag D-081, Ausgänge der Bauweisen, Kennzahl Vertiefen, Determinismus, Völker begrenzt. `CampaignTests`: M3 nach M2 offen |
| App | `UpgradeControllerTests`: Knopf nur in Missionen mit Aufwertung, zweimal tippen, Gold fehlt dimmt und sendet nichts, Zielwahl erst ab Stufe 2 und nicht beim Sporenturm, Weiterschalten sendet den nächsten Modus. `BattleSpritesTests`: Stufe-2-Bild je Turm. `HudLayoutTests`: drei Knöpfe am Turm auf jeder Zelle von M3. `SoundMapTests` für die neuen Ereignisse |
| Ende-zu-Ende | `UpgradeE2ETests`: M3 über `--play` mit `--e2e-knoten m3` starten, Wachturm bauen, aufwerten (Infotafel, Preis), Zielwahl erscheint und schaltet weiter. `CampaignE2ETests`: M3 ist nach M2 offen |
| Grafik | `tools/art-check`: Vertrag für `tower_watch_2`, `tower_lightning_2`, `tower_spore_2` |

Jeder neue Test wird einmal rot gesehen.

## Risiken

- **Balance ohne Spieltest:** Werte sind Hypothesen, die Balancetests halten
  nur die Beziehungen. Nach WP-15 werden M1 bis M3 zusammen nachgezogen; das
  Balance-Labor (P2-6b) misst später genauer.
- **R-7a läuft parallel** im Haupt-Thread und ändert Turmwerte über
  `applying(equipment:)`. Weil Stufe 2 mit Faktoren auf die angepasste Stufe 1
  rechnet, vertragen sich beide; Konflikte erwarte ich nur in Dokumenten und
  `BalanceTests`.
- **Drei Knöpfe am Turm** am Kartenrand: `HudLayout.ring` kennt beliebige
  Anzahlen, `HudLayoutTests` bekommt den Fall.
