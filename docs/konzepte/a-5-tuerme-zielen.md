# Konzept A-5 Teil 3: Türme zielen

Status: **in Arbeit (0.46.0)** · Plan [AAA-Schnitt](aaa-review.md#plan), Paket A-5 ·
Maßnahme G9 aus [aaa-bewegung-und-bauen.md](aaa-bewegung-und-bauen.md#a-5-eine-malweise-in-der-welt)
Befund: G9 („Türme sind tot“) · Entscheidungen: [D-185 bis D-189](../decisions/decision-log.md)
Vorgänger: [A-5 Teil 1](a-5-spezialisierungen-und-ringe.md) (0.34.0), [A-5 Teil 2](a-5-kopfleiste-und-effektbudget.md) (0.45.0),
[A-3](a-3-figuren-vollstaendig.md) (3D-Figuren)

## Ziel

Ein Turm ist ein Bauwerk mit jemandem darin, kein Bild, das sich beim Schuss staucht.
Man sieht, **wen** der Wachturm gerade meint, **wann** der Blitzturm wieder springt und
**dass** der Sporenturm ausstößt. Säule 2: „in jeder Sekunde sehen, was passiert“; die
Liste „AAA-Anmutung“ der [Marktanalyse](../game-design/market-analysis.md) (Abschnitt 3):
Türme reagieren auf das Geschehen, Vorbilder drehen Geschütz oder Schützen zum Ziel.

## Umfang

| Drin | Nicht drin |
|---|---|
| Wachturm: Schütze als eigene 3D-Figur auf der Plattform, acht Blickrichtungen, Schussfolge; die gemalte Armbrust verschwindet aus den vier Wachturmbildern | Bank (zielt nicht) |
| Salve: zwei Schützen, jeder zielt auf sein eigenes Ziel | Schützen je Volk (Entscheidungskarte, Empfehlung: ein Zwergenschütze für alle) |
| Blitzturm: Kristall lädt sichtbar auf, aus dem Zustand der Abklingzeit | Neue Malerei der Blitz- und Sporentürme |
| Sporenturm: Hut hebt sich beim Ausstoß und setzt federnd auf | Andere Regeln: Die Simulation ändert nichts am Spiel |
| Kein senkrechtes „Atmen“ und kein Stauchen mehr bei Stein | |
| Messung „Schütze blickt aufs Ziel“ in App-Test, E2E und Kontaktabzug | |

## Architektur

### Wer was darf

- **Simulation** (`Packages/OddlingsCore`): bekommt zwei **reine Abfragen**, die nichts
  am Zustand ändern und nicht in die Prüfsumme gehen:
  - `Simulation.aim(of: Tower, in: GameState) -> [Int]` — die IDs der Gegner, auf die der
    Turm **jetzt** schießen würde. Sie ruft dieselbe Zielwahl auf wie `fireTowers`
    (`targets(in:around:range:mode:count:)`), damit es keine zweite Umsetzung der Zielregel
    gibt (Architekturregel „keine zweite Umsetzung derselben Sache“). Ohne Gegner in
    Reichweite: leer.
  - `Simulation.charge(of: Tower) -> Double` — 0 direkt nach dem Schuss, 1 bereit;
    aus `cooldownTicks` und dem Takt der Stufe. Rechnet mit der Konfiguration, keine
    Zahl im Code.
- **Darstellung** (`App/Battle`): `TowerNode` bekommt je Art eine **Krone** (`TowerCrown`):
  `ShooterCrown` (Wachturm), `CrystalCrown` (Blitz), `CapCrown` (Spore). Die Szene gibt
  jedem Turm in `sync` Ziel und Ladung aus den Abfragen; die Krone dreht, lädt und hebt
  mit der Effekt-Uhr. Der Schuss kommt weiter als Ereignis `towerFired`; der
  `FxDirector` lässt die Krone abdrücken bzw. ausstoßen (Architekturregel 3).
- **Daten**: Wo ein Schütze steht und wo die Hutlinie eines Sporenbilds liegt, steht im
  Asset-Vertrag (`art/asset-vertrag.json`, Felder `schuetzen` und `hutLinie` am Turmbild),
  nicht im Code (Regel 7). Die Werte der Bewegung (Drehtempo, Hub, Ladeschein) stehen in
  `FxStyle`, wie alle anderen Darstellungswerte.

### Datenfluss je Bild

```
GameState ─┬─ Simulation.aim(of:in:)  → Ziel-IDs ─┐
           └─ Simulation.charge(of:)  → 0…1 ──────┤
                                                  ▼
BattleScene.sync ── TowerNode.aim(at: Punkte, charge:) ── Krone (Richtung, Schein)
Event towerFired ── FxDirector.arrow/bolt/spores ─ Krone.fire() (Abdrücken, Entladen, Hutstoß)
```

## Wachturm: Schütze (D-185, D-186)

- **Figur**: eigene 3D-Figur nach der Kette von A-3 (FLUX-Vorlage, TRELLIS, `figur.py` mit
  der Vertragskamera, `folge.py` mit Konturpass). Name `tower_guard`.
- **Bildfolgen**: `tower_guard_aim_<r>` (Ruhe im Anschlag, 1 Bild) und
  `tower_guard_shoot_<r>` (4 Bilder: Abdrücken, Rückstoß, Spannen, Anschlag) für acht
  Richtungen `r = 0…7` (0 = rechts, gegen den Uhrzeigersinn in 45°, wie die Sonne im
  Vertrag). Gedreht wird die **Figur** vor fester Kamera und Sonne (D-160), nicht
  gespiegelt: Das Licht kommt dann in jeder Richtung von derselben Seite.
- **Richtung**: Winkel vom Schützen zum Ziel auf dem **Boden** (Szene in Bodenmaß
  zurückgerechnet, die Tiefe ist um 1/sin 40° gestreckt). Die Figur dreht höchstens
  `FxStyle.guardTurnRate` je Sekunde (ein Schütze reißt nicht herum) und wechselt das Bild
  mit einer Spanne von 10° (Hysterese), damit sie an der Grenze zweier Richtungen nicht
  flackert. Ohne Ziel bleibt sie stehen, wo sie zuletzt hinsah.
- **Schuss**: Beim Ereignis spielt die Schussfolge in der aktuellen Richtung; der Pfeil
  startet an der Armbrust (Mündungspunkt je Richtung aus dem Bild), nicht mehr aus der
  Turmmitte. Der Turm selbst staucht nicht mehr.
- **Gestalten**: Stufe 1 und 2 ein Schütze; **Salve** zwei Schützen, der erste nimmt das
  erste Ziel der Salve, der zweite das zweite (gleiche Reihenfolge wie die Simulation);
  **Falkenhorst** ein Schütze auf der Spitze, der Falke bleibt gemalt.
- **Turmbilder**: Die vier Wachturmbilder werden ohne Armbrust neu ausgegeben
  (Bild-zu-Bild aus dem Rohbild mit Maske auf der Plattform, Stärke wie A-5 Teil 1), dann
  `freistellen.py`, `atlas.py`, `turmboden.py` für die Schatten. Herkunft in
  `art/tuerme-zielen/ENTSTEHUNG.md`.
- **Maßstab**: Schütze 0,5 Felder hoch (Turm 1,4, Plünderer 0,8; der Schütze steht
  oben und ist kleiner als ein Gegner, gehört aber erkennbar zur selben Welt).

## Blitzturm: Kristall lädt (D-187)

Kein neues Bild. Der Schein über dem Kristall (`glow`) folgt der Ladung: kaum sichtbar
nach dem Sprung, dann ansteigend, und bei voller Ladung mit ruhigem Flimmern. Ab 70 %
ziehen kleine Funken von außen in den Kristall (aus dem Effektvorrat, nicht wesentlich:
unter Last fallen sie zuerst weg). Beim Sprung entlädt er sich sichtbar (Blitz wie bisher,
Schein fällt auf null). Der Turm staucht nicht mehr. Ohne Gegner bleibt der Kristall voll
geladen und flimmert: Er wartet.

## Sporenturm: Hut hebt sich (D-188)

Kein neues Bild. Das Turmbild bekommt ein Verzerrungsgitter (`SKWarpGeometryGrid`, 2 × 4):
Alles über der Hutlinie hebt sich beim Ausstoß um bis zu 0,12 Felder und setzt federnd
wieder auf, der Stiel darunter dehnt sich mit. Die Hutlinie steht je Bild im Vertrag
(Anteil der Bildhöhe), weil Moorherz und Fäulnis ihren Hut anders tragen. Das leichte
Atmen bleibt beim Pilz: Er lebt, Stein nicht.

## Bedienentscheidungen

- Keine neue Bedienung. Die Zielwahl („erster“, „letzter“, „stärkster“) sieht man jetzt
  ohne Tafel: Der Schütze dreht sich nach dem Umschalten zum neuen Ziel.
- „Weniger Bewegung“ (Bedienungshilfe, `reduceMotion`): Der Schütze wechselt die Richtung
  ohne Drehen, die Schussfolge entfällt, der Hut hebt sich nicht, der Kristall zeigt die
  Ladung ohne Flimmern.

## Sicherheit

Keine Eingabe von außen, kein Netz. Die neuen Felder im Asset-Vertrag prüft `art-check`
(Zahlen im Bild, Schützen innerhalb des Turmbilds). Die Abfragen der Simulation sind rein
und laufen auf dem Hauptfaden wie `sync`. Blender, TRELLIS und FLUX laufen nur im
Entwicklungscontainer; Herkunft jedes Bilds in `ENTSTEHUNG.md`.

## Leistung

Je Bild und Wachturm eine Zielwahl (linear in der Zahl der Gegner, wie ein Schuss), also
bei 12 Türmen und 40 Gegnern rund 500 Abstandsrechnungen: vernachlässigbar neben dem
Zeichnen. Der Probelauf in der CI misst weiter die Bildrate (FX-Probe).

## Tests

| Ebene | Test |
|---|---|
| Simulation | `aim` liefert genau die Ziele des nächsten Schusses (nach einem Schritt mit `towerFired` verglichen), über alle Zielwahlen und die Salve; `charge` ist 0 nach dem Schuss und 1 bereit; beide ändern den Zustand nicht (Prüfsumme gleich) |
| App | `TowerNodeAimTests`: Richtung aus dem Winkel (acht Sektoren, Tiefe gestreckt), Hysterese, Drehtempo; Salve hat zwei Schützen mit getrennten Zielen; Stein staucht nicht; Hut hebt sich und setzt auf; Ladung steuert den Schein |
| App, Szene | über eine ganze Mission 1: in jedem Bild mit Ziel blickt jeder Schütze nach höchstens 0,4 s in den Sektor seines Ziels |
| Bilder | `art-check`: alle 8 × 5 Schützenbilder vorhanden, Größe und Anker nach Vertrag, Herkunft in `ENTSTEHUNG.md`, keine Armbrust mehr in den Wachturmbildern (Name ohne Eintrag `armbrust`) |
| E2E | `TowerAimE2ETests`: Wachturm bauen, Welle rufen, warten, bis die Szene „zielt=1“ meldet und der Schütze in die Richtung des Ziels blickt; nach dem Verkaufen ist kein Schütze mehr da |
| Kontaktabzug | Messung `schuetzenDaneben`: Bilder, in denen ein Schütze mit Ziel länger als 0,5 s woanders hinsieht; Warnung ab 1 % |

## Risiken

- **Schütze zu klein**: 0,5 Felder sind am Gerät rund 22 Punkte. Die Richtung trägt die
  Armbrust, nicht das Gesicht; die Vorlage malt sie groß und hell. Abnahme am Bildpaar.
- **Armbrust aus dem Turmbild entfernen** kann die Plattform verändern. Rückfall: Retusche
  mit Planken desselben Bilds (`retusche.py`).
- **TRELLIS-Kontingent**: war bei A-6 einmal aufgebraucht. Dann wartet nur der Schütze,
  Blitz und Spore können vorher fertig werden.
