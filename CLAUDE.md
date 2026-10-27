# Oddlings – Arbeitsgrundlage für Claude Code

> Arbeitstitel „Project Oddlings" (nicht final). Fantasy-Tower-Defense für iPhone,
> nativ in Swift. Solo-Entwicklung durch Steffen mit KI-Unterstützung.
> Sprache in Dokumenten und Gespräch: Deutsch. Code, Bezeichner, Commits: Englisch.

## Stand

**Phase 1 technisch fertig, Spieltest WP-15 offen.** Mission 1 ist spielbar
(WP-02 bis WP-14, UI-01). Vorgezogener Spielrahmen (D-060) steht bis R-6: Hauptmenü,
Kampagnenkarte Region 1 mit Sternen, Steinregen, Völker Zwerge/Elfen, Avatar einmal am
Anfang (0.11.0), Avatarrang mit Talenten und eigenem Avatar-Menü (0.12.0). Grafik 01
bis 05 (zuletzt Kampfplatz und Zwergenfeste, 0.11.1), Effekte an Ereignissen über
`App/Battle/Fx/FxDirector` (FX 01, D-050). In Arbeit: FX 02 (Gegner mit Gliedmaßen aus
3D, wartet auf Steffens Freigabe), danach R-7 Ausrüstung (D-066). Reihenfolge und was
auf Steffen wartet: [Roadmap](docs/production/roadmap.md), Kurzstand:
[status.md](docs/production/status.md), Versionen: [CHANGELOG.md](CHANGELOG.md).
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

