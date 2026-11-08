# Konzept: Kampfplätze für Mission 6a und 6b (Grafik 08)

Status: **umgesetzt in 0.28.1** · Stil D-016 · Thread „Kampfplätze für Mission 5 und 6 malen"
Anlass: Mission 6a „Sumpfpfad II“ und 6b „Ruinen II“ sind seit 0.27.0 (P3-3) spielbar,
bisher auf der schlichten Karte. Vorgehen wie [Grafik 07](grafik-07-kampfplaetze-m5.md);
dieses Dokument nennt nur, was neu ist.

## Ziel

Der zweite Schritt auf jedem Ast soll tiefer hineinführen: in 6a weiter ins Moor, in 6b
weiter in den Tempel. Man soll die Karte sofort ihrem Ast zuordnen können und trotzdem
sehen, dass es ein neuer Ort ist. Die Qualität entspricht M1 bis M5.

## Wer was festlegt

| Was | Wer |
|---|---|
| Wege, Feldgröße, Bauzonen | `mission-06a.json` und `mission-06b.json` (P3-3, 0.27.0). Sie übernehmen die Vorschläge aus diesem Thread wörtlich (`art/karten/wegvorschlaege/`) |
| Bild, Rand, Deko, Licht | dieser Thread |

Missionsdateien, Simulation und App-Code ändern sich durch dieses Paket nicht.
Ursprünglich als 0.27.1 abgesprochen. Mission 7 (0.28.0) kam zuerst auf main, deshalb wird es 0.28.1.

## Die zwei Orte

| Mission | Ort | Rand-Deko (neues Teileblatt) | Licht |
|---|---|---|---|
| M6a | **Tiefes Moor**: Mangroven und Trauerweiden statt toter Bäume | Mangrove mit Bogenwurzeln, leuchtende blaue Pilze, halb versunkener Steinkopf, hohler Stamm, Moortümpel mit leuchtenden Seerosen, Trauerweide (dazu Schilf und Laterne aus M5a) | Mondnacht, kühl blaugrün, Nebel, einzelne leuchtende Punkte |
| M6b | **Tempelplatz**: das Innere des Tempels, dessen Hof M5b war | Kristallgruppe (türkis leuchtend), Feuerschale, eingestürzte Wand mit Relief, zerbrochene Treppe, Altar, Säule mit Efeu | Mondlicht mit warmen Feuerinseln und türkisem Kristallschein |

Sie grenzen sich wie folgt ab:
- M5a war grünliche Dämmerung mit toten Bäumen. M6a ist Nacht mit lebenden, nassen Bäumen.
- M4 war warm, M5b kühl violett. M6b ist Nacht mit zwei Lichtfarben, Feuer und Kristall.

Auch nachts muss das Feld hell genug bleiben, um Türme, Gegner und Weg sicher zu
erkennen. Deshalb kommt die Nacht nur über Farbton und Rand-Abdunklung ins Bild, das
Feld selbst bleibt deutlich heller als der Rand. Prüfmaß: In der Vorschau mit Figuren
(`vorschau.py`) bleiben Gegner und Weg so gut lesbar wie in M5.

### Wege (aus den Missionsdateien)

- **M6a** (doppeltes S, 34 Zellen):
  `[[-1,7.5],[3.5,7.5],[3.5,1.5],[8.5,1.5],[8.5,7.5],[13.5,7.5],[13.5,3.5],[17,3.5]]`
- **M6b** (Z-Schlange, 42 Zellen):
  `[[-1,1.5],[12.5,1.5],[12.5,4.5],[3.5,4.5],[3.5,7.5],[17,7.5]]`

## Architektur

Unverändert aus Grafik 06 und 07: Name aus der Missionskennung
(`map_mission06a_ground`, `map_mission06b_ground`), 24 × 13 Zellen, 3096 × 1677 px @3x,
JPEG in `App/Assets.xcassets/Maps`, Vertragseintrag mit `mission`. Das Werkzeug ändert sich nicht.
Prompts, Seeds und Schritte stehen in `art/karten/ENTSTEHUNG.md`.

## Tests

- `tools/art-check`: Für jede Karte im Vertrag wird geprüft, dass Weg und Wald richtig liegen.
  Für M6a und M6b wird diese Prüfung einmal rot gesehen (Bild mit dem Weg von M5a).
- `test_wegvorschlaege_sind_spielbar` umfasst die neuen Vorschläge.
- App: `testEveryBundledMissionHasItsPaintedGround` umfasst `mission-06a` und `mission-06b`.
- Vor der Abgabe beide Karten in einer Szene mit Türmen, Festung und Gegnern ansehen.

## Risiken

- **Nacht zu dunkel.** Lieber Dämmerung als unlesbare Gegner. Notfalls hebt `LICHT` an, und
  der Prompt sagt „bright moonlight“.
- **Leuchtende Teile im Feld.** FLUX verteilt Leuchtpunkte gern über die Wiese. Die werden
  wie in M5a mit `retusche.py` entfernt, weil sie wie Effekte oder Gegner wirken würden.
- **Mission 7 folgt.** Der Wegvorschlag für die Bosslichtung liegt beim Mission-Thread. Ihr Kampfplatz
  ist ein eigenes Paket nach diesem.
