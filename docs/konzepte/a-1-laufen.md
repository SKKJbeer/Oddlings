# Konzept A-1: Laufen wie in einem AAA-Titel (0.39.0)

Status: umgesetzt in 0.39.0 (D-144, D-150, D-151) · Stand 16.11.2026 · Thread „Laufen der Figuren verbessern“
Grundlage: [Bewegung und Bauen](aaa-bewegung-und-bauen.md) Abschnitt A-1 und „Kontaktabzug“,
[Review](aaa-review.md) Befunde B2 bis B5, D-050 (Effekte auf eigener Uhr), D-144 (Bewegung
nur in der Darstellung glätten), D-145 (Kontaktabzug in der CI).

## Ziel

Steffens Befund vom 16.11.2026: „Das Laufen sieht noch nicht perfekt aus.“ Heute knicken die
Figuren an jeder Ecke um 90° in einem Bild, laufen im Gänsemarsch exakt auf der Mittellinie,
zeigen nur die Seitenansicht (auch wenn sie auf den Betrachter zu laufen) und gleiten ohne
Gewicht. Nach A-1 gilt, messbar und getestet:

1. Keine Figur wechselt die Laufrichtung in einem einzigen Bild: An jeder Ecke läuft sie
   einen Bogen.
2. Zwei Gegner mit gleicher Strecke liegen nie deckungsgleich: Jeder hat seine eigene Spur.
3. Jede Figur schaut dorthin, wohin sie geht, in allen drei Blickrichtungen, sobald die
   Bildfolgen da sind (A-3); bis dahin fällt sie auf die Seitenansicht zurück wie heute.
4. Figuren haben Gewicht: Schatten atmet mit dem Schritt, Staub beim Aufsetzen, Neigung in
   die Kurve, Anlaufen beim Erscheinen.

## Umfang und Abgrenzung

- **Drin:** `PathView` (Bogen, Spur, Richtung, Krümmung), Spurversatz je Gegner,
  Blickrichtungen mit Rückfall, Überblenden beim Wechsel, Gewicht (Schatten, Staub, Neigung,
  Anlaufen), Kontaktabzug in der CI mit `scripts/kontaktabzug.py`.
- **Nicht drin:** die Bilder der Vorder- und Rückansicht (A-3 liefert sie, Namen siehe unten),
  Bauen und Tafeln (A-2), Maßstab der Figuren (A-4), jede Regeländerung.
- **Simulation unberührt (D-144):** Reichweite, Treffer, Prüfsummen und das Balance-Labor
  rechnen weiter auf der Linie aus Strecken (`PathGeometry`). `Packages/` wird nicht angefasst.

## Architektur

```
GameState.enemies[].distance ─▶ BattleScene.sync
                                   │ PathView.sample(at: distance, lane:)  (Darstellung)
                                   ▼
                                 PathSample { position, tangent, curvature }
                                   │                    │
                    FxMath.facing(tangent) ─▶ EnemyView  │ Neigung aus curvature
                                   ▼                    ▼
                                 EnemyNode.show(view:)  EnemyNode.apply(pose)
                                   │ Aufsetzen (FxMath.footfalls)
                                   ▼
                                 FxDirector.footfall ─▶ Staub (Effekt-Uhr, D-050)
```

| Baustein | Ort | Darf | Darf nicht |
|---|---|---|---|
| `PathView` | `App/Battle/PathView.swift`, nur Foundation und `OddlingsCore.Point` | aus den Wegpunkten Bögen bauen und eine Simulationsstrecke auf Position, Richtung und Krümmung abbilden | Zustand ändern, eigene Strecke führen |
| `FxMath.lane`, `FxMath.facing`, `FxMath.footfalls` | `App/Battle/Fx/FxMath.swift` | reine Rechnungen, ohne Szene testbar | Zufall außer aus der ID |
| `BattleScene.sync` | Szene | fragt `PathView` statt `path.position(at:)` | an der Simulation etwas ändern |
| `EnemyNode` | `BattleSprites.swift` | Folge wählen, überblenden, Rückfall | Laufbild aus der Uhr statt aus der Strecke |
| `FxDirector.footfall` | Effekte | Staubwölkchen, höchstens drei je Figur | etwas zeichnen, wenn „Bewegung reduzieren“ an ist |

Architekturregeln: Darstellung liest Zustand (2), Staub hängt am Lauf, nicht an der Uhr (3,
D-050), keine Zahl im Code außer in `FxStyle` mit Begründung (7), kein Zufall außer aus der ID
(6 gilt für die Simulation, hier freiwillig, damit Tests wiederholbar bleiben).

### Kurve statt Knick

