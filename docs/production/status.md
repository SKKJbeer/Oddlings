# Stand des Projekts

Kurzer Überblick für Steffen, bei jeder Auslieferung neu geschrieben (nicht
ergänzt, D-067). Reihenfolge, Pakete und alles, was auf dich wartet, stehen in der
[Roadmap](roadmap.md); Einzelheiten im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 01.11.2026** · Neueste Version **0.16.1** (gemalte Kampfplätze für Mission 2 bis 4), Bau 37 VALID;
davor 0.16.0 (Mission 2 mit Zwergenbank, Bau 36 VALID), 0.15.0 (Ton und Musik), 0.13.0 (Plünderer mit Gliedmaßen). Der Spielrahmen R-1 bis R-6 steht. Spielbar sind Mission 1 und Mission 2.

## Wartet auf dich

1. Volk wechseln, bevor es eine Spielwährung gibt: Entscheidungskarte im Haupt-Thread.
   Blockiert nichts, es gilt „gar nicht“.
2. **Spieltest mit drei Personen** (WP-15) auf dem neuesten Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Davon hängen Phase 2 und die
   Werte von Mission 1 ab.
3. **Was nach der Ausrüstung kommt:** Entscheidungskarte im Thread „Architektur, Doku und
   Roadmap nachziehen“ (Empfehlung: Mission 3 mit Aufwertungen).
4. Ohne Eile: Messung des Spikes auf dem iPhone (WP-01).

## Fertig

- **Mission 1 spielbar** mit Kreismenü, Kopfleiste, Pause, 2×, Ergebnis, Neustart (0.5.0, 0.6.0).
- **Spielrahmen** (D-060): Hauptmenü, Einstellungen, Spielstand, gemalte Kampagnenkarte
  Region 1 mit Sternen (0.7.0, 0.10.2), Steinregen (0.8.0), Zwerge mit Bollwerk und
  billigeren Wachtürmen, Elfen mit Mondmal (0.9.0, 0.10.1).
- **Avatar** (D-063 bis D-065): einmal am Anfang Volk, Porträt und Name (0.11.0); Rang aus
  Sternen, vier Talentreihen je Volk, eigenes Avatar-Menü (0.12.0). Die erste Talentwahl
  kommt mit Mission 2 (ab 6 Sternen).
- **Mission 2 mit Zwergenbank** (P2-5, 0.16.0): neuer Weg, zehn härtere Wellen, die
  Bank als vierter Knopf im Kreismenü (zahlt nach 20 s alle 4 s Gold bis 300, höchstens
  zwei), Gold fürs frühe Rufen der Welle. Nach dem Sieg in Mission 1 auf der Karte
  offen. Werte sind Hypothesen bis zum Spieltest. Gemalter Kampfplatz am Zwergenstollen (0.16.1);
  die Kampfplätze für Mission 3 (Pilzhain) und 4 (Ruinenrand) liegen bereit.
- **Grafik und Bewegung**: gemalte Figuren, Türme, Symbole, Titelbild, Kampfplatz als
  Waldlichtung mit Zwergenfeste, Porträts (Grafik 01 bis 05); Laufen, Treffer, Tod,
  Turmangriffe und Fähigkeiten als Effekte (FX 01, 0.10.0); der Plünderer geht,
  zuckt und stürzt mit echten Armen und Beinen aus einem 3D-Modell (FX 02, 0.13.0).
- **Ton und Musik** (P2-3, 0.15.0): 30 Klänge an den Spielereignissen, fünf Musikstücke
  (Menü, Kampf, letzte Welle, Sieg, Niederlage), Regler für Klänge und Musik in den
  Einstellungen. Nur CC0-Quellen, jede mit Herkunft in `art/ton/` (D-082).
- **Qualität**: rund 190 Kerntests, 122 App-Tests, 31 Ende-zu-Ende-Fälle, Probelauf im
  Simulator, alles bei jedem PR in der CI.
- **Doku nachgezogen** (27.10.2026): Architektur, Datenmodelle, Teststrategie,
  Oberfläche, Art, Roadmap; die CI prüft seitdem, dass der Doku-Stand mitwächst (D-067).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Haupt-Thread | [Konzept R-7 Ausrüstung](../konzepte/r-7-ausruestung.md) steht: höchstens +10 % (D-069), feste Belohnungen und Schmiede (D-070) | R-7a feste Belohnungen umsetzen |
| Mission 2 mit Zwergenbank | 0.16.0, Bau 36 in TestFlight | Werte nach dem Spieltest nachziehen |
| Plünderer-3D-Modell | 0.13.0 in TestFlight | Flitzer und Panzerbestie, wenn dir der Plünderer im Spiel gefällt |
| Ton und Musik | 0.15.0 in Bau 35 | Hörprobe beim Spieltest |

## Als Nächstes

Die Reihenfolge steht in der [Roadmap](roadmap.md#als-nächstes): Mission 2 mit Zwergenbank ist da (deine Wahl vom 01.11., D-080),
R-7 Ausrüstung läuft parallel, der Spieltest korrigiert danach die Werte von Mission 1 und 2. Ton ist mit 0.15.0 drin; hör beim Spieltest bitte auch auf Lautstärke und Musik.
