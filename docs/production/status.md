# Stand des Projekts

Kurzer Überblick für Steffen, nach jedem Meilenstein neu geschrieben (nicht
ergänzt). Die Reihenfolge und Abhängigkeiten stehen in der
[Roadmap](roadmap.md), die Pakete im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 25.10.2026, 18:35** · Phase 1: neue Oberfläche wird eingebaut, danach Spieltest. Hauptmenü, Weltkarte und Völker vorgezogen (D-060)

## Fertig

- Phase 0: Designstand, MVP-Grenze, Backlog, Marktanalyse (E1 bis E15),
  Geschäftsmodell-Richtung D-015.
- Simulation von Mission 1 vollständig und getestet (WP-02 bis WP-10).
- **Mission 1 ist spielbar und in TestFlight**: bauen und verkaufen per Tippen,
  Kopfleiste, Pause, 2×, Ergebnis, Neustart. Neuester Stand ist Version 0.5.2, **Bau 21 VALID**.
- **Ende-zu-Ende-Tests** (D-029): 13 Fälle spielen die App bei jedem PR wie ein Spieler
  durch und sind grün. Damit ist der Testteil von M1.4 erledigt.
- **Echte Grafik im Spiel** (0.5.2, Bau 21): gemalte Türme, Gegner, Festung und Karte
  im Stil Stylized 3D (D-016) statt Platzhalterformen.
- Grafikstil gewählt (D-016, Stylized 3D). Oberflächenkonzept für Phase 1 und 2 steht
  ([07](../game-design/07-ui-ux.md)), Kreismenü und Platz der Festungsfähigkeit entschieden
  (D-031, D-033), Schriften Lilita One und Nunito entschieden (D-032).
- Reihenfolge entschieden (Steffen, 25.10.2026): **erst die neue Oberfläche, dann der Spieltest.**
- Hauptmenü, Kampagnenkarte Region 1 und Völkerwahl mit Festungsfähigkeit vorgezogen (D-060).
- Richtung für Phase 2 und 3 entschieden: Aufwertungen mit Gabelung (D-024),
  Festungsfähigkeit und Völker (D-025), Zwergenbank für alle (D-026), Region 1 mit
  sieben Haupt- und zwei Nebenmissionen (D-027). Balance-Labor eingeplant (D-028).
- Bauen bei laufender Mission entschieden (D-019).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Designstand und MVP-Plan (Code) | Neue Oberfläche für Mission 1, dann Hauptmenü und Speicherstand (R-1) | Bau mit neuer Oberfläche für den Spieltest |
| Spieloberfläche und Menüs | Einbau der Oberfläche für Mission 1; Entwürfe für Hauptmenü, Kampagnenkarte, Völkerwahl | Entwürfe vor R-1, R-2, R-4 |
| AAA-Grafik | Erste Grafik ist im Spiel (0.5.2) | Menühintergrund, Karte Flüsterwald, Wappen und Porträts |
| Animationen und Effekte | Effekt-Uhr (D-050), Ansatz für Laufzyklen (D-051, liegt dir vor) | Steinregen, Volksfähigkeiten, Kartenübergänge |
| Projektplanung | Roadmap, Register, dieses Dokument | Phase 2 schneiden, sobald der Spieltest ausgewertet ist |

## Als Nächstes

1. **Neue Oberfläche in TestFlight**: Kreismenü zum Bauen, Schriften, Kopfleiste im Stil.
2. **Spieltest mit drei Personen** (WP-15) auf diesem Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Er prüft Mission 1 und wartet
   nicht auf Menü und Karte.
3. **Spielrahmen** ([Roadmap](roadmap.md#vorgezogen-spielrahmen-d-060)): Hauptmenü mit
   Speicherstand (R-1) und Steinregen (R-3) parallel, dann die Kampagnenkarte
   Region 1 (R-2), dann die Völkerwahl (R-4).
4. Danach der Rest von Phase 2: Zwergenbank, Aufwertungen, Ton.

## Wartet auf Steffen

| Frage | Woher |
|---|---|
| Spieltest durchführen, sobald der Bau mit neuer Oberfläche da ist | WP-15 |
| Ansatz für echte Laufzyklen (D-051) | Animationen und Effekte |
| Ohne Eile: Messung des Spikes auf dem iPhone | WP-01 |
