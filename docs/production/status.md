# Stand des Projekts

Kurzer Überblick für Steffen, nach jedem Meilenstein neu geschrieben (nicht
ergänzt). Die Reihenfolge und Abhängigkeiten stehen in der
[Roadmap](roadmap.md), die Pakete im [Backlog](backlog.md), offene Fragen im
[Register](offene-fragen.md).

**Stand: 25.10.2026, 16:05** · Phase 1, M1.3 erreicht und auf dem Gerät, M1.4 als Nächstes

## Fertig

- Phase 0: Designstand, MVP-Grenze, Backlog, Entscheidungen D-001 bis D-015.
- Marktanalyse mit Empfehlungen E1 bis E15; Geschäftsmodell-Richtung D-015.
- Simulation von Mission 1 vollständig und getestet (WP-02 bis WP-10):
  drei Türme, Wellen, Sieg, Niederlage, Determinismus, Balancetests.
- Die App zeigt die laufende Mission mit Mitspieler (WP-11, Version 0.4.0).
- **Mission 1 ist per Hand spielbar und in TestFlight** (WP-12 bis WP-14, Version
  0.5.0, **Bau 19 VALID**): bauen und verkaufen per Tippen, Kopfleiste, Ergebnis, Neustart.
- TestFlight-Weg steht (D-014); Grafikstil gewählt (D-016, Stylized 3D).
- Konzepte für Phase 2 und 3 ausgearbeitet: Aufwertungen, Festungsfähigkeit,
  Völker, Zwergenbank, Kampagne, Fortschritt, Speicherstand
  ([Konzepte](../konzepte/phase-2-3.md)).

## Läuft

| Thread | Woran | Nächster Schritt |
|---|---|---|
| Designstand und MVP-Plan (Code) | WP-15 Spieltest vorbereiten | Beobachtungsbogen, Protokoll unter `docs/production/playtests/` |
| AAA-Grafik | Türme, Gegner, Festung, Karte im Stil A | Atlas per PR, dann Charakterblätter, Zwergenbank, Völker |
| Spieloberfläche und Menüs | Mockups für HUD, Menü, Pause, Ergebnis | UI-Konzept, Abstimmung mit Code- und Grafik-Thread |
| Projektplanung | Roadmap, Register, dieses Dokument (Konzepte K1–K10 auf main) | Entscheidungen E-1 bis E-4 einarbeiten, Phase 2 nach WP-15 schneiden |

## Als Nächstes

1. **Spiel Mission 1 auf deinem iPhone** (TestFlight, Bau 19). Was dir auffällt,
   gehört schon in den Spieltest.
2. **Erster Spieltest** mit drei Personen (WP-15), dazu die Leistungsmessung auf
   dem iPhone aus WP-01. Danach wird Phase 2 endgültig geschnitten.
3. Grafik einbauen, sobald der Atlas da ist (Steffens Reihenfolge: erst
   spielbar, dann Grafik).

## Wartet auf Steffen

| | Frage | Empfehlung |
|---|---|---|
| E-1 | Aufwertungen in Phase 2? | Ja, zwei Stufen und eine Gabelung je Turm |
| E-2 | Festungsfähigkeit und Völker | Eine Fähigkeit in Phase 2; Volk bestimmt später Fähigkeit und einen kleinen Zug |
| E-3 | Zwergenbank für alle oder nur Zwerge (D-010) | Für alle, Zwerge mit Bank-Zug |
| E-4 | Umfang der kostenlosen Region 1 | Sieben Haupt- und zwei Nebenmissionen mit Gabelung |

Außerdem offen bei Steffen: D-019 (läuft die Mission weiter, während das Baumenü offen ist?) aus dem Code-Thread, und ohne Eile die Messung des Spikes auf dem iPhone (WP-01).
