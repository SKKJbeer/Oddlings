# 07 – Oberfläche und Bedienung

Status: **[VORSCHLAG]**, soweit nicht anders markiert · Stand 25.10.2026

Klickbare Entwürfe aller Schirme (iPhone 15, Querformat 852 × 393 pt):
[Oddlings – Spieloberfläche](https://claude.ai/artifact/PKpZrLVV42wje1isSfvB8z).
Die Entwürfe zeigen Aufteilung, Größen und Abläufe. Grafik ist Platzhalter; die
gemalten Bilder kommen aus dem Asset-Vertrag (`docs/art/asset-vertrag.md`,
Abschnitt „Oberfläche").

Maßstab für alles hier ist die Liste „AAA-Anmutung" der
[Marktanalyse](market-analysis.md#3-was-aaa-anmutung-bei-diesen-spielen-konkret-heißt):
wenige große Knöpfe, jede Handlung mit Bild, Ton und Haptik, Zahlen zählen hoch,
keine Ladezeit zwischen Mission und Ergebnis.

## 1 Grundsätze

1. **Die Karte ist der Bildschirm.** 16 × 9 Felder füllen im Querformat die volle
   Höhe (D-004). Alles andere ist klein, randständig und verschwindet, wenn es
   nicht gebraucht wird.
2. **Lesen oben, Handeln unten.** Im Querformat liegen die Daumen an den unteren
   Ecken. Anzeigen (Leben, Gold, Welle) stehen oben, häufige Knöpfe (Welle rufen,
   Tempo) unten. Pause liegt oben rechts, damit man sie nicht versehentlich trifft.
3. **Wählen am Ort.** Gebaut und verkauft wird direkt am Feld, nicht über eine
   Leiste am Rand (offen als D-031).
4. **Zweimal tippen für Gold.** Alles, was Gold kostet oder bringt, braucht eine
   Bestätigung durch zweites Tippen. Das erste Tippen zeigt die Folge
   (Reichweite, Erstattung). Kein Dialogfenster.
5. **Tippziele ≥ 44 pt**, Knöpfe im Kreismenü 54 pt.
6. **Farbe hat eine Bedeutung** und nie die einzige: Rot = Festung und Leben,
   Blau = Blitz, Grün = Sporen und verlangsamt, Orange = Gefahr und Flitzer, warmes
   Gold = Gold. Jeder Turm hat zusätzlich eine eigene Form. Kontur dunkles Braun
   `#22160F`. Quelle der Farben: `docs/art/art-direction.md`.
7. **Ein Ereignis, eine Rückmeldung.** Jede Bedienhandlung hat Bild, Ton und
   Haptik (Tabelle in Abschnitt 5).

## 2 Raster und Bildschirm

| Gerät | Bildschirm (pt) | Feld (pt) | Randstreifen je Seite | Sicherer Bereich |
|---|---|---|---|---|
| iPhone SE (3. Gen.) | 667 × 375 | 41,7 | 0 | ganzer Schirm |
| iPhone 15 | 852 × 393 | 43,7 | 76,5 | links/rechts je 59 pt, unten 21 pt |
| iPhone 16 Pro Max | 956 × 440 | 48,9 | 87 | links/rechts je 62 pt, unten 21 pt |

Folgerungen:

- **Die Szene skaliert auf volle Höhe**, das Feld ist `Höhe / 9`. Die Karte liegt
  mittig. Auf breiteren Telefonen zeigen die Randstreifen Kulisse: links die
  Höhle, aus der die Gegner kommen, rechts die Festung. Die Karte selbst liegt
  dann vollständig im sicheren Bereich.
- **Auf dem iPhone SE gibt es keinen Rand.** Das HUD muss deshalb auf der Karte
  liegen. Damit es keine Bauplätze verdeckt, reserviert jede Mission vier
  Eckbereiche (**D-030**, vorgeschlagen; Steffen hat am 25.10.2026 entschieden, erst den Spieltest WP-15 abzuwarten: Treten mit der heutigen Kopfleiste Fehltipps auf, kommt der Vorschlag wieder auf den Tisch):

| Ecke | Felder (Mission 1) | Inhalt | Warum dort |
|---|---|---|---|
| oben links | Zeile 0, Spalten 0–3 | Leben, Gold, Welle x/10 | Lesestart, weit weg von den Daumen |
| oben rechts | Zeile 0, Spalte 15 | Pause | schwer versehentlich zu treffen |
| unten links | Zeile 8, Spalten 0–1 | Nächste Welle rufen, mit Countdown-Ring | linker Daumen |
| unten rechts | Zeile 8, Spalte 15 | Tempo 1×/2× | rechter Daumen |

Die Ecken gelten **auf jedem Gerät gleich**. Sonst hätte ein Spieler mit großem
Telefon mehr Bauplätze, und Balancetests wären geräteabhängig.
Mission 1 verliert dadurch 8 von 114 Bauplätzen; der Weg berührt keine Ecke.

Festungsleben steht zusätzlich als kleines Schild an der Festung selbst. Wer auf
den Ausgang schaut, sieht dort, was ein Durchbruch kostet.

## 3 Schirme und Abläufe

```
Hauptmenü ──Spielen──▶ Schlacht ◀──Weiter── Pause
   ▲                     │  ▲                  ▲
   │                     │  └──────────────────┘ (Pause-Knopf)
   │                     ▼
   └──────Menü────── Ergebnis (Sieg / Niederlage) ──Nochmal──▶ Schlacht
Phase 3: Hauptmenü ─▶ Kampagnenkarte ─▶ Schlacht ─▶ Ergebnis ─▶ Karte
```

### Hauptmenü
Gemaltes Bild links, Knöpfe rechts im Daumenbereich: großes „Spielen" (64 pt
hoch), darüber eine Karte „Weiter mit Mission 1" mit Wellenzahl und Dauer, darunter
Einstellungen (Klänge, Musik, Vibration) und Mitwirkende. Unten links „Offline ·
ohne Konto" (Lücke 5 der Marktanalyse). Kein Ladebildschirm, kein Anmeldefenster.

### Schlacht und HUD
Aufteilung siehe Abschnitt 2. Weitere Regeln:

- **Welle rufen** zeigt die Nummer der kommenden Welle und einen Ring, der bis
  zum automatischen Start abläuft (D-009). Während eine Welle noch Gegner
  entsendet, ist der Knopf gedimmt.
- **Tempo** wechselt 1× ↔ 2×, bei 2× goldfarben.
- **Zahlen zählen** bei Änderungen kurz hoch oder runter; Gold blinkt orange,
  wenn ein Kauf daran scheitert; Leben wackeln bei Durchbruch.
- Lebensbalken an Gegnern nur bei Schaden, Verlangsamung als grüner Ring
  (Marktanalyse E3).

### Bauen
1. Freies Feld antippen → Feld wird umrandet, drei Turmknöpfe erscheinen im Bogen
   darüber (in den oberen zwei Zeilen darunter), jeweils mit Preisschild.
2. Turm antippen → Reichweite als gestrichelter Kreis, Vorschau des Turms auf dem
   Feld, Preisschild wird zu „Bauen".
3. Denselben Turm erneut antippen → gebaut. Anderes Feld oder leere Stelle →
   abgebrochen.
- Nicht leistbar: Knopf gedimmt, Schild orange „fehlt 30". Antippen zeigt einen
  kurzen Hinweis und gibt Warnhaptik, öffnet nichts.
- Der Bogen klappt an Rändern nach innen und weicht den HUD-Ecken aus.

### Turm antippen, verkaufen
Reichweite, Infotafel auf der freien Bildschirmseite (Name, eine Zeile Rolle,
eine Zeile Zusammenspiel, z. B. „Macht Blitze stärker") und ein Knopf
„Verkaufen +56". Zweites Tippen verkauft. Die Infotafel ist der erste Ort, an dem
die Kernsynergie in Worten steht; gelernt wird sie aber im Spiel (02).

### Pause
Karte abgedunkelt, Tafel mit Stand (Welle, Leben, Gold). Großer Knopf „Weiter"
rechts im Daumenbereich, links Neu starten, Einstellungen, Aufgeben.
Die App pausiert selbst, sobald sie in den Hintergrund geht.

### Ergebnis
Erscheint als Tafel über der stehenden Karte, ohne Ladezeit.

- **Sieg:** Band „Sieg!", Werte Leben übrig, Dauer, Türme gebaut (zählen hoch,
  enden exakt auf dem echten Wert). Darunter **Kombi-Bilanz** (Phase 2, aus
  Ereignissen gezählt): „23 Blitzsprünge trafen verlangsamte Gegner." Das
  belohnt Säule 1 sichtbar (Marktanalyse E2).
- **Niederlage:** Band „Die Festung ist gefallen", Wellen gehalten, Dauer, besiegte
  Gegner. Darunter **ein** Hinweis, abgeleitet aus dem, was am häufigsten
  durchgebrochen ist (z. B. Flitzer → Sporenturm an der Kurve). So lehrt die
  Niederlage, statt nur zu strafen.
- Primärknopf rechts: „Nochmal spielen" / „Nochmal versuchen". Neustart in unter
  einer Sekunde.
- Sterne kommen erst mit der Kampagne (Phase 3).

### Kampagnenkarte (Phase 3, Richtung)
Gemalte Region, Knoten mit Pfaden, eine Gabelung, eine Nebenmission (Raute),
Bossknoten. Sterne unter erledigten Knoten. Rechts die Missionstafel: Art, Name,
Sterne, kurzer Satz, „Neu: Panzerbestie" (eine Neuheit je Mission, wie in 02
und Marktanalyse 2 „Lehren ohne Text"), Starten unten rechts. Namen im Entwurf
sind Platzhalter. Umfang und Regeln stehen in [05](05-campaign-and-progression.md).

## 4 Architektur

Grundlage sind die Schichten aus [architecture.md](../technical/architecture.md)
und das, was mit 0.5.0 gebaut ist ([Konzept WP-12 bis WP-14](../konzepte/wp-12-14-spielbare-mission.md)).
Die Oberfläche **erzeugt nur Befehle** und **liest nur Zustand und Ereignisse**
(Architekturregeln 2 und 3). Dieser Entwurf baut auf den vorhandenen Bausteinen
auf und legt keinen zweiten daneben.

**Stand 0.5.0:** Kopfleiste über der Karte (Zellen etwa 38 statt 43 pt, als
HYPOTHESE markiert), Baumenü an der Zelle mit zwei Tipps, Ergebnistafel. Dieser
Entwurf führt das weiter zu HUD-Ecken auf voller Kartenhöhe, Kreismenü und den
gestalteten Tafeln.

```
BattleView (SwiftUI, ZStack)
├── SpriteView(BattleScene)        Karte, Türme, Gegner, Effekte, Reichweitenkreis
├── HUD in vier Ecken              ersetzt BattleTopBar, liest BattleController
├── Kreismenü und Infotafel        ersetzt BattleMenu, liest BattleController.selection
├── Hinweise                       abgelehnte Befehle (heute Text an der Stelle)
└── Pause, Ergebnis                ersetzt BattleOverlay
```

| Baustein | Stand | Aufgabe | Test |
|---|---|---|---|
| `BoardLayout` | vorhanden | Karte einpassen, Zelle ↔ Bildschirmpunkt; eine Rechnung für Szene, Menü und Oberflächentest | vorhanden |
| `HudLayout` | **neu**, reine Funktion neben `BoardLayout` | Bildschirmgröße + sichere Ränder + `BoardLayout` → Rechtecke der vier Ecken, Lage des Kreismenüs zu einer Zelle (Umklappen an Rändern und Ecken) | Für SE, 13 mini, 15, 16 Pro Max: Tippziele ≥ 44 pt, Knöpfe im sicheren Bereich, Kreismenü vollständig sichtbar, keine Überlappung mit Ecken |
| `BattleController` | vorhanden | Auswahl (Zelle, Vorschau, Turm), beobachtete Kopien von Gold, Leben, Welle, Countdown, Ergebnis, Pause, Tempo; setzt nur bei Änderung | vorhanden; neu: zweites Tippen beim Verkaufen |
| `UITheme` | **neu** | Farben, Schriften, Radien, Kontur an einer Stelle; Farben laut `art-direction.md`. Löst die UI-Farben in `BattleStyle` ab, Szenenfarben bleiben dort | Farben gleich der Art-Direction |
| `FeedbackPlayer` | **neu** | Haptik und Ton laut Tabelle 5, hängt an Ereignissen und an Controller-Handlungen | Jede Zeile der Tabelle hat einen Eintrag |
| Hauptmenü, Kampagnenkarte | Hauptmenü vorhanden (Startbildschirm), Karte Phase 3 | Navigation; Ergebnis und Pause bleiben Überlagerungen der Schlacht | Oberflächentest Menü → Schlacht → Ergebnis → Nochmal |

Abgelehnte Befehle (zu wenig Gold, Feld belegt) meldet die Simulation als
Ereignis; die Oberfläche zeigt sie nur an und prüft Gold nur lesend zum Dimmen.

Die Mission läuft weiter, während das Kreismenü offen ist (D-019).

## 5 Rückmeldung je Bedienhandlung

| Handlung | Bild | Ton | Haptik |
|---|---|---|---|
| Feld antippen | Umrandung, Bogen springt auf | leises Klicken | Auswahl (`selectionChanged`) |
| Turm vorwählen | Reichweitenkreis, Vorschau | Holzklopfen | Auswahl |
| Bauen | Turm wächst aus dem Boden, Staub, Gold zählt runter | Aufbau je Turm eigen | Stoß mittel |
| Zu wenig Gold | Knopf wackelt, Gold blinkt orange, Hinweis | dumpfer Ton | Warnung |
| Verkaufen | Turm sinkt ein, Münzen fliegen zum Goldzähler | Münzen | Stoß leicht |
| Welle rufen | Band „Welle 5", Ring leert sich | Horn | Stoß schwer |
| Durchbruch | Festung blitzt rot, Leben wackeln | Einschlag | Warnung |
| Sieg / Niederlage | Tafel mit Band | Fanfare / tiefer Akkord | Erfolg / Fehler |

## 6 Zugänglichkeit

- VoiceOver-Beschriftung für jede Zelle („Bauplatz, Zeile 3, Spalte 5"), jeden
  Knopf und den HUD-Status.
- „Bewegung reduzieren" schaltet Hochzählen und Aufspringen ab.
- Menüs folgen der Systemschriftgröße bis zur Grenze der Tafel; das HUD hat feste
  Größen, weil es Teil der Spielgrafik ist.
- Kontrast: Text auf Holz ≥ 4,5 : 1 (Creme `#FFF4DC` auf `#2E1F14`).

## 7 Schrift

Lilita One für Titel, Zahlen und Knöpfe, Nunito für Fließtext. Beide unter der
SIL Open Font License, frei auch für kommerzielle Apps, liegen als Datei in der
App (kein Nachladen, offline). Dieselbe Paarung trägt Stack & Siege.
Eintrag **D-032** (vorgeschlagen).

## 8 Offen

- **D-031** Turmauswahl: Kreismenü am Feld (Empfehlung) oder feste Leiste.
- **D-030** reservierte HUD-Ecken je Mission: wartet auf den Spieltest WP-15 (Fehltipps beobachten).
- Kombi-Bilanz und Niederlagen-Hinweis: Phase 2, nach dem ersten Spieltest.
- Linkshänder-Spiegelung der unteren Ecken: Kandidat für die Einstellungen,
  erst wenn der Spieltest danach fragt.
