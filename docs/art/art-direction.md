# Art-Direction

Status: Stil **[ENTSCHIEDEN]** (Steffen, 25.10.2026, D-016), Rest **[VORSCHLAG]**. Technische
Abmachungen mit der Szene: [asset-vertrag.md](asset-vertrag.md). Rückmeldung je
Ereignis: [rueckmeldung-je-ereignis.md](rueckmeldung-je-ereignis.md).

## Ziel

Oddlings soll auf dem Telefon aussehen wie ein Spiel aus einem großen Studio:
gemalt, plastisch, mit Licht und Charakter. Keine Pixelgrafik, keine
Platzhalterformen, kein Baukasten-3D. Gleichzeitig gilt Säule 2: In jeder
Sekunde muss man auf 6 Zoll sehen, was passiert. Wo Pracht und Lesbarkeit
streiten, gewinnt Lesbarkeit.

## Stil: Muster A „Stylized 3D" [ENTSCHIEDEN]

Gemalte Oberflächen auf plastischen, gedrungenen Formen. Kräftige, satte
Farben, dunkle Kontur um jede Figur, warmes Kantenlicht. Vorlage ist die
Linie der Fortress-Avatare.

Warum A und nicht die Alternativen (Bilder in `art/stilmuster/`):

- **Lesbarkeit.** Die Kontur trennt Figuren vom Boden, auch bei 30 px Höhe und
  voller Welle. Das gemalte Märchenbuch (B) verliert diese Trennung; das
  Diorama (C) lebt von Tiefenunschärfe, die auf dem kleinen Schirm wie ein
  Fehler wirkt.
- **Erprobt.** Werkzeug, Prompts und Nachbearbeitung haben in Fortress zwölf
  Avatare, Welten und Store-Bilder in diesem Stil geliefert.
- **Markt.** Die erfolgreichen TD-Spiele der Marktanalyse liegen alle in
  dieser Familie: gedrungene Proportionen, klare Silhouetten, starke Farben.
  Wir übernehmen die Familie, nicht die Figuren.

## Kamera und Licht

- Eine Kamera für alles: Aufsicht von schräg oben, etwa 45°. Die Karte ist ein
  rechteckiges Raster (D-005), Türme und Figuren stehen darauf in 3/4-Ansicht.
- Licht von oben links, warm. Schatten nach unten rechts, als weiche Ellipse
  unter jeder Figur (von der Szene gezeichnet, nicht ins Bild gemalt).

## Farbwelt

Die Farben tragen Bedeutung. Jede Rolle hat eine eigene Hauptfarbe, damit man
Türme und Gegner ohne Lesen unterscheidet.

| Element | Hauptfarbe | Begründung |
|---|---|---|
| Boden, Wiese | sattes Grün, gedämpft | ruhiger Hintergrund, nichts darauf darf wie ein Hindernis aussehen |
| Weg | warmer Sand | hebt sich vom Grün ab, Gegner laufen darauf |
| Wachturm | graues Gestein, Holz, Rot | neutral, „Grundturm" |
| Blitzturm | Kupfer, leuchtendes Blau | Blitz und Kette sind blau |
| Sporenturm | Violett, leuchtendes Grün | Sporen und Verlangsamung sind grün |
| Plünderer | Grün-Braun, Leder | Referenzgegner |
| Flitzer | Orange, Rot | Warnfarbe für „schnell" |
| Panzerbestie | Eisen, Dunkelbraun | wirkt schwer |
| Festung | Stein, Rot | Spielerfarbe Rot an Bannern |

Grün bedeutet „verlangsamt", Blau „Blitz". Kein anderes Element darf diese
beiden Leuchtfarben tragen. Der Sporenfunke (E2) mischt beide.

## Silhouetten

Jeder Gegnertyp ist am Umriss erkennbar, auch einfarbig: Plünderer klein mit
Sack, Flitzer schmal und vorgebeugt, Panzerbestie breit mit Hörnern. Jeder
Turm hat eine eigene Spitze: Armbrust und Fahne, schwebender Kristall,
Pilzhut.

## Bewegung

Stufe 1 (im Spiel seit 0.10.0, FX 01, D-050): gemalte Einzelbilder, bewegt von der
Szene: Hüpfen und Squash-and-Stretch im Lauftakt, Kippen in Kurven, Aufbau-Effekt
beim Bauen, Aufblitzen bei Treffern. Begründung und Grenzen in
[asset-vertrag.md](asset-vertrag.md#bewegung).

Stufe 2 (in Arbeit, FX 02, D-051): echte Gliedmaßen über 3D-Modelle, die aus unseren
Gemälden entstehen und zu Bildfolgen (Gehen, Treffer, Sturz) gerendert werden.
Zuerst der Plünderer; ob Flitzer und Panzerbestie folgen, entscheidet Steffen am
Bild. Weg und Werkzeuge: [FX 02](../konzepte/fx-02-figuren-in-3d.md).

## Werkzeug

`.claude/skills/spielgrafik/`: FLUX.1-schnell lokal (Apache 2.0),
stable-diffusion.cpp (MIT), Real-ESRGAN (BSD-3), rembg zum Freistellen (MIT,
Modelle Apache 2.0). Keine Kosten, kein fremder Dienst. Jedes Bild hat Prompt
und Seed in einer `ENTSTEHUNG.md`; die CI prüft das.

Ablauf je Asset: beschreiben → mehrere Seeds mit 512 px → ansehen und wählen →
hochrechnen → freistellen → in den Atlas legen (`atlas.py`) → Prüfung
(`tools/art-check`).

Die Karte entsteht anders: `kartenvorlage.py` zeichnet aus der Weggeometrie
eine grobe Vorlage, die dann übermalt wird. So deckt sich der gemalte Weg mit
dem gerechneten.

Kampagnenkarte und Kampfplatz teilen sich dieselben gemalten Teile (Bäume,
Ruinen, Höhle, Boden): `karte_zusammensetzen.py` und `regionscollage.py` für die
Karte (0.10.2), `kampfplatz.py` für die Lichtung um den Weg (0.11.1,
[Grafik 05](../konzepte/grafik-05-kampfplatz.md)). So sehen Karte und Mission wie
ein Ort aus. Avatar-Porträts: `art/avatar/ENTSTEHUNG.md`.

## Grenzen

- Kein gezieltes Nachmalen einzelner Stellen; Figuren werden nachempfunden,
  nicht exakt getroffen. Varianten heißen neue Seeds.
- Keine frame-genauen Animationen aus dem Generator.
- KI-Bilder sind urheberrechtlich schwach geschützt. Nutzen dürfen wir sie,
  andere aber auch nachahmen.
