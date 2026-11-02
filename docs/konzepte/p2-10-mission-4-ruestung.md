# Konzept: Mission 4 „Ruinenrand“ mit gepanzerter Panzerbestie (P2-10)

Stand 02.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-027 (Region 1, M4 lehrt „aktiv eingreifen, zähe Ziele“,
[05](../game-design/05-campaign-and-progression.md#region-1-flüsterwald-kostenlos)),
K7 (Rüstung als fester Abzug je Treffer, [phase-2-3](phase-2-3.md#k7--gegner-bosse-rüstung)),
D-081 (Weg aus dem Vorschlag des Grafik-Threads), D-080 (Missionen vor dem
Spieltest, Werte danach), D-084 (Aufwerten), D-086 (Bank und Bonus bleiben).
Offene Frage an Steffen: Entscheidungskarte S8 „Was soll Mission 4 Neues
bringen?“ (Roadmap). Bis zur Antwort gilt die Empfehlung **[VORSCHLAG]**.

## Ziel

Nach 05 bringt M4 „Festungsfähigkeit und Panzerbestie“. Beides gibt es seit dem
vorgezogenen Spielrahmen schon in Mission 1 (R-3, D-060; Panzerbestie ab
Welle 7). Ohne neue Regel hätte M4 nichts zu lehren. Deshalb bekommt die
Panzerbestie hier, was K7 für sie vorsieht: **Rüstung als fester Abzug je
Treffer**.

Das macht „zähe Ziele“ zu einer Entscheidung, ohne Schadenstypen einzuführen:

- Viele kleine Treffer (Blitzsprünge, Sporenpuls) verlieren an der Panzerung
  den größten Teil, wenige große (Wachturm auf Stufe 2) nur einen kleinen.
- Aufwerten aus M3 lohnt sich doppelt, und die Zielwahl „stärkster“ hat einen
  klaren Zweck.
- Die Festungsfähigkeit wird zum Werkzeug gegen genau diese Gegner („aktiv
  eingreifen“): Der Steinregen schlägt durch die Panzerung, das Mondmal der
  Elfen vervielfacht, was durchkommt, das Bollwerk der Zwerge hält sie im Feuer.

## Umfang

| Teil | Inhalt |
|---|---|
| Regel Rüstung | Gegner tragen optional `armor` in der Missionsdatei. Jeder Turmtreffer verliert `armor` Punkte, behält aber mindestens den Anteil `armorMinShare` (die Panzerung macht einen Treffer nie wirkungslos). Ohne Eintrag ändert sich nichts, M1 bis M3 bleiben Byte für Byte gleich |
| Fähigkeit | Der Steinregen durchschlägt Rüstung. Mondmal vervielfacht nach dem Abzug |
| Mission 4 | `mission-04.json` „Ruinenrand“: Weg aus dem Vorschlag D-081 unverändert, 10 Wellen mit mehr Panzerbestien, Aufwertungen, Bank und Bonus wie in M3. Alle Werte **[HYPOTHESE]** bis nach WP-15 |
| Kampagne | Knoten `m4` bekommt seine Missionsdatei, Neuigkeit „Neu: gepanzerte Panzerbestie“ (`armor`) statt „Festungsfähigkeit und Panzerbestie“ |
| Bedienung und Bild | Schildsymbol an gepanzerten Gegnern (E3), abprallender Funke und dumpfer Klang, wenn die Panzerung einen Treffer schluckt, Hinweis beim ersten Auftritt |
| Grafik | Gemalter Kampfplatz `map_mission04_ground` liegt seit 0.16.1 bereit. Das Schild ist eine Form im Code wie das „II“ am Turm, kein neues Bild |

Nicht drin: Rüstung für andere Gegner, Schadenstypen, Rüstung brechen,
Spezialisierungen (kommen mit M5/M6), Panzerbestie in 3D (FX 02, wartet auf
Steffens Urteil am Plünderer).

## Regel Rüstung

```json
"enemies": {
  "brute": { "hp": 330, "speed": 0.6, "reward": 20, "leakDamage": 3,
             "armor": 8, "armorMinShare": 0.25 }
}
```

```
durch  = max(Treffer − armor, Treffer × armorMinShare)   nur Turmtreffer
Schaden = durch × Mondmal-Faktor
```

- **Fester Abzug, kein Prozent** (K7): Er unterscheidet die Türme. Werte
  **[HYPOTHESE]** mit `armor 8` (in den Balancetests gefunden; mit 6 machte die
  Rüstung das Aufwerten nicht lohnender, siehe 04):

  | Treffer | ohne Rüstung | mit Rüstung | bleibt |
  |---|---|---|---|
  | Wachturm Stufe 1 | 12 | 4 | 33 % |
  | Wachturm Stufe 2 | 18 | 10 | 56 % |
  | Blitz Stufe 1, erster / vierter Sprung | 18 / 9,2 | 10 / 2,3 | 56 % / 25 % |
  | Sporenpuls | 1 | 0,25 | 25 % (Mindestanteil) |
  | Steinregen | 20 | 20 | 100 % |
  | Wachturm Stufe 1 mit Mondmal 1,5 | 18 | 6 | – |

- **Mindestanteil** statt Mindestschaden 1: Der Sporenpuls ist 1 Punkt; mit
  einem Mindestwert von 1 wäre er gegen Rüstung unverändert, mit 0 wäre er
  wertlos. Der Anteil gilt für jeden Turm gleich und steht in der Datei.
- **Erst die Rüstung, dann das Mondmal.** Geplant war das Mal vor dem Abzug, damit
  die Elfen die Antwort auf Panzerung sind. Gemessen hob das die Elfen an einer
  Bauweise um 0,15 über „ohne Volk“, über der Grenze aus 03. Danach gerechnet sind
  es 0,12 dort und 0,05 an der Vorführbauweise. **[gilt]**
- **Fähigkeit durchschlägt Rüstung.** Ein Stein ist kein Pfeil; außerdem ist der
  Steinregen das, was M4 lehren soll. Als Regel im Code, nicht als Zahl, weil
  es kein Zwischending gibt. **[VORSCHLAG]**
- **Panzerbestie weniger Leben als in M1** (330 statt 370), weil die Rüstung sie
  für Stufe-1-Türme deutlich zäher macht.
- Die Lebensleiste zeigt weiter Leben, keine eigene Rüstungsleiste. Rüstung
  nutzt sich nicht ab.

## Mission 4 „Ruinenrand“

- **Weg:** `art/karten/wegvorschlaege/mission-04.json` unverändert: von links
  unten hoch, lange Gerade oben, rechts wieder hinunter. Der Weg ist ein großes
  „U“, in dessen Innerem Türme beide Schenkel und die Gerade sehen; außen am
  Rand stehen Plätze, die nur einen Schenkel erreichen. Ein Test hält Datei
  und Vorschlag gleich wie in M3.
- **Wellen:** 10. Ab Welle 2 sind Panzerbestien dabei (in M1 erst ab 7), oft
  mit Flitzern oder Plünderern davor, damit der Spieler zwischen „Gruppe“ und
  „zähes Ziel“ entscheiden muss. Welle 6 ist eine reine Panzerwelle, damit der
  Wert von Stufe 2 und Steinregen sichtbar wird.
- **Gold, Leben, Sterne, Bank, Bonus, Aufwertungen** wie in M3, die genauen
  Zahlen aus den Balancetests. Startgold so, dass zwei Türme plus eine
  Aufwertung vor Welle 2 möglich sind.
- **Prüfung durch die Bots:** Monokultur Sporen und Monokultur Blitz verlieren,
  gemischte Bauweise mit Aufwertung und Zielwahl gewinnt mit Reserve, die
  Bauweise ohne Aufwertung verliert oder gewinnt knapp (Kennzahl „Panzerung“,
  analog zur Kennzahl „Vertiefen“ in M3). Jedes Volk bleibt in der Grenze (D-064,
  D-069).

## Architektur

```
mission-04.json ─▶ ConfigValidation (armor ≥ 0, armorMinShare in (0, 1])
Simulation.fireTowers ─▶ damage(index, by:) ─▶ strike(enemy, by:, tick:)
Simulation.resolveAbility ─▶ hurt(…, piercesArmor: true)
strike: Rüstung (nicht beim Stein) → × Mondmal → hp −= dealt
      Ereignis enemyDamaged(id, amount) wie bisher, dazu armorAbsorbed(id, amount) wenn Rüstung griff
Szene ◀── armorAbsorbed (Funke, Klang, gedrosselt)
```

- **`EnemyConfig` bekommt `armor: Double?` und `armorMinShare: Double?`**,
  beide optional. Fehlen sie, gibt es keine Rüstung. Kein eigener Abschnitt:
  Rüstung ist eine Eigenschaft des Gegners wie Leben und Tempo.
- **Eine Stelle:** `hurt` ist schon heute der Durchgang für jeden Treffer
  (Mondmal). Sie bekommt die Herkunft (`tower` oder `ability`) und wendet die
  Rüstung an. Keine zweite Schadensrechnung.
- **Ereignis `armorAbsorbed(id:, amount:)`** nur, wenn die Rüstung wirklich
  etwas geschluckt hat. Effekte und Ton hängen daran (Architekturregel 3).
  `enemyDamaged` bleibt unverändert, damit kein bestehender Hörer bricht.
- **Zustand:** keiner neu. Rüstung steht in der Konfiguration, nicht im Gegner.
- **Bots:** `simStrategies` braucht nichts Neues; `watch+` gibt es seit M3.
  Balance-Bot und Mitspieler stellen aufgewertete Wachtürme auf „stärkster“, wenn
  die Mission gepanzerte Gegner hat (`config.hasArmoredEnemies`), sonst bleibt
  alles, wie es war. Ein Spieler täte dasselbe; ohne das würde die Balance die
  Zielwahl aus M3 nicht mitrechnen.
- **Kampagne:** `region-01.json`, Knoten `m4` bekommt `"mission": "mission-04"`,
  Neuigkeit `armor` (neuer Fall in `CampaignNovelty`).

## Bedienung

- **Schild am Gegner (E3):** kleines graues Schild neben der Lebensleiste jedes
  Gegners mit Rüstung. Umriss und Symbol sagen „gepanzert“, ohne Text.
- **Treffer an der Panzerung:** heller Funke, der abprallt, und der vorhandene
  Trefferklang eine Quinte tiefer, dumpf wie Metall (kein neuer Klang, wie beim
  Aufwerten). Höchstens einmal je Gegner und halbe Sekunde, sonst knistert es bei
  Blitz und Sporen ununterbrochen; der Klang folgt derselben Grenze.
- **Erster Auftritt:** kurzer Hinweis über dem ersten gepanzerten Gegner,
  „Gepanzert: Steine schlagen durch“. Einmal je Kampf, auch nicht wieder nach
  einem Neustart. Ein Wellenbanner wäre für den Satz zu breit.
- **Missionstafel der Kampagne:** „Neu: gepanzerte Panzerbestie“, Lehre „Aktiv eingreifen,
  zähe Ziele.“ bleibt.

## Sicherheit

`mission-04.json` läuft durch dieselbe Prüfung wie M1 bis M3, bevor sie die
Simulation erreicht. Neu: `armor` nicht negativ, `armorMinShare` größer 0 und
höchstens 1, beide nur zusammen (`armorNeedsBothValues`). Kein Netz, keine neue
Bibliothek, kein neuer Klang und kein neues Bild.

## Testplan

| Ebene | Was |
|---|---|
| Paket | `ArmorTests`: Abzug je Turmtreffer, Mindestanteil, Steinregen durchschlägt, Mondmal nach dem Abzug, Blitzsprünge einzeln, Sporenpuls, Ereignis nur wenn Rüstung griff, Gegner ohne Rüstung unverändert, Missionen ohne Eintrag unverändert (die Balancetests von M1 bis M3 laufen ohne Änderung). `ConfigValidation` für die neuen Felder. `MissionFourTests`: Datei gültig, Weg = Vorschlag D-081, Ausgänge der Bauweisen, Kennzahl Panzerung, Determinismus, Völker begrenzt. `CampaignTests`: M4 nach M3 offen |
| App | `BattleSceneTests`: Schild nur an gepanzerten Gegnern. `BattleSpritesTests`: gemalter Boden M1 bis M4. `SoundMapTests` (tieferer Treffer), `FeedbackPlayerTests` (keine Haptik). `AppFlowTests`: M4 spielbar, Weiter endet bei M4 |
| Ende-zu-Ende | `ArmorE2ETests`: M4 über `--play --e2e-knoten m4` im Zeitraffer starten, zwei Wachtürme bauen, die erste Panzerbestie wirft Funken, der Hinweis kommt genau einmal (`fx.stats`, wie FX 01; SpriteKit ist für XCUITest unsichtbar) |

Jeder neue Test wird einmal rot gesehen.

## Risiken

- **Antwort auf S8 steht aus.** Wählt Steffen „keine neue Regel“, entfallen
  Regel Rüstung, Schild und Klang; Mission 4 bleibt mit Weg und Wellen. Wählt
  er den Prozentabzug, ändert sich nur die Formel in `hurt` und die Datei. Ich
  baue zuerst die Mission und die Regel getrennt, damit beides einzeln geht.
- **Balance ohne Spieltest:** Werte sind Hypothesen. Rüstung macht die
  Rechnung zweidimensional (02, Abschnitt Schaden); die Balancetests halten
  Beziehungen, nicht Feinheiten.
- **R-7a** ändert Turmwerte über Ausrüstung. Rüstung wirkt danach auf den
  fertigen Treffer, beides verträgt sich.
- **Blitzturm wird an Panzerbestien deutlich schwächer.** Gewollt (K7), aber er
  darf in M4 nicht nutzlos werden: Gegen die Plünderer und Flitzer davor bleibt
  er die beste Wahl, das prüft die Kennzahl der Bauweisen.
