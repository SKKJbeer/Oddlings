# Konzept: Festungsfähigkeit Steinregen (R-3)

Stand 25.10.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-025 (Regel in [03](../game-design/03-races-and-avatar.md#eine-aktive-festungsfähigkeit-phase-2)),
D-033 (Knopf unten rechts), D-060 (vorgezogen), Bedienung in
[07](../game-design/07-ui-ux.md#festungsfähigkeit-steinregen), Architektur des
Spielrahmens in [r-spielrahmen.md](r-spielrahmen.md).

## Ziel

Steht die Verteidigung, hat der Spieler trotzdem etwas zu tun: Er wirft Steinregen
auf die dichteste Stelle am Weg. Die Regel steht in 03; dieses Konzept legt fest,
wie sie in Simulation, Bedienung und Tests kommt.

## Umfang

| Teil | Wer | Inhalt |
|---|---|---|
| Regel in der Simulation | Haupt-Thread | Befehl `useAbility(Point)`, Verzögerung, Kreis, Schaden, Anhalten, Abklingzeit, Ereignisse |
| Werte | Haupt-Thread | `ability` in `mvp-mission-01.json`, **[HYPOTHESE]** bis zum Spieltest |
| Bedienung im Controller | Haupt-Thread | Zielen an/aus, Einrasten am Weg, Ladeanteil als beobachtete Kopie |
| Knopf unten rechts, Zielansicht | Oberflächen-Thread | nach 07; liest nur den Controller |
| Schatten, Einschlag, Staub | Animations-Thread | hängt an den Ereignissen |

Mission 1 bekommt die Fähigkeit jetzt, obwohl 05 sie für Mission 4 vorsieht:
Solange nur Mission 1 spielbar ist, gäbe es sie sonst nirgends (D-060). Kommt
Mission 4, rückt sie dorthin; die Missionsdatei entscheidet, nicht der Code.

## Regel

| Wert | Bedeutung | Erster Wert |
|---|---|---|
| `radius` | Wirkkreis in Feldern | 1,2 |
| `damage` | Schaden je Gegner im Kreis | 20 |
| `delay` | Sekunden vom Wurf bis zum Einschlag (der Schatten) | 0,8 |
| `stunDuration` | Sekunden, die Getroffene anhalten | 1,0 |
| `cooldown` | Sekunden ab dem Wurf bis zur nächsten Bereitschaft | 35 |
| `snapDistance` | So weit darf der Finger neben dem Weg liegen | 1,0 |

Zuerst gerechnet waren 40 Schaden und 25 s Abklingzeit, ein Wurf je Welle. Die
Prüfung aus 03 (Bot wirft auf die dichteste Stelle, Reserve höchstens +0,1) ergab
+0,29, also fast dreimal zu stark. Die Werte oben halten +0,075; Messreihe und
Begründung stehen in [04](../game-design/04-economy-and-balance.md#steinregen-r-3-25102026-hypothese).

- **Bereit ab Beginn** (03): `readyTick = 0`.
- **Zielen auf den Weg:** Der Punkt wird auf den nächsten Wegpunkt gezogen, wenn er
  höchstens `snapDistance` entfernt ist, sonst abgelehnt (`notOnPath`). So trifft
  der Wurf immer den Weg, auch mit dickem Finger.
- **Einschlag** im Tick `Wurf + delay`, vor dem Feuern der Türme: Getroffen ist,
  wer dann im Kreis steht, nicht wer beim Wurf dort stand. Das ist der Sinn des
  Schattens: Man zielt voraus.
- **Anhalten** stapelt nicht: Es gilt das spätere Ende, wie bei Sporen.
  Angehaltene bewegen sich nicht; Verlangsamung läuft daneben ab.
- **Kein Gold**, keine Ladungen, ein Wurf zur Zeit.

## Architektur

```
Controller.beginAim ─▶ Zielansicht ─▶ Controller.cast(at: Feldpunkt)
  ─▶ BattleModel.enqueue(.useAbility(point)) ─▶ Simulation.step
  ─▶ .abilityCast(center, impactTick) … .abilityImpact(center, hits) ─▶ Szene, Haptik
```

- `AbilityConfig` optional in `BalanceConfig`; ohne sie lehnt die Simulation den
  Befehl ab (`noAbility`). Prüfung: alle Werte positiv, `delay < cooldown`.
- `GameState.ability = AbilityState { readyTick, pendingStrike: Strike? }`,
  `Enemy.stunUntilTick: Int?`. Beides in der Prüfsumme (Determinismus, WP-10).
- Schrittfolge: Befehle → **Einschlag** → Wellen → Erscheinen → Türme → Tote → Bewegung → Durchbrüche → Ende.
- Neue Ablehnungen: `abilityNotReady`, `notOnPath`, `noAbility`. Neue Ereignisse:
  `abilityCast(center: Point, impactTick: Int)`, `abilityImpact(center: Point, hits: [Int])`.
- Der Controller bekommt `abilityCharge` (0…1, nur bei Änderung gesetzt),
  `abilityReady`, `aiming` und `snappedTarget(for:)`. Öffnen des Zielens schließt
  das Kreismenü und umgekehrt (07).

## Bedienentscheidungen

Stehen in 07. Hier nur: Ein Wurf, der wegen `notOnPath` abgelehnt wird, kostet
nichts und lässt das Zielen offen, damit man gleich neu ansetzen kann.

## Sicherheit

Keine neuen Daten von außen außer der Missionsdatei, die wie bisher beim Laden
geprüft wird. Die Fähigkeit ist ein Befehl wie `build`; die Darstellung ändert
keinen Zustand.

## Testplan

| Ebene | Test |
|---|---|
| Kern `AbilityTests` | Bereit ab Tick 0; Wurf vor Bereitschaft abgelehnt; Einschlag genau nach `delay`; nur Gegner im Kreis getroffen, gezählt beim Einschlag; Anhalten hält, endet, stapelt nicht; neben dem Weg abgelehnt, nahe am Weg eingerastet; ohne `ability` abgelehnt; Prüfung der Werte |
| Kern Determinismus | Wiederholung mit Würfen ergibt dieselbe Prüfsumme |
| Kern Balance | Bot mit Würfen auf die dichteste Stelle: Reserve steigt um mehr als 0 und höchstens 0,1 |
| App `BattleControllerTests` | Zielen an/aus, Wurf reiht den Befehl ein, Ladeanteil läuft, Zielen schließt das Kreismenü |
| E2E | Fähigkeit bereit, werfen, Knopf lädt, nach der Abklingzeit wieder bereit (mit dem Knopf des Oberflächen-Threads) |

## Risiken

- **Die Fähigkeit ersetzt Türme:** Die Balanceprüfung deckelt das.
- **Zielen verdeckt die Karte:** Die Zielansicht dunkelt nur ab, der Weg bleibt hell (07).
