# Stand des Projekts

Kurzer Überblick für Steffen, nach jedem Meilenstein neu geschrieben (nicht
ergänzt). Die Reihenfolge und Abhängigkeiten stehen in der
[Roadmap](roadmap.md), die Pakete im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 25.10.2026, 17:25** · Phase 1 technisch fertig, es fehlt nur noch der Spieltest (M1.4)

## Fertig

- Phase 0: Designstand, MVP-Grenze, Backlog, Marktanalyse (E1 bis E15),
  Geschäftsmodell-Richtung D-015.
- Simulation von Mission 1 vollständig und getestet (WP-02 bis WP-10).
- **Mission 1 ist spielbar und in TestFlight**: bauen und verkaufen per Tippen,
  Kopfleiste, Pause, 2×, Ergebnis, Neustart. Neuester Stand ist Version 0.5.1, **Bau 20 VALID**.
- **Ende-zu-Ende-Tests** (D-029): 13 Fälle spielen die App bei jedem PR wie ein Spieler
  durch und sind grün. Damit ist der Testteil von M1.4 erledigt.
- Grafikstil gewählt (D-016, Stylized 3D). Oberflächenkonzept für Phase 1 und 2 steht
  ([07](../game-design/07-ui-ux.md)), Kreismenü und Platz der Festungsfähigkeit entschieden
  (D-031, D-033).
- Richtung für Phase 2 und 3 entschieden: Aufwertungen mit Gabelung (D-024),
  Festungsfähigkeit und Völker (D-025), Zwergenbank für alle (D-026), Region 1 mit
  sieben Haupt- und zwei Nebenmissionen (D-027). Balance-Labor eingeplant (D-028).
- Bauen bei laufender Mission entschieden (D-019).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Designstand und MVP-Plan (Code) | Spieltest WP-15 vorbereitet ([Beobachtungsbogen](playtests/beobachtungsbogen.md)) | Protokolle auswerten, sobald gespielt wurde |
| Spieloberfläche und Menüs | Entwürfe für Phase 2: Aufwerten, Bank, Fähigkeit | Einbau der neuen Oberfläche, falls du sie vor dem Spieltest willst |
| AAA-Grafik | Türme, Gegner, Festung, Karte im Stil A | Atlas per PR, dann Charakterblätter |
| Projektplanung | Roadmap, Register, dieses Dokument | Phase 2 schneiden, sobald der Spieltest ausgewertet ist |

## Als Nächstes

1. **Spieltest mit drei Personen** (WP-15) auf Bau 20, mit dem
   [Beobachtungsbogen](playtests/beobachtungsbogen.md). Dazu die Leistungsmessung
   auf dem iPhone (WP-01). Damit ist M1.4 und Phase 1 abgeschlossen.
2. **Phase 2 schneiden** aus den Ergebnissen: zuerst Grafik und Oberfläche einbauen,
   dann Zwergenbank, Aufwertungen und Festungsfähigkeit ([Roadmap](roadmap.md#entwurf-phase-2-vorschlag)).

## Wartet auf Steffen

| Frage | Woher |
|---|---|
| Spieltest durchführen (drei Personen, Bogen ausfüllen) | WP-15 |
| Neue Oberfläche **vor** dem Spieltest einbauen oder danach? | Oberflächen-Thread |
| Ohne Eile: Messung des Spikes auf dem iPhone | WP-01 |
