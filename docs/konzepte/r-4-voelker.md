# Konzept: Völkerwahl Zwerge und Elfen (R-4)

Stand 26.10.2026, umgesetzt in 0.9.0 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: Regel in [03](../game-design/03-races-and-avatar.md#wie-ein-volk-wirkt-phase-3) (D-025),
vorgezogen mit D-060, Bedienung der Fähigkeit in
[07](../game-design/07-ui-ux.md#festungsfähigkeit-steinregen), Architektur des
Spielrahmens in [r-spielrahmen.md](r-spielrahmen.md), Steinregen in
[r-3-steinregen.md](r-3-steinregen.md).

## Ziel

Der Spieler wählt vor einer Mission Zwerge oder Elfen. Das Volk tauscht die
Festungsfähigkeit aus und bringt einen kleinen passiven Zug. Die Türme bleiben
für alle gleich (03, Grundsätze).

## Umfang

| Teil | Inhalt |
|---|---|
| Regel | Bollwerk (Zwerge), Mondmal (Elfen), Zustand „verwundbar“, Sporenreichweite der Elfen |
| Werte | `Balance/races.json`, **[HYPOTHESE]** bis zum Spieltest |
| Wahl | auf der Missionstafel der Karte, vor dem Start; gemerkt im Spielstand (`SaveGame.race`) |
| Ohne Wahl | Steinregen wie in 0.8.0, solange kein Volk gewählt ist |
| Nicht drin | Avatar (Name, Aussehen), weitere Völker, eigene Türme |

**Sofort wählbar** (Steffen, 25.10.2026, „ja“ zur Roadmap): Solange nur
Mission 1 spielbar ist, gibt es keine Freischaltung. Die nach D-027 greift,
sobald Mission 7 steht.

**[OFFEN] Passiver Zug der Zwerge.** 03 sieht „Zwergenbank mit höherem
Ertragsdeckel“ vor, die Bank kommt erst mit Mission 2. Empfehlung an Steffen:
vorerst ohne passiven Zug, Ausgleich über das Bollwerk; die Entscheidung steht
aus. Der Rest des Konzepts hängt nicht davon ab. 0.9.0 setzt die Empfehlung um.

## Regeln

| Fähigkeit | Wirkung | Werte (Zielgröße) |
|---|---|---|
| Steinregen | wie R-3 | aus der Missionsdatei |
| Bollwerk | Mauer an der eingerasteten Stelle, sofort; wer sie erreicht, bleibt stehen, bis sie fällt | 4 s, Abklingzeit 35 s |
| Mondmal | Gegner im Kreis nehmen für eine Weile mehr Schaden (Faktor auf jeden Treffer) | Radius 1,5, nach 0,5 s, 4 s lang, ×1,5, Abklingzeit 35 s |

Werte gemessen, nicht gerechnet: [04](../game-design/04-economy-and-balance.md#völker-zwerge-und-elfen-r-4-26102026-hypothese).
Das Bollwerk hat keine Verzögerung: Eine Mauer, die erst steht, wenn die
Gegner vorbei sind, wäre Glück statt Planung.

- **Verwundbar** ist ein Zustand am Gegner (`vulnerable: { factor, untilTick }`),
  wie die Verlangsamung: kein Stapeln, es gilt der stärkste aktive Faktor. Die
  spätere Spezialisierung Fäulnis (02) nutzt denselben Zustand.
- **Bollwerk** speichert die Stelle als Wegstrecke (`distance`), nicht als Punkt.
  Gegner davor rücken bis an die Mauer und nicht weiter; wer schon dahinter ist,
  läuft weiter. Eine Mauer zur Zeit.
- **Elfen:** Reichweite der Sporentürme × Faktor aus `races.json`.

## Architektur

```
races.json ──▶ BalanceConfig.applying(race:) ──▶ Simulation(config:)
SaveGame.race ──▶ AppFlow.race ──▶ BattleView(mission: config.applying(race))
```

- **Die Simulation kennt keine Völker.** Ein Volk ist eine zweite Konfiguration
  derselben Mission (03): `applying(race:)` ersetzt die Fähigkeit und skaliert
  Werte, rein und getestet. So rechnen Balance- und Determinismustests jedes Volk,
  ohne dass der Kern einen Fall je Volk bekommt.
- `AbilityConfig` bekommt `kind: AbilityKind { stoneRain, bulwark, moonMark }`
  und die Felder, die eine Art braucht; die Prüfung verlangt genau diese.
  Fehlendes `kind` liest sich als `stoneRain`, damit Missionsdateien von 0.8.0
  gültig bleiben.
- Zustand: `AbilityState.barrier: Barrier? { distance, untilTick }`,
  `Enemy.vulnerable`. Beides in der Prüfsumme.
- Ereignisse: `abilityCast` bleibt (beim Bollwerk mit dem Wurftick als
  Einschlag); der Einschlag meldet `abilityImpact` für Stein und Mondmal, das
  Bollwerk `barrierRaised(distance:untilTick:)` und `barrierFell`.
- Jeder Treffer läuft durch `Simulation.hurt`, damit das Mondmal für alle
  Türme und den Stein gleich wirkt.
- `races.json` wird beim Laden geprüft wie die Missionsdatei. `SaveGame.race`
  ist schon im Schema 1 vorgesehen; ein unbekanntes Volk wird beim Laden
  verworfen (Steinregen).

## Bedienung

- Missionstafel: zwei Wappen „Zwerge“ und „Elfen“ über „Starten“, darunter je
  eine Zeile, was das Volk tut. Keine Vorauswahl beim ersten Mal; „Starten“
  fragt nicht nach, ohne Wahl gilt Steinregen. Ist einmal gewählt, wechselt man
  zwischen den Völkern; zurück zum Steinregen geht es nicht, er ist kein drittes Volk.
- Der Knopf unten rechts zeigt das Bild der Fähigkeit des gewählten Volks (07).
  Bollwerk zeigt beim Zielen die Mauer statt des Kreises.

## Sicherheit

Neue Daten von außen: `races.json` (mit der App ausgeliefert, beim Laden
geprüft) und das Volk im Spielstand (beim Laden geprüft, Unbekanntes verworfen).

## Testplan

| Ebene | Test |
|---|---|
| Kern `RaceTests` | `applying` tauscht Fähigkeit und Sporenreichweite, ändert sonst nichts; `races.json` lädt und besteht die Prüfung; Prüfung findet fehlende Felder je Art |
| Kern `BulwarkTests` | Mauer an der Stelle, Gegner stauen sich davor, Dahinterliegende laufen, Mauer fällt nach der Dauer, eine zur Zeit |
| Kern `MoonMarkTests` | Treffer im Kreis werden verwundbar, Schaden × Faktor, kein Stapeln, läuft ab |
| Kern Determinismus | Wiederholung je Volk |
| Kern Balance | je Volk mit Fähigkeit: Reserve höchstens 0,1 über ohne; Zwerge und Elfen höchstens 0,05 auseinander |
| App | Wahl im AppFlow und im Spielstand, Knopfbild je Volk |
| E2E | Volk wählen, Mission starten, Fähigkeit des Volks ist da; nach Neustart der App noch gewählt |

## Risiken

- **Ein Volk wird Pflicht:** die 0,05-Grenze im Balancetest.
- **Bollwerk staut zu stark** (Blitz trifft eine stehende Traube): Dauer kurz
  halten, die Messung entscheidet.