**Vorgezogen (D-060, Steffen 25.10.2026):** Hauptmenü, Kampagnenkarte Region 1,
Festungsfähigkeit, Völkerwahl, Avatar mit Rang, Talenten und Ausrüstung (D-063 bis
D-066), Pakete R-1 bis R-7 in der [Roadmap](docs/production/roadmap.md#vorgezogen-spielrahmen-d-060).

**Nicht drin:** Zwergenbank (Phase 2), Upgrades, Multiplayer, PvP, weitere
Missionen der Kampagne, Echtgeld, Backend, Meta-Progression, 3D, steuerbarer Held.

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
| Oberfläche, HUD, Menüs | [docs/game-design/07-ui-ux.md](docs/game-design/07-ui-ux.md) |
| Architektur, Module, Datenfluss | [docs/technical/architecture.md](docs/technical/architecture.md) |
| Grafikstil, Asset-Vertrag, Figuren | [docs/art/](docs/art/art-direction.md) |
| Datenmodelle | [docs/technical/data-models.md](docs/technical/data-models.md) |
| Tests | [docs/technical/testing-strategy.md](docs/technical/testing-strategy.md) |
| **Gemeinsame Arbeitsliste**: Phasen, Als Nächstes, Wartet auf Steffen | [docs/production/roadmap.md](docs/production/roadmap.md) |
| Stand für Steffen (Fertig / Läuft / Als Nächstes) | [docs/production/status.md](docs/production/status.md) |
| Offene Fragen, wer entscheidet | [docs/production/offene-fragen.md](docs/production/offene-fragen.md) |
| Konzepte, die auf Entscheidung warten | [docs/konzepte/phase-2-3.md](docs/konzepte/phase-2-3.md) |
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
(`git status`, `git log`) → **Konzept und Architektur entwerfen und festhalten**
→ offene Entscheidungen und Risiken nennen → in kleinen Schritten umsetzen → testen → Dokumente und Backlog nachziehen →
berichten (was geändert, welche Tests liefen, was offen ist).

Kleine, eindeutige Änderungen direkt. Bei Auswirkungen auf Spielgefühl,
Architektur, Aufwand oder Monetarisierung: anhalten, Optionen mit Empfehlung
vorlegen.

**Erst Konzept, dann Umsetzung** (Steffen, 25.10.2026). Vor dem ersten Code
eines Arbeitspakets liegt `docs/konzepte/<wp>-<name>.md` mit Ziel, Umfang,
Architektur (Datenfluss, wer was darf), Bedienentscheidungen, Sicherheit und
Testplan. Kleine Korrekturen brauchen keins. Das Konzept geht im selben PR mit.

**Doku wächst mit jeder Auslieferung (D-067, Steffen 27.10.2026).** Wer Verhalten,
Daten, Schirme oder Abläufe ändert, zieht im selben PR nach: Architektur
(`architecture.md`, `data-models.md`, `testing-strategy.md`), Design
(`docs/game-design/`, `docs/art/`), Konzept, Roadmap, `status.md`, „Stand“ oben und
CHANGELOG. Ein PR ohne passende Doku ist nicht fertig. Die CI prüft den prüfbaren
Teil (`scripts/regeln-pruefen.sh`). Welche Änderung welches Dokument berührt:
Skill [`arbeitspaket-ausliefern`](.claude/skills/arbeitspaket-ausliefern/SKILL.md), Abschnitt 4.

**Nichts blockiert unbemerkt (D-067).** Jede Entscheidungskarte für Steffen meldet
der Thread im selben Zug dem Coordinator (`message_coordinator`), der sie im
Projektchat mit Link zeigt, und trägt sie in der Roadmap unter „Wartet auf Steffen“
ein. Beantwortet: ins Entscheidungsprotokoll, Zeile aus der Roadmap streichen.

Ein Arbeitspaket = ein Pull Request. Nach Steffens Wahl vom 25.10.2026 kommt
Arbeit per PR, nicht direkt auf `main`.

Ablauf von der Umsetzung bis zum Bau in TestFlight:
[`.claude/skills/arbeitspaket-ausliefern`](.claude/skills/arbeitspaket-ausliefern/SKILL.md).

**Absprachen mit Steffen (25.10.2026):**
- Claude arbeitet das Backlog selbstständig ab, führt PRs bei grüner CI selbst
  zusammen und richtet Zugänge selbst ein. Steffen wird gefragt bei Design-,
  Feature- und Architekturentscheidungen, mit Optionen und Empfehlung, und lieber
  einmal zu viel als zu wenig, wenn etwas unklar ist.
- Jede Absprache und Entscheidung wird festgehalten: Entscheidungen im
  [Entscheidungsprotokoll](docs/decisions/decision-log.md), Arbeitsregeln hier,
  wiederkehrende Abläufe als Skill unter `.claude/skills/`.
- Jede Auslieferung bekommt eine Version und einen Eintrag in
  [CHANGELOG.md](CHANGELOG.md), mit Baunummer, sobald Apple den Bau als VALID meldet.

## Testen

- Simulation: `swift test -c release -Xswiftc -enable-testing --package-path Packages/OddlingsCore` (ab WP-02; Release, weil die Balancetests sonst über 20 Minuten brauchen).
- Balance: `BalanceTests` im Paket (Bot-Bauweisen aus `simStrategies`, Reserve je Bauweise).
- Jede Balanceänderung: Balancetests laufen lassen und Ergebnis in
  [04](docs/game-design/04-economy-and-balance.md) nachtragen.
- Jeder neue Test wird einmal rot gesehen.
- **Cloud-Sitzungen:** Swift für Linux kommt über `scripts/swift-linux.sh`, das der
  Startup-Haken in `.claude/settings.json` im Hintergrund lädt (Log
  `/tmp/swift-linux.log`, ca. 1 Minute). Damit läuft `swift test` für OddlingsCore.
  Die App (SwiftUI, SpriteKit) baut nur die macOS-CI; über sie nie behaupten, sie
  sei grün, ohne den CI-Lauf.

## Qualität und Sicherheit (Steffen, 25.10.2026, gilt für jede Auslieferung)

- **Jede Auslieferung bringt Tests mit.** Ein PR, der Verhalten ändert, enthält
  die Tests dafür; Regeln in der Simulation, Darstellung in den App-Tests
  (`AppTests/`). Kein PR ohne neue oder angepasste Tests, außer reinen Dokumenten.
- **Die CI prüft alles, was geprüft werden kann**: Regeln (`scripts/regeln-pruefen.sh`),
  Simulation unter Linux, App-Bau, App-Tests und Probelauf im Simulator. Zusammengeführt
  wird nur bei grünem Lauf. Was neu dazukommt und prüfbar ist, bekommt einen Schritt
  dort, statt nur beschrieben zu werden.
- **Saubere Architektur**: die Architekturregeln oben, ein Modul je Aufgabe, keine
  zweite Umsetzung derselben Sache. Wer eine Regel brechen will, schreibt einen
  Eintrag ins Entscheidungsprotokoll.
- **Sicherheit**: Schlüssel und Zertifikate nur in GitHub-Secrets, nie im Repo und
  nie im Protokoll. Abläufe mit knappen Rechten (`permissions` auf oberster Ebene),
  fremde Actions nur an einem festen Commit. Keine Fremdbibliotheken ohne Eintrag im
  Entscheidungsprotokoll. Alles, was von außen kommt (Konfiguration, Spielstand),
  wird beim Laden geprüft, bevor es die Simulation erreicht. Kein Netzcode im MVP.
  `scripts/regeln-pruefen.sh` hält die prüfbaren Teile davon fest.

## Verwandte Projekte von Steffen

Zählora (Repo PulseMeter) und Stack & Siege (Repo Fortress) sind bereits über
Xcode/XcodeGen und TestFlight ausgeliefert. Erprobte Abläufe lassen sich von dort
übernehmen, insbesondere `.claude/skills/xcode-workflow` und
`.claude/skills/projekt-baukasten` (PulseMeter) sowie `.claude/skills/spielgrafik`
(Fortress). Übernehmen heißt: lesen, anpassen, hier ablegen – nicht blind kopieren.
