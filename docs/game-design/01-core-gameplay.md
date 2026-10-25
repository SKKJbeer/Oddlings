# 01 – Kern-Spielablauf

## Spielschleife einer Mission

**[ENTSCHIEDEN]** in der Abfolge, **[VORSCHLAG]** in den Einzelregeln.

1. Mission starten. Das Schlachtfeld zeigt Weg, Festung am Wegende und Bauflächen.
2. **Aufbauzeit** vor der ersten Welle. Startgold verteilen.
3. Wellen laufen. Gegner folgen dem Weg; Türme greifen automatisch an.
4. Besiegte Gegner bringen Gold. Bauen und Verkaufen ist jederzeit möglich, auch
   während einer Welle.
5. Gegner, die das Wegende erreichen, ziehen Festungsleben ab.
6. **Sieg:** alle Wellen sind gespawnt und kein Gegner lebt mehr, Festung hat Leben > 0.
   **Niederlage:** Festungsleben erreicht 0. Die Mission endet sofort.
7. Ergebnisbildschirm, Neustart oder (ab Phase 3) zurück zur Kampagnenkarte.

## Wellentakt [VORSCHLAG]

- Vor Welle 1 läuft eine Aufbauzeit (Mission 1: 20 s).
- Sobald die letzte Einheit einer Welle erschienen ist, läuft der Zähler bis zur
  nächsten (Mission 1: 15 s). Die nächste Welle wartet also **nicht**, bis alle
  Gegner besiegt sind. So überlappen Wellen leicht und die Mission bleibt im Fluss.
- Ein Knopf „Nächste Welle" startet sie sofort. Im MVP ohne Bonus; ein Goldbonus
  für frühes Rufen ist ein bekanntes Muster und kommt in Phase 2 auf den Prüfstand.

Begründung: „Warten bis alles tot ist" macht starke Verteidigungen langweilig,
weil sie nur noch auf die nächste Welle warten. Ein fester Takt mit Abkürzung
lässt gute Spieler schneller spielen, ohne schwächere zu hetzen.

## Spielgeschwindigkeit [VORSCHLAG]

1× und 2×, dazu Pause. Umgesetzt durch mehr Simulationsschritte je Bild, nicht
durch größere Schritte, damit das Ergebnis bei 2× dasselbe bleibt
(siehe [architecture.md](../technical/architecture.md)).

## Schlachtfeld und Platzierung

**[ENTSCHIEDEN]**
- Feste Wege im MVP, Türme blockieren nicht.
- Bauen nur auf erlaubten Flächen.
- Reichweiten, Effekte und Bewegungen müssen gut lesbar sein.

**[VORSCHLAG – D-005, wartet auf Freigabe]** Bauflächen sind **Zonen aus
Rasterzellen**. Ein Turm belegt genau eine Zelle. Innerhalb der Zone ist jede
freie Zelle wählbar.

| Option | Vorteil | Nachteil |
|---|---|---|
| A: Wirklich frei (Punkt beliebig) | Maximal flexibel | Überlappungsregeln, Fingerverdeckung, schwer lesbar, schwer testbar |
| **B: Raster in Bauzonen (Empfehlung)** | Fühlt sich frei an, eindeutige Treffer per Antippen, einfache Regeln, Datenmodell trivial | Etwas weniger Feinplatzierung |
| C: Feste Bauplätze (wie viele Mobile-TD) | Einfachste Bedienung | Weniger Entscheidungen, widerspricht der Übergabe |

Ein Feld ist die Grundeinheit für alle Strecken (Reichweite, Geschwindigkeit).

**[VORSCHLAG – D-004]** Querformat. Begründung: Wege lesen sich in der Breite
besser, ein 16×9-Raster ergibt auf einem iPhone im Querformat Zellen von etwa
43 pt, knapp über Apples Mindestgröße von 44 pt für Tippziele. Im Hochformat
wären es bei gleicher Feldzahl nur etwa 24 pt.

## Bedienung [VORSCHLAG]

- Freie Zelle antippen → Baumenü an der Zelle mit Preis je Turm; nicht leistbare
  Türme ausgegraut. Vor dem Bestätigen erscheint die Reichweite.
- Turm antippen → Reichweite, Werte, „Verkaufen (Erstattung)".
- Kein Ziehen und Ablegen im MVP: Beim Ziehen verdeckt der Finger genau die
  Stelle, um die es geht.

## Festung

**[VORSCHLAG]** Lebenspunkte als ganze Zahl; jeder Gegner nimmt beim Durchbruch
seinen `leakDamage`. Keine Regeneration im MVP.
