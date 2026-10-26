# Konzept: Bewegung und Effekte (FX 01)

Status: **[VORSCHLAG]** · Stand 25.10.2026 · Version 0.5.3 · Thread „Animationen
und Effekte hochwertig machen"
Grundlage: [Marktanalyse](../game-design/market-analysis.md) E1 (jedes Ereignis
bekommt sichtbare Rückmeldung) und Abschnitt 3 „AAA-Anmutung",
[Rückmeldung je Ereignis](../art/rueckmeldung-je-ereignis.md),
[Asset-Vertrag](../art/asset-vertrag.md), Stil D-016.

## Ziel

Steffen fand Bau 21 „billig", weil sich die Figuren kaum bewegen: Gegner
gleiten starr über den Weg, Treffer sind ein Ausblenden, der Tod ein weißer
Kreis, Türme schießen Striche. Nach diesem Paket hat jedes Ereignis der
Simulation eine Bewegung mit Gewicht: Gegner laufen im Schritttakt, Treffer
blitzen und stoßen zurück, Gegner zerplatzen in Rauch, Splitter und Münzen,
Pfeile fliegen im Bogen, der Blitz springt sichtbar von Ziel zu Ziel, der
Sporenturm pumpt eine Wolke aus, Türme fallen beim Bau auf ihren Platz und
versinken beim Verkauf. Alles bei 60 Bildern je Sekunde auf dem iPhone.

## Umfang

**Drin (Stufe 1, dieses Paket)**

| Ereignis / Zustand | Bild | Dauer |
|---|---|---|
| Gegner läuft | Hüpfen im Schritttakt (Schrittlänge je Gegnerart), Stauchen beim Aufsetzen, Strecken in der Luft, Wiegen von Seite zu Seite, Vorneigung, Schatten wird in der Luft kleiner, Blick in Laufrichtung | dauerhaft |
| `enemySpawned` | Gegner wächst aus einem Staubwölkchen | 0,25 s |
| `towerFired` Wachturm | Turm federt zurück, Pfeil fliegt im Bogen und folgt dem Ziel, Funken beim Einschlag | 0,06–0,16 s Flug |
| `towerFired` Blitzturm | Kristall leuchtet auf, gezackter Blitz Glied für Glied (40 ms Versatz) mit Glühen und Kern, Funken je Ziel | 0,22 s |
| Blitz trifft verlangsamtes Ziel (E2) | Sporenfunke: größerer grün-blauer Funkenregen | 0,3 s |
| `towerFired` Sporenturm | Pilzhut staucht und federt nach, Ring breitet sich bis zur Reichweite aus, Sporenwölkchen treiben nach außen | 0,5 s |
| `enemyDamaged` | Gegner blitzt hell auf (additive Kopie des Bildes), kleiner Rückstoß und Stauchen, Lebensbalken mit nachlaufendem hellem Schadensstück | 0,12 s |
| `enemySlowed` | grüner Farbton am Gegner, Schritttakt folgt der langsameren Bewegung von selbst | solange verlangsamt |
| `enemyKilled` | Treffer-Halt, Gegner staucht und zerplatzt, Rauchwolken, Splitter in seiner Farbe, Münzen springen heraus und drehen sich, `+n` springt auf | 0,5 s |
| `enemyLeaked` | Gegner schrumpft ins Tor, Festung bebt, rotes Aufblitzen, Bildschirm wackelt | 0,4 s |
| `towerBuilt` | Turm fällt von oben, setzt mit Stauchen und Nachfedern auf, Staubring, Staubwolken, Bildschirm zuckt leicht | 0,45 s |
| `towerSold` | Turm versinkt in Staub, Münzen springen auf, `+n` | 0,4 s |
| `commandRejected` | Zelle blinkt rot, Text wackelt seitlich | 0,3 s |
| `waveStarted` | Banner springt mit Überschwingen ein, bleibt, fährt aus | 1,6 s |
| `missionEnded(won: true)` | Konfettiregen | 1,5 s |
| `abilityCast` Steinregen | Schatten wächst bis zum Einschlag, Ring pulsiert und zieht sich zusammen, Felsen prasseln versetzt und landen zum Einschlag | Warnzeit (0,8 s) |
| `abilityImpact` Steinregen | Lichtblitz, Druckwelle, Staubwolken, Steinsplitter im Bogen, Bild wackelt | 0,5 s |
| Betäubt (`stunUntilTick`) | drei Sternchen kreisen über dem Kopf, hinten kleiner und blasser | solange betäubt |
| `abilityCast` / `abilityImpact` Mondmal | kühles Licht sammelt sich, leuchtet auf, Funken; kein Wackeln | Warnzeit + 0,3 s |
| Mondmal am Gegner | pulsierender Mond über dem Kopf, wippt mit | solange markiert |
| `barrierRaised` / `barrierFell` | Steinmauer schießt federnd aus dem Boden mit Staub und Ruck; am Ende versinkt sie in Staub | 0,32 s / 0,35 s |
| Türme in Ruhe | ganz leichtes Atmen (Skalierung um 1 %), Blitzturm mit pulsierendem Glühen | dauerhaft |

