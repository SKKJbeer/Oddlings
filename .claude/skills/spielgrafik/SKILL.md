---
name: spielgrafik
description: Hochwertige Spielgrafik (App-Symbole, Figuren, Store-Bilder, Hintergruende, Werbegrafik) im Stil grosser Mobile-Games erzeugen — lokal mit FLUX.1-schnell, ohne Kosten und ohne fremden Dienst. Verwenden, wenn ein Projekt ein neues App-Symbol, eine Illustration oder ein anderes Grafikelement braucht, das professionell und nicht nach Baukasten-3D oder Pixelgrafik aussehen soll.
---

# Spielgrafik mit FLUX (lokal)

> Aus Stack & Siege übernommen und für Oddlings ergänzt (25.10.2026): Sprites
> für ein Spielfeld (freistellen, Kontur, Atlas), Karten entlang einer
> Weggeometrie und eine CI-Prüfung. Stil und Abmachungen mit der Szene:
> `docs/art/art-direction.md`, `docs/art/asset-vertrag.md`.

## Oddlings: Sprites und Karten

- **Konzept zuerst:** Jede Figur bekommt ein Blatt in `docs/art/figuren.md`
  (Rolle, Silhouette, Farben, Bewegung, was sie nicht zeigen darf), dann erst
  den Prompt.
