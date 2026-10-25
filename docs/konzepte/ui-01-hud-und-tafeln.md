# Konzept: Spieloberfläche nach Entwurf (UI 01)

Status: **[VORSCHLAG]** · Stand 25.10.2026 · Thread „Spieloberfläche und Menüs"
Grundlage: [07-ui-ux.md](../game-design/07-ui-ux.md) (Abschnitte 1 bis 7),
D-019, D-031 (entschieden), D-030 (zurückgestellt), D-032 (vorgeschlagen).
Ob das Paket vor oder nach dem Spieltest WP-15 kommt, entscheidet Steffen
(Empfehlung: vorher, damit der Spieltest die Bedienung misst, die bleibt).

## Ziel

Die Mission sieht und fühlt sich an wie im Entwurf: Kreismenü am Feld,
zweimal tippen für Gold, Holztafeln für Pause und Ergebnis, eine Kopfleiste
mit Symbolen und Countdown-Ring, Haptik zu jeder eigenen Handlung. Die Regeln
bleiben, wie sie sind; kein Simulationscode ändert sich.

## Umfang

**Drin**

| Teil | Ersetzt | Inhalt |
|---|---|---|
| Kreismenü | `BattleMenu` | Freies Feld: drei Turmknöpfe (54 pt) im Bogen, je mit Preisschild; erstes Tippen zeigt Reichweite und Vorschau, zweites baut. Turm: Infotafel (Name, Rolle, Zusammenspiel) auf der freien Seite und Knopf „Verkaufen +N"; erstes Tippen fragt „Sicher?", zweites verkauft |
| Kopfleiste | `BattleTopBar` (Aussehen) | Leben, Gold, Welle x/10 mit Symbolen; „Welle rufen" mit Countdown-Ring; Tempo; Pause. **Bleibt über der Karte**, weil D-030 bis zum Spieltest zurückgestellt ist |
| Pause | Hinweis „Angehalten" | Tafel mit Stand (Welle, Leben, Gold), „Weiter" groß rechts, links „Neu starten" und „Aufgeben" |
| Ergebnis | `ResultCard` | Band „Sieg!" bzw. „Die Festung ist gefallen"; Werte zählen hoch und enden exakt auf dem echten Wert. Sieg: Leben übrig, Dauer, Türme gebaut. Niederlage: Wellen gehalten, Dauer, besiegte Gegner. „Nochmal" rechts, „Menü" links |
| Hauptmenü | `StartView` (Menüteil) | Bild links (Platzhalter bis `ui_keyart_menu`), „Spielen" 64 pt rechts, darunter Vorführung; Leistungsprobe bleibt, bis WP-01 gemessen ist |
| Haptik | – | Tabelle aus 07, Abschnitt 5, ohne Ton (Ton kommt mit K9) |
| Rückmeldung | – | Gold blinkt orange und Warnhaptik bei zu wenig Gold; Leben wackeln bei Durchbruch |

**Nicht drin**

- HUD-Ecken auf der Karte (D-030, wartet auf WP-15).
- Kombi-Bilanz und Niederlagen-Hinweis (Phase 2, nach dem Spieltest).
- Alles aus 07, Abschnitt 8 (Phase 2: Aufwerten, Bank, Steinregen).
- Schriftdateien Lilita One und Nunito: erst nach D-032. Bis dahin
  `.rounded` in Schwer bzw. Fett aus der Systemschrift, an einer Stelle im
  Theme, damit der Tausch eine Zeile ist.
- Ton, Musik.

## Architektur

```
Simulation ──Ereignisse──▶ BattleModel ──▶ BattleController ──Kopien──▶ SwiftUI-Ansichten
   ▲                                        │   ▲                         │
   └──────────── Befehle ◀──────────────────┘   └────── Aufrufe ──────────┘
                                            │
                                            └──Ereignisse──▶ FeedbackPlayer (Haptik)
```

| Baustein | Ort | Darf | Darf nicht |
|---|---|---|---|
| `BattleController` (erweitert) | `App/Battle/` | Auswahl führen (neu: `tower(id:, sellArmed:)`), Kopien setzen, Ereignisse zählen (Türme gebaut, besiegte Gegner) für das Ergebnis, Befehle einreihen | Spielzustand ändern |
| `HudLayout` (neu, rein) | `App/Battle/HudLayout.swift` | aus `BoardLayout`, Bildschirmgröße, sicheren Rändern und Höhe der Kopfleiste die Rechtecke des Kreismenüs und der Infotafel rechnen (Umklappen an Rändern, oben unter der Leiste) | SwiftUI importieren; nur CoreGraphics und OddlingsCore, damit es ohne Ansicht testbar ist |
| `RingMenu` (neu) | `App/Battle/` | `HudLayout` zeichnen, Controller aufrufen | eigene Positionsrechnung (eine Quelle: `HudLayout`) |
| `UITheme` (neu) | `App/UI/UITheme.swift` | Farben (aus art-direction.md), Größen, Schrift, Tafel- und Knopfstil | Spielwerte enthalten (Regel 7) |
| `WoodPanel`, `GoldButton`, `WoodButton` (neu) | `App/UI/` | Tafel und Knöpfe; nimmt `ui_panel_wood`, `ui_button_*` aus `UI/` im Katalog, sonst gezeichnete Form im selben Maß | Bilder aus dem Netz laden |
| `FeedbackPlayer` (neu) | `App/UI/FeedbackPlayer.swift` | Ereignis bzw. Handlung → Haptik-Art (reine Zuordnung) und Abspielen über UIKit | in die Szene oder den Zustand greifen |
| `BattleScene` | unverändert | | |

