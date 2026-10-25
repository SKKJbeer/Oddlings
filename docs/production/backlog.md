# Backlog – Phase 1: Spielbarer Kampfprototyp

Priorität = Reihenfolge. Jedes Paket ist für sich prüfbar und ergibt einen eigenen
Pull Request. Zahlenwerte kommen immer aus der Konfiguration.

Abkürzungen: **Abh.** = Abhängigkeiten.

---

### WP-00 · Phase 0 freigeben
- **Ziel:** Designstand und MVP-Plan sind abgestimmt.
- **Umfang:** Dieses Dokumentationspaket; Entscheidungen B1–B4.
- **Abnahme:** Steffen hat den Pull Request durchgesehen; D-004 bis D-008 sind entschieden
  (D-004 Querformat und D-005 Raster am 25.10.2026).
- **Tests:** `python3 tools/balance-sim/sim.py --reserve` läuft.
- **Abh.:** –  · **Risiken:** –

### WP-01 · Technik-Spike: App-Hülle und Leistungsprobe
- **Stand:** in TestFlight (Bau 4, VALID, 25.10.2026), Messung auf dem iPhone offen.
  Gebaut wird mit Xcode 26, Apple nimmt ältere SDKs nicht mehr an.
- **Ziel:** Beweisen, dass SwiftUI + SpriteKit auf dem iPhone trägt, bevor darauf gebaut wird.
- **Umfang:** `project.yml` (XcodeGen), leere SwiftUI-App im Querformat, `SpriteView` mit
  einer Szene, die 300 Sprites auf einem Pfad bewegt und 30 Kettenblitz-Linien je
  Sekunde zeichnet; SwiftUI-HUD darüber, das zweimal je Sekunde einen Zähler ändert.
  CI-Ablauf (macOS) baut die App.
- **Abnahme:** Auf Steffens iPhone stabil 60 Bilder/s (Anzeige in der App), HUD verursacht
  keine Einbrüche; CI grün. Ergebnis als Notiz in `docs/technical/architecture.md`.
  Die 600-Sprite-Stufe steht für die späteste Welle bei 2×; die Grenze gilt auf dem
  ältesten Zielgerät (iPhone XS/XR, D-006). Ist Steffens Gerät neuer, ist die
  Messung eine Obergrenze, keine Zusage ([Marktanalyse](../game-design/market-analysis.md) E4).
