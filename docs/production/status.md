# Stand des Projekts

Kurzer Überblick für Steffen, bei jeder Auslieferung neu geschrieben (nicht
ergänzt, D-067). Reihenfolge, Pakete und alles, was auf dich wartet, stehen in der
[Roadmap](roadmap.md); Einzelheiten im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 03.11.2026** · Neueste Version **0.23.0** (Blitz allein verliert Mission 2 und 3), Bau folgt;
davor 0.22.0 (Fortsetzen: eine laufende Mission übersteht das Beenden der App, Bau 43 VALID), 0.21.1 (Balance-Labor in der CI, Bau 42 VALID), 0.21.0 (Schmiede mit Erz im Avatar-Menü, Bau 41 VALID), 0.20.0 (Mission 4 mit gepanzerter Panzerbestie, Bau 40), 0.19.0 (Ausrüstung im Avatar-Menü, Bau 39 VALID), 0.18.0 (Mission 3 mit Aufwertungen, Bau 38 VALID), 0.16.1 (gemalte Kampfplätze für Mission 2 bis 4), 0.16.0 (Mission 2 mit Zwergenbank). Der Spielrahmen R-1 bis R-6 steht. Spielbar sind Mission 1 bis 4.

## Wartet auf dich

1. Volk wechseln, bevor es eine Spielwährung gibt: Entscheidungskarte im Haupt-Thread.
   Blockiert nichts, es gilt „gar nicht“.
2. **Spieltest mit drei Personen** (WP-15) auf dem neuesten Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Davon hängen Phase 2 und die
   Werte von Mission 1 ab.
3. Was Mission 4 Neues bringt: Entscheidungskarte im Thread „Mission 3 mit
   Aufwertungen bauen“. Gebaut ist die Empfehlung, Panzerbestie mit Rüstung.
4. Ohne Eile: drei Karten zur Schmiede (R-7b) im Haupt-Thread: woher die Spielwährung
   kommt, was die Schmiede macht, wie die Währung heißt. Gebaut sind die Empfehlungen
   (0.21.0, D-072); entscheidest du anders, wird umgebaut.
5. Wie schwer Mission 1 bis 4 beim ersten Versuch sein sollen: Entscheidungskarte im
   Haupt-Thread. Empfehlung „steigend“ (M1 ≥ 90 % bis M4 ≥ 50 %), das Labor warnt danach.
6. Das Labor hatte gefunden, dass Blitz allein Mission 2 und 3 gewinnt. Behoben ist es
   mit der Empfehlung der Karte (jetzt, 0.23.0, D-075): Flitzer schneller, Mission 2 etwas
   härter. Entscheidest du anders, wird es zurückgenommen.
7. Ohne Eile: Messung des Spikes auf dem iPhone (WP-01).
8. Wo die App nach einem Neustart mitten in einer Mission öffnet: Entscheidungskarte
   im Thread „Fortsetzen nach App-Neustart bauen“. Gebaut ist die Empfehlung, direkt in
   der Mission, angehalten (0.22.0, D-074).

## Fertig

- **Mission 1 spielbar** mit Kreismenü, Kopfleiste, Pause, 2×, Ergebnis, Neustart (0.5.0, 0.6.0).
- **Spielrahmen** (D-060): Hauptmenü, Einstellungen, Spielstand, gemalte Kampagnenkarte
  Region 1 mit Sternen (0.7.0, 0.10.2), Steinregen (0.8.0), Zwerge mit Bollwerk und
  billigeren Wachtürmen, Elfen mit Mondmal (0.9.0, 0.10.1).
- **Avatar** (D-063 bis D-065): einmal am Anfang Volk, Porträt und Name (0.11.0); Rang aus
  Sternen, vier Talentreihen je Volk, eigenes Avatar-Menü (0.12.0). Die erste Talentwahl
  kommt mit Mission 2 (ab 6 Sternen). Ausrüstung mit drei Plätzen, Grundstücke als
  feste Belohnung aus Mission 1 und Sternschwellen, höchstens +10 % (0.19.0). Schmiede:
  Erz aus jedem Sieg, neue Sterne mehr, Stücke auf Stufe II und III (0.21.0).
- **Mission 2 mit Zwergenbank** (P2-5, 0.16.0): neuer Weg, zehn härtere Wellen, die
  Bank als vierter Knopf im Kreismenü (zahlt nach 20 s alle 4 s Gold bis 300, höchstens
  zwei), Gold fürs frühe Rufen der Welle. Nach dem Sieg in Mission 1 auf der Karte
  offen. Werte sind Hypothesen bis zum Spieltest. Gemalter Kampfplatz am Zwergenstollen (0.16.1);
  der Kampfplatz für Mission 4 (Ruinenrand) liegt bereit.
