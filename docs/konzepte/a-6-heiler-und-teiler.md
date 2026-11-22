# Konzept: Moorhexe und Pilzbalg, Heiler und Teiler (A-6, Teil Gegner)

Stand 17.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-143 (zwei neue Gegnerrollen, entschieden), [Leveldesign, Gegnerrollen](aaa-leveldesign.md#gegnerrollen-d-143),
[Gesamtbild](gamedesign-gesamtbild.md) (D-146 Sägezahn, kennenlernen → prüfen → verbinden),
[Marktanalyse](../game-design/market-analysis.md) Abschnitt 3 („Gegner mit Persönlichkeit“)
und E3, E11. Entscheidungen dieses Pakets: D-175 bis D-179.

## Ziel

Ab Mission 4 stellt Region 1 keine neue Frage mehr; drei Gegner sind gelöst (Masse →
Blitz, Tempo → Sporen, Panzer → Einzelschaden). Zwei neue Rollen geben den
Spezialisierungen aus M5 und M6 einen Grund:

| Rolle | Gegner | Fordert | Antwort |
|---|---|---|---|
| Heiler | **Moorhexe** (`witch`) | Fokus: zuerst sie | Zielwahl „Stärkster“, Falkenhorst, Steinregen (betäubt sie), Fäulnis verstärkt den Schaden auf die Gruppe |
| Teiler | **Pilzbalg** (`puffball`) | Schaden nach dem Tod, an einer zweiten Stelle | Blitzkette und Salve über die Sporlinge, Sporenturm hinter dem Ort des Todes |

## Regeln

### Heilen (D-175)

`EnemyConfig.heal = { radius, interval, share }` (Werte in der Missionsdatei, D-143:
1 Feld, 2 s, 6 %).

1. Alle `interval` Sekunden heilt jede lebende Moorhexe **jeden anderen** lebenden Gegner
   im `radius` um `share` seines Höchstlebens, nie über das Höchstleben. Sich selbst heilt
   sie nicht, sonst wäre sie für einen einzelnen Turm unknackbar und „zuerst sie“ kein
   Rezept mehr.
2. Der Takt beginnt mit ihrem Erscheinen (erste Heilung nach `interval`), er ist im Zustand
   (`Enemy.healTick`) und damit wiederholbar und im Spielstand.
3. **Betäubt heilt sie nicht.** Steinregen schiebt ihre nächste Heilung auf das Ende der
   Betäubung plus `interval`. So wird die Festungsfähigkeit zur Antwort.
4. **Bosse werden nicht geheilt.** Der Moorkönig hält an seiner Schildschwelle (P3-4);
   eine Heilung würde die zweite Phase verschieben und den Boss beliebig zäh machen.
5. Reihenfolge im Tick: nach den Türmen und Bossen, vor dem Auswerten der Toten. Wer in
   diesem Tick auf 0 fiel, ist tot und wird nicht geheilt.
6. Ereignis `enemiesHealed(healerID, healed, amount)`: wer, wen, wie viel insgesamt. Nur
   wenn jemand geheilt wurde, damit kein Puls ins Leere zuckt.

### Zerfallen (D-176)

`EnemyConfig.split = { into, count, spread }` (D-143: drei Sporlinge).

1. Stirbt ein Pilzbalg durch Schaden, erscheinen `count` Gegner der Art `into` an seiner
   Stelle: der erste genau am Todesort, die übrigen je `spread` Felder dahinter (nie vor
   dem Start des Wegs). Ein Zerfall schiebt so niemanden näher an die Festung. Bricht er
   durch, zerfällt er nicht.
2. Die Sporlinge tragen die Stärke der Welle: Leben = Leben der Art × (Höchstleben des
   Balgs ÷ Grundleben des Balgs). Ohne das wären sie in der letzten Welle Papier.
3. Sie kommen ans Ende der Gegnerliste (neue IDs), wie Gerufene des Bosses. Belohnung
   haben sie selbst (`reward`), der Balg zahlt seine beim Tod.
4. Ein Sporling zerfällt nicht weiter, und kein Boss zerfällt (Prüfung beim Laden).
5. Ereignis `enemySplit(id, into)`: Darstellung lässt den Balg aufplatzen und die Sporlinge
   aus der Wolke treten; dazu wie immer `enemySpawned` je Sporling.

### Neue Arten

`EnemyKind` bekommt `witch`, `puffball`, `sporeling`. Was sie können, steht in den Daten;
im Code stehen nur die Namen, damit Bild, Ton und Text einen festen Schlüssel haben (wie
beim Moorkönig).

### Laden prüfen (Regel Sicherheit)

`ConfigValidation`: `heal.radius`, `heal.interval` positiv, `heal.share` ein Anteil;
`split.count` positiv, `split.spread` nicht negativ, `split.into` muss in der Mission
stehen, darf selbst nicht zerfallen und kein Boss sein; ein Boss darf nicht zerfallen.

## Einsatz in der Kampagne (D-177, Entscheidungskarte an Steffen)

M6a und M6b sind Alternativen (Gabelung), M7 braucht eine von beiden. Empfehlung, gebaut:

| Mission | Neuheit | Wie |
|---|---|---|
| M6a Tiefes Moor | Moorhexe | Welle 2 stellt sie vor (zwei Hexen hinter Plünderern, leicht), ab der Mitte Hexen hinter Flitzerwänden, Spitze mit Hexen zwischen Panzerbestien |
| M6b Tempelplatz | Pilzbalg | Welle 2 stellt ihn vor, danach Bälge in Kolonnen, die Spitze lässt sie in der Engstelle platzen |
| M7 Bosslichtung | beide verbunden | eine leichte Welle früh zeigt den Gegner, den man auf der anderen Gabel nicht hatte; danach gemischt |

Andere Wege auf der Karte: beide in beiden M6 (zwei Neuheiten je Mission), oder nur in
ihrer Mission (wer M6b spielt, sieht die Hexe nie).

## Werte [HYPOTHESE bis Spieltest]

In den Missionsdateien, gemessen mit dem Labor. Zahlen, Wellen und Laborergebnis stehen in
[04](../game-design/04-economy-and-balance.md#moorhexe-und-pilzbalg-in-m6a-m6b-und-m7-ergebnis-der-prüfung-0420-hypothese).
Kurz: Die Hexe ist so zäh wie zwei Plünderer und langsam, der Balg etwas weniger zäh,
der Sporling hat ein Drittel eines Plünderers und läuft wie ein Flitzer.

Ergebnis: Alle Mischungen gewinnen M6a, M6b und M7, jede Monokultur verliert. Die
Heilung bestraft Salven mit Moorherz in M6a deutlich (1,19 → 0,55), Falkenhorste kaum.
Der Zerfall kostet Mischungen wenig, weil sie die Antwort schon haben. Elfen liegen in
M7 mit 0,33 knapp unter der Dominanzgrenze 0,35; mehr Hexen in M7 schieben sie darüber.

## Darstellung und Ton

- **Figuren** (D-178): drei 3D-Figuren nach der Kette von A-3 (`tools/figuren-3d`:
  FLUX-Vorlage → TRELLIS → `rig.json` → `figur.py` mit Kamera und Sonne aus dem
  Asset-Vertrag → `folge.py` mit Kontur), Folgen `walk`, `walkFront`, `walkBack` (je 8),
  `hit` (3), `die` (6). Abgestimmt mit dem Coordinator, damit A-3 sie nicht doppelt baut.
  Stand 0.42.0: Die Moorhexe ist fertig (eigener Knochen für den Stab). Für Pilzbalg und
  Sporling war das freie TRELLIS-Kontingent aufgebraucht; sie hatten in 0.42.0 ein
  gemaltes FLUX-Standbild im Atlas und liefen mit der Gangart aus `FxStyle`.
  Stand 0.43.0: Pilzbalg und Sporling sind 3D-Figuren aus ihren gemalten Vorlagen. Der
  Pilzbalg watschelt (Becken kippt seitlich), beim Sporling ist der Hut nach hinten
  gekippt, damit das Gesicht bei 30° Kamera frei bleibt. Ihre Größe auf dem Feld ist jetzt
  gleich der Seite im Vertrag (Hexe 0,85, Balg 0,8, Sporling 0,65 Felder).
- **Heilung**: grüner Puls um die Hexe, ein heller Funke über jedem Geheilten, Lebensleiste
  wächst sichtbar. **Zerfall**: Sporenwolke am Todesort, Sporlinge springen heraus.
- **Ton**: Heilen und Zerfallen bekommen je einen Klang aus den vorhandenen CC0-Quellen
  (D-082), gedrosselt über `SoundLimiter`, damit zehn Hexen nicht zehnmal klingen.
- **Haptik**: keine; nur Ereignisse, die den Spieler selbst betreffen, rütteln.

## Architektur

- Regeln in `OddlingsCore/Simulation.swift` (`runHealers`, Zerfall in `collectKills`),
  Werte in `EnemyConfig.heal` und `.split` (Regel 1, 7). Keine Iteration über Dictionary,
  kein Zufall (Regel 6). Neue Felder optional, Missionen ohne sie bleiben bitgleich
  (Determinismus- und Balancetests der alten Missionen unverändert).
- `Enemy.healTick` optional (Spielstand Schema bleibt; ein alter Stand ohne Feld lädt).
- App: neue Fälle in `BattleScene` (Ereignisse → `FxDirector`, `AudioDirector`), Größen und
  Gangart je Art in `BattleStyle`/`FxStyle`.

## Testplan

| Ebene | Was |
|---|---|
| Kern | Heilen: Takt, Radius, Deckel Höchstleben, nicht sich selbst, nicht Bosse, nicht Tote, Betäubung schiebt; Zerfallen: Zahl, Ort, Wellenstärke, kein Zerfall beim Durchbruch, IDs hinten, Belohnung; Prüfung beim Laden; Determinismus; Spielstand mit `healTick` |
| Balance | M6a/M6b: Mischung gewinnt, Monokulturen verlieren; Antwort schlägt Mischung ohne Antwort; M7 Bosssieg bleibt |
| Labor | `oddlings-balance --stufe pr` ohne neue Befunde |
| App | Ereignisse erzeugen Effekte und Klänge; Platzhalter je neuer Art; Figuren im Atlas, sobald sie da sind |
| Ende zu Ende | Probelauf M6a im Simulator bis zur ersten Heilung |

## Risiken

- Heilung kann Bauweisen mit vielen schwachen Treffern (Sporenpuls) entwerten. Das ist
  gewollt (Fokus), darf aber Sporen nicht nutzlos machen; das Labor misst die Bauanteile.
- Sporlinge erhöhen die Gegnerzahl in der Spitze; Leistungsmessung (S4) beachten,
  Effektbudget der Sporenwolke klein halten.
