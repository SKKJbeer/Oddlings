# Konzept: Ton und Musik (P2-3)

Status: **[VORSCHLAG]**, Musikquelle **[ENTSCHIEDEN D-082]** · Stand 01.11.2026 ·
Thread „Ton und Musik für Oddlings gestalten"
Grundlage: [K9](phase-2-3.md#k9--ton-und-haptik),
[Rückmeldung je Ereignis](../art/rueckmeldung-je-ereignis.md) (Spalte „Ton"),
[Marktanalyse](../game-design/market-analysis.md) E1, E2 und Abschnitt 3
(„Eigene Klangfarbe je Turm … Begrenzung gleichzeitiger Klänge. Musik wechselt mit
der Lage"), [07 Oberfläche](../game-design/07-ui-ux.md) Abschnitt 5.

## Ziel

Bis 0.13.0 ist Oddlings stumm. Nach diesem Paket hat jede Zeile der
Rückmeldeliste einen Klang, jede Bedienhandlung einen kurzen Ton, und Musik
trägt die Lage: ruhig im Menü, treibend im Kampf, drängend in der letzten Welle,
Fanfare oder Moll-Ausklang am Ende. In einer vollen Welle bleibt es hörbar und
lesbar, nichts übertönt die eigene Handlung.

## Umfang

**Drin:** Klänge für alle Simulationsereignisse und die Bedienung, vier Musiklagen
plus zwei Ausklänge, Lautstärkeregler für Klänge und Musik in den Einstellungen,
Rücksicht auf Stummschalter und fremde Musik, Pause und Hintergrund, Lizenzprüfung
in der CI, Tests auf allen Ebenen.

**Nicht drin:** Stimmen, Raumklang, Musik je Region oder Bossfassung (es gibt
noch keine zweite Region und keinen Boss, K9), Klangunterschiede je Volk. Alles
davon passt später in dieselbe Tabelle, ohne Umbau.

## Klangstil [VORSCHLAG]

- **Musik:** verspielt-mittelalterlich, kleine Besetzung mit Laute, Flöte,
  Streichern und Trommeln. Vier der fünf Stücke stammen von einem Komponisten
  (RandomMind, Reihe „Medieval"), damit Menü, Kampf, Sieg und Niederlage nach einem
  Spiel klingen. Die letzte Welle nimmt ein orchestrales Stück (Emma_MA), das
  bewusst größer klingt: Die Musik soll hier spürbar anziehen (Marktanalyse,
  Abschnitt 3).
- **Klänge:** natürlich und körperlich statt Pieps: Stein setzt auf, Pfeil zischt,
  Blitz knistert, Sporen machen „Puff", Gegner zerplatzen mit Plopp (Comic, passt
  zum Zerplatzen in FX 01). Bedienung leise und kurz (Kenney Interface).
- **Wiederholung:** Häufige Klänge haben zwei bis drei Fassungen und eine kleine
  Tonhöhenstreuung, damit eine Welle nicht wie ein Maschinengewehr klingt.

## Quellen und Lizenzen [ENTSCHIEDEN D-082]

Steffen, 01.11.2026: Musik bleibt dauerhaft frei. Dasselbe gilt hier für die
Klänge. Erlaubt ist nur **CC0** (keine Namensnennung, keine Weitergabebedingung,
auch in einem öffentlichen Repo unproblematisch). Herkunft je Datei steht in
genau einer Liste, [`art/ton/klaenge.json`](../../art/ton/klaenge.json): Seite,
Download, Autor, Lizenz, SHA-256 des Downloads, Pfad im Archiv, Schnitt. Lesbar
aufbereitet in [`art/ton/ENTSTEHUNG.md`](../../art/ton/ENTSTEHUNG.md).

- `tools/ton/ton_bauen.py` lädt jede Quelle, prüft die Prüfsumme, schneidet,
  gleicht an (Klänge Spitze −1 dBFS, Mono, 44,1 kHz, CAF/PCM; Musik −16 LUFS,
  AAC 128 kbit/s, M4A) und schreibt nach `App/Audio/Sounds`. Ein Klang wird
  getauscht, indem man die Liste ändert und das Skript erneut laufen lässt.
- `tools/ton/ton_pruefen.py` (CI, Job `art`) bricht, wenn eine Datei unter
  `App/Audio/Sounds` nicht in der Liste steht, eine Liste ohne Datei ist, eine
  Quelle eine andere Lizenz als CC0 trägt, eine Prüfsumme fehlt oder Klänge,
  Musik oder das Paket zu groß werden. Dazu prüft es, dass jede Datei, die
  `AudioStyle.swift` nennt, existiert.
- Bekannte Falle: Die Suche auf OpenGameArt filtert nicht zuverlässig nach
  Lizenz. Maßgeblich ist das Lizenzfeld der jeweiligen Seite.

## Architektur

```
Simulation ──Event──▶ BattleScene ──SoundMoment──▶ AudioDirector ──▶ SoundOutput (AudioEngine)
                         │                              │                 AVAudioEngine: Klänge
Controller ─UserAction──▶┘ (Bedienung)                  │                 AVAudioPlayer: Musik
StartView/BattleView ─Lage──────────────────────────────┘ MusicMood
```

| Baustein | Ort | darf | darf nicht |
|---|---|---|---|
| `SoundMoment`, `SoundCue`, `MusicMood` | `App/Audio/SoundCue.swift` | beschreiben, was zu hören ist | – |
| `SoundMap` (rein) | `App/Audio/SoundMap.swift` | Ereignis → Moment → Klang; Lage aus Schirm und Welle | Zustand lesen außer dem übergebenen Ereignis |
| `SoundLimiter` (rein) | `App/Audio/SoundLimiter.swift` | Stimmen je Klang und Mindestabstand begrenzen | Uhrzeit selbst lesen (bekommt sie hineingereicht) |
| `AudioStyle` | `App/Audio/AudioStyle.swift` | Mischung: Pegel, Stimmen, Abstand, Streuung, Überblendung | – |
| `AudioDirector` | `App/Audio/AudioDirector.swift` | Moment annehmen, begrenzen, Fassung wählen, Lage wechseln, zählen | Spielzustand ändern |
| `AudioEngine` | `App/Audio/AudioEngine.swift` | AVFoundation, Audiositzung, Unterbrechungen | Spielregeln kennen |

- **Architekturregel 3:** Klänge hängen an Ereignissen. `BattleScene.play(_:)`
  ruft neben dem `FxDirector` den `AudioDirector`; beide lesen und ändern keinen
  Zustand. Der Sporenfunke (E2) wird wie im Bild dort erkannt, wo das Ziel
  verlangsamt ist.
- **Zuschauen:** Die Vorführung klingt wie ein Spiel, aber ohne Bedientöne.
- **Zufall:** Die Fassung eines Klangs wählt ein eigener, gesäter Generator im
  Director (Darstellung, nicht Simulation; Regel 6 gilt für den Kern).
- **Rückgabe statt Wirkung:** `SoundOutput` ist ein Protokoll. Tests setzen einen
  Mitschreiber ein und prüfen, was gespielt würde, ohne Lautsprecher.
- **Engine:** ein `AVAudioEngine` mit 16 vorbereiteten Spielern (je mit
  `AVAudioUnitVarispeed` für die Tonhöhe) an einem Klangbus; alle Klänge liegen
  beim Start als Puffer im Speicher (zusammen unter 1 MB). Ist kein Spieler frei,
  entfällt der Klang (zählt als `dropped`). Musik über zwei `AVAudioPlayer`
  mit Überblendung, weil sie gestreamt und nahtlos geschleift wird.
- **Audiositzung `.ambient`:** Der Stummschalter macht das Spiel stumm, und hört
  jemand eigene Musik, läuft sie weiter. Dann schweigt die Spielmusik
  (`secondaryAudioShouldBeSilencedHint`), die Klänge bleiben.
- **Pause, Hintergrund, Anruf:** Bei Pause wird die Musik auf `pauseDuck`
  gedämpft, Klänge laufen aus. Im Hintergrund hält die Engine an und startet
  beim Zurückkommen neu; eine Unterbrechung (Anruf, Siri) ebenso.
- **2×:** Mehr Schritte heißt mehr Ereignisse; der Begrenzer hält die Dichte.

## Klang je Ereignis

| Moment | Ereignis | Klang | Stimmen / Abstand |
|---|---|---|---|
| Bauen | `towerBuilt` | Stein setzt auf (2 Fassungen) | 2 / 0,05 s |
| Verkaufen | `towerSold` | Münzen | 2 |
| Abgelehnt | `commandRejected`, „zu wenig Gold" | dumpfes Tok | 1 / 0,15 s |
| Wachturm schießt | `towerFired` | Pfeil zischt (3) | 4 / 0,04 s |
| Blitz | `towerFired` | Knistern (2), Tonhöhe steigt mit der Kettenlänge | 3 |
| Sporenturm | `towerFired` | Puff (2) | 3 |
| Sporenfunke (E2) | Blitz trifft verlangsamtes Ziel | heller Glasklang | 2 / 0,08 s |
| Treffer | `enemyDamaged` | Holztreffer (2), leise | 4 / 0,05 s |
| Verlangsamt | `enemySlowed` | Blubbern | 2 / 0,15 s |
| Gegner fällt | `enemyKilled` | Plopp (3) | 4 / 0,03 s |
| Gold | `enemyKilled` | Münzklang, leise | 2 / 0,08 s |
| Durchbruch | `enemyLeaked` | dumpfer Schlag | 2 |
| Welle | `waveStarted` | Gong | 1 |
| Fähigkeit wirken | `abilityCast` | Zauber | 1 |
| Steinregen / Mondmal | `abilityImpact` | Felssturz (2) / Zauberschlag | 1 |
| Bollwerk | `barrierRaised` / `barrierFell` | Steine schieben / zerbrechen | 1 |
| Bedienung | Zelle, Vorschau, Verkaufen scharf | leises Tippen (2) | 2 / 0,03 s |
| Welle rufen | `callWave` | Bestätigung | 1 |
| zu wenig Gold | `cannotAfford` | Tok | 1 / 0,15 s |

Musiklagen: `menu` (Hauptmenü, Karte, Avatar), `battle` (Kampf und Vorführung),
`finalWave` (ab Start der letzten Welle), `victory` / `defeat` (einmal, ohne
Schleife). Wechsel mit Überblendung (`crossfade`), Pause dämpft.

## Bedienentscheidungen [VORSCHLAG]

- Zwei Regler in den Einstellungen, Klänge und Musik, je 0 bis 100 %. Vorgabe
  Klänge 80 %, Musik 60 %: Musik soll tragen, nicht übertönen. Ein Regler
  wirkt sofort hörbar (Probeton beim Loslassen).
- Kein eigener Stummschalter: Regler auf 0 oder der Stummschalter des iPhones.
- Werte gehören dem Gerät wie die Vibration (K6) und werden beim Laden auf
  0…1 begrenzt.

## Sicherheit

Keine Fremdbibliothek (nur AVFoundation), kein Netz zur Laufzeit. Downloads
gibt es nur im Bauwerkzeug, mit Prüfsumme je Quelle. Lizenzen werden in der CI
geprüft. Eingelesene Einstellungen werden begrenzt.

## Testplan

| Ebene | Test | prüft |
|---|---|---|
| Werkzeug | `tools/ton/tests` (CI `art`) | Prüfer findet fehlende Datei, fremde Lizenz, fehlende Prüfsumme, unbekannte Datei; echte Liste ist sauber |
| App | `SoundMapTests` | jede Ereignisart hat ihren Klang, Sporenfunke, Blitzhöhe, letzte Welle wechselt die Lage, Zuschauen ohne Bedientöne |
| App | `SoundLimiterTests` | Stimmen und Abstand je Klang, Freigabe nach Ablauf |
| App | `AudioDirectorTests` | Lautstärke aus den Einstellungen, Pause dämpft, Fassungswechsel, Zähler |
| App | `AudioAssetTests` | jede Datei aus `AudioStyle` liegt im Bündel und lädt als Puffer |
| App | `AppSettingsTests` | Regler-Vorgaben, Speichern, Begrenzen |
| E2E | `SoundE2ETests` | Vorführung spielt jede Klanggruppe und die Kampfmusik (`audio.stats`, nur Debug); Regler in den Einstellungen bleiben nach Neustart |
