# 02 – Kampf, Türme und Gegner

Zahlenwerte stehen **nicht** hier, sondern ausschließlich in
[`mvp-mission-01.json`](../../Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json).
Begründung und Rechnung dazu: [04-economy-and-balance.md](04-economy-and-balance.md).
Hier stehen Rollen und Regeln.

## Turmprinzipien [ENTSCHIEDEN]

- Jeder Turm hat einen erkennbaren Zweck.
- Türme ergänzen sich; keiner ist in jeder Lage die beste Wahl.
- Werte sind konfigurierbar, nicht im Code verstreut.
- Upgrades kommen später (**[VORSCHLAG D-008]**: nicht im MVP).

## Türme im MVP

### Wachturm – zuverlässiger Einzelschaden [ENTSCHIEDEN: Rolle]

- Schießt auf **ein** Ziel in Reichweite.
- Referenzturm für Kosten und Schaden: das beste Schaden-pro-Gold gegen
  einzelne Ziele.
- **[VORSCHLAG]** Zielwahl „erster": der Gegner, der am weitesten auf dem Weg ist.
- **[VORSCHLAG]** Treffer ohne Flugzeit (sofort). Ein sichtbares Geschoss ist nur
  Darstellung. Begründung: Geschosse mit Flugzeit erzeugen Fehlschüsse auf
  schnelle Ziele, das ist eine zusätzliche Regel, die der MVP nicht braucht.

### Blitzturm – Schaden gegen Gruppen [ENTSCHIEDEN: Rolle]

- Trifft ein erstes Ziel (Zielwahl „erster") und springt dann zum **nächsten
  noch nicht getroffenen** Gegner innerhalb des Sprungradius.
- **[VORSCHLAG]** Jeder Sprung verliert einen festen Anteil Schaden
  (`chainFalloff`). Die Kette endet, wenn kein Ziel im Radius ist oder die
  Sprungzahl erreicht ist.
- Gegen Einzelziele bewusst schwächer als der Wachturm, gegen dichte Gruppen
  deutlich stärker.

### Sporenturm – Kontrolle [ENTSCHIEDEN: Rolle]

- **[VORSCHLAG]** Wirkt als Puls auf **alle** Gegner in Reichweite: geringer
  Schaden, Verlangsamung für eine kurze Dauer, die mit jedem Puls erneuert wird.
- **[VORSCHLAG]** Verlangsamungen **stapeln nicht**; es gilt die stärkste aktive.
  Begründung: Stapeln macht „fünf Sporentürme an eine Stelle" zur Pflichtlösung
  und Gegner stehen still.
- Der Eigenschaden ist absichtlich gering. Sein Wert entsteht dadurch, dass
  andere Türme länger schießen und der Blitz dichtere Gruppen findet.
- **Immunitäten** gegen Verlangsamung: **[OFFEN]**, nicht im MVP. Kandidat später:
  Bosse mit verringerter Wirkung statt voller Immunität.

### Zwergenbank – Wirtschaft (Phase 2) [ENTSCHIEDEN: Rolle und Zeitpunkt]

Kein Kampfschaden. Erträgt nach einer Verzögerung Gold. Regeln und Kennzahlen in
[04](04-economy-and-balance.md#zwergenbank-phase-2).

## Die Kernsynergie und wie Mission 1 sie lehrt

Sporen verlangsamen → Gegner bleiben länger in Reichweite und rücken enger
zusammen → Kettenblitze treffen mehr Ziele. Die Rechnung bestätigt das: Blitz
allein verliert, Blitz mit Sporen ist die stärkste geprüfte Kombination
(Zahlen in [04](04-economy-and-balance.md#ergebnis-der-prüfung)).

Damit Spieler das selbst entdecken, wird es nicht erklärt, sondern provoziert:
Welle 5 ist eine dichte Kolonne Plünderer (Blitz glänzt), Welle 6 eine Welle
schneller Flitzer (Verlangsamung glänzt). **[VORSCHLAG]**

## Gegner

| Gegner | Rolle | MVP |
|---|---|---|
| Plünderer | Referenz: mittlere Geschwindigkeit und Zähigkeit | ja |
| Flitzer | Schnell, wenig Leben; bestraft Lücken und fehlende Kontrolle | ja |
| Panzerbestie | Langsam, sehr zäh; prüft nachhaltigen Einzelschaden | **[VORSCHLAG]** in Mission 1 ab Welle 7, abschaltbar, weil datengetrieben fast kostenlos |
| Schattenflieger | Fliegt, umgeht etwas | nein, später |
| Bosse | Taktische Herausforderung (Phasen, Schild, Beschwörung) | nein |

**[VORSCHLAG]** Gegner sind im MVP nicht anvisierbar durch den Spieler (kein
„Fokus auf dieses Ziel"). Kandidat für Phase 2.

## Schaden

**[VORSCHLAG]** Ein Schadenstyp, keine Rüstung, keine Resistenzen im MVP.
Rüstung gegen bestimmte Türme ist ein naheliegender späterer Hebel für die
Panzerbestie, macht aber jede Balancerechnung zweidimensional. Erst wenn der
Grundloop trägt.
