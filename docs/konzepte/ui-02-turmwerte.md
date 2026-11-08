# Konzept: Turmwerte und Vergleich beim Aufwerten (UI-02)

Stand 08.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: Steffen, 08.11.2026: „weil ich auch daten und statistiken liebe will ich
sehen was es bringt und wie die aktuellen stats sind und wie es sich verändert wenn
man upgrade“. Baut auf D-024 (Aufwertungen), D-031 (Kreismenü am Feld), D-077 und
D-079 (Spezialisierungen) auf; Bedienung nach [07](../game-design/07-ui-ux.md#turm-antippen-je-nach-stufe).
Entwurf zum Anklicken: [Turmwerte und Aufwerten](https://claude.ai/artifact/Us5EkoKvq76roBQPFn28JW).
Entscheidungskarte **S24** (wie viel Statistik), gebaut ist die Empfehlung.

## Ziel

Bis 0.28 sagte die Tafel am Turm nur „Stufe 2: gleiche Rolle, spürbar stärker.“
Wer Zahlen mag, sah nicht, **was** stärker wird und um wie viel, und beim
Spezialisieren nicht, was er dafür hergibt (Falkenhorst: mehr Schaden, weniger Tempo).
Die großen Tower Defense zeigen genau das (Marktanalyse, E5: Aufwertung als lesbare
Entscheidung). Ziel: Ein Blick auf die Tafel beantwortet drei Fragen.

1. **Was kann der Turm jetzt?** Vier Kennzahlen, die wichtigste vorn.
2. **Was bringt der Kauf?** Beim ersten Tippen auf Aufwerten oder einen Stern jede
   Kennzahl alt → neu mit Plus, ein Minus orange.
3. **Was hat der Turm schon geleistet?** Schaden, Erledigte, Zeit im Kampf.

## Umfang

| Teil | Inhalt |
|---|---|
| Simulation | `TowerSheet` rechnet aus `TowerConfig` die Kennzahlen einer Turmart und den Vergleich zweier Stände (`TowerChange`). `Tower` zählt `damageDealt`, `kills`, `slowHits` |
| Tafel am Turm | Titel, vier Kacheln, eine Zeile (Kampfbilanz, Neues der Stufe oder Warnung), was das nächste Tippen tut |
| Tafel vor dem Bau | Dieselben Kacheln ohne Vergleich, dazu die Rolle |
| Lage | Hohe Tafel 256 × 176, wo sie frei liegt; sonst flache Leiste 380 × 100 mit vier Kacheln nebeneinander |
| Tests | Regeln im Paket, Texte, Vorschau und Lage in `AppTests`, Vergleich und Bilanz mit echtem Tippen in `UpgradeE2ETests` |

**Nicht drin:** Werte der Gegner, eine Statistikseite nach der Mission, Balken über
mehrere Türme. Die Bank zeigt weiter Ertrag und Auszahlung als Text, sie hat keine
Kampfwerte.

## Kennzahlen je Turm

Alle Kennzahlen sind so gerichtet, dass **mehr besser** ist. So heißt ein Minus beim
Vergleich immer „das zahlst du dafür“, und die Farbe muss nicht je Kennzahl gedeutet
werden.

| Turm | Leitzahl (Gold hinterlegt) | Weitere Kacheln | Zusatz |
|---|---|---|---|
| Wachturm | Schaden/s = Schaden × Ziele ÷ Takt | Schaden, Tempo (Schüsse/s), Reichweite | Ziele/Schuss bei der Salve |
| Blitzturm | Schaden/s über die volle Kette (erster Treffer, jeder Sprung um den Abfall schwächer) | Erster Treffer, Kette (Ziele), Reichweite | |
| Sporenturm | Bremst um (1 − Verlangsamung, „50 %“) | Reichweite, Dauer, Puls (Pulse/s) | Verwundbar bei Fäulnis |

- **Schaden/s statt Takt.** „Takt 0,8 s“ ist richtig, aber kleiner ist dort besser,
  das widerspricht der einen Richtung. Tempo als Schüsse je Sekunde.
- **Blitzturm mit voller Kette.** Die Kachel heißt „Schaden/s, Kette“, damit klar ist,
  was gezählt wird. Die Gewitterkrone (kein Abfall auf gebremste Ziele) ist nicht
  eingerechnet: Die Tafel nennt die sichere Untergrenze.
- **Volk und Ausrüstung stecken drin.** `TowerSheet` liest nur `TowerConfig` aus
  `BalanceConfig.stats(of:)`, in der Elfenreichweite, Ausrüstung, Stufe und
  Spezialisierung schon verrechnet sind. Keine eigene Zahl, keine zweite Rechnung
  (Architekturregel 7).
- Rüstung der Gegner zieht die Tafel nicht ab. Sie hängt am Gegner, nicht am Turm.

## Vergleich

- Beim ersten Tippen auf Aufwerten oder einen Stern zeigt jede Kachel `alt → neu`
  und ein Schild: **grün** „+50 %“, **orange** „−33 %“, **braun** „gleich“.
- Prozent, wo das Verhältnis zählt (Schaden/s, Tempo, Reichweite, Dauer); Betrag beim
  Schaden („+6“, man hält ihn gegen das Leben der Gegner); Stückzahl bei Zielen;
  Prozentpunkte bei Anteilen (Bremse, Verwundbar).
- Unter einem Plus wächst ein Balken vom alten (hell) zum neuen Wert (grün).
- Eine Kennzahl, die neu dazukommt, hat den Wert, den der Turm ohne sie hatte: Ziele
  von 1, Verwundbar von 0.
- Vorschau und Kauf nehmen **dieselben Werte** wie der Reichweitenkreis
  (`BattleController.previewStats`), die Tafel kann also nichts versprechen, was der
  Kauf nicht hält.
- Titel beim Vergleich: „Wachturm → II“, „Wachturm II → Falkenhorst“.

## Kampfbilanz

**[VORSCHLAG, Karte S24]** Die Simulation schreibt dem Turm gut, was er tut:

- `damageDealt`: Schaden, der am Leben ankam, also nach Rüstung und Mal und **ohne
  Überschuss** über das Restleben hinaus. Sonst hätte ein Schuss von 45 auf einen
  Flitzer mit 3 Leben 45 gezählt.
- `kills`: Der Treffer, der das Leben auf null bringt, ist der Sieg dieses Turms.
- `slowHits`: Treffer des Sporenpulses (der Sporenturm zeigt „gebremst“ statt Schaden).
- Zeit im Kampf aus `builtTick`, nicht gespeichert.

Die Zeile lautet „312 Schaden · 7 erledigt · seit 1:40“, beim Sporenturm „38
gebremst · 0 erledigt · seit 1:40“. Aufwerten und Spezialisieren behalten die
Bilanz (derselbe Turm), Verkaufen nimmt sie mit.

## Architektur

```
BalanceConfig.stats(of:) ─▶ TowerSheet(kind:stats:) ─▶ changes(to:) ─▶ [TowerChange]
                                                          ▲
BattleController.statChanges(for:)  (jetzt, oder jetzt → previewStats beim Vormerken)
RingMenu ─▶ InfoPanel(stats:) ─▶ TowerStatGrid ─▶ StatTile (Texte: TowerStatTexts)
Simulation.damage(… tower:) ─▶ Tower.damageDealt / kills;  Sporenpuls ─▶ slowHits
```

- **`TowerSheet` im Paket**, nicht in der App: reine Rechnung, unter Linux testbar,
  und der Bot oder das Labor können sie später lesen. Keine Zahl im Code außer der
  Regel „ohne Salve ein Ziel“. Eintrag **D-130**.
- **Bilanz im Zustand** (`Tower`), nicht aus Ereignissen in der App zusammengezählt:
  `enemyDamaged` trägt den Schützen nicht, und nach Fortsetzen (P2-2) wäre eine
  App-Zählung weg. Die Felder werden beim Lesen mit 0 vorbelegt, alte Spielstände
  bleiben lesbar (Architekturregel 4). Die Regeln lesen sie nie, darum gehören sie
  nicht in die Prüfsumme; Determinismus und Replays ändern sich nicht. Eintrag **D-131**.
- **Lage:** `HudLayout.statPanel` versucht die hohe Tafel in den Ecken und zuletzt
  in der Mitte; liegt sie nirgends frei (gemessen: iPhone SE, vier Knöpfe in der
  Kartenmitte, 29 von 16 288 Fällen), nimmt sie die flache Leiste. Eintrag **D-132**.
- Die alte Tafel (`plainBody`) bleibt für die Bank.

## Bedienung

- Keine neuen Knöpfe, kein Fenster. Die Mission läuft weiter (D-019), die Tafel
  verdeckt so wenig Karte wie vorher in Fällen ohne Platz.
- Schrift: Kennzahlen in Lilita One, Beschriftungen in Nunito, Großbuchstaben mit
  Sperrung. Farben aus `UITheme` (Gold, Grün, Orange, Pergament).
- VoiceOver liest jede Kachel als „Schaden: 12 auf 18, +6“, die Kennung ist
  `stat.<kennzahl>`, der Wert das Schild.

## Sicherheit

Keine neuen Eingaben von außen. Die drei neuen Zustandsfelder kommen aus dem
Spielstand und werden mit Vorgabe gelesen; sie steuern nichts in der Simulation, ein
manipulierter Wert ändert nur eine Anzeige.

## Testplan

| Ebene | Test |
|---|---|
| Paket | `TowerSheetTests`: Reihenfolge und Werte je Turm, Kette mit Abfall, Bank leer, Vergleich Stufe 2, Sporenturm, Salve (Ziele von 1), Falkenhorst (Minus beim Tempo), Fäulnis (von 0), Volk/Ausrüstung über die Konfiguration. `TowerTallyTests`: Überschuss zählt nicht, Kettentreffer, gebremste Treffer, alter Spielstand, Speichern und Laden. Alle einmal rot gesehen |
| App | `TowerStatsTests`: Vorschau = gekaufte Werte, Bau-Vorschau, Bank ohne Werte, Zeit seit dem Bau, deutsche Zahlen, Schilder, VoiceOver. `HudLayoutTests.testStatPanelFitsEveryCellOfEveryMission`: alle Missionen, vier Geräte, bis vier Knöpfe |
| Ende-zu-Ende | `UpgradeE2ETests`: Kampfbilanz am Turm, Schaden/s vorn, nach dem ersten Tippen „Wachturm → II“, Schild = Plus aus der Konfiguration, Reichweite „gleich“, Bildschirmfoto `d-130-vergleich` |