**Nicht drin**

- Ton und Haptik. Haptik baut der Oberflächen-Thread (`FeedbackPlayer`, UI 01),
  Ton kommt mit K9.
- Echte Gliedmaßen-Animation (Stufe 2, siehe Entscheidung unten).
- Neue Bilder. Effekttexturen werden im Code erzeugt und unter den
  Vertragsnamen `fx_*` durch Atlasbilder ersetzbar.
- Keine Regel ändert sich, `Packages/` bleibt unberührt.

Die Fähigkeiten (R-3, R-4) kamen während der Arbeit auf `main`; ihre
Platzhalter sind mit diesem Paket ersetzt (Nachtrag 26.10.2026).

## Architektur

```
Simulation ──Ereignisse──▶ BattleScene.frame ──▶ FxDirector.play(event)   (Wann)
                │                                      │
                └──GameState──▶ BattleScene.sync ──▶ EnemyNode.pose(...)   (Lauf aus Zustand)
                                                       │
            Bildzeit dt ──▶ FxDirector.advance(dt) ──▶ Tweens + Partikel (eigene Effekt-Uhr)
                                                       │
                                     FxTextures (Atlas `fx_*` oder im Code erzeugt)
```

| Baustein | Ort | Darf | Darf nicht |
|---|---|---|---|
| `FxMath` (rein) | `App/Battle/Fx/FxMath.swift` | Kurven (Easing), Laufhaltung aus zurückgelegter Strecke, Blitzzacken, Pfeilbogen, Wackeln. Nur Foundation, ohne Bildschirm testbar | SpriteKit importieren |
| `FxStyle` | `App/Battle/Fx/FxStyle.swift` | alle Dauern, Farben, Mengen und Obergrenzen der Effekte, Gangart je Gegner | Spielwerte enthalten (Regel 7) |
| `FxTextures` | `App/Battle/Fx/FxTextures.swift` | Texturen nach Name aus dem Atlas, sonst einmal gezeichnet und zwischengespeichert | aus dem Netz laden |
| `FxDirector` | `App/Battle/Fx/FxDirector.swift` | Ereignis → Effekt, Pool von Sprites, Tweens auf der eigenen Uhr, Wackeln der Welt-Node, Obergrenzen | Zustand oder Befehle anfassen |
| `EnemyNode` (erweitert) | `App/Battle/BattleSprites.swift` | Haltung aus `FxMath` übernehmen, Aufblitzen, nachlaufender Lebensbalken | Strecke selbst berechnen |
| `BattleScene` (angepasst) | `App/Battle/BattleScene.swift` | Ereignisse an den Director, Strecke und Laufrichtung an die Gegner, Gegner und Türme zum Sterben/Versinken an den Director abgeben | Effekte selbst zeichnen |

**Warum eine eigene Effekt-Uhr statt `SKAction`?**

1. **Testbar ohne Bildschirm.** `SKAction` läuft nur in einer angezeigten
   Szene. In `AppTests` blieben sterbende Gegner für immer stehen, und kein
   Test könnte prüfen, dass Effekte enden. Der Director bekommt die Bildzeit
   in `frame(after:)` wie die Simulation und ist damit so prüfbar wie der Rest
   der Szene.
