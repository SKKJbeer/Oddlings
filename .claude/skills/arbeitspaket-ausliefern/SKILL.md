---
name: arbeitspaket-ausliefern
description: Ein Arbeitspaket von Oddlings bis TestFlight bringen – Tests, Regeln, Änderungsprotokoll, PR, grüne CI, Zusammenführen, Bau VALID. Für jedes WP und jede Korrektur.
---

# Arbeitspaket ausliefern

Gilt für jedes Arbeitspaket (WP) aus `docs/production/backlog.md` und für jede
Korrektur. Grundlage sind die Absprachen in `CLAUDE.md`, Abschnitte
„Arbeitsweise“ und „Qualität und Sicherheit“.

## 1. Vorher

1. `git fetch origin main`, Zweig `claude/…` frisch von `origin/main`.
   Es gibt nur einen Push-Zweig: PRs laufen nacheinander, nie zwei offen.
2. Abnahmekriterien des WP im Backlog lesen, dazu die Dokumente, auf die es
   verweist. Vor Designarbeit: `docs/game-design/market-analysis.md`, Abschnitt 7.
3. **Konzept schreiben, bevor Code entsteht** (Steffen, 25.10.2026):
   `docs/konzepte/<wp>-<name>.md` mit Ziel, Umfang und Abgrenzung, Architektur
   (Datenfluss, welche Schicht was darf, Bezug auf die Architekturregeln),
   Bedienentscheidungen mit Kennzeichnung, Sicherheit, Testplan je Ebene.
   Vorlage: `docs/konzepte/wp-12-14-spielbare-mission.md`. Nur kleine
   Korrekturen kommen ohne Konzept aus.
4. Berührt das WP Spielgefühl, Architektur, Aufwand oder Geld und ist die Frage
   nicht entschieden: Steffen fragen (Optionen mit Empfehlung), auf der
   Empfehlung weiterarbeiten, Antwort ins Entscheidungsprotokoll.

## 2. Umsetzen

- **Jedes Feature, das man auf dem Bildschirm sieht, bekommt seinen
  End-zu-End-Fall in `AppUITests/`** (Steffen, 25.10.2026, D-029), über
  `E2EApp`, Zahlen aus der Missionsdatei. Konzept: `docs/konzepte/e2e-tests.md`.

- Regeln in `Packages/OddlingsCore`, Darstellung in `App/`. Zahlen nur in
  `mvp-mission-01.json`.
- **Tests gehören dazu.** Jede neue Regel und jedes neue Verhalten bekommt einen
  Test, Regeln im Paket (Swift Testing), Darstellung in `AppTests/` (XCTest).
- Jeder neue Test wird einmal rot gesehen: Quelle sichern, Fehler einbauen,
  Lauf ansehen, Quelle zurück.
- Kann etwas Neues automatisch geprüft werden (eine Regel, ein Verbot, ein
  Format), kommt die Prüfung in die CI, meist in `scripts/regeln-pruefen.sh`.

## 3. Prüfen vor dem Push

```bash
export PATH=/opt/swift/usr/bin:$PATH        # Cloud-Sitzung
swift test -c release -Xswiftc -enable-testing --package-path Packages/OddlingsCore
scripts/regeln-pruefen.sh
```

Balance berührt? Ergebnis der `BalanceTests` in
`docs/game-design/04-economy-and-balance.md` nachtragen.
Die App baut nur auf dem Mac: über die App erst etwas sagen, wenn der CI-Lauf
`iphone` grün ist.

## 4. Dokumente nachziehen (Pflicht, D-067)

Steffen, 27.10.2026: Architektur und Design werden bei **jeder** Auslieferung
mitgezogen, damit Struktur und Dokumentation sauber bleiben. Ein PR ohne passende
Doku ist nicht fertig. Gehe die Tabelle durch und fasse an, was zutrifft:

