# Konzept: Gemalte Grafik für das Spielfeld (Grafik 01)

Status: umgesetzt in 0.5.2 · Stil D-016 · Thread „AAA-Grafik und Art-Direction"

## Ziel

Der Bau auf dem iPhone zeigt statt Platzhalterformen gemalte Türme, Gegner,
Festung und Boden im gewählten Stil. Der Tausch geschieht ohne Regeländerung
und ohne neue Abhängigkeit im App-Bundle.

## Umfang

- Drin: `tower_watch`, `tower_lightning`, `tower_spore`, `enemy_raider`,
  `enemy_runner`, `enemy_brute`, `fortress`, `map_mission01_ground`.
- Nicht drin: Effekte (`fx_*`), Zustandssymbol, UI-Bilder, Laufanimation,
  Turmdrehung. Sie folgen in eigenen Schritten nach
  [rueckmeldung-je-ereignis.md](../art/rueckmeldung-je-ereignis.md).

## Architektur

```
Prompt + Seed ─► FLUX (lokal) ─► Rohbild ─► freistellen.py ─► atlas.py ─► Battle.spriteatlas
                                   │                              │
                                   └─ art/**/ENTSTEHUNG.md         └─ art/asset-vertrag.json
Weggeometrie (mvp-mission-01.json) ─► karte_zusammensetzen.py ─► Bild-zu-Bild ─► map_mission01_ground
```

- **Eine Quelle für Maße:** `art/asset-vertrag.json` (Seite in Zellen,
  Ankerhöhe). `atlas.py` setzt die Bilder danach, `tools/art-check` prüft sie,
  `BattleStyle` hat dieselben Werte für die Szene. Text dazu:
  [asset-vertrag.md](../art/asset-vertrag.md).
- **Szene:** `BattleSprites` lädt nach Namen und fällt ohne Bild auf die
  Platzhalterform zurück (seit WP-11). Neu: Turmbilder als Quadrat mit
  `towerSpriteSide`, Festung als Bild, gemalter Boden ersetzt die gezeichnete
  Weglinie. Bauzonen bleiben als Overlay. Architekturregeln 1–3 unberührt:
  Nichts davon liest oder ändert Simulationszustand außer Positionen.
- **Karte:** Der Weg wird nicht frei gemalt, sondern aus der Geometrie
  zusammengesetzt; nur so deckt sich der gemalte Weg mit dem gerechneten.

## Entscheidungen

- Stil: D-016 (Steffen).
- Figuren ohne gemalte Laufzyklen, Bewegung prozedural in der Szene
  **[VORSCHLAG]**, Begründung im Asset-Vertrag.
- Türme 1,9 Zellen Bildseite (sichtbar ≈ 1,5), Gegner 0,9 (Panzerbestie 1,2) **[HYPOTHESE]**: groß genug für
  Charakter, klein genug, dass Nachbarn sich nicht verdecken. Prüft der
  Spieltest (WP-15).

## Sicherheit

- Keine neue Bibliothek in der App, keine Netzverbindung, nur PNG und JPEG im Katalog.
- Werkzeuge laufen nur auf dem Entwicklungsrechner, nicht in der App.
- Lizenzen: alle verwendeten Modelle kommerziell frei; die CI weist eine
  `ENTSTEHUNG.md` ab, die ein nicht-kommerzielles Modell nennt.

## Tests

| Ebene | Test |
|---|---|
| Pipeline (CI-Job `art`) | `tools/art-check/tests`: Atlas gegen Vertrag (Namen, @2x/@3x, Quadrat, Fußhöhe, Alpha, Ecken, Dateigröße, Herkunft, Lizenz), Vertrag kennt alle IDs der Simulation, Kartenvorlage legt den Weg auf die Geometrie |
| Atlas (CI-Job `art`) | `check_assets.py` gegen das echte Repo |
| Darstellung (`AppTests/BattleSpritesTests`) | jedes Bild im Katalog gefunden, Turm als Quadrat mit Anker, Boden deckt genau die Karte, Weglinie entfällt mit gemaltem Boden |
| Bestehend | `BattleSceneTests`, E2E-Tests in `AppUITests` (tippen über `BoardLayout`, unverändert) |
