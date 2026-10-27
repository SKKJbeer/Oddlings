# Stand des Projekts

Kurzer Überblick für Steffen, bei jeder Auslieferung neu geschrieben (nicht
ergänzt, D-067). Reihenfolge, Pakete und alles, was auf dich wartet, stehen in der
[Roadmap](roadmap.md); Einzelheiten im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 27.10.2026, 10:30** · Neueste Version **0.12.0** (Avatarrang und Avatar-Menü), Bau läuft;
neuester VALID-Bau 32 (0.11.1). Der Spielrahmen R-1 bis R-6 steht. Spielbar ist Mission 1.

## Wartet auf dich

1. **Darf der neue 3D-Plünderer ins Spiel?** Entscheidungskarte im Thread
   „Plünderer-3D-Modell mit Token erzeugen“. Ohne Antwort ruht FX 02.
2. Volk wechseln, bevor es eine Spielwährung gibt: Entscheidungskarte im Haupt-Thread.
   Blockiert nichts, es gilt „gar nicht“.
3. **Spieltest mit drei Personen** (WP-15) auf dem neuesten Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Davon hängen Phase 2 und die
   Werte von Mission 1 ab.
4. Ohne Eile: Messung des Spikes auf dem iPhone (WP-01).

## Fertig

- **Mission 1 spielbar** mit Kreismenü, Kopfleiste, Pause, 2×, Ergebnis, Neustart (0.5.0, 0.6.0).
- **Spielrahmen** (D-060): Hauptmenü, Einstellungen, Spielstand, gemalte Kampagnenkarte
  Region 1 mit Sternen (0.7.0, 0.10.2), Steinregen (0.8.0), Zwerge mit Bollwerk und
  billigeren Wachtürmen, Elfen mit Mondmal (0.9.0, 0.10.1).
- **Avatar** (D-063 bis D-065): einmal am Anfang Volk, Porträt und Name (0.11.0); Rang aus
  Sternen, vier Talentreihen je Volk, eigenes Avatar-Menü (0.12.0). Die erste Talentwahl
  kommt mit Mission 2 (ab 6 Sternen).
- **Grafik und Bewegung**: gemalte Figuren, Türme, Symbole, Titelbild, Kampfplatz als
  Waldlichtung mit Zwergenfeste, Porträts (Grafik 01 bis 05); Laufen, Treffer, Tod,
  Turmangriffe und Fähigkeiten als Effekte (FX 01, 0.10.0).
- **Qualität**: rund 190 Kerntests, 87 App-Tests, 27 Ende-zu-Ende-Fälle, Probelauf im
  Simulator, alles bei jedem PR in der CI.
- **Doku nachgezogen** (27.10.2026): Architektur, Datenmodelle, Teststrategie,
  Oberfläche, Art, Roadmap; die CI prüft seitdem, dass der Doku-Stand mitwächst (D-067).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Haupt-Thread | 0.12.0 in TestFlight | Konzept R-7 Ausrüstung (D-066) mit Karten an dich |
| Plünderer-3D-Modell | FX 02: Plünderer mit Gliedmaßen fertig | wartet auf deine Freigabe (Punkt 1) |

## Als Nächstes

Die Reihenfolge steht in der [Roadmap](roadmap.md#als-nächstes): FX 02 einbauen,
R-7 Ausrüstung, Spieltest, dann Mission 2 mit Zwergenbank und Ton.
