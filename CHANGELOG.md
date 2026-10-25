# Änderungsprotokoll

Jede Auslieferung auf `main` bekommt hier einen Eintrag, neueste oben.

- **Version** = `MARKETING_VERSION` in `project.yml`. Neue Funktion oder neues
  Arbeitspaket: zweite Stelle (0.2.0 → 0.3.0). Korrektur, Doku, Werkzeug: dritte
  Stelle (0.2.0 → 0.2.1).
- **Bau** = Laufnummer von `testflight.yml`, wird beim Archivieren als
  `CURRENT_PROJECT_VERSION` gesetzt. Ein Bau zählt erst, wenn Apple ihn als VALID
  meldet. Gescheiterte Bauten stehen mit Grund dabei, weil ihre Nummer verbraucht ist.
- Ein Eintrag, der nichts an der App ändert (nur Dokumente), löst keinen Bau aus.
  Dort steht „kein Bau“.

## 0.3.2 – 25.10.2026

**Neu**
- Konzept für Oberfläche und Bedienung: [07-ui-ux.md](docs/game-design/07-ui-ux.md)
  mit Raster je iPhone, HUD-Ecken, Bauen und Verkaufen am Feld, Pause, Sieg,
  Niederlage, Hauptmenü, Richtung der Kampagnenkarte und der Architektur
  (`HudLayout`, `PlacementState`, `BattleHUDModel`).
- Klickbare Entwürfe aller Schirme: [Oddlings – Spieloberfläche](https://claude.ai/artifact/PKpZrLVV42wje1isSfvB8z).
- Vorschläge D-017 (HUD-Ecken), D-018 (Kreismenü, liegt Steffen vor), D-019 (Schriften).

**Tests**: keine, nur Dokumente. Die Tests der Bausteine stehen in 07 und kommen
mit WP-12 bis WP-14.

Kein Bau.

## 0.3.1 – 25.10.2026

**Neu**
- CI-Schritt `regeln` (`scripts/regeln-pruefen.sh`): bricht ab, wenn die
  Simulation mehr als Foundation importiert oder Uhrzeit, Zufall oder Umgebung
  benutzt, bei Netzcode, bei eingecheckten Schlüsseln oder Zertifikaten, bei
  Abläufen ohne festgelegte Rechte und bei fremden Actions ohne festen Commit.
- `CLAUDE.md`: Abschnitt „Qualität und Sicherheit“ und die Absprachen mit Steffen
  (selbstständig arbeiten, Entscheidungen festhalten, Änderungsprotokoll führen).
- Skill `.claude/skills/arbeitspaket-ausliefern`: der Weg von der Änderung bis zum
  VALID-Bau in TestFlight.

**Tests**: Jede Prüfung in `regeln-pruefen.sh` einmal mit einem eingebauten
Verstoß rot gesehen.

Bau: wird nach dem Zusammenführen nachgetragen.

## 0.3.0 – 25.10.2026

**Neu**
- WP-10: Prüfsumme über den ganzen Spielzustand. Gleicher Startwert und gleiche
  Befehle ergeben dieselbe Prüfsumme, auch nach Speichern und Laden mitten in der
  Welle und bei doppelter Geschwindigkeit.
- Balance wird jetzt im Swift-Paket geprüft (`BalanceTests`), mit denselben
  Bot-Bauweisen wie vorher in Python. Die Bauweisen stehen in
  `mvp-mission-01.json` unter `simStrategies`.

**Entfernt**
- Python-Prüfskript `tools/balance-sim` und der CI-Schritt `balance`. Zwei
  Umsetzungen derselben Regeln wären auseinandergelaufen.

**Befund**: Rangfolge der Bauweisen wie in Phase 0, die Abstände sind kleiner,
weil Türme nicht mehr auf schon tote Ziele schießen (Einzelheiten in
`docs/game-design/04-economy-and-balance.md`).

**Tests**: `DeterminismTests`, `BalanceTests`.

Bau: wird nach dem Zusammenführen nachgetragen.

## 0.2.0 – 25.10.2026

**Neu**
- WP-09: Sieg, sobald alle Wellen erschienen und keine Gegner mehr da sind.
  Ein letzter Durchbruch zählt vorher, eine verlorene Festung gewinnt nicht mehr.
- Befehl „Nächste Welle“ (`callNextWave`): startet die nächste Welle sofort und
  schiebt den restlichen Takt mit. Ohne verbleibende Welle wird er abgewiesen.

**Tests**: `VictoryTests` (Sieg, Reihenfolge Durchbruch vor Sieg, Welle rufen).

Bau: **15 VALID**.

## 0.1.1 – 25.10.2026

**Behoben**
- TestFlight-Bau scheiterte seit Bau 6 beim Archivieren: Das Profil wurde über
  die Befehlszeile gesetzt und galt damit auch für das Ressourcenbündel von
  `OddlingsCore`. Es gilt jetzt nur noch für die App.

**Neu**
- Dieses Änderungsprotokoll, rückwirkend ab Phase 0.

Bau: **13 VALID** (Probebau vom Arbeitszweig vor dem Zusammenführen), **14 VALID** (von main).

## 0.1.0 – 25.10.2026

Alles bis hierher lief unter Version 0.1.0.

| PR | Inhalt | Bau |
|---|---|---|
| #12 | WP-08: Sporenturm mit Puls und Verlangsamung | 12 gescheitert (Profil) |
| #11 | WP-07: Blitzturm mit Kettenblitz | 11 gescheitert (Profil, siehe 0.1.1) |
| #10 | Marktanalyse in Doku, Backlog und Roadmap; D-015 Geschäftsmodell | kein Bau |
| #9 | WP-06: Wachturm, Schaden, Belohnung | 10 gescheitert (Profil) |
| #8 | WP-05: Bauen und Verkaufen, Gold | 9 gescheitert (Profil) |
| #7 | Marktanalyse der führenden mobilen Tower-Defense-Spiele | kein Bau |
| #6 | WP-04: Wellen, Bewegung, Festung | 8 gescheitert (Profil) |
| #5 | WP-03: Weggeometrie und Bauzonen | 7 gescheitert (Profil) |
| #4 | WP-02: Paket OddlingsCore, Konfiguration mit Prüfung | 6 gescheitert (Profil) |
| #3 | Bauen mit Xcode 26, damit TestFlight den Bau annimmt | **5 VALID** |
| #2 | WP-01: Technik-Spike (App-Hülle, Leistungsprobe, CI, TestFlight-Ablauf) | 1–3 gescheitert (Einrichtung), **4 VALID** |
| #1 | Phase 0: Designdokumentation, Balance für Mission 1, Backlog | kein Bau |

Bauten 6 bis 12 enthielten in der App nichts Neues gegenüber Bau 5: Die
Simulation ist bis WP-11 nicht an die Darstellung angebunden.