2. **Keine Speicheranforderung je Bild.** Flüchtige Sprites kommen aus einem
   Pool, `SKShapeNode` wird für Effekte nicht mehr benutzt (sie zerlegt ihren
   Pfad bei jeder Änderung neu und ist der übliche Grund für Ruckler in
   SpriteKit).
3. **Pause und 2×.** Angehalten steht auch jeder Effekt still. Bei 2× laufen
   doppelt so viele Schritte, Effekte aber in Echtzeit; die Obergrenzen fassen
   die Menge zusammen ([Rückmeldung je Ereignis](../art/rueckmeldung-je-ereignis.md), Grenzen).

**Architekturregeln.** Regel 2 und 3 gelten unverändert: Effekte hängen an
Ereignissen, die Laufbewegung leitet sich aus dem Zustand ab (zurückgelegte
Strecke), nichts schreibt zurück. Regel 6 betrifft nur die Simulation; der
Director nutzt trotzdem einen eigenen gesäten Zufallsgenerator, damit Tests
wiederholbar sind. Regel 7: Zahlen der Darstellung stehen in `FxStyle`,
Spielwerte weiter nur in der Missionsdatei.

**Laufbewegung ohne Rutschen.** Die Haltung hängt an der zurückgelegten
Strecke, nicht an der Uhr: ein Schritt je `stride` Felder. Wird ein Gegner
verlangsamt, trippelt er automatisch langsamer, und die Füße rutschen nie
über den Boden. Jeder Gegner bekommt aus seiner Kennung eine eigene Phase,
damit eine Welle nicht im Gleichschritt hüpft.

**Pfeil und Treffer.** Die Simulation trifft sofort, der Pfeil braucht
0,06–0,16 s. Der Director merkt sich ankommende Pfeile je Ziel und spielt
Aufblitzen und Tod erst bei Ankunft. Ein getroffener Gegner bleibt bis dahin
stehen; das wirkt als kurzer Treffer-Halt.

## Stufe 2: echte Gliedmaßen [ENTSCHIEDEN: 3D zu Sprite-Blättern, D-051]

