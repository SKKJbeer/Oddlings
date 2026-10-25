# 05 – Kampagne und Fortschritt

**Nicht Teil des MVP** (Phase 3). Die Übergabe sah dafür zwei Dateien vor
(Weltkarte, Fortschritt); sie sind hier zusammengelegt, weil beide heute nur
Richtung enthalten und eine Kampagne ohne ihre Belohnungen nicht zu entwerfen ist.

## Kampagnenkarte [ENTSCHIEDEN: Richtung]

Verzweigte Knotenkarte statt offener Welt. Enthält Haupt- und Nebenmissionen,
verborgene Herausforderungen, alternative Routen, Bossmissionen, neue Regionen.
Die Karte soll Entscheidungen erzeugen: welcher Weg, welche Nebenmission, welche
Belohnung.

Beispielregionen (Platzhalter): Flüsterwald, Eisengipfel, Sturmklamm.

### Region 1 und die Vollversion

**[ENTSCHIEDEN D-027]** Steffen, 25.10.2026 (E-4). Zahlen sind Zielgrößen für die erste Rechnung; die Werte kommen in die Missionsdatei.

Herkunft: Übergabe Nr. 10, folgt aus D-015.

D-015 legt das Geschäftsmodell nahe: erste Region kostenlos, Vollversion
einmalig. Daraus folgt eine harte Anforderung an Region 1: **Sie muss allein
überzeugen** und lange genug sein, um ein Urteil zu tragen (Ziel: etwa eine bis
anderthalb Stunden), aber kurz genug, dass man das Ende sieht und mehr will.

#### Region 1 „Flüsterwald" (kostenlos)

```
 M1 ─ M2 ─ M3 ─ M4 ─┬─ M5a Sumpfpfad ─ M6a ─┬─ M7 Boss
                    └─ M5b Ruinen ─── M6b ─┘
            N1 (ab 6 Sternen)      N2 (ab 15 Sternen)
```

| Mission | Neu | Lehrt |
|---|---|---|
| M1 | Wach-, Blitz-, Sporenturm; Plünderer, Flitzer | Grundspiel (heutige Mission 1) |
| M2 | Zwergenbank | Ernten oder verteidigen |
| M3 | Aufwerten Stufe 2, Zielwahl | Vertiefen statt verbreitern |
| M4 | Festungsfähigkeit; Panzerbestie | Aktiv eingreifen, zähe Ziele |
| M5a/b, M6a/b | Spezialisierungen (je Weg andere zuerst) | Gabelung: Sumpf schickt Flitzer, Ruinen schicken Panzerbestien |
| M7 | Boss | Alles zusammen |
| N1, N2 | Nebenmissionen mit Sonderregel | Wiederspielwert |

Beide Wege der Gabelung führen zum Boss. Wer will, spielt den anderen danach
nach. Am Ende von Region 1 sind beide Völker freigespielt ([03](03-races-and-avatar.md#wie-ein-volk-wirkt-phase-3)), damit auch
wer nicht kauft das ganze Grundspiel kennt.

#### Regionen der Vollversion

Region 2 „Eisengipfel" und Region 3 „Sturmklamm", je etwa acht Missionen. Jede
bringt **eine** neue Gegnerart (Region 2: Schattenflieger, nur von Wach- und
Blitzturm zu treffen), **einen** neuen Boss und eine neue Kartenoptik. Spätere
Erweiterungsregionen (D-015) dürfen einen volkseigenen Turm oder ein neues Volk
bringen.

#### Sterne und Herausforderungen (E9)

- Sterne nach verbleibendem Leben: 1 (gewonnen), 2 (ab 15), 3 (alle 20). Die
  Grenzen stehen in der Missionsdatei.
- Sterne öffnen Nebenmissionen, nie Hauptmissionen. Niemand bleibt stecken.
- Je Mission ein **Eisern-Modus** nach dem ersten Sieg: eine Einschränkung
  („nur zwei Turmtypen", „Festung hat 1 Leben"). Gibt ein Abzeichen, keinen
  Spielvorteil.

#### Aufwand, nüchtern

Eine Mission ist eine Wegführung, zehn Wellen in der Missionsdatei und eine
Kartenansicht. Wellen und Weg sind Daten; die Karte ist der teure Teil. Deshalb
teilt sich eine Region einen Kartenstil, und die Missionen unterscheiden sich
durch Wegführung, Bauzonen und Wellen. Ein Kartenwerkzeug, das Weg und Zonen
aus einer Datei vorzeichnet, spart hier viel und gehört in Phase 3.

**Verworfen:** fünf Missionen, Rest in der Vollversion; billiger, aber
die freie Region zeigte dann weder Spezialisierungen noch Völker, also genau das
nicht, was Oddlings ausmacht.

## Fortschritt

**[ENTSCHIEDEN D-027]** Steffen, 25.10.2026 (E-4). Zahlen sind Zielgrößen für die erste Rechnung; die Werte kommen in die Missionsdatei.

Leitplanke **[ENTSCHIEDEN]**: Freischaltungen fühlen sich wie Belohnung an, die
Balance hängt nie an Käufen.

Was dauerhaft freigeschaltet wird:

| Freischaltung | Wodurch |
|---|---|
| Türme, Aufwertungen, Spezialisierungen, Festungsfähigkeit | Hauptmissionen ([Region 1](#region-1-und-die-vollversion)) |
| Völker | Ende Region 1 |
| Nebenmissionen | Sterne |
| Bestiarium und Turmbuch (E11): Eintrag mit Bild und Charaktertext | erste Begegnung |
| Abzeichen, Banner, Titel für den Avatar | Eisern-Modi, Bosse, alle Sterne einer Region |

Was es **nicht** gibt:
- Keine dauerhaften Werteboni („+5 % Schaden"). Jede Mission rechnet mit
  denselben Werten für jeden Spieler; nur so bleiben die Balancetests gültig.

- Keine zweite Währung, keine Erfahrungspunkte, kein Ausdauerbalken. Säule 5.
- Keine täglichen Pflichtaufgaben im ersten Release. Die tägliche Herausforderung
  (E10) bleibt ein Kandidat für nach dem Release und braucht eine Freigabe.

Damit ist Fortschritt: mehr Möglichkeiten, nicht mehr Zahl. Der Spieler wird
besser, nicht sein Spielstand.

## Speicherstand

**[GILT D-022]** Lokal, versioniert, atomar, beim Laden geprüft; Einzelheiten in
[K6](../konzepte/phase-2-3.md#k6--speicherstand). Cloud-Speicher in Phase 4.
Fortsetzen einer laufenden Mission nach Beenden der App: Phase 2.