- **Weg aufs Gerät (D-014):** TestFlight. Einmalig von Steffen: App-Eintrag in App Store
  Connect (Bundle-ID `de.skkjbeer.oddlings`) und Apple-Zugänge aus Zählora übertragen
  (PulseMeter → Actions → „Apple-Zugänge weitergeben", Ziel Oddlings).
- **Tests:** CI-Bau. Leistung manuell gemessen und notiert.
- **Abh.:** WP-00 (Ausrichtung, iOS-Version)
- **Risiken:** Läuft nicht → Plan B Godot prüfen, bevor weitergebaut wird. Signierung
  für das Gerät: Bundle-ID und Team festlegen.

### WP-02 · OddlingsCore-Paket und Konfiguration
- **Stand:** umgesetzt (25.10.2026). Linux-Toolchain für Cloud-Sitzungen: machbar,
  `scripts/swift-linux.sh`.
- **Ziel:** Simulation hat ein Zuhause und liest Werte aus einer Quelle.
- **Umfang:** Swift-Paket `OddlingsCore` (nur Foundation); `BalanceConfig` aus
  [data-models.md](../technical/data-models.md); JSON zieht von `config/balance/` in
  die Paket-Ressourcen, Prüfskript liest den neuen Ort; Validierung mit klaren Fehlern;
  Architekturtest (kein SpriteKit-Import). Prüfen, ob eine Linux-Swift-Toolchain für
  Cloud-Sitzungen per Startskript machbar ist.
- **Abnahme:** `swift test` grün; ungültige Konfiguration liefert benannten Fehler.
- **Tests:** Laden der Missionsdatei; je Validierungsregel ein Negativfall; Importtest.
- **Abh.:** WP-00 (parallel zu WP-01 möglich) · **Risiken:** gering

### WP-03 · Karte, Weg und Bauzonen
- **Stand:** umgesetzt (25.10.2026): `PathGeometry`, `MissionMap`, `Cell`, `Placement`.
  Bauzonen werden aus Weg und `minDistanceFromPath` berechnet, nicht einzeln gelistet;
  114 Bauplätze, genau wie im Prüfskript.
- **Ziel:** Geometrie der Mission.
- **Umfang:** Weg als Polylinie, `position(at: distance)`, Weglänge; Bauzonen
  (Rasterzellen, Abstand zum Weg); Zellprüfung frei/belegt/außerhalb.
- **Abnahme:** Weglänge Mission 1 = 32,0; jede Zelle eindeutig klassifiziert.
- **Tests:** Position an Anfang, Knick, Ende; Zelle auf dem Weg ist kein Bauplatz.
- **Abh.:** WP-02 · **Risiken:** Bauzonen gehören in die Konfiguration, nicht in den Code

### WP-04 · Wellen, Gegnerbewegung, Festung
- **Stand:** umgesetzt (25.10.2026). Ohne Türme verliert Mission 1 bei Tick 2731
  (91 s): Die Flitzer aus Welle 3 überholen die letzten Plünderer aus Welle 2.
- **Ziel:** Gegner erscheinen, laufen, brechen durch.
- **Umfang:** `GameState`, `step`, fester Takt, Aufbauzeit, Spawn-Plan aus Wellen,
  `hpScale`, Bewegung, `leakDamage`, Niederlage bei 0 Leben, Ereignisse.
- **Abnahme:** Ohne Türme verliert Mission 1 nach berechenbarer Zeit; Ereignisfolge stimmt.
- **Tests:** Plünderer braucht 32 s ± 1 Tick; Niederlage exakt beim 20. Durchbruch.
- **Abh.:** WP-03 · **Risiken:** Determinismus (T1) von Anfang an beachten

### WP-05 · Bauen, Verkaufen, Gold
- **Stand:** umgesetzt (25.10.2026). Befehle `build`/`sell`, Ablehnung mit Grund
  (zu wenig Gold, belegt, zu nah am Weg, außerhalb, unbekannter Turm). Erstattung
  abgerundet; 90 × 0,7 ergibt in Double 62,999…, deshalb ein Test genau dafür.
- **Ziel:** Ökonomie des Bauens.
- **Umfang:** Befehle `build`, `sell`; Kosten, Erstattung 70 %, Ablehnungsgründe.
- **Abnahme:** Kein Weg führt zu negativem Gold oder zwei Türmen in einer Zelle.
- **Tests:** zu wenig Gold, belegte Zelle, außerhalb Zone, Verkaufen erstattet abgerundet.
- **Abh.:** WP-03, WP-04 · **Risiken:** Rundung der Erstattung festlegen (abrunden)

### WP-06 · Wachturm, Schaden, Belohnung
- **Stand:** umgesetzt (25.10.2026). Abnahme wie im Prüfskript: dieselben Bauplätze
  (11|4, 11|3), zwei Türme 0 Durchbrüche, einer 6 von 8.
- **Ziel:** Erster Turm tötet Gegner.
- **Umfang:** Zielwahl „erster", Abklingzeit in Ticks, Schaden, Tod, Gold-Gutschrift.
- **Abnahme:** Wie im Prüfskript: Zwei Wachtürme auf den besten Plätzen halten Welle 1
  ohne Durchbruch, einer allein lässt 6 von 8 Plünderern durch.
- **Tests:** Zielwahl bei zwei Gegnern; Abklingzeit 0,8 s = 24 Ticks; Belohnung genau einmal.
- **Abh.:** WP-05 · **Risiken:** Reihenfolge im Schritt (data-models.md) einhalten

### WP-07 · Blitzturm
- **Ziel:** Gruppenschaden.
- **Umfang:** Kette mit Sprungradius, Abfall, keine Doppeltreffer; `towerFired(targets:)`.
- **Abnahme:** Kette trifft nur noch nicht getroffene Gegner in Reichweite des letzten Ziels.
- **Tests:** Fall aus [testing-strategy.md](../technical/testing-strategy.md) (18 / 14,4 / 11,52); Kette bricht ab, wenn niemand im Radius.
- **Abh.:** WP-06 · **Risiken:** gering
- **Stand:** Umgesetzt in `Simulation.chainTargets`; Regeltests in `LightningTests` auf eigener `TestConfig` (gerader Weg), damit Balanceänderungen sie nicht brechen. Bei gleichem Abstand springt die Kette zum älteren Gegner ([VORSCHLAG], wie bei der Zielwahl).

### WP-08 · Sporenturm
- **Ziel:** Kontrolle.
- **Umfang:** Puls an alle in Reichweite, Verlangsamung mit Dauer, Erneuerung, kein Stapeln.
- **Abnahme:** Zwei Sporentürme verlangsamen nicht stärker als einer.
- **Tests:** Plünderer unter Dauerverlangsamung braucht doppelt so lang durch die Zone; Ablauf nach 1,5 s.
- **Abh.:** WP-06 · **Risiken:** gering
- **Stand:** Umgesetzt (`Simulation.applySlow`, `Enemy.slow`, Ereignis `enemySlowed`). Ohne Gegner in Reichweite pulst der Turm nicht und bleibt bereit. Ein Puls übernimmt den stärkeren Faktor und die längere Restdauer, verkürzt also nie eine laufende Verlangsamung ([VORSCHLAG]). Tests in `SporeTests`.

### WP-09 · Sieg, Wellentakt, „Nächste Welle"
- **Ziel:** Mission hat ein Ende und einen Fluss.
- **Umfang:** Sieg-Bedingung, Takt nach letztem Erscheinen, Befehl `callNextWave`.
- **Abnahme:** Mission endet genau einmal mit genau einem Ergebnis.
- **Tests:** Sieg erst, wenn der letzte Gegner tot ist; frühes Rufen verschiebt den Plan.
- **Abh.:** WP-04 · **Risiken:** Gleichzeitiger Tod und Durchbruch im letzten Tick → Reihenfolge entscheidet, Test
- **Stand:** Umgesetzt. Sieg wird nach den Durchbrüchen geprüft: Bricht der letzte Gegner durch und die Festung hält, ist es ein Sieg; leert er sie, eine Niederlage. `callNextWave` setzt den nächsten Wellenstart auf den laufenden Tick, der Takt zur übernächsten läuft ab deren letztem Erscheinen. Zwei Rufe im selben Tick starten eine Welle; nach der letzten wird abgelehnt (`noWaveLeft`). Tests in `VictoryTests`.

### WP-10 · Determinismus und Balancetests in Swift
- **Ziel:** Reproduzierbarkeit absichern, Prüfskript ablösen.
- **Umfang:** Replay-Test mit Prüfsumme; 1× = 2×; Speichern/Laden in der Welle;
  Bot-Bauweisen aus `simStrategies` in Swift; Python-Skript löschen.
- **Abnahme:** Swift-Bot liefert dieselbe Rangfolge der Bauweisen wie das Prüfskript.
- **Tests:** siehe Ebenen „Determinismus" und „Balancetests".
- **Abh.:** WP-06 … WP-09 · **Risiken:** Abweichende Ergebnisse zwischen Python und Swift → ein Befund, nicht übergehen
- **Stand:** Umgesetzt. `GameState.checksum` (FNV-1a über die Bitmuster, nicht über JSON), `DeterminismTests`, Bot und `BalanceTests` in den Tests (Gewichte des Bots sind Prüfwerkzeug, keine Spielwerte). Rangfolge gleich wie im Skript, Abstände kleiner: Befund in [04](../game-design/04-economy-and-balance.md#ergebnis-der-prüfung). Python-Skript und CI-Schritt gelöscht.

### WP-11 · Szene zeigt die Simulation
- **Ziel:** Man sieht, was die Simulation tut.
- **Umfang:** Karte, Weg, Bauzonen, Türme, Gegner mit Lebensbalken, Blitzlinien,
  Verlangsamung sichtbar (Einfärbung). Platzhaltergrafik (Formen, Farben).
- **Abnahme:** Mission läuft sichtbar mit Bot-Befehlen ab; Interpolation flüssig.
  Jedes Ereignis der Simulation hat eine sichtbare Rückmeldung (Liste je Ereignis,
  [Marktanalyse](../game-design/market-analysis.md) E1); Verlangsamung als Zustand am
  Gegner, Lebensbalken nur bei Schaden (E3). Grafik und Stil kommen aus dem
  Art-Direction-Thread; WP-11 baut mit Platzhaltern so, dass Assets ohne
  Regeländerung tauschbar sind.
- **Tests:** Knotenzahl = Entitätenzahl über eine ganze Mission.
- **Stand:** Umgesetzt mit Platzhaltern. `BattleModel` rechnet feste Schritte aus der
  Bildzeit (2× = doppelt so viele) und hält den Vorzustand für die Interpolation;
  `BattleScene` gleicht Nodes mit dem Zustand ab und hängt Effekte an Ereignisse
  (Schuss, Blitzkette, Sporenpuls, Treffer, Tod mit „+Gold", Durchbruch, Welle,
  Ende). Bilder heißen wie im Asset-Vertrag (`tower_watch`, `enemy_raider`, …);
  liegt eines im Katalog, wird es benutzt, sonst die Platzhalterform. Mitspieler
  `Autoplayer` im Kern (Vorführbauweise `demoStrategy` aus der Missionsdatei,
  exakte Wegabdeckung statt Abtastung). Tests: `AppTests/BattleSceneTests`
  (Knotenzahl über Mission 1, Neustart, 2×) in der macOS-CI; die CI startet die App
  mit `--demo` und fotografiert die laufende Mission.
- **Abh.:** WP-01, WP-09 · **Risiken:** Logik rutscht in die Szene (T2) → Review-Punkt

### WP-12 · Bedienung: bauen und verkaufen per Antippen ✓ 0.5.0
- **Ziel:** Ein Mensch kann spielen.
- **Umfang:** Zelle antippen → Baumenü mit Preisen, Reichweitenvorschau, bestätigen;
  Turm antippen → Info und Verkaufen; abgelehnte Befehle sichtbar.
- **Abnahme:** Auf dem iPhone ohne Fehltipp bedienbar (Selbsttest + Spieltest).
- **Tests:** UI-Test: Turm bauen und verkaufen.
- **Abh.:** WP-11 · **Risiken:** Fingerverdeckung (P2), Tippziele ≥ 44 pt

### WP-13 · HUD ✓ 0.5.0
- **Ziel:** Gold, Leben, Welle, Zähler, Pause, 1×/2×, „Nächste Welle".
- **Abnahme:** Werte stimmen jederzeit mit dem Zustand; kein Bildeinbruch durch das HUD.
- **Tests:** HUD-Modell setzt nur geänderte Werte.
- **Abh.:** WP-11 · **Risiken:** T3

### WP-14 · Ergebnis und Neustart ✓ 0.5.0
- **Ziel:** Runde schließen, neue Runde.
- **Umfang:** Sieg-/Niederlagen-Bildschirm mit Leben und Dauer; Neustart setzt alles zurück.
- **Abnahme:** Zehn Neustarts hintereinander ohne Speicherwachstum oder Restzustand.
- **Tests:** UI-Test: Mission mit Bot zu Ende, Neustart.
- **Abh.:** WP-12, WP-13 · **Risiken:** gering

### WP-15 · Erster Spieltest
- **Ziel:** Phase 1 abschließen mit Menschen, nicht mit Code.
- **Umfang:** Build auf Steffens Gerät bzw. TestFlight; drei Personen spielen Mission 1;
  Beobachtungsbogen: Wird der Sporenturm gebaut? Wann? Verstehen sie die Kette?
  Dauer, Ergebnis, Abbrüche, Fehltipps.
- **Abnahme:** Protokoll in `docs/production/playtests/`; Balancewerte angepasst oder
  bestätigt; Phase 2 geschnitten.
- **Abh.:** WP-14 · **Risiken:** Ergebnis „macht keinen Spaß" ist ein gültiges Ergebnis

---

## Danach (Phase 2, noch nicht geschnitten)

Reihenfolge und Abhängigkeiten als Entwurf in der
[Roadmap](roadmap.md#entwurf-phase-2-vorschlag) (P2-1 bis P2-9), Konzepte in
[konzepte/phase-2-3.md](../konzepte/phase-2-3.md). Geschnitten wird
nach WP-15; vorher werden hier keine Phase-2-Pakete angelegt. Das Balance-Labor
(K11, D-028) ist als P2-6b und Meilenstein M4.1 eingeplant.

**Für jedes Paket mit Bedienung gilt ab WP-15 zusätzlich:** Ende-zu-Ende-Test des
neuen Ablaufs in `AppUITests/`, grün in der CI (D-029,
[Teststrategie](../technical/testing-strategy.md#ende-zu-ende-tests-d-029)).