| Wenn der PR … | dann im selben PR |
|---|---|
| eine Version hebt | `CHANGELOG.md` oben, `MARKETING_VERSION` in `project.yml`, `CLAUDE.md` „Stand“, `docs/production/status.md` neu schreiben, Roadmap-Zeile „Ausgeliefert“ (die CI prüft die Version in `CLAUDE.md` und `status.md`) |
| einen Ordner unter `App/` oder eine Datei im Kern anlegt, umbenennt oder löscht | `docs/technical/architecture.md` §5 (Kern-Tabelle) und §6 (Module) – die CI prüft beides |
| einen Datenfluss oder eine Schichtgrenze ändert | `architecture.md` §6 Datenfluss, bei Regelbruch Eintrag im Entscheidungsprotokoll |
| ein Feld in Konfiguration, Zustand, Spielstand, Kampagne ändert | `docs/technical/data-models.md`, Schemaversion und Migration nennen |
| einen E2E-Fall oder Testschalter hinzufügt | `docs/technical/testing-strategy.md`, Tabelle und Schalterliste |
| Spielregeln, Werte, Völker, Avatar, Kampagne ändert | das zuständige `docs/game-design/0x-*.md`; Werte nur in der JSON, Messung in 04 |
| einen Schirm, Ablauf oder ein Bedienelement ändert | `docs/game-design/07-ui-ux.md` (Schirmfolge, Abschnitt des Schirms) |
| Bilder, Figuren, Effekte, Werkzeuge der Grafik ändert | `docs/art/` (Art-Direction, Asset-Vertrag, Figuren), `ENTSTEHUNG.md` der Bildgruppe |
| eine Entscheidung von Steffen umsetzt oder bringt | Entscheidungsprotokoll, Fachdokument, Register `offene-fragen.md` |
| ein Paket abschließt oder ein neues anlegt | `docs/production/roadmap.md` (Als Nächstes, Ausgeliefert), Backlog abhaken |
| eine neue Absprache oder einen Ablauf bringt | `CLAUDE.md` oder ein Skill unter `.claude/skills/`, genau einmal |

Danach `scripts/regeln-pruefen.sh` (prüft Verweise, Nummern und den Doku-Stand).

### Entscheidungskarten

Jede Karte an Steffen (`request_decision`) im selben Zug dem Coordinator melden
(`message_coordinator`: Frage, Thread, Empfehlung, was sie blockiert), damit er sie
im Projektchat mit Link zeigt, und in der Roadmap unter „Wartet auf Steffen“
eintragen. Ist sie beantwortet: Entscheidungsprotokoll, Fachdokument, Zeile in der
Roadmap streichen. Eine Karte, die niemand sieht, blockiert still (27.10.2026: zwei
Karten lagen unbemerkt einen Tag).

## 5. PR und Zusammenführen

1. Push, PR auf `main`, PR-Abo einschalten.
2. CI rot: Ursache aus dem Protokoll, beheben, neu pushen. Nie einen Test
   abschalten.
3. CI grün (`regeln`, `core-linux`, `iphone`): selbst zusammenführen
   (Steffens Auftrag vom 25.10.2026), mit dem vollen Commit-Hash.

## 6. Bis aufs Gerät

Fertig heißt: Bau VALID in TestFlight, nicht „auf main“.

1. Nach dem Zusammenführen läuft `testflight.yml`, wenn App, Paket oder
   `project.yml` geändert sind. Den Lauf ansehen, nicht annehmen:
   ```bash
   gh api 'repos/SKKJbeer/Oddlings/actions/workflows/testflight.yml/runs?per_page=3' \
     --jq '.workflow_runs[]|"\(.run_number) \(.head_sha[0:7]) \(.conclusion)"'
   ```
2. Rot: fehlgeschlagenen Schritt im Protokoll suchen, beheben, als Korrektur
   ausliefern. (Bauten 6 bis 11 scheiterten unbemerkt, weil niemand nachsah.)
3. Grün: Laufnummer = Baunummer. Im `CHANGELOG.md` beim Eintrag nachtragen,
   dazu Spalte „Bau“ in der Roadmap („Ausgeliefert“) und `status.md`, im nächsten PR mit.

## 7. Melden

Kurz an Steffen: was ausgeliefert ist, Version und Bau, was offen ist. Keine
Zwischenmeldungen ohne Ergebnis.
