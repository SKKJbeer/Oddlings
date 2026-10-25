# Rückmeldung je Ereignis

Status: **[VORSCHLAG]** · Umsetzung der Empfehlungen E1–E3 aus der
[Marktanalyse](../game-design/market-analysis.md). Abnahmekriterium für die
Darstellung: Jede Zeile hat Bild, Ton und, wo genannt, Haptik. Nichts passiert
stumm. Die Ereignisse sind die der Simulation (Architekturregel 3); keine Zeile
braucht eine neue Spielregel.

Dauern sind Richtwerte. Effekte sind kräftig, aber kurz, damit sie bei voller
Welle nicht die Lesbarkeit (Säule 2) zerstören.

| Ereignis | Bild | Ton | Haptik | Dauer |
|---|---|---|---|---|
| `towerBuilt` | Turm wächst aus dem Boden (Skalierung 0 → 1,1 → 1,0), Staubring, kleine Funken | Holz/Stein setzt auf, tief | leicht (`.light`) | 0,35 s |
| `towerSold` | Turm sinkt ein, Staub, Goldzahl steigt über der Zelle auf | Münzklang, kurz | leicht | 0,4 s |
| `commandRejected` | Zelle blinkt rot, Turmvorschau wackelt seitlich | dumpfes „Tok" | Warnung (`.warning`) | 0,25 s |
| `towerFired` Wachturm | Pfeil fliegt zum Ziel (nur Darstellung, Treffer ist sofort), Mündungsblitz | Sehne, trocken | – | 0,15 s |
| `towerFired` Blitzturm | Zickzackblitz entlang der Kette in Trefferreihenfolge, Kristall leuchtet auf, Glieder nacheinander mit 40 ms Versatz | Knistern, je Sprung höher | – | 0,25 s |
| `towerFired` Sporenturm | Sporenring breitet sich bis zur Reichweite aus, Hut pumpt | weiches „Puff" | – | 0,5 s |
| `enemyDamaged` | Gegner blitzt weiß auf (1 Bild), kleiner Rückstoß, Lebensbalken erscheint (nur bei Schaden, E3) | Treffer je Turmtyp, Lautstärke gedeckelt | – | 0,1 s |
| `enemySlowed` | Grüner Sporenschleier am Gegner, Symbol `icon_slowed` über dem Kopf, Laufhüpfen halb so schnell | leises Blubbern beim ersten Mal | – | solange verlangsamt |
| Blitz trifft verlangsamtes Ziel (E2) | **Sporenfunke:** größerer grün-blauer Funkenregen, Kettenglied dicker | eigener heller Klang | – | 0,3 s |
| `enemyKilled` | Gegner zerplatzt in Rauch und Konfetti in seiner Farbe, Goldzahl `+n` steigt auf, Goldanzeige im HUD zählt hoch | Plopp plus Münze | – | 0,4 s |
| `enemySpawned` | Gegner tritt am linken Rand aus einem Staubwölkchen | – | – | 0,2 s |
| `enemyLeaked` | Festung bebt, rotes Aufblitzen am Rand, Lebensherz im HUD springt | dumpfer Schlag | mittel (`.medium`) | 0,5 s |
| `waveStarted` | Banner „Welle n" fährt kurz ein, Horn | Horn | – | 1,2 s |
| `missionEnded(won: true)` | Zeitlupe 0,3 s, Konfetti, Ergebnisfenster mit hochzählenden Zahlen | Fanfare | Erfolg (`.success`) | – |
| `missionEnded(won: false)` | Festungstor bricht, Bild entsättigt | tiefer Akkord | Fehler (`.error`) | – |

## Grenzen gegen Überladung

- Höchstens vier gleichzeitige Klänge derselben Art; weitere entfallen.
- Treffer-Aufblitzen je Gegner höchstens alle 0,1 s.
- Bei 2× Geschwindigkeit werden Dauern nicht halbiert, sondern Effekte zusammengefasst.
