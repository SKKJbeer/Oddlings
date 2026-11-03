# Konzept: Spezialisierungen und Mission 5a „Sumpfpfad“ (P3-1)

Stand 03.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-024 (zwei Stufen und eine Gabelung je Turm, Regeln in
[02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2)),
D-027 (Region 1 mit Gabelung nach M4, [05](../game-design/05-campaign-and-progression.md#region-1-flüsterwald-kostenlos)),
D-084 (Stufe 2 als Faktoren), Bedienung nach [07](../game-design/07-ui-ux.md#8-phase-2-aufwerten-fähigkeit-bank).
Entscheidung: D-077, Modus **[ENTSCHIEDEN]** von Steffen auf Karte S14 (03.11.2026, „Je Weg drei, Wahl ab M6“); Werte **[HYPOTHESE]**.

## Ziel

Nach Mission 4 gabelt sich die Region: Der Sumpfpfad schickt Flitzer, die Ruinen
schicken Panzerbestien (05). Mission 5a bringt die dritte Stufe: Ein Turm auf Stufe 2
lässt sich **spezialisieren**, und die Spezialisierung stärkt eine Kombination, nie nur
den Schaden (02). Auf dem Sumpfpfad sind das die drei Spezialisierungen gegen schnelle
Schwärme, je Turm eine.

## Karte S14 und Empfehlung

| Option | Was es heißt |
|---|---|
| **Je Weg drei, Wahl ab M6** (Empfehlung) | M5a: Salve, Gewitterkrone, Moorherz. M5b: Falkenhorst, Funkensäule, Fäulnis. Ab M6 bietet jede Mission beide, je Turm eine von zwei |
| Alle sechs ab Mission 5 | Beide Wege bieten sofort die Wahl, der Weg ändert nur die Gegner |
| Mission 5 noch nicht | Phase 3 wartet bis nach dem Spieltest |

Warum die Empfehlung: eine Neuheit je Mission (Marktanalyse, „Plants vs. Zombies“).
M5 lehrt „Stufe 3 gibt es, und sie passt zum Gegner“, M6 lehrt die Wahl. Gebaut wird
die Regel trotzdem so, dass eine Mission beliebig viele Spezialisierungen je Turm
anbieten kann. Wählt Steffen „alle sechs“, ändert sich nur die Missionsdatei und das
Kreismenü zeigt zwei Karten statt einer.

## Umfang

| Teil | Inhalt |
|---|---|
| Regel | Befehl `specialize(towerID:, Specialization)`: Stufe 2 → 3, Gold aus `specializations.<name>.cost`, Werte nach der Spezialisierung. Ereignis `towerUpgraded(level: 3)`. Verkaufen erstattet 70 % von allem |
| Spezialisierungen | Salve (Wachturm, zwei Ziele je Schuss), Gewitterkrone (Blitzturm, zwei Sprünge mehr, kein Abfall auf verlangsamten Zielen), Moorherz (Sporenturm, größerer Radius, stärkere und längere Verlangsamung) |
| Mission 5a | `mission-05a.json` „Sumpfpfad“: neuer Weg mit langen Geraden, 10 Wellen mit Flitzer-Schwerpunkt, Aufwertung wie M4, Bank, Fähigkeit. Werte **[HYPOTHESE]** |
| Kampagne | Knoten `m5a` bekommt seine Missionsdatei und ist nach M4 spielbar |
| Bedienung | Kreismenü eines Turms auf Stufe 2: Knopf „Spezialisieren“ mit Name und Preis an der Stelle von „Aufwerten“, zweimal tippen, darunter die Warnzeile „Endgültig“ (07). Schild „III“ am Turm |
| Labor | M5a in allen Stufen, Bauweisen mit Spezialisierung (`"volley"` usw.) |
| Tests | Regel im Paket, Balance, Darstellung in `AppTests`, Ende-zu-Ende: M5a, Turm bauen, aufwerten, spezialisieren |

**Nicht drin:** Mission 5b und die drei Ruinen-Spezialisierungen (nächstes Paket, P3-2;
Fäulnis braucht den Zustand „verwundbar“ an verlangsamten Zielen). Gemalter Kampfplatz
und eigene Bilder der Stufe 3: Bis sie da sind, zeigt die Szene die schlichte Karte und
das Stufe-2-Bild mit Schild „III“. Keine Änderung an M1 bis M4.

## Regel Spezialisieren

Die Missionsdatei trägt einen Abschnitt `specializations`, je angebotener
Spezialisierung Preis und Wirkung. Fehlt er, ist Stufe 2 die höchste.

```json
"specializations": {
  "volley":     { "cost": 35, "targets": 2 },
  "stormCrown": { "cost": 45, "scale": { "chainRadius": 1.4 }, "extraJumps": 2, "keepsDamageOnSlowed": true },
  "bogHeart":   { "cost": 45, "scale": { "range": 1.2, "slowFactor": 0.6, "slowDuration": 1.5 } }
}
```

So gebaut (0.25.0). Die Gewitterkrone springt auch weiter (`chainRadius`): Ohne das
fand die Kette zwischen auseinandergezogenen Flitzern kaum ein nächstes Ziel, und die
Krone war ihr Gold nicht wert.

- Jede Spezialisierung gehört zu genau einem Turm (`Specialization.tower`), das steht
  im Code, nicht in der Datei: Eine Salve am Sporenturm wäre keine Wertfrage.
- Nur aus Stufe 2 und nur, wenn die Mission sie anbietet. Eine zweite
  Spezialisierung am selben Turm wird abgelehnt (`notUpgradable`).
- **Wirkung rechnet von Stufe 2 aus**, wie Stufe 2 von Stufe 1 (D-084): Faktoren auf
  die Werte, dazu die drei neuen Felder:
  - `targets`: Der Wachturm trifft so viele verschiedene Ziele je Schuss, gewählt nach
    seiner Zielwahl (bester, zweitbester …). Fehlt es, eines.
  - `extraJumps`: Sprünge mehr für die Kette des Blitzturms.
  - `keepsDamageOnSlowed`: Ein Sprung auf ein verlangsamtes Ziel verliert keinen
    Schaden. Das ist die Kernsynergie als Regel.
- Der Takt läuft weiter, `Tower.spent` wächst um den Preis (wie beim Aufwerten).
- Preis etwa wie ein Grundturm (02, „Wirtschaft“). Volk und Ausrüstung ändern den
  Preis nicht.
- Erste Werte **[HYPOTHESE]**, gestellt mit dem Balance-Labor: Jede Spezialisierung ist
  in mindestens einer Bauweise die beste Wahl (02, „Prüfung“).

## Mission 5a „Sumpfpfad“

- Weg vom Grafik-Thread (D-081, `art/karten/wegvorschlaege/mission-05a.json`): ein
  Mäander mit drei Schleifen, Einstieg und Ausgang in der Mitte. Flitzer laufen lange
  Geraden dicht an Bauzellen vorbei: Salve und Gewitterkrone lohnen, Moorherz an einer
  Schleife hält sie dort fest. `MissionFiveATests` prüft, dass Datei und Vorschlag gleich sind.
- Wellen: Flitzer in jeder zweiten Welle als Hauptgruppe, Plünderer dazwischen, wenige
  Panzerbestien. Bank, Bonus für frühes Rufen und Aufwertung wie M4.
- Ziel für das erste Spielen (S10, Empfehlung „steigend“): Menschenbot ≥ 50 %,
  Monokultur verliert, die beste Mischung mit Spezialisierung hat die größte Reserve.

## Bedienung

- Kreismenü eines Turms auf Stufe 2 zeigt an der Stelle von „Aufwerten“ den Knopf
  „Spezialisieren“ (Stern statt Pfeil, Preis), die Tafel nennt Name und Preis
  (bei mehreren Angeboten ab M6 je eine Karte, P3-2). Erstes Tippen zeigt die Wirkung in einem Satz
  und „Endgültig“, zweites Tippen kauft. Das ist dasselbe Muster wie Verkaufen und
  Aufwerten.
- Auf Stufe 3 bleibt die Zielwahl, Aufwerten verschwindet.
- Rückmeldung: Bauklang höher, Effekt wie beim Aufwerten, Schild „III“.

## Architektur

- `Specialization` (Kern, `String`-Enum, `CaseIterable`): `volley`, `stormCrown`,
  `bogHeart`. Weitere Fälle kommen mit P3-2, nicht vorher (Scope-Verbot).
- `SpecializationConfig` in `BalanceConfig.specializations`, nur zum Nachschlagen; die
  Simulation iteriert über `Specialization.allCases` (Regel 6).
- `Tower.specialization: Specialization?`, `level` wird 3. Gesicherte Missionen (P2-2)
  tragen das Feld mit; der Fingerabdruck der Konfiguration ändert sich mit der Datei.
- `BalanceConfig.stats(of:)` bleibt die einzige Stelle, die Werte einer Stufe rechnet.
  `TowerConfig` bekommt die optionalen Felder `targets` und `keepsDamageOnSlowed`.
- `StrategyStep.specialize(Specialization)` (in der Datei der Name der Spezialisierung):
  spezialisiert den ältesten passenden Turm auf Stufe 2. Mitspieler und Labor lesen das.
- `ConfigValidation`: Spezialisierung nur für einen Turm mit Aufwertung, Preis > 0,
  Faktoren > 0, `targets` ≥ 1, `extraJumps` ≥ 0.

## Sicherheit

Die Missionsdatei liegt im Bündel und wird beim Laden geprüft. Eine gesicherte Mission
mit `specialization` besteht nur, wenn die Konfiguration sie anbietet
(`SuspendedBattle.problems`). Kein Netz, keine Fremdbibliothek.

## Testplan

| Ebene | Test |
|---|---|
| Kern | `SpecializationTests`: nur aus Stufe 2, nur angeboten, nur einmal, Gold, Verkaufserlös; Salve trifft zwei verschiedene Ziele nach Zielwahl; Gewitterkrone springt weiter und verliert auf verlangsamten Zielen nichts; Moorherz rechnet von Stufe 2 aus; Bauweise mit `"volley"`; Prüfung der Datei lehnt falsche Werte ab; Fortsetzen mit Spezialisierung |
| Balance | `MissionFiveATests`: Monokulturen verlieren, Mischung mit Spezialisierung hat die größte Reserve, jede der drei ist in einer Bauweise die beste |
| Labor | M5a in `labor.json`, PR-Stufe grün |
| App | Kreismenü zeigt „Spezialisieren“ nur auf Stufe 2 mit Angebot, zweimal tippen kauft, Schild „III“ |
| E2E | `SpecializationE2ETests`: M5a öffnen, Turm bauen, aufwerten, spezialisieren, Schild prüfen |

Jeder neue Test wird einmal rot gesehen.

## Risiken

- **Werte.** Drei neue Hebel in einer Mission; das Labor fängt grobe Fehler, das Gefühl
  der Spieltest.
- **Bild.** Ohne gemalten Kampfplatz wirkt M5a schlichter als M1 bis M4. Der Grafik-Thread
  bekommt den Weg als Vorschlag (`art/karten/wegvorschlaege/mission-05a.json`).
- **Kreismenü.** Ein vierter Knopf an der Oberseite darf keine Zelle verdecken, die man
  noch braucht; die Lage rechnet `HudLayout` wie bei „Aufwerten“.
