# Konzept: Mission 5b „Ruinen“ mit Falkenhorst, Funkensäule und Fäulnis (P3-2)

Stand 03.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-077 (Karte S14: je Weg drei, Wahl ab M6), [P3-1](p3-1-spezialisierungen-sumpfpfad.md),
Regeln in [02](../game-design/02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2),
D-087 (Rüstung), D-081 (Wege vom Grafik-Thread).

## Ziel

Der zweite Weg nach Mission 4. Die Ruinen schicken Panzerbestien, und die drei
Spezialisierungen dort helfen gegen zähe Ziele, jede über eine Kombination:

| Spezialisierung | Turm | Wirkung | Kombination |
|---|---|---|---|
| **Falkenhorst** | Wachturm | große Reichweite, schwerer Schuss, langsamer | schwerer Schuss schlägt durch die Rüstung (fester Abzug je Treffer) |
| **Funkensäule** | Blitzturm | erster Treffer deutlich stärker, weniger Sprünge | Blitz auch gegen gepanzerte Einzelziele |
| **Fäulnis** | Sporenturm | was die Sporen verlangsamen, nimmt von allen Türmen mehr Schaden | Sporen neben Wachtürmen und Blitz |

## Umfang

| Teil | Inhalt |
|---|---|
| Regel | `Specialization` bekommt `falconHold`, `sparkColumn`, `rot`. Neues Feld `vulnerableFactor`: Der Sporenpuls macht getroffene Gegner so lange verwundbar, wie er sie verlangsamt. `extraJumps` darf negativ sein, die Kette behält mindestens null Sprünge |
| Mission 5b | `mission-05b.json` „Ruinen“: Weg aus `art/karten/wegvorschlaege/mission-05b.json` (Becken), Panzerbestien als Hauptgegner, Aufwertung, Bank, Fähigkeit wie M4. Werte **[HYPOTHESE]** |
| Kampagne | Knoten `m5b` bekommt seine Missionsdatei |
| Bedienung | wie P3-1: Stern an der Stelle von „Aufwerten“; Namen und Sätze der drei neuen |
| Tests | Kern, Balance, App, Ende-zu-Ende (M5b: Sporenturm zur Fäulnis) |

**Nicht drin:** Wahl zwischen zwei Spezialisierungen je Turm (ab M6, eigenes Paket mit
zwei Karten im Kreismenü). Gemalter Kampfplatz M5b (Grafik-Thread). M6 und M7.

## Regeln

- **Verwundbar** gibt es schon (Mondmal der Elfen, `VulnerableEffect`): Faktor und
  Ende, kein Stapeln, es gilt der stärkere Faktor und das spätere Ende. Fäulnis nutzt
  denselben Zustand. Mondmal und Fäulnis zusammen addieren sich also nicht.
- Die Fäulnis wirkt nach dem Schaden des Pulses: Der Puls selbst trifft nicht stärker.
- Rüstung vor Verwundbarkeit, wie beim Mondmal (P2-10).
- Falkenhorst und Funkensäule sind reine Faktoren auf Stufe 2 plus `extraJumps`
  (Funkensäule negativ). Die Prüfung beim Laden lehnt eine Kette unter null ab.

## Architektur

- Kern: drei neue Fälle in `Specialization` (Turm im Code), `SpecializationConfig`
  bekommt `vulnerableFactor`, `TowerConfig` ebenso. `ConfigValidation`: Faktor > 1 und
  nur am Sporenturm, Sprünge nach der Spezialisierung ≥ 0.
- Simulation: im Sporenpuls nach `applySlow` `applyVulnerable` mit dem Ende der
  Verlangsamung. Keine Iteration über Dictionary, kein Zufall.
- App: nur Texte (`BattleTexts.name/effect`); das Kreismenü kann es seit P3-1.

## Sicherheit

Missionsdatei im Bündel, beim Laden geprüft. Gesicherte Missionen prüfen die
Spezialisierung gegen das Angebot (P3-1). Kein Netz, keine Fremdbibliothek.

## Testplan

| Ebene | Test |
|---|---|
| Kern | `SpecializationTests`: Fäulnis macht verlangsamte Gegner verwundbar, so lange wie die Verlangsamung, nicht stapelnd mit dem Mondmal; Funkensäule springt weniger und trifft stärker; Prüfung lehnt Kette unter null und Faktor am falschen Turm ab |
| Balance | `MissionFiveBTests`: je Turm eine der drei Ruinen-Spezialisierungen, Weg = Vorschlag, Monokulturen verlieren, Spezialisieren hebt die Mischung, Völker |
| App | Texte der drei, Kreismenü in M5b bietet sie an |
| E2E | `SpecializationE2ETests`: M5b, Sporenturm bauen, aufwerten, „Fäulnis“ |

## Ergebnis

Werte und Labor in [04](../game-design/04-economy-and-balance.md#mission-5b--ruinen-ergebnis-der-prüfung-0260-hypothese).
Die Funkensäule war schwerer als gedacht: Ohne langsameren Takt gewinnt der reine Blitz,
deshalb lädt sie langsamer (Satz auf der Tafel angepasst). Die Elfen gewinnen in M5b mehr
als anderswo (+0,16), weil ihre Sporen weiter reichen; der Test erlaubt dort 0,2.

## Risiken

- Fäulnis wirkt auf alle Türme: Mit vielen Sporentürmen könnte es zu stark werden.
  Das Labor misst die Monokultur Sporen.
- Ohne gemalten Kampfplatz zeigt die Szene die schlichte Karte, bis das Bild kommt.