- **Mission 3 „Pilzhain“ mit Aufwertungen** (P2-6, 0.18.0): Türme lassen sich einmal
  auf Stufe 2 aufwerten (zweimal tippen, etwa 70 % des Turmpreises, eigenes Bild und
  Schild „II“), danach wählen Wach- und Blitzturm ihr Ziel: Erster, Letzter oder
  Stärkster. Der Weg mit der Haarnadel belohnt tiefe Plätze, breit bauen gewinnt aber
  auch. Bank und Bonus wie in Mission 2 (deine Wahl, D-086). Nach dem Sieg in Mission 2 offen; Werte sind
  Hypothesen bis zum Spieltest.
- **Mission 4 „Ruinenrand“ mit Rüstung** (P2-10, 0.20.0): Die Panzerbestie zieht von
  jedem Turmtreffer einen festen Betrag ab, der Steinregen schlägt durch. Aufgewertete
  Wachtürme sind die Antwort, breit bauen ohne Aufwerten gewinnt nur knapp, jede
  Monokultur verliert. Schild am Gegner, Funke und tiefer Klang an der Panzerung.
  Nach dem Sieg in Mission 3 offen; Werte sind Hypothesen bis zum Spieltest.
- **Grafik und Bewegung**: gemalte Figuren, Türme, Symbole, Titelbild, Kampfplatz als
  Waldlichtung mit Zwergenfeste, Porträts (Grafik 01 bis 05); Laufen, Treffer, Tod,
  Turmangriffe und Fähigkeiten als Effekte (FX 01, 0.10.0); der Plünderer geht,
  zuckt und stürzt mit echten Armen und Beinen aus einem 3D-Modell (FX 02, 0.13.0).
- **Ton und Musik** (P2-3, 0.15.0): 30 Klänge an den Spielereignissen, fünf Musikstücke
  (Menü, Kampf, letzte Welle, Sieg, Niederlage), Regler für Klänge und Musik in den
  Einstellungen. Nur CC0-Quellen, jede mit Herkunft in `art/ton/` (D-082).
- **Qualität**: rund 250 Kerntests, rund 125 App-Tests, 36 Ende-zu-Ende-Fälle, Probelauf im
  Simulator, alles bei jedem PR in der CI.
- **Fortsetzen** (P2-2, 0.22.0): Geht die App mitten in einer Mission in den
  Hintergrund und wird beendet, öffnet sie beim nächsten Mal direkt in dieser Mission,
  angehalten. Nach einem Update, das die Mission ändert, beginnt sie neu, mit Hinweis.
- **Balance-Labor** (P2-6b, 0.21.1): Bots spielen bei jedem PR alle vier Missionen beim
  ersten Spielen, gierig, zufällig und menschenähnlich; Bericht im Artefakt der CI.
- **Blitz allein verliert** Mission 2 und 3 (P2-11, 0.23.0): Flitzer laufen dort
  schneller, Mission 2 hat etwas mehr Leben je Welle.
- **Doku nachgezogen** (27.10.2026): Architektur, Datenmodelle, Teststrategie,
  Oberfläche, Art, Roadmap; die CI prüft seitdem, dass der Doku-Stand mitwächst (D-067).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Haupt-Thread | 0.23.0 Blitz-Monokultur (P2-11) im PR | zusammenführen, Bau in TestFlight; Antwort auf die Karten S10 und S11 |
| Fortsetzen nach App-Neustart bauen | 0.22.0 (P2-2) in TestFlight (Bau 43) | deine Karte S12 (wo der Neustart landet) |
| Mission 2 mit Zwergenbank | 0.16.0, Bau 36 in TestFlight | Werte nach dem Spieltest nachziehen |
| Mission 3 mit Aufwertungen | 0.18.0 in Bau 38; Mission 4 (0.20.0) im PR | zusammenführen, Bau in TestFlight, Antwort auf die Karte zu Mission 4 |
| Plünderer-3D-Modell | 0.13.0 in TestFlight | Flitzer und Panzerbestie, wenn dir der Plünderer im Spiel gefällt |
| Ton und Musik | 0.15.0 in Bau 35 | Hörprobe beim Spieltest |

## Als Nächstes

Die Reihenfolge steht in der [Roadmap](roadmap.md#als-nächstes): Mission 2 mit Zwergenbank ist da (deine Wahl vom 01.11., D-080),
R-7 Ausrüstung läuft parallel, der Spieltest korrigiert danach die Werte von Mission 1 und 2. Ton ist mit 0.15.0 drin; hör beim Spieltest bitte auch auf Lautstärke und Musik.
