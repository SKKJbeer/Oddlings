# P2-2: Fortsetzen nach App-Neustart

Status: **umgesetzt in 0.22.0** mit der Empfehlung der Karte S12 (direkt in die
pausierte Mission, D-074). Grundlage: [K6](phase-2-3.md#k6--speicherstand), D-022.
Vorgänger: R-1 (Speicherstand), R-7b (Spielstand Schema 2).

## Ziel

Wer eine Mission spielt, das iPhone weglegt und später zurückkommt, findet sie genau
so vor, wie er sie verlassen hat, auch wenn iOS die App inzwischen beendet hat oder
das Telefon neu gestartet wurde. Mobile Spieler werden ständig unterbrochen (Anruf,
Bahnsteig, Akku); eine Mission von acht Minuten, die bei jeder Unterbrechung verloren
geht, ist auf dem Telefon nicht fair (Säule 5, Marktanalyse 3 „AAA-Anmutung“:
nichts geht verloren).

## Umfang

**Drin:** Sichern des laufenden Zustands, sobald die App in den Hintergrund geht;
beim nächsten Start direkt in die Mission, angehalten mit der Pausentafel; Prüfung
des gesicherten Zustands beim Laden; Neustart mit Hinweis, wenn sich die Regeln
geändert haben; Verwerfen, sobald die Mission endet oder verlassen wird.

**Nicht drin:** mehrere gesicherte Missionen, Fortsetzen nach bewusstem Verlassen
über „Zurück“ (das beendet die Mission wie bisher), Wiederholung aus Befehlen,
iCloud (Phase 4, K6).

## Bedienentscheidung (Karte S12)

Wo landet der Spieler, wenn die App mitten in einer Mission neu startet?

- **A. Direkt in der Mission, pausiert (Empfehlung, gebaut).** Die App öffnet die
  Schlacht am alten Stand, die Pausentafel liegt darüber und sagt „Mission
  fortgesetzt“. Fühlt sich an, als wäre die App nie zu gewesen.
- B. Hauptmenü mit Knopf „Fortsetzen“. Zwischen Start und Fortsetzen ließe sich
  Ausrüstung und Talent ändern; der Stand müsste dann die Wahl vom Missionsbeginn
  mitführen.
- C. Gar nicht fortsetzen (Stand vor 0.22.0).

Mit A gibt es keinen Weg vom gesicherten Zustand in das Avatar-Menü: Entweder er wird
beim Start fortgesetzt, oder die Mission wird verlassen und der Stand verworfen. Die
Regeln der Mission (Volk, Talente, Ausrüstung) können sich dazwischen also nur durch
ein Update ändern. Das hält die Prüfung einfach (ein Fingerabdruck, siehe unten).
Wählt Steffen B, kommt die Wahl vom Missionsbeginn als Feld in den Stand.

## Architektur

### Daten (Kern, nur Foundation)

`SuspendedBattle` in `OddlingsCore/SuspendedBattle.swift`:

| Feld | Bedeutung |
|---|---|
| `node` | Kampagnenknoten der Mission |
| `rules` | Fingerabdruck der **gespielten** Konfiguration (Mission mit Volk, Talenten, Ausrüstung), 16 Hexziffern |
| `seed` | Startwert, für „Neu starten“ in der fortgesetzten Mission |
| `state` | der ganze `GameState` (Architekturregel 4: er ist schon `Codable`) |

Er steht im Spielstand als `SaveGame.battle` (Schema **3**, Migration 2 → 3 ohne
Inhalt: Ein alter Stand hat keine laufende Mission). Eine Datei, ein atomares
Schreiben (D-022): Fortschritt und laufende Mission können nicht auseinanderlaufen.
`SaveStore.maximumBytes` steigt von 64 auf 512 KB, weil ein Zustand mitten in einer
großen Welle einige zehn KB hat.

**Fingerabdruck** `BalanceConfig.fingerprint`: FNV-1a über das JSON der Konfiguration
mit sortierten Schlüsseln. Alle Tabellen der Konfiguration haben Aufzählungen als
Schlüssel (`CodingKeyRepresentable`) und werden deshalb als Objekte mit sortierten
Schlüsseln geschrieben, nie in Hash-Reihenfolge. Die Prüfsumme des Zustands (WP-10)
geht absichtlich von Hand über die Felder, weil JSON-Zahlen je Plattform anders
aussehen dürfen; hier wird nur auf demselben Gerät verglichen. Schlimmster Fall nach
einem iOS-Update, das Zahlen anders schreibt: Die Mission beginnt einmal neu.

### Prüfen beim Laden (Sicherheitsregel)

Der gesicherte Zustand kommt von außen und erreicht die Simulation erst nach
`SuspendedBattle.problems(for: Simulation)`. Leer heißt gültig. Geprüft wird alles,
woran die Simulation sich verlassen muss:

- Tick ≥ 0, Gold ≥ 0, Leben 1 … Startleben, Welle −1 … Wellenzahl − 1, kein Ergebnis
- Türme: Art in der Mission vorhanden (Bank nur mit Bankwerten), Zelle baubar, keine
  zwei auf einer Zelle, Stufe 1 … Höchststufe, Werte nicht negativ
- Gegner: Art in der Mission vorhanden, Leben endlich und 0 < LP ≤ max, Weg 0 … Länge,
  Wirkungen endlich und positiv
- Kennungen eindeutig und kleiner als `nextEntityID`, Zeitpunkte nicht in der
  Vergangenheit, wo die Simulation das annimmt (`pendingSpawns`, Einschlag)
- Fähigkeit nur, wenn die Mission eine hat; Ziel und Mauer endlich bzw. auf dem Weg

Ein Fehler verwirft den ganzen gesicherten Zustand, nicht den Spielstand: Fortschritt
und Avatar bleiben (wie `SaveGameCodec.Dropped`). Geraten wird nichts.

### Ablauf in der App

```
Hintergrund (scenePhase .background)
  BattleView → onSuspend(state)  → AppFlow.suspend(node, rules, seed, state) → SaveStore.save
App-Start
  AppFlow.init lädt SaveGame.battle
    Knoten spielbar, Fingerabdruck gleich, problems leer → Schirm .battle(resume)
    Knoten spielbar, Fingerabdruck anders oder Zustand ungültig → .battle neu, Hinweis
    Knoten nicht spielbar/unbekannt → Hauptmenü, Stand verworfen
Mission endet (Sieg, Niederlage, Aufgeben) → AppFlow.finish verwirft den Stand
„Zurück“ aus der Schlacht → AppFlow.leaveBattle verwirft den Stand
```

- Nur das eigene Spiel wird gesichert, nie die Vorführung.
- Gesichert wird nur bei `.background`, nicht bei `.inactive` (Kontrollzentrum,
  Mitteilungen): iOS meldet `.background` vor jedem Beenden aus dem Hintergrund.
- Die Schlacht beginnt fortgesetzt **angehalten**; die Pausentafel trägt den Hinweis.
  Wer zurückkommt, soll nicht mitten in eine laufende Welle fallen.
- „Neu starten“ in der fortgesetzten Mission beginnt mit demselben Startwert neu.
- `BattleModel` bekommt den Zustand fertig (`resume:`); die Darstellung baut Türme
  und Gegner wie nach jedem Bild aus dem Zustand (Architekturregel 2).

### Wer was darf

| Teil | darf | darf nicht |
|---|---|---|
| Kern | Zustand prüfen, Fingerabdruck rechnen, Schema migrieren | Dateien suchen, die App kennen |
| `AppFlow` | sichern, verwerfen, beim Start entscheiden | Zustand ändern |
| `BattleView` | den Zustand beim Weggehen abgeben | selbst schreiben |

## Tests

- Kern (`SuspendedBattleTests`): Zustand nach N Schritten sichern, über die Datei
  zurücklesen und weiterrechnen ergibt dieselbe Prüfsumme wie ohne Unterbrechung
  (Determinismus über das Speichern); Migration 2 → 3; Fingerabdruck stabil und
  empfindlich (Volk, Talent, Ausrüstung, Mission ändern ihn); jede Prüfregel einmal
  rot (Gold negativ, Turm auf dem Weg, unbekannte Art, Bank ohne Bankwerte, Stufe zu
  hoch, Gegner jenseits des Wegs, NaN, doppelte Kennung, Ergebnis gesetzt, …);
  ungültiger Zustand kostet nur die Mission, nicht den Fortschritt; Stand über 64 KB
  wird gelesen.
- App (`AppFlowTests`): Sichern schreibt, Start mit gültigem Stand öffnet die
  Schlacht, geänderter Fingerabdruck öffnet sie neu mit Hinweis, unbekannter Knoten
  führt ins Menü, Sieg und Verlassen verwerfen.
- E2E (`ResumeUITests`): Mission starten, bauen, App in den Hintergrund (Home),
  App beenden, neu starten → Pausentafel mit Hinweis, Turm steht, Gold wie vorher;
  „Weiter“ läuft weiter.

## Risiken

- **Größe:** Viele Gegner machen die Datei größer; gemessen im Test mit voller
  Welle. Grenze 512 KB.
- **Schreiben im Hintergrund:** iOS gibt nach `.background` wenige Sekunden. Ein
  Spielstand ist klein, das Schreiben dauert Millisekunden.
- **Alter Stand nach Absturz:** Stürzt die App im Vordergrund ab, gilt der letzte
  Hintergrundstand. Lieber ein paar Sekunden zurück als nichts.