- **Sprites** auf `plain flat light grey background` malen, dann
  `freistellen.py` (rembg, isnet-general-use; schneidet zu und zieht eine
  Kontur #22160F, 0,9 % der Höhe) und `atlas.py <frei.png> <name> <höhe_zellen>`.
  `$SPIELGRAFIK_HOME/rv/bin/python -I` nehmen (eigene Umgebung mit rembg).
- **„facing right" wirkt nicht**: Figuren blicken meist nach links. Spiegeln,
  nicht neu rechnen.
- **Karten:** NICHT frei malen und nicht per Bild-zu-Bild mit hoher Stärke —
  0,7 machte aus rechten Winkeln Schlangenlinien und legte Steine auf den Weg.
  Stattdessen Gras- und Sandtextur malen, störungsfreie Ausschnitte nehmen,
  `karte_zusammensetzen.py` legt sie entlang `map.path`, danach ein
  Bild-zu-Bild-Lauf mit geringer Stärke (`INIT=… STAERKE=0.35 erzeugen.sh`).
  Texturen bekommen trotz „no objects" Steine und Baumstümpfe: zuschneiden.
- **Regionskarte (Knoten an festen Lagen):** Bild-zu-Bild über eine Vorlage
  trifft die Lichtungen nie (26.10.2026, Stärke 0,3 bis 0,6, 4 bis 16
  Schritte, auch mehrere leichte Durchgänge). Stattdessen Teileblätter malen
  (`sprite sheet of six separate … each isolated on a plain white background`),
  mit `zerlegen.py` in Einzelteile schneiden (Teile am Bildrand fallen weg) und
  `regionscollage.py` setzen lassen: Boden, Wege auf der App-Kurve, Teiche und
  Ruinen an die Lichtungsränder, Höhle über die Bossmedaille, Bäume zuletzt um
  alles herum. Mit fünftem Argument zeichnet es die Medaillen in App-Größe ein.
  Bäume malt FLUX trotz „seen from above" schräg mit Stamm; das passt zum
  Märchenkarten-Stil und bleibt so. Blätter in 768, 1024 läuft über den Speicher.
- **Prüfung:** `python3 tools/art-check/check_assets.py` und
  `python3 -m unittest discover -s tools/art-check/tests` (laufen in der CI).
  Jedes Atlas-Bild braucht seinen Namen in Backticks in einer
  `art/**/ENTSTEHUNG.md`.

Erprobt bei Stack & Siege (App-Symbol v3.119.0). Ergebnis auf Augenhoehe mit
handgemalter Mobile-Game-Grafik — deutlich besser als selbstgebautes
three.js/SVG (beides versucht, beides wirkte „billig 3D" bzw. „Baukasten").

## Was NICHT funktioniert hat (nicht wiederholen)
- **SVG/Vektor von Hand**: sauber, aber amateurhaft.
- **three.js mit PBR, Bloom, Toon-Shading, Konturen**: wirkt wie ein
  einfaches Blender-Set. Zu wenig Detail, egal wie viel Licht.
- **Kostenlose Online-Generatoren ohne Schluessel** (z. B. pollinations):
  fallen auf schwache Modelle zurueck, Wasserzeichen, 768 px.

## Werkzeuge und Lizenzen (alle kommerziell frei)
| Teil | Lizenz | Zweck |
|---|---|---|
| FLUX.1-schnell (GGUF Q4_0, second-state) | Apache 2.0 | Bild erzeugen |
| stable-diffusion.cpp | MIT | laeuft auf der CPU |
| Real-ESRGAN x4plus anime 6B | BSD-3 | 512 → 2048 hochrechnen |

Nie FLUX.1-dev, SDXL-Turbo oder SD-Turbo nehmen — nicht-kommerzielle Lizenz.

## Ablauf

1. **Einrichten** (einmal je Maschine, ~10 GB, ~5 Min):
   `bash .claude/skills/spielgrafik/scripts/einrichten.sh`
   Ziel: `$SPIELGRAFIK_HOME` (Vorgabe `~/.cache/spielgrafik`). Im
   Cloud-Container den Scratchpad nehmen — nichts davon gehoert ins Repo.
   **Rauchtest vor jedem langen Lauf:** `bash scripts/erzeugen.sh /tmp/t.png 1 test 64x64`
   muss ein Bild liefern. Stirbt `sd-cli` still (Exit 132 = SIGILL), war es
   fuer einen anderen Prozessor gebaut — `einrichten.sh` erneut laufen lassen,
   es baut dann portabel neu (ist bei Stack & Siege nach einem
   Container-Wechsel genau so passiert: drei Laeufe „fertig", null Bilder).
2. **Beschreibung schreiben** (Englisch, siehe Regeln unten).
3. **Varianten erzeugen — immer 512 px, mehrere Seeds:**
   `bash scripts/erzeugen.sh <ausgabe.png> <seed> "<prompt>" [512 | BxH]`
   Hochformat (Ladebild, Store-Bild): `576x1024`, Kanten durch 64 teilbar,
   dauert ~2,3x so lang.
   Dauer auf 4 CPU-Kernen: **~10 Min je Bild**. 1024 direkt kostet ~40 Min
   und bringt nichts — hochrechnen ist schneller und schaerfer. Drei Seeds
   nacheinander im Hintergrund laufen lassen, nicht parallel (alle Kerne
   sind schon belegt).
4. **Ansehen und auswaehlen.** Jedes Bild WIRKLICH anschauen: Text-Artefakte,
   religioese Symbole (ein Kreuz auf der Turmspitze kam vor), seltsame
   Anatomie (Zaehne unter dem Schnabel), Rahmen/abgerundete Ecken im Bild.
   Dem Nutzer mehrere zeigen, mit `scripts/vorschau.py` (iOS-Rundung und
   kleine Groessen — viele Motive kippen erst bei 40 px).
5. **Hochrechnen:** `bash scripts/hochskalieren.sh <in.png> <out-1024.png>`
6. **Herkunft festhalten:** Prompt, Seed, Modell, Schritte, Groesse in eine
   `ENTSTEHUNG.md` neben die Vorlage. Ohne Seed+Prompt ist ein Bild nicht
   reproduzierbar, und FLUX kann ein Bild nicht „ein bisschen aendern".
7. **Ausspielen** (bei Symbolen): `python3 scripts/symbole.py vorlage.png ...`
   erzeugt iOS (1024, OHNE Alphakanal — Apple lehnt sonst ab, und zwar erst
   NACH dem Hochladen per Mail), PWA (gerundet), maskable (vollflaechig),
   Play (512) und ein Favicon-SVG mit eingebettetem PNG.

8. **Ladebild/Startschirm** (Hochformat `576x1024` erzeugen, auf `2304x4096`
   hochrechnen mit `hochskalieren.sh in.png out.png 1152x2048`): `python3
   scripts/ladebild.py vorlage.png --web public/ladebild.jpg --ios
   ios/.../Splash.imageset/splash.png`. Web als JPEG (leicht), iOS als PNG
   ohne Alpha.

## Prompt-Regeln
- Stil-Anker: `mobile strategy game app icon artwork, stylized 3D cartoon
  render, hand-painted textures, vibrant saturated colors, bold dark outlines,
  warm rim light, highly detailed`.
- **Immer**: `full bleed square illustration filling the entire image, no
  border, no rounded corners, no frame` — sonst malt FLUX selbst eine
  Icon-Kachel mit weissem Rand, und iOS rundet dann doppelt.
- **Immer**: `no text, no letters`.
- **Keine Marken- oder Spielenamen** in der Beschreibung (Store-Richtlinie,
  Verwechslungsgefahr). Den Stil beschreiben, nicht das Vorbild nennen.
- Figur zuerst und konkret (Kleidung, Farben, was sie haelt), dann
  Hintergrund, dann Licht. Projektfarben ausdruecklich nennen.
- **Hoechstens 4–5 Figuren je Bild.** Bei 8+ Figuren verschmilzt FLUX sie
  (Pferdekopf auf Monster, Maske als Turm, Laterne ohne Traeger) — gemessen
  bei Stack & Siege, 5 Laeufe. Hauptfigur ausdruecklich „center foreground,
  large" nennen, sonst faellt ausgerechnet sie weg.
- Bildaufbau in Haelften beschreiben („Upper half: …", „Lower half: …") —
  das hat die Burgschlacht erst zuverlaessig ins Bild gebracht.
- Gegen religioese Symbole hilft nur Ansehen und Verwerfen (Kreuze auf
  Turmspitzen kamen zweimal vor).
- FLUX.1-schnell: `--cfg-scale 1.0 --steps 4 --sampling-method euler`.
  Mehr Schritte verbessern schnell nichts.

## Viele Bilder auf einmal

`scripts/schlange.sh liste.txt ausgabe/ seed groesse` — je Zeile `name|prompt`,
fertige Bilder werden uebersprungen (nach einem Neustart einfach erneut
aufrufen), am Ende prueft sie, ob WIRKLICH alle da sind. Auf vier CPU-Kernen
rechnet ein 512er-Bild rund 20 Minuten, ein 384er rund 12 — Stapel ueber
Stunden im Hintergrund laufen lassen (`setsid nohup … &`) und zwischendurch
Gruppen ansehen, nicht erst am Ende.

## Nachbearbeitung: Fremdkoerper und Stoerer entfernen

Das Modell haelt sich nicht immer an „no buildings / no water": Bei
Spielfeld-Boeden kamen Haeuser, Kisten, Kugeln (lasen sich wie
Kanonenkugeln), Baeche (Verwechslung mit dem Fluss) und leuchtende Linien
(wirken wie Grenzen). JEDES Bild in Spielgroesse ansehen, dann:

- `scripts/retusche.py ein aus "x0,y0,x1,y1:sx,sy" ...` — Flicken aus dem
  SELBEN Bild, farblich an den Rand des Ziels angeglichen; `RAND=20` fuer
  weiche Kanten. Kasten grosszuegig um den Fremdkoerper legen.
- `scripts/umfaerben.py ein aus "h0,h1,smin:hNeu,sFaktor,vFaktor" ...` —
  Farbton-Bereich umfaerben (Kugeln → Moos, Bach → Moorwasser, Leuchten →
  Plattenfarbe). Erst breit pruefen, dann eng nachziehen.
- `scripts/glut.py ein aus staerke vFaktor sFaktor` — Leuchten (rot/orange)
  daempfen, z. B. Lava, die mit einem Lavafluss konkurriert.
- `scripts/risse.py ein aus staerke [fenster]` — dunkle Linien zur
  Umgebungsfarbe ziehen (Risse, die wie Grenzen wirken).

Rohbild UND Ergebnis aufbewahren und die Eingriffe in `ENTSTEHUNG.md`
festhalten. Lieber retuschieren als neu rechnen, wenn ein Bild 20–45 Minuten
kostet.

## Spielfeld-Hintergruende beruhigen

Ein Hintergrund, auf dem gespielt (gebaut, gezogen) wird, darf nichts zeigen,
was wie ein Hindernis aussieht. Gemalte Steine, Bueschel und Laub sind dafuer
zu plastisch. `scripts/beruhigen.py ein aus 0.7 4 0.62 0.82` (Anteil scharf,
Weichzeichner-Radius, Kontrast, Saettigung) macht sie flacher, ohne das Bild
unscharf wirken zu lassen. Starke Weichzeichnung sieht billig aus — die
plastische Schattierung ist das Problem, nicht die Kante. Im Spiel ansehen,
nicht im Kleinbild.

## Verneinungen wirken kaum

„no dollar signs" malte zweimal Dollarmuenzen — das Wort zieht das Motiv an.
Unerwuenschtes nicht verbieten, sondern das Motiv so beschreiben, dass es gar
nicht vorkommt (Muenzen → „goldene Sterne, Funken, Nuggets"). Fuer Spiele
ohne Echtgeld: keine Muenzen mit Waehrungszeichen, keine Geldkoffer.

## Grenzen (dem Nutzer ehrlich sagen)
- Kein gezieltes NEUMALEN einzelner Stellen (kein Inpainting). Kleine
  Fremdkoerper lassen sich wegretuschieren oder umfaerben (siehe oben);
  alles, was das Motiv traegt, braucht einen neuen Seed.
- Figuren aus dem Spiel werden nachempfunden, nicht exakt getroffen.
- KI-Bilder sind urheberrechtlich schwach geschuetzt; nutzen darf man sie.

## Vorgaben des Betreibers
- Grafik fuer dieses und andere Projekte kuenftig auf diesem Weg erstellen.
- Keine Emojis in UI-Grafik, keine Verweise auf aeltere Spiele.

### Keyart und Menübilder (Oddlings, 26.10.2026)

Bild-zu-Bild über eine flach gezeichnete Vorlage mit eingesetzten Figuren ergibt
flache Flash-Optik (Stärke 0,45 und 0,55 verworfen); reines Text-zu-Bild malt
eigene Türme und Gegner, die nicht zum Spiel passen. Bewährt: den Hintergrund
ohne Figuren und Gebäude malen lassen und die freigestellten Spielfiguren mit
Schatten und Farbangleichung darüber setzen, wie bei den Menüs der Marktführer.
Umgesetzt in `scripts/titelbild.py`. Die Figuren dafür aus den `*-frei.png` des
Spielfelds hochrechnen (RGB auf Konturfarbe, Real-ESRGAN, Alpha per Lanczos), nicht
die Rohbilder neu freistellen: rembg verlor beim Blitzturm die Funkenbögen.
Freistellen braucht die eigene Umgebung (`$SPIELGRAFIK_HOME/../rv/bin/python`), mit
dem System-Python fehlt rembg still.

**Bild-zu-Bild bei großen Bildern (gemessen 26.10.2026):** Flux schnell kippt
zwischen „Vorlage bleibt flach“ und „eigene Szene“: bei 4 Schritten schon ab
Stärke 0,3 (1024 × 576), bei 8 Schritten zwischen 0,25 (2 Restschritte, flach) und
0,4 (3 Restschritte, Vorlage weg), bei 16 Schritten ist 0,3 noch flach.
`SCHRITTE` und `VERSCHIEBUNG` in `erzeugen.sh` sind dafür da; die Verschiebung
allein half nicht. Für Karten mit festen Knotenlagen deshalb lieber eine Vorlage,
die schon nach Malerei aussieht.
