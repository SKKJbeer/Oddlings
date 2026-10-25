# Konzept: End-zu-End-Tests der App

Stand 25.10.2026 · Version 0.5.1 · Auftrag Steffen: „generelle e2e tests sollen
auch laufen mit allen möglichen tests, dass die app genau so funktioniert wie
gedacht“ (D-029).

## Ziel

Die CI spielt die App bei jedem PR so durch, wie ein Mensch sie bedient:
starten, Mission wählen, bauen, verkaufen, Wellen rufen, anhalten,
beschleunigen, gewinnen, verlieren, neu starten, in den Hintergrund und zurück.
Was dort grün ist, funktioniert auf dem iPhone so wie gedacht. Was neu ins
Spiel kommt, bekommt seinen End-zu-End-Fall im selben PR.

## Abgrenzung zu den anderen Ebenen

| Ebene | Prüft | Ort |
|---|---|---|
| Regeltests | jede Spielregel für sich, deterministisch | `Packages/OddlingsCore/Tests` |
| App-Tests | Controller, Szene, Modell ohne Bildschirm | `AppTests/` |
| **End-zu-End** | **die ausgelieferte App über die Oberfläche, wie ein Spieler** | `AppUITests/` (XCUITest) |
| Spieltest | Spaß, Verständnis, Fehltipps | Menschen, WP-15 |

End-zu-End-Tests prüfen nicht noch einmal Regeln (die Zahl der Kettensprünge),
sondern dass Regel und Oberfläche zusammen stimmen: Wer baut, sieht das Gold
sinken. Wer verkauft, bekommt die Erstattung aus der Missionsdatei.

## Architektur

- **Ein Zugang für alle Fälle:** `AppUITests/E2EApp.swift` startet die App,
  kennt alle Kennungen (`hud.gold`, `build.watch`, `result.title` …) und tippt
  Zellen mit derselben Lagerechnung wie `BoardLayout`. Ändert sich eine
  Kennung, ändert sie sich an einer Stelle.
- **Zahlen aus der Missionsdatei:** Das Testziel bindet `OddlingsCore` ein und
  liest Preise, Startgold, Leben und Erstattung aus `mvp-mission-01.json`. Eine
  Balanceänderung bricht keinen Oberflächentest (Architekturregel 7).
- **Warten statt Momentaufnahme:** Die Oberfläche folgt dem Zustand ein Bild
  später. Jede Prüfung wartet mit Frist auf den erwarteten Wert und meldet
  sonst den zuletzt gelesenen.
- **Zeitraffer für ganze Missionen:** `--e2e-zeitraffer N` lässt Mission 1 in
  Sekunden laufen. Es sind dieselben festen Schritte, nur mehr je Bild
  (Regel 5), das Ergebnis ist also dasselbe wie in Echtzeit.
- **Startargumente** `--play` und `--demo` führen direkt in die Mission.
  Testschalter gibt es nur als Startargument, nie als Knopf in der App.
- **Jedes Bedienelement hat eine `accessibilityIdentifier`**, die Tests suchen
  nur danach, nie nach sichtbarem Text (Ausnahme: der Pausenhinweis, dessen
  Text der Prüfgegenstand ist).

Vorgaben der Planung: [testing-strategy.md](../technical/testing-strategy.md)
und Meilenstein M1.4 (volle Abdeckung von Mission 1, dazu Zugänglichkeit und
mehrere Geräte). Dieser Stand ist der erste Schritt dorthin.

## Sicherheit

Der Zeitraffer gibt es nur im Debug-Bau (`#if DEBUG`). Ein TestFlight- oder
App-Store-Bau hat keinen Schalter, der das Spieltempo von außen ändert. Die
übrigen Startargumente wählen nur den Bildschirm. Ungültige Werte (keine
Zahl, nicht positiv) werden ignoriert.

## Fälle (Stand 0.5.1)

| Datei | Fall |
|---|---|
| `NavigationE2ETests` | Start → Spielen → Zurück; Vorführung nimmt keine Eingaben; Hintergrund hält an, zurück steht „Angehalten“ |
| `BuildAndSellE2ETests` | Bauen zieht Gold ab, Verkaufen erstattet, Zelle danach frei; erster Tipp nur Vorschau; zweiter Tipp auf die Zelle schließt; zu teuer ist ausgegraut |
| `HUDE2ETests` | Startwerte aus der Missionsdatei; Welle rufen; Pause friert den Countdown ein, Weiter setzt fort; 1× ↔ 2× |
| `MissionE2ETests` | Ohne Türme verloren, Tafel, keine Welle und keine Pause mehr, Nochmal setzt Gold und Leben zurück; Vorführung gewinnt, Zurück führt ins Menü |

## Bedienentscheidung

**[VORSCHLAG]** Geht die App in den Hintergrund, hält die Mission an. Wer
zurückkommt, soll keine Welle verpasst haben. So machen es die Vorbilder aus
der Marktanalyse.

## Pflege

Jedes neue Feature bringt im selben PR seinen End-zu-End-Fall mit, steht im
Skill `arbeitspaket-ausliefern`. Die CI listet jeden Testfall mit Ergebnis,
damit sichtbar ist, dass ein Ziel überhaupt gelaufen ist.
