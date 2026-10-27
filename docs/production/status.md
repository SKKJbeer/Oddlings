# Stand des Projekts

Kurzer Überblick für Steffen, nach jedem Meilenstein neu geschrieben (nicht
ergänzt). Die Reihenfolge und Abhängigkeiten stehen in der
[Roadmap](roadmap.md), die Pakete im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 26.10.2026, 04:45** · Phase 1 mit vorgezogenem Spielrahmen (D-060) fertig: Hauptmenü, Kampagnenkarte, Steinregen und Völkerwahl sind in TestFlight. Als Nächstes der Spieltest

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
- **Spielrahmen (D-060) in TestFlight**: Hauptmenü, Kampagnenkarte Region 1, Sterne,
  Speicherstand und Einstellungen (0.7.0, R-1/R-2), Festungsfähigkeit Steinregen
  (0.8.0, R-3, Bau 24), Völkerwahl Zwerge mit Bollwerk und Elfen mit Mondmal
  (Zwerge bauen Wachtürme 10 % billiger, D-062, ab 0.10.1)
  (0.9.0, R-4, **Bau 25 VALID**). Spielbar bleibt nur Mission 1.
- **Avatar einmal am Anfang** (0.11.0, R-5, D-063, **Bau 31 VALID**): Volk, Porträt und Name beim ersten
  „Spielen“, danach ist das Volk gesetzt. Rollenspielartig wird der Avatar über Rang
  mit Talentwahl ohne Mehrkraft (D-064, Paket R-6).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Designstand und MVP-Plan (Code) | R-6 Avatarrang mit Talentwahl (0.12.0) im CI | Bau in TestFlight, Spieltest WP-15 begleiten |
| Spieloberfläche und Menüs | Einbau der Oberfläche für Mission 1; Entwürfe für Hauptmenü, Kampagnenkarte, Völkerwahl | Entwürfe vor R-1, R-2, R-4 |
| AAA-Grafik | Kampfplatz als Waldlichtung, neue Festung, Avatar-Porträts (0.11.1, **Bau 32 VALID**) | Rückmeldung von Steffen zum Kampfplatz; Streifen hinter der Kopfleiste |
| Animationen und Effekte | FX 01 in TestFlight (0.10.0, Bau 27): Laufen, Treffer, Tod, Turmangriffe, Fähigkeiten | FX 02: Gegner als 3D-Figuren mit Gliedmaßen (D-051), [Konzept](../konzepte/fx-02-figuren-in-3d.md) |
| Projektplanung | Roadmap, Register, dieses Dokument | Phase 2 schneiden, sobald der Spieltest ausgewertet ist |

## Als Nächstes

1. **Neue Oberfläche in TestFlight**: Kreismenü zum Bauen, Schriften, Kopfleiste im Stil.
2. **Spieltest mit drei Personen** (WP-15) auf diesem Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Er prüft Mission 1 und wartet
   nicht auf Menü und Karte.
3. Danach der Rest von Phase 2: Zwergenbank, Aufwertungen, Ton.

## Wartet auf Steffen

| Frage | Woher |
|---|---|
| Wechsel des Volks, bevor es eine Spielwährung gibt (Entscheidungskarte) | R-5 |
| Spieltest durchführen, sobald der Bau mit neuer Oberfläche da ist | WP-15 |
| Herkunft der 3D-Modelle für FX 02 (Entscheidungskarte) | Animationen und Effekte |
| Ohne Eile: Messung des Spikes auf dem iPhone | WP-01 |
