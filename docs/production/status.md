# Stand des Projekts

Kurzer Überblick für Steffen, nach jedem Meilenstein neu geschrieben (nicht
ergänzt). Die Reihenfolge und Abhängigkeiten stehen in der
[Roadmap](roadmap.md), die Pakete im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 25.10.2026, 18:20** · Phase 1: neue Oberfläche wird eingebaut, danach Spieltest (M1.4)

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
- Richtung für Phase 2 und 3 entschieden: Aufwertungen mit Gabelung (D-024),
  Festungsfähigkeit und Völker (D-025), Zwergenbank für alle (D-026), Region 1 mit
  sieben Haupt- und zwei Nebenmissionen (D-027). Balance-Labor eingeplant (D-028).
- Bauen bei laufender Mission entschieden (D-019).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Designstand und MVP-Plan (Code) | Spieltest WP-15 vorbereitet ([Beobachtungsbogen](playtests/beobachtungsbogen.md)) | Protokolle auswerten, sobald gespielt wurde |
| Spieloberfläche und Menüs | **Einbau der neuen Oberfläche für Mission 1** (Kreismenü, Schriften, HUD) | Neuer Bau in TestFlight, dann Spieltest |
| AAA-Grafik | Erste Grafik ist im Spiel (0.5.2) | Laufzyklen und Treffereffekte, dann Zwergenbank und Völker |
| Projektplanung | Roadmap, Register, dieses Dokument | Phase 2 schneiden, sobald der Spieltest ausgewertet ist |

## Als Nächstes

1. **Neue Oberfläche in TestFlight**: Kreismenü zum Bauen, Schriften, Kopfleiste im Stil.
2. **Spieltest mit drei Personen** (WP-15) auf diesem neuen Bau, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Dazu die Leistungsmessung
   auf dem iPhone (WP-01). Damit ist M1.4 und Phase 1 abgeschlossen.
3. **Phase 2 schneiden** aus den Ergebnissen: zuerst Bewegung der Grafik und Ton,
   dann Zwergenbank, Aufwertungen und Festungsfähigkeit ([Roadmap](roadmap.md#entwurf-phase-2-vorschlag)).

## Wartet auf Steffen

| Frage | Woher |
|---|---|
| Spieltest durchführen (drei Personen, Bogen ausfüllen), sobald der Bau mit neuer Oberfläche da ist | WP-15 |
| Ohne Eile: Messung des Spikes auf dem iPhone | WP-01 |