Ein Bildgenerator malt dieselbe Figur nicht Bild für Bild gleich, ein gemalter
Laufzyklus flackert (Asset-Vertrag, „Bewegung"). Für Arme und Beine liegen
Steffen drei Wege vor:

| Weg | Was | Aufwand | Risiko |
|---|---|---|---|
| Teile-Rig in SpriteKit (war Empfehlung) | Jede Figur in Teile (Kopf, Rumpf, Arme, Beine, Sack) mit Gelenkpunkten, Laufzyklus als Schlüsselbilder | mittel, je Figur ein Teileblatt aus dem Grafik-Thread | Teile müssen Überlappungen sauber gemalt haben |
| **3D-Modell zu Sprite-Blättern (gewählt)** | Figur als 3D-Modell, riggen, Bildfolgen rendern | hoch, neue Pipeline | Stil weicht ab, App wird größer |
| prozedural bleiben | nur Stufe 1, nach WP-15 entscheiden | keiner | Gliedmaßen bleiben starr |

Steffen hat am 26.10.2026 den Weg über 3D-Modelle gewählt (D-051). Das wird
ein eigenes Paket mit eigenem Konzept, zusammen mit dem Grafik-Thread: Woher
die Modelle kommen (Lizenz), wie sie im Stil der gemalten Figuren gerendert
werden, Bildfolgen je Richtung und App-Größe. Stufe 1 bleibt darunter: Schatten,
Treffer, Tod und alle Effekte hängen nicht am Bild, und die Bildfolge ersetzt
nur Hüpfen und Kippen.

## Leistung (60 Bilder je Sekunde)

- **Obergrenzen** in `FxStyle`: höchstens `maxSprites` flüchtige Sprites. Ab 80 %
  entfallen Zierpartikel (Rauch, Splitter), Pflichtteile (Pfeil, Blitz, Münze)
  kommen bis zur Grenze.
- **Pool** statt Neuanlage, ein Texturset für alles, additive Mischung nur für
  Glühen.
- **Messung in der CI:**
  1. `AppTests/FxBudgetTests` spielt Mission 1 mit allen Effekten im
     60-Hz-Takt durch: Obergrenze nie überschritten, nach dem Ende ist die
     Effektebene leer, keine `SKShapeNode` in der Effektebene, Rechenzeit je
     Bild im Mittel unter `FxStyle`-Budget (gemessen, großzügig für den
     Simulator).
  2. Probelauf im Simulator mit `--fx-messung`: Die App misst 20 s lang
     Bildzeiten und schreibt mittlere Bildrate und schlechtestes Bild in eine
     Datei; der CI-Schritt liest sie, zeigt sie an und wird rot unter 30 Bildern
     je Sekunde. Maßgeblich bleibt das Gerät (WP-01).
- „Bewegung reduzieren" (iOS): kein Bildschirmwackeln, kein Atmen der Türme.

## Sicherheit

Keine neue Bibliothek, kein Netz, keine neuen Rechte. Texturen aus dem
App-Katalog oder im Speicher gezeichnet. Die Messschalter `--fx-messung` und
`--e2e-fx` gibt es nur im Debug-Bau.

## Testplan

Jeder neue Test wird einmal rot gesehen.

| Ebene | Test |
|---|---|
| `AppTests/FxMathTests` | Kurven beginnen bei 0 und enden bei 1, Überschwingen nur wo gewollt; Laufhaltung wiederholt sich nach genau einem Schritt, hängt nur an der Strecke, bleibt in ihren Grenzen; Blitzzacken beginnen und enden exakt an den Zielen; Pfeilbogen endet am Ziel; Wackeln klingt ab |
| `AppTests/FxDirectorTests` | jedes Ereignis erzeugt seinen Effekt; Effekte enden und geben Sprites in den Pool zurück; Obergrenze hält; Pfeil verzögert Aufblitzen und Tod bis zur Ankunft; angehalten (dt = 0) bewegt sich nichts; Neustart räumt alles ab |
| `AppTests/FxBudgetTests` | ganze Mission mit Effekten: Grenze, leere Effektebene am Ende, keine `SKShapeNode`, Rechenzeit je Bild |
| `AppTests/BattleSceneTests` (bestehend) | weiter genau eine Node je Turm und Gegner, auch mit sterbenden und versinkenden Nodes |
| `AppUITests/EffectsE2ETests` | Vorführung im Zeitraffer: Pfeile, Blitze, Sporen, Bau, Tod und Münzen wurden in der echten App gespielt (Zähler `fx.stats`, nur Debug) |
| CI-Probelauf | Bildrate im Simulator, Artefakt mit Bildschirmfoto |

## Schritte

1. Konzept (dieses Dokument), D-Nummern, Entscheidungskarte Stufe 2.
2. `FxMath`, `FxStyle`, `FxTextures` mit Tests.
3. `FxDirector` und Umbau der Szene, Gegnerbewegung.
4. Leistungstests und Messschritt in der CI.
5. Dokumente nachziehen (Asset-Vertrag `fx_*`, Rückmeldung je Ereignis,
   CHANGELOG, Status), Version 0.5.3, Bau in TestFlight.

## Abstimmung

- Oberflächen-Thread (UI 01): ändert `BattleScene` nicht, baut Haptik. Dieses
  Paket fasst Controller, HUD und Menüs nicht an; eigene Werte in `FxStyle`
  statt `BattleStyle`, damit sich die Zweige nicht überschneiden.
- Grafik-Thread: Namen `fx_*` im Asset-Vertrag; bei Stufe 2 Teileblätter.

## Risiken

- **Zu viel auf dem Schirm** bei voller Welle (Säule 2, Lesbarkeit): Grenzen,
  kurze Dauern, Zierpartikel entfallen zuerst. Der Spieltest beobachtet es.
- **Simulator misst anders als das Gerät**: Schwelle in der CI bewusst niedrig,
  die echte Abnahme bleibt die Messung auf dem iPhone.
