# Oddlings – Arbeitsgrundlage für Claude Code

> Arbeitstitel „Project Oddlings" (nicht final). Fantasy-Tower-Defense für iPhone,
> nativ in Swift. Solo-Entwicklung durch Steffen mit KI-Unterstützung.
> Sprache in Dokumenten und Gespräch: Deutsch. Code, Bezeichner, Commits: Englisch.

## Stand

**Phase 1 läuft.** Phase 0 ist abgeschlossen (PR #1). WP-01, der Technik-Spike
(`App/Spike/`, Wegwerfcode), ist in TestFlight; die Messung auf dem iPhone steht aus.
Simulationspaket `Packages/OddlingsCore`: Konfiguration mit Validierung (WP-02),
Weg und Bauzonen (WP-03). Als Nächstes WP-04 (Wellen, Bewegung, Festung).
Projekt erzeugen: `xcodegen generate` (Xcode-Projekt ist nicht eingecheckt).
Aufs Gerät: `.github/workflows/testflight.yml` (bei App-Änderungen auf main automatisch),
Hilfsskript `scripts/apple.py`. Ein Bau ist erst verfügbar, wenn Apple ihn als VALID meldet.

## Vision in drei Sätzen

Der Spieler verteidigt eine Festung gegen Wellen fantasievoller Gegner.
Gewonnen wird durch Kombinationen von Türmen, nicht durch den größten
Schadenswert. Leicht zu verstehen, taktisch tief, kurz spielbar, offline, fair.

Säulen und Zielbild: [00-vision-and-pillars.md](docs/game-design/00-vision-and-pillars.md).

Anspruch (Steffen, 25.10.2026): ein professionelles Tower Defense mit AAA-Anmutung,
an den Marktführern orientiert, ohne sie zu kopieren. Spaß zuerst, später viele
Spieler und Einnahmen. Die [Marktanalyse](docs/game-design/market-analysis.md)
fließt in jede Design- und Darstellungsarbeit ein: vor einem Designvorschlag dort
nachsehen (Abschnitt 7, Empfehlungen E1–E15), und die Liste „AAA-Anmutung"
(Abschnitt 3) ist der Maßstab für Darstellung, Ton und Bedienung.

## MVP-Grenze (Phase 1)

**Drin:** eine Karte, ein fester Weg, Bauzonen, Wachturm, Blitzturm, Sporenturm,
Plünderer, Flitzer (Panzerbestie optional), Gold, Wellen, Festungsleben, Sieg,
Niederlage, Neustart, Verkaufen, Tests.

**Nicht drin:** Zwergenbank (Phase 2), Upgrades, Multiplayer, PvP, Kampagne,
Völker, Echtgeld, Backend, Meta-Progression, 3D, steuerbarer Held.

### Scope-Verbot

Nichts außerhalb der MVP-Grenze wird gebaut, auch nicht „schon mal vorbereitet",
ohne ausdrückliche Freigabe von Steffen. Wer eine Erweiterung für nötig hält,
schreibt sie als Vorschlag ins [Entscheidungsprotokoll](docs/decisions/decision-log.md)
und fragt. Das gilt besonders für Netzcode, Monetarisierung und Völker.

## Wo was steht

| Thema | Maßgebliche Quelle |
|---|---|
| Analyse, Risiken, blockierende Fragen | [docs/production/phase-0-analyse.md](docs/production/phase-0-analyse.md) |
| Vision, Säulen | [docs/game-design/00-vision-and-pillars.md](docs/game-design/00-vision-and-pillars.md) |
| Markt, Vorbilder, Empfehlungen | [docs/game-design/market-analysis.md](docs/game-design/market-analysis.md) |
| Spielablauf, Platzierung, Bedienung | [docs/game-design/01-core-gameplay.md](docs/game-design/01-core-gameplay.md) |
| Türme, Gegner, Regeln | [docs/game-design/02-combat-and-towers.md](docs/game-design/02-combat-and-towers.md) |
| Völker, Avatar | [docs/game-design/03-races-and-avatar.md](docs/game-design/03-races-and-avatar.md) |
| Zahlen und ihre Begründung | [docs/game-design/04-economy-and-balance.md](docs/game-design/04-economy-and-balance.md) |
| **Zahlen selbst** | [mvp-mission-01.json](Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json) – die einzige Quelle |
| Kampagne, Fortschritt | [docs/game-design/05-campaign-and-progression.md](docs/game-design/05-campaign-and-progression.md) |
| Monetarisierung | [docs/game-design/06-monetization.md](docs/game-design/06-monetization.md) |
| Architektur | [docs/technical/architecture.md](docs/technical/architecture.md) |
| Datenmodelle | [docs/technical/data-models.md](docs/technical/data-models.md) |
| Tests | [docs/technical/testing-strategy.md](docs/technical/testing-strategy.md) |
| Phasen | [docs/production/roadmap.md](docs/production/roadmap.md) |
| Arbeitspakete | [docs/production/backlog.md](docs/production/backlog.md) |
| Entscheidungen | [docs/decisions/decision-log.md](docs/decisions/decision-log.md) |

Eine Designentscheidung steht an **genau einer** Stelle. Andere Dokumente
verlinken, statt zu wiederholen. Zahlen stehen nur in der Konfiguration.

## Kennzeichnung

**[ENTSCHIEDEN]** von Steffen bestätigt · **[HYPOTHESE]** muss sich im Test
bewähren · **[VORSCHLAG]** von Claude, wartet auf Freigabe · **[OFFEN]**.
Wichtige Spielregeln werden nie erfunden, ohne sie als Vorschlag zu markieren.

## Architekturregeln (nicht verhandelbar ohne Eintrag im Entscheidungsprotokoll)

1. Spielregeln leben in `Packages/OddlingsCore`, das nur Foundation importiert.
   Kein SpriteKit, SwiftUI oder UIKit dort.
2. Eingaben sind Befehle (`build`, `sell`, `callNextWave`). Darstellung ändert nie
   Zustand direkt.
3. Die Simulation meldet Ereignisse; Effekte und Ton hängen an Ereignissen.
4. Zustand ist ein `Codable`, `Equatable` Wert.
5. Fester Takt (30/s). 2× heißt mehr Schritte, nicht größere.
6. Keine Iteration über `Dictionary`/`Set` in der Simulation, kein `Date()`, kein
   Zufall außer dem gesäten Generator im Zustand.
7. Keine Zahlenwerte im Code. Ausnahme: Testkonfigurationen in den Tests.
8. Kommentare begründen *warum*, nicht *was*.

## Arbeitsweise

Bei jeder größeren Aufgabe: relevante Dokumente lesen → Repo-Zustand prüfen
(`git status`, `git log`) → kurzer Plan → offene Entscheidungen und Risiken nennen
→ in kleinen Schritten umsetzen → testen → Dokumente und Backlog nachziehen →
berichten (was geändert, welche Tests liefen, was offen ist).

Kleine, eindeutige Änderungen direkt. Bei Auswirkungen auf Spielgefühl,
Architektur, Aufwand oder Monetarisierung: anhalten, Optionen mit Empfehlung
vorlegen.

Ein Arbeitspaket = ein Pull Request. Nach Steffens Wahl vom 25.10.2026 kommt
Arbeit per PR, nicht direkt auf `main`.

## Testen

- Simulation: `swift test --package-path Packages/OddlingsCore` (ab WP-02).
- Balance: `BalanceTests` im Paket (Bot-Bauweisen aus `simStrategies`, Reserve je Bauweise).
- Jede Balanceänderung: Balancetests laufen lassen und Ergebnis in
  [04](docs/game-design/04-economy-and-balance.md) nachtragen.
- Jeder neue Test wird einmal rot gesehen.
- **Cloud-Sitzungen:** Swift für Linux kommt über `scripts/swift-linux.sh`, das der
  Startup-Haken in `.claude/settings.json` im Hintergrund lädt (Log
  `/tmp/swift-linux.log`, ca. 1 Minute). Damit läuft `swift test` für OddlingsCore.
  Die App (SwiftUI, SpriteKit) baut nur die macOS-CI; über sie nie behaupten, sie
  sei grün, ohne den CI-Lauf.

## Verwandte Projekte von Steffen

Zählora (Repo PulseMeter) und Stack & Siege (Repo Fortress) sind bereits über
Xcode/XcodeGen und TestFlight ausgeliefert. Erprobte Abläufe lassen sich von dort
übernehmen, insbesondere `.claude/skills/xcode-workflow` und
`.claude/skills/projekt-baukasten` (PulseMeter) sowie `.claude/skills/spielgrafik`
(Fortress). Übernehmen heißt: lesen, anpassen, hier ablegen – nicht blind kopieren.
