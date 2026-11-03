# P2-8: Synergie sichtbar und Einstieg ohne Erklärtext

Status: **[ENTSCHIEDEN]** „nur wenn man zögert“ (Steffen, 03.11.2026, Karte S13,
D-076). Die Wartezeiten
(`BattleStyle.guideBuildDelay` 6 s, `guideWaveDelay` 5 s) bleiben [HYPOTHESE] bis
zum Spieltest (S3). Grundlage:
[K8](phase-2-3.md#k8--einstieg-ohne-erklärtext), Marktanalyse E2
([market-analysis.md](../game-design/market-analysis.md), Abschnitt 7) und
[Rückmeldung je Ereignis](../art/rueckmeldung-je-ereignis.md).

## Ziel

Die Kernsynergie (Sporen bremsen, der Blitz springt durch die Gruppe) soll man
**sehen und hören**, ohne einen Satz zu lesen. Und wer Mission 1 zum ersten Mal
spielt, soll ohne Texttafel bauen, die Welle rufen und den Sporenfunken bemerken.

Bisher (FX 01, P2-3) gab es den Sporenfunken nur als etwas größeren Funkenregen
und einen Glasklang. Im Getümmel ging er unter: Das Kettenglied sah aus wie jedes
andere, und „verlangsamt“ war nur ein grüner Farbton am Gegner.

## Umfang

**Drin**

| Teil | Was man sieht | Wann |
|---|---|---|
| Verlangsamt lesbar | grüner Sporenschimmer am Boden unter dem Gegner, atmet leicht; der Farbton bleibt | solange verlangsamt |
| Sporenfunke im Blitz | das Kettenglied **in** ein verlangsamtes Ziel leuchtet grün-türkis statt blau und ist dicker | bei jedem Treffer |
| Sporenfunke am Ziel | größerer Funkenregen, Ring, Sporenwölkchen platzen nach außen, heller Lichtpunkt | bei jedem Treffer |
| Wort „Sporenfunke!“ | springt über dem Ziel auf, in der Farbe des Funkens | beim ersten Funken jeder Mission |
| Zeichen 1: Bauen | Hand tippt auf eine gute Bauzelle, Kreis breitet sich aus | Mission 1, erst wenn 6 s lang kein Turm gebaut wurde, bis der erste Turm steht |
| Zeichen 2: Welle | Pfeil wippt unter „Welle 1“, Knopf glüht | Mission 1, nach dem ersten Turm, erst wenn der Knopf 5 s lang unberührt bleibt, bis die erste Welle läuft |
| Zeichen 3: Synergie | unter „Sporenfunke!“ eine Zeile: „Gebremst rücken sie zusammen – der Blitz trifft mehr.“ | beim ersten Funken überhaupt |
| Schalter „Hinweise“ | in den Einstellungen, neben Vibration | jederzeit |

Jedes Zeichen erscheint **einmal** im Leben der App (nicht je Mission) und
verschwindet von selbst, sobald man tut, worauf es zeigt. **Nur wenn man zögert:**
Wer früh baut oder die Welle selbst ruft, sieht Hand bzw. Pfeil nie, und das
Zeichen gilt als gelernt. Kommt die Welle von selbst, gilt der Pfeil nicht als
gelernt. Jedes Tippen auf die Karte überspringt das stehende Zeichen. Wer
Mission 1 schon gewonnen hat, bekommt Hand und Pfeil nicht mehr. Beim Zuschauen
(Vorführung) erscheint nichts. Ausgeschaltet kommt
keins mehr; „Sporenfunke!“ und die Effekte bleiben, sie sind Rückmeldung, kein
Hinweis.

**Nicht drin**

- Keine neue Regel, kein Schaden mehr: der Sporenfunke ist reine Darstellung (E2).
- Keine Texttafel vor Mission 1 (Option 3 der Karte, nicht gewählt).
- Kein Zähler „Sporenfunken“ auf der Ergebnistafel. Kandidat nach dem Spieltest.
- Hinweise in späteren Missionen (Bank, Aufwerten, Panzer haben eigene Zeilen).

## Architektur

```
Simulation ──Ereignisse──▶ BattleScene ──▶ FxDirector (Funke, Wort, Hand)
                               │   ▲
                               ▼   │ liest
BattleController.afterFrame ──▶ BattleGuide ◀── GuideMemory (UserDefaults)
                                   │
                         BattleTopBar (Pfeil am Welle-Knopf)
```

- **Kern (`Packages/OddlingsCore`)**: unverändert in den Regeln. Neu ist nur
  `MissionMap.bestCell(radius:excluding:least:)`, die Suche „welche freie Zelle
  deckt am meisten Weg ab“, die bisher privat im `Autoplayer` stand. Der Mitspieler
  und die Hand zeigen so auf dieselbe Art Zelle; eine zweite Umsetzung entfällt
  (Qualitätsregel „keine zweite Umsetzung“).
- **`App/Battle/BattleGuide.swift`** (neu): entscheidet, welches Zeichen gerade
  dran ist. Liest nur Kopien aus dem `BattleController` (gebaute Türme, Welle,
  Countdown, Pause, Ende) und schreibt nur in `GuideMemory`. Den Spielzustand
  fasst es nie an (Regel 2). Ob eine Mission die Einstiegszeichen hat, sagt die
  Kampagne: nur der erste Knoten, und nur solange er keinen Stern hat
  (`AppFlow.showsIntro(for:)`). Pause, Zielen und Hinweistafeln halten das Warten an.
- **`GuideMemory`**: „schon gezeigt“ je Zeichen, als Geräteeinstellung in
  `UserDefaults` wie Ton und Vibration (K6): Es ist Wissen des Spielers an diesem
  Gerät, kein Fortschritt. Im Debug-Bau nimmt es für End-zu-End-Tests eine eigene
  Ablage je `--e2e-speicher`; `--e2e-frisch` setzt sie zurück,
  `--e2e-ohne-hinweise` schaltet den Schalter aus.
- **`FxDirector`**: der Funke wird kräftiger (`bolt`), dazu `sparkCallout`,
  `guideTap` und `clearGuide`. Die Hand läuft auf der Effekt-Uhr in Schleife,
  hält also in der Pause an. `onCombo` meldet der Szene den ersten Funken mit
  Ort; ob es der erste ist, weiß nur die Szene.
- **`EnemyNode`**: `slowAura` zeigt die Verlangsamung, `isSlowed` liest sie dort
  statt am Farbton.
- **`BattleTopBar`**: Pfeil und Glühen am Welle-Knopf, wenn der Guide es sagt.
  Nimmt keine Berührung an (`allowsHitTesting(false)`), ist für VoiceOver
  unsichtbar; der Knopf selbst trägt dann den Hinweis als `accessibilityHint`.

Effekte und Zeichen nehmen keine Eingaben an. Wer sofort baut, sieht die Hand nur
kurz; bestehende Oberflächentests tippen unverändert.

## Bedienentscheidungen

- **[VORSCHLAG]** Hand auf die Zelle, die für den **günstigsten** baubaren Turm am
  meisten Weg abdeckt. Ein Anfänger, der dort baut, hat einen guten ersten Turm.
- **[VORSCHLAG]** Der Pfeil kommt erst nach dem ersten Turm: Wer die Welle vor dem
  Bauen ruft, verliert Mission 1 beinahe sicher.
- **[VORSCHLAG]** Satz beim ersten Funken: „Gebremst rücken sie zusammen – der
  Blitz trifft mehr.“ Er beschreibt, was die Regel tut (02, Kernsynergie), und
  verspricht keinen Bonus, den es nicht gibt.
- „Bewegung reduzieren“: Hand und Pfeil stehen still, statt zu wippen; der Kreis
  pulsiert nur in der Helligkeit.

## Sicherheit

Keine neue Eingabe von außen. Was in `UserDefaults` steht, ist ein Wahrheitswert
je Zeichen; ein fremder Wert (keine Zahl, kein Bool) gilt als „nicht gezeigt“.
Der Spielstand bleibt unverändert (Schema 3).

## Tests

| Ebene | Test | prüft |
|---|---|---|
| Kern | `MissionMapTests.bestCell…` | beste und schwächste Zelle, belegte Zellen ausgelassen, Gleichstand nach Kartenreihenfolge |
| Kern | bestehende `AutoplayerTests`, `BalanceTests` | der Mitspieler baut nach dem Umzug genau wie vorher |
| App | `BattleGuideTests` | erst nach dem Zögern, Reihenfolge Bauen → Welle, früh gehandelt heißt gelernt, jedes Zeichen einmal, Schalter aus, nur Mission 1, Pause hält an, Tippen überspringt, Zeichen 3 einmal, fremde Werte und Zurücksetzen in `GuideMemory`, Hand auf der besten Zelle |
| App | `FxDirectorTests` | Funke färbt das Glied, Wort einmal je Mission, Hand läuft in Schleife und räumt auf, Pause hält sie an |
| App | `BattleSpritesTests` | Sporenschimmer an und aus mit der Verlangsamung |
| E2E | `GuideE2ETests` | Mission 1 frisch: nach dem Zögern Hand da, nach dem Bau Pfeil, nach dem Rufen weg; zweiter Start: keins mehr; Schalter aus: keins; Schalter in den Einstellungen |
| E2E | `EffectsE2ETests` | Vorführung zählt `combos` und `callouts` |

Für die E2E-Fälle zeigt der Debug-Bau den Zustand des Guides als unsichtbaren Text
`guide.state` (`build`, `wave`, `none`), wie `fx.stats`.
