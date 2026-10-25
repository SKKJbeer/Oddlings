# 02 – Kampf, Türme und Gegner

Zahlenwerte stehen **nicht** hier, sondern ausschließlich in
[`mvp-mission-01.json`](../../Packages/OddlingsCore/Sources/OddlingsCore/Resources/Balance/mvp-mission-01.json).
Begründung und Rechnung dazu: [04-economy-and-balance.md](04-economy-and-balance.md).
Hier stehen Rollen und Regeln.

## Turmprinzipien [ENTSCHIEDEN]

- Jeder Turm hat einen erkennbaren Zweck.
- Türme ergänzen sich; keiner ist in jeder Lage die beste Wahl.
- Werte sind konfigurierbar, nicht im Code verstreut.
- Upgrades kommen nicht in den MVP (**[VORSCHLAG D-008]**), in Phase 2 mit einer Gabelung je Turm:
  [Aufwertungen](#aufwertungen-mit-einer-gabelung-je-turm-phase-2) (D-024).
  Rüstung, Immunität, Bosse, Schattenflieger: [K7](../konzepte/phase-2-3.md#k7--gegner-bosse-rüstung).

## Türme im MVP

### Wachturm – zuverlässiger Einzelschaden [ENTSCHIEDEN: Rolle]

- Schießt auf **ein** Ziel in Reichweite.
- Referenzturm für Kosten und Schaden: das beste Schaden-pro-Gold gegen
  einzelne Ziele.
- **[VORSCHLAG]** Zielwahl „erster": der Gegner, der am weitesten auf dem Weg ist,
  bei Gleichstand der ältere.
- **[VORSCHLAG]** Kein Schuss auf schon tödlich Getroffene: Feuern zwei Türme im
  selben Tick, nimmt der zweite den nächsten Gegner, statt seinen Schuss an einen
  Toten zu verschwenden. Fühlt sich klüger an und ist üblich (seit WP-06 so in der
  Simulation; Folgen für die Balance in [04](04-economy-and-balance.md#ergebnis-der-prüfung)).
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
- **[VORSCHLAG]** Trifft ein Puls eine laufende Verlangsamung, gelten der
  stärkere Faktor und die längere Restdauer. Ein Puls verkürzt nie, was schon wirkt.
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

## Aufwertungen mit einer Gabelung je Turm (Phase 2)

**[ENTSCHIEDEN D-024]** Steffen, 25.10.2026 (E-1). Zahlen sind Zielgrößen für die erste Rechnung; die Werte kommen in die Missionsdatei.

Herkunft: Übergabe Nr. 7, Marktanalyse E5 und E6.

**Warum überhaupt.** Alle Marktführer leben von Aufwertungen. Ohne sie gibt es
ab der Mitte einer Mission nur noch eine Frage, „wohin der nächste Turm", und
bei 114 Bauplätzen ist die schnell beantwortet. Aufwertungen bringen die zweite
Frage dazu: verbreitern (neuer Turm, mehr Abdeckung) oder vertiefen (bestehender
Turm, mehr Wirkung an einer Stelle).

**Aufbau.** Drei Stufen, eine Wahl.

| Stufe | Wie man hinkommt | Was sie tut |
|---|---|---|
| 1 | Bauen | Grundturm wie im MVP |
| 2 | Aufwerten, Gold | Gleiche Rolle, spürbar stärker; schaltet die Zielwahl frei (E5) |
| 3 | Spezialisieren, Gold, **eine von zwei** | Verstärkt je eine andere Synergie; die andere ist für diesen Turm weg |

Die Wahl gilt je Turm und je Mission. Zwei Blitztürme dürfen verschieden
spezialisiert sein. Das ist die eigentliche Tiefe: dieselbe Karte wird mit einer
anderen Mischung anders gespielt.

**Spezialisierungen.** Jede stärkt eine Kombination, keine ist reiner Mehrschaden.

| Turm | A | B |
|---|---|---|
| Wachturm | **Falkenhorst:** große Reichweite, schwerer Schuss, langsamer. Gegen Panzerbestien und Bosse | **Salve:** trifft zwei Ziele je Schuss. Gegen Flitzerschwärme |
| Blitzturm | **Gewitterkrone:** zwei Sprünge mehr; Sprünge auf verlangsamte Gegner verlieren keinen Schaden. Verstärkt die Kernsynergie | **Funkensäule:** erster Treffer deutlich stärker, weniger Sprünge. Blitz auch gegen zähe Einzelziele |
| Sporenturm | **Moorherz:** größerer Radius, stärkere Verlangsamung. Reine Kontrolle | **Fäulnis:** verlangsamte Gegner nehmen von allen Türmen mehr Schaden. Macht Sporen neben Wachtürmen wertvoll (Befund aus WP-10, siehe [04](../game-design/04-economy-and-balance.md#ergebnis-der-prüfung)) |

Neue Regeln, die das braucht: ein Zustand „verwundbar" (Schadensfaktor mit
Dauer, wie die Verlangsamung, stapelt nicht), Mehrfachziel beim Wachturm,
Abfall abhängig vom Zustand des Ziels. Alle drei passen in die bestehende
Simulation (Ereignisse, Zustand als Wert); keine braucht Zufall.

**Wirtschaft.** Zielgröße: Stufe 2 kostet etwa 70 % des Grundturms und bringt
etwa 50 % mehr Wirkung, ist also je Gold leicht besser als ein zweiter Turm,
deckt aber keinen neuen Wegabschnitt ab. Spezialisierung kostet etwa so viel wie
ein Grundturm. Verkaufen erstattet 70 % von **allem**, was im Turm steckt
(`Tower.spent` gibt es schon).

**Bedienung.** Turm antippen → im Turmmenü aus WP-12 „Aufwerten (Preis)". Auf
Stufe 2 zeigt das Menü zwei Karten nebeneinander, je mit Symbol, einem Satz und
Preis. Zielwahl als Umschalter im selben Menü (erster / letzter / stärkster).
Abhängigkeit zum Thread „Spieloberfläche und Menüs".

**Grafik.** Je Turm Stufe 2 als Anbau am selben Bild, Stufe 3 je eigene Ansicht:
sechs neue Turmbilder. Abhängigkeit zum Thread „AAA-Grafik".

**Prüfung.** `BalanceTests` bekommen Bauweisen mit Aufwertungen. Erwartung:
Mischungen mit passenden Spezialisierungen haben die größte Reserve, und jede
der sechs Spezialisierungen ist in mindestens einer Bauweise die beste Wahl.
Ist eine nie die beste, ist sie falsch, nicht der Test.

**Freischaltung.** In Region 1 kommen Stufe 2 und die Spezialisierungen nach und
nach dazu ([05](05-campaign-and-progression.md#region-1-flüsterwald-kostenlos)), damit Mission 1 so einfach bleibt, wie sie ist.

**Verworfen:** eine lineare dritte
Stufe ohne Wahl: halb so viel Grafik, aber nur „mehr Zahl", das widerspricht
Säule 1 und 3.

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
