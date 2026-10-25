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
swift test --package-path Packages/OddlingsCore
scripts/regeln-pruefen.sh
```

Balance berührt? Ergebnis der `BalanceTests` in
`docs/game-design/04-economy-and-balance.md` nachtragen.
Die App baut nur auf dem Mac: über die App erst etwas sagen, wenn der CI-Lauf
`iphone` grün ist.

## 4. Dokumente nachziehen

- **`CHANGELOG.md`**: neuer Eintrag oben, Version in `project.yml`
  (`MARKETING_VERSION`) hochsetzen. WP = zweite Stelle, Korrektur/Doku = dritte.
- Backlog: WP abhaken, Abweichungen von den Abnahmekriterien nennen.
- `CLAUDE.md`, Abschnitt „Stand“.
- Neue Absprache oder Entscheidung von Steffen: dort festhalten, wo sie
  hingehört (Entscheidungsprotokoll, `CLAUDE.md`, ein Skill), genau einmal.

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
   im nächsten PR mit.

## 7. Melden

Kurz an Steffen: was ausgeliefert ist, Version und Bau, was offen ist. Keine
Zwischenmeldungen ohne Ergebnis.