`PathView` legt über jede Ecke einen Kreisbogen mit Radius `FxStyle.pathCornerRadius`
(0,5 Felder, halbe Wegbreite wie im Wegwerkzeug). Der Bogen berührt beide Strecken im Abstand
`t = r · tan(θ/2)` vor und nach der Ecke; ist eine Strecke zu kurz, wird `t` auf die halbe
Strecke begrenzt und der Radius passt sich an.

**Gleiche Strecke:** Das Fenster `[D − t, D + t]` der Simulationsstrecke um die Ecke wird
anteilig auf den Bogen abgebildet. Außerhalb der Fenster sind Simulations- und Bildposition
identisch. Eine Figur läuft also nie vor oder hinter ihrer Regelposition her und stirbt an
derselben Stelle; im Bogen ist sie auf dem Bildschirm etwas langsamer (Bogen 0,79 statt 1,0
Felder bei 90°), was wie Abbremsen in der Kurve wirkt.

**Abweichung:** höchstens `r · (√2 − 1)` = 0,21 Felder bei 90°, nur an der Ecke. Kleiner als
die Figur, kein Treffer geht sichtbar daneben.

### Spuren statt Gänsemarsch

`FxMath.lane(forID:)` gibt einen Wert in −1…1 aus der Folge `frac(id · 0,618)`
(goldener Schnitt; aufeinanderfolgende IDs liegen 0,76 von 2 auseinander, bis fünf IDs
Abstand mindestens 0,18). Der erste Entwurf nahm den Kehrwert der plastischen Zahl; dort
lagen IDs im Abstand 4 nur 0,04 auseinander, und gemeinsam erscheinende Gegner liefen in
Mission 6a und 7 sekundenlang deckungsgleich (CI-Lauf zu PR #100, unter Linux nachgestellt). Mal `FxStyle.laneWidth(kind)`: Plünderer und Flitzer ±0,18, Panzerbestie
±0,08, Boss 0. Der Versatz liegt quer zur Tangente von `PathView`; im Bogen ist die
Innenspur dadurch kürzer, wie bei echten Läufern. Gesamtabweichung zur Regelposition höchstens
0,39 Felder.

### Drei Blickrichtungen mit Rückfall

Namensvertrag, abgestimmt mit A-3 (16.11.2026):

| Folge | Name | Wann |
|---|---|---|
| seitlich | `enemy_<art>_walk_00..07` (wie heute) | Richtung innerhalb ±35° zur Waagerechten |
| vorn | `enemy_<art>_walkFront_00..07` | läuft auf dem Bildschirm nach unten |
| hinten | `enemy_<art>_walkBack_00..07` | läuft nach oben |

Alle drei mit gleicher Bildzahl, gleicher Schrittphase (Bild n vorn = Bild n seitlich),
Fußanker 0,1, als Dreiviertelansicht nach rechts gedreht; nach links spiegelt die Szene wie
seitlich. `hit` und `die` bleiben seitlich.

- `FxMath.facing(dx:dy:)` liefert `side`, `front` oder `back` aus der Tangente in Feldern
  (y nach unten). Grenze `FxStyle.sideAngle` = 35°.
- **Rückfall:** Fehlt einer Art die Folge, zeigt `EnemyNode` die Seitenfolge und behält die
  letzte waagerechte Blickrichtung, wie bis 0.29.1. So kann A-3 Figur für Figur liefern.
- **Überblenden:** Beim Wechsel der Folge liegt das alte Bild für `FxStyle.viewBlend` (0,12 s)
  über dem neuen und blendet aus; der Schritt läuft mit gleichem Index weiter.
- **Spiegeln nach links:** Die Blickrichtung (rechts/links) folgt dem Vorzeichen von `dx`,
  mit `FxStyle.facingThreshold` als Schwelle, damit senkrechte Strecken nicht flackern.

### Gewicht

| Was | Wie | Je Gegner |
|---|---|---|
| Fußkontakt | Schatten wird beim Aufsetzen breiter, dazwischen schmaler (`FxMath.contact`) | alle |
| Staub | Wölkchen beim Aufsetzen über `FxDirector.footfall`, höchstens `FxStyle.dustPerEnemy` (3) je Figur | Flitzer jeder Schritt klein, Plünderer jeder zweite, Panzerbestie jeder dritte groß, Boss jeder zweite groß |
| Neigung | in Kurven zur Innenseite, Krümmung mal `FxStyle.bankLean(kind)` | Flitzer stark, Plünderer leicht, Panzerbestie und Boss kaum |
| Wanken | bleibt aus der Gangart (`sway`), bei der Panzerbestie verstärkt | Panzerbestie, Boss |
| Anlaufen | erste `FxStyle.startupLife` (0,4 s) nach dem Erscheinen stärkere Vorneigung, abklingend | alle |

Aufsetzen zählt `FxMath.footfalls(from:to:stride:phase:)` aus der Strecke zwischen zwei
Bildern, nicht aus der Uhr: Ein verlangsamter Gegner staubt seltener, im Zeitraffer gleich oft
je Feld. **Bewegung reduzieren:** kein Staub, keine Neigung, kein Anlaufen; Laufen, Spur,
Bogen und Blickrichtung bleiben (aaa-bewegung-und-bauen.md, Grenzen).

### Kontaktabzug (D-145)

- Die App nimmt mit `--e2e-knoten <id>` auch in der Vorführung (`--demo`) die gewünschte
  Mission (bisher nur im eigenen Spiel).
- `--kontaktabzug` (nur Debug-Bau, wie `--fx-messung`): `ContactSheetProbe` schreibt an
  festen Effekt-Zeiten eine kleine Messung nach `Documents/kontaktabzug.json`: Zahl der
  Gegner, Zahl der Paare, die sich mehr als zur Hälfte überdecken, größte Abweichung von
  der Regelposition.
- CI-Schritt „Kontaktabzug“ nach dem Probelauf: startet jede Mission der Region im
  Zeitraffer, sichert fünf Bilder je Mission und die Messung, `scripts/kontaktabzug.py`
  setzt sie zu einem Blatt je Mission plus Übersicht zusammen (Pillow) und warnt
  (`::warning::`) bei Überschreitung. Artefakt `kontaktabzug`, Link im PR.
- Warnung statt Fehler: Der Abzug ist zum Ansehen; was hart prüfbar ist, prüfen die
  App-Tests.

## Bedienentscheidungen

Keine neue Bedienung. Alles hier ist Darstellung und folgt D-144; kein offener Punkt für
Steffen. Abweichungen vom Rahmenkonzept: keine.

## Sicherheit

Keine neue Eingabe von außen, kein Netz. Die neuen Startschalter wirken nur im Debug-Bau
(`#if DEBUG`), wie die übrigen E2E-Schalter. `kontaktabzug.py` liest nur Dateien aus dem
eigenen Lauf und läuft nur in der CI mit festen Versionen (Pillow 11.3.0).

## Testplan

| Ebene | Test | Prüft |
|---|---|---|
| App | `PathViewTests` | Abweichung ≤ r·(√2−1) über alle Missionen; Strecke außerhalb der Ecken gleich der Simulation; Endpunkte gleich; Richtung stetig (kein Sprung über den Bogen hinaus); Radius 0 knickt (rot gesehen) |
| App | `EnemyLaneTests` | gleicher Versatz für gleiche ID; im Band je Art; Boss 0; aufeinanderfolgende IDs mindestens 0,48 von 2 auseinander; zwei Gegner mit gleicher Strecke nie auf demselben Punkt |
| App | `FacingTests` | jede Strecke jeder Missionsdatei bekommt die erwartete Folge; Rückfall auf seitlich ohne Bilder; Überblenden läuft ab |
| App | `FxMathTests` (erweitert) | Aufsetzen je Schritt genau einmal, auch bei großen Bildsprüngen; nicht rückwärts |
| App | `BattleSceneTests` (erweitert) | keine Figur dreht in einem Bild um mehr als `maxTurnPerFrame`; Staub höchstens drei je Figur; mit „Bewegung reduzieren“ kein Staub |
| E2E | `WalkE2ETests` | Mission 1 im Zeitraffer: Figurenknoten tragen ihre Spur und Folge im Zugänglichkeitswert; zwei Gegner nie an derselben Stelle |
| CI | Kontaktabzug | Bilder je Mission, Messung, Warnung bei Überdeckung |

## Risiken

- **Bildfolgen fehlen noch:** Ohne A-3 sieht man von „drei Blickrichtungen“ nur den
  Rückfall. Der Code ist getestet; sichtbar wird es Figur für Figur.
- **Spur und Effekte:** Pfeile und Blitze zielen auf die Node, also auf die Spur, nicht auf
  die Mittellinie. Gewollt: Der Treffer sitzt an der Figur, die man sieht.
- **Stau am Bollwerk:** Steht eine Menge an der Mauer, stehen alle auf derselben Strecke.
  Die Spuren trennen sie, aber zwei Panzerbestien (schmales Band) können in Mission 7
  sekundenlang zusammenstehen; der Kontaktabzug warnt dort. Auffächern im Stehen wäre ein
  eigener kleiner Schritt nach Steffens Blick auf den Abzug.
- **Kontaktabzug kostet CI-Zeit:** neun Missionen je rund 25 s, etwa 4 Minuten im Mac-Lauf.