- **Eine Quelle für Lage:** `BoardLayout` (Karte) und `HudLayout` (Menüs). Die
  E2E-Tests tippen weiter über `BoardLayout`.
- **Bilder mit Rückfall:** Jede Ansicht fragt nach dem Namen aus dem
  Asset-Vertrag (Abschnitt „Oberfläche"). Fehlt das Bild, zeichnet sie die
  Form aus dem Entwurf. So kann das Paket vor den UI-Bildern ausgeliefert
  werden, und der Tausch ist ein Katalog-Wechsel.
- **D-019 bleibt:** Die Mission läuft, während das Kreismenü offen ist.
- **Bedienkennungen bleiben** (`hud.gold`, `hud.lives`, `hud.wave`,
  `hud.nextWave`, `hud.speed`, `hud.pause`, `hud.back`, `battle.menu`,
  `build.<turm>`, `sell`, `result`, `result.title`, `result.again`,
  `result.back`, `menu.play`, `menu.watch`). Neu: `pause.card`,
  `pause.resume`, `pause.restart`, `pause.quit`, `sell.confirm`.

## Bedienentscheidungen

Alle aus 07, hier nur, was beim Bauen auffällt:

- Verkaufen bekommt das zweite Tippen (Grundsatz 4). Heute verkauft ein Tipp.
  Ein Tipp neben das Menü bricht ab, wie beim Bauen.
- „Aufgeben" in der Pause führt zur Niederlage-Tafel, nicht still ins Menü:
  Man sieht, wie weit man gekommen ist. Das ist Darstellung: Die Mission bleibt
  angehalten, die Simulation bekommt keinen Befehl, und der Spielstand meldet
  kein Ergebnis, das sie nicht gerechnet hat.
- Die Kopfleiste bleibt 40 pt hoch und über der Karte (D-030). Dafür liegt
  das Kreismenü nie unter ihr: `HudLayout` klappt es dort nach unten.
- „Bewegung reduzieren": kein Hochzählen, kein Aufspringen, Werte stehen sofort.

## Sicherheit

- Keine neue Bibliothek, kein Netz, keine neuen Rechte.
- Bilder nur aus dem App-Katalog. Schriftdateien kommen erst mit D-032 und dann
  mit Lizenzdatei (OFL) und Herkunft in `ENTSTEHUNG.md`.
- Der Controller nimmt weiter nur die bekannten Befehle; die Oberfläche bekommt
  keinen Zugriff auf `GameState` außer zum Lesen.

## Testplan

Jeder neue Test wird einmal rot gesehen.

| Ebene | Test |
|---|---|
| `AppTests/HudLayoutTests` (neu) | Für iPhone SE, 13 mini, 15, 16 Pro Max und **jede** Bauzelle und jeden Turmplatz von Mission 1: alle Knöpfe ≥ 44 pt, ganz im sicheren Bereich, nicht unter der Kopfleiste, nicht übereinander, Infotafel überdeckt weder Knöpfe noch die gewählte Zelle; Umklappen in Zeile 0 und 1 |
| `AppTests/BattleControllerTests` (erweitert) | Verkaufen braucht zwei Tipps, Tipp daneben bricht ab; Zähler „Türme gebaut" und „besiegte Gegner" folgen den Ereignissen; Dauer aus `tick` und Takt; Neustart setzt Zähler zurück; Aufgeben hält die Mission an und zeigt die Niederlage-Tafel mit dem aktuellen Stand, ohne neuen Befehl an die Simulation |
| `AppTests/FeedbackPlayerTests` (neu) | jede Handlung und jedes Ereignis der Tabelle bildet auf die richtige Haptik ab; Treffer ergeben keine Haptik |
| `AppUITests` (angepasst) | Bauen per Kreismenü (zwei Tipps), Verkaufen mit Bestätigung, Pause-Tafel Weiter und Neu starten, Ergebnis mit Werten, Nochmal; bestehende Tests laufen mit den alten Kennungen weiter |
| Probelauf | Bildschirmfotos im Simulator (Schlacht, Kreismenü offen, Pause, Ergebnis) als CI-Artefakt, zum Vergleich mit dem Entwurf |

## Schritte (ein PR, eine Version)

1. `HudLayout` mit Tests.
2. `UITheme`, Tafel und Knöpfe.
3. Kreismenü und zweites Tippen beim Verkaufen.
4. Kopfleiste.
5. Pause- und Ergebnistafel, Zähler im Controller.
6. `FeedbackPlayer`.
7. Hauptmenü.
8. Dokumente nachziehen (07, Backlog, CHANGELOG), Version 0.6.0, Bau in TestFlight.

## Abstimmung

- Haupt-Thread: `BattleController` und `AppUITests` werden mitgeändert; keine
  Änderung in `Packages/`.
- Grafik-Thread: UI-Bilder nach dem Asset-Vertrag, Abschnitt „Oberfläche";
  bis dahin gezeichnete Formen.

## Risiken

- **Kreismenü verdeckt den Weg** über engen Kurven: `HudLayout` legt den Bogen
  auf die Seite mit weniger Weg; der Spieltest beobachtet es.
- **Gezeichnete Holztafeln wirken billig**, bis die Bilder da sind: Sie sind ein
  Übergang, kein Stand für den Laden.
