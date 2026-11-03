# P2-11: Blitz allein verliert Mission 2 und 3

Status: **[VORSCHLAG]**, gebaut mit der Empfehlung der Karte S11 („jetzt, als eigenes
Paket“), solange Steffen nicht anders entscheidet (D-075). Werte bleiben [HYPOTHESE]
bis zum Spieltest.

## Ziel

Das Balance-Labor (P2-6b) hat beim ersten Lauf gefunden, dass eine Monokultur aus
Blitztürmen Mission 2 und 3 beim ersten Spielen gewinnt (Reserve 1,18 bzw. bis 1,14
mit Volk und Talent). Das widerspricht D-071 und Säule 1: Gewonnen wird durch
Kombinationen. Ziel ist, dass Blitz allein in beiden Missionen mit jedem Volk verliert,
die Mischungen klar gewinnen und die Bank eine echte Wahl bleibt (±0,05).

## Umfang

**Drin:** Werte in `mission-02.json` und `mission-03.json`, ein Balancetest für die ganze
Region, die bekannten Befunde für M2/M3 aus `labor.json` gestrichen.

**Nicht drin:** Turmwerte, neue Regeln, Mission 1 (Elfen-Dominanz bleibt bekannter
Befund) und Mission 4 (Blitz allein verliert dort schon).

## Optionen (gemessen, Reserve Blitz allein / beste Mischung, ohne Volk)

| Hebel | M2 | Urteil |
|---|---|---|
| Ausgangslage | 1,18 / 1,42 | Blitz gewinnt |
| Blitzturm schwächer je Mission | – | verworfen: ein Turm, der je Mission anders wirkt, ist unlesbar |
| Flitzer 2,2 → 2,6 Felder/s | 1,05 / 1,33 | trifft gezielt Blitz allein, reicht in M2 nicht |
| Gegner weiter auseinander (×1,3) | 1,08 / 1,56 | macht Mischungen leichter, Blitz kaum schwächer |
| Mehr Panzerbestien | 1,07 / 1,40 | stärkt Nur-Wachtürme (Zwerge 1,09, Sieg) |
| **Flitzer 2,6 und Lebenspunkte ×1,1** | **0,95 / 1,20** | gewählt für M2 |
| Flitzer 2,6 allein in M3 | 0,90 / 1,41 | gewählt für M3 |

Warum die Flitzer: Sporen verlangsamen, Wachtürme treffen schnell. Wer nur Blitztürme
baut, lässt schnelle Einzelläufer durch, die Kette findet zwischen ihnen keinen
Nachbarn. Das ist die Lehre, die Säule 1 will, ohne neue Regel.

In Mission 4 brach dieselbe Änderung zwei Kennzahlen der Panzerung
(`MissionFourTests.armorRewardsUpgrading`, Völker +0,1) und war nicht nötig; dort bleiben
die Flitzer bei 2,2. Ob alle Missionen ab 2 dieselbe Geschwindigkeit haben sollen,
gehört in die Werte nach dem Spieltest.

## Architektur

Nur Konfiguration (Regel 7). Simulation und App unverändert. Das Labor prüft die Wahl
in jedem PR; der neue Test `BalanceTests.monocultureLosesOnEveryFirstPlay` hält D-071
für jede Mission mit `FirstPlay` aus dem Labor fest.

## Sicherheit

Keine neue Eingabe, keine neue Datei; die Missionsdateien werden beim Laden geprüft wie
bisher.

## Tests

- `monocultureLosesOnEveryFirstPlay`: Blitz und Sporen allein verlieren beim ersten
  Spielen jeder Mission mit jedem Volk, die beste Mischung liegt über 1,1. Rot gesehen
  mit den alten Werten (vier Verstöße: M2 und M3 je Volk).
- Bestehende Tests von Mission 2 und 3 (Bank als Wahl, Gier verliert, Aufwertung als
  Wahl) laufen unverändert grün.
- Labor Stufe pr: keine neue Verletzung, ein bekannter Befund (M1 Elfen).

## Ergebnis

| Mission | Blitz allein, erstes Spielen | beste Mischung | Menschenbot |
|---|---|---|---|
| M2 | 0,92 bis 0,94 | 1,19 (ohne Fähigkeit) | 75 % (Ziel 75 %) |
| M3 | 0,88 bis 0,91 | 1,35 | 92 % (Ziel 60 %) |

## Risiken

Mission 2 ist spürbar schwerer: Der Menschenbot gewinnt drei von vier Läufen, genau am
Ziel „steigend“, und „Mix mit Bank (früh)“ hat nur noch 1,09 Reserve. Fällt das im
Spieltest auf, zuerst die Lebenspunkte ×1,1 zurücknehmen und den Flitzer stärker
machen.
