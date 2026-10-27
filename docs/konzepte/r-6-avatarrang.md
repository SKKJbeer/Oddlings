# R-6 Avatarrang mit Talentwahl

**Stand:** 27.10.2026 · Grundlage D-064 (Steffen, 26.10.2026: „Rang mit Talentwahl“
ohne Mehrkraft), Vorgänger [R-5](r-5-avatar.md).

## Ziel

Der Avatar soll sich nach Rollenspiel anfühlen: Er wächst sichtbar, und der Spieler
trifft Entscheidungen, die seine Spielweise prägen. Stärker wird er dabei nicht
(Leitplanke aus [05](../game-design/05-campaign-and-progression.md#fortschritt)).
Ein Rang schaltet eine **Wahl** frei, keine Zahl. Jede Wahl ist eine andere Spielart
der Volksfähigkeit, gleich stark wie die andere Seite, und lässt sich jederzeit
umstellen.

## Was der Spieler erlebt

1. Das Avatarschild im Hauptmenü und auf der Karte zeigt den Rang (römische Ziffer am
   Porträt) und den Fortschritt zum nächsten Rang („4 von 12 Sternen“).
2. Ein Tippen auf das Schild öffnet die **Avatartafel**: Porträt, Name, Volk, Rang,
   die Fähigkeit mit ihren Werten und darunter die Talentreihen.
3. Jede Talentreihe hat zwei Karten nebeneinander. Gesperrte Reihen zeigen, ab
   welchem Rang sie frei werden. In einer freien Reihe ist eine Karte gewählt; ein
   Tippen auf die andere stellt um. Umstellen kostet nichts und gilt ab der nächsten
   Mission.
4. Erreicht der Spieler mit einem Sieg einen neuen Rang, sagt die Ergebnistafel es
   („Rang II: neues Talent frei“), und auf der Karte leuchtet das Schild, bis die
   Tafel einmal offen war.

## Ränge **[VORSCHLAG]**

| Rang | ab Sternen | frei wird |
|---|---|---|
| I | 0 | Grundform der Fähigkeit |
| II | 3 | Talentreihe 1: **Reichweite oder Wucht** |
| III | 12 | Talentreihe 2: **Takt oder Dauer** |

Drei Sterne sind Mission 1 mit voller Wertung: Wer heute spielt, erreicht Rang II
und erlebt die erste Wahl. Rang III braucht mehrere Missionen und kommt mit dem Ausbau
von Region 1 (27 Sterne in den Hauptmissionen). Gezählt werden die besten Sterne je
Mission aus dem Spielstand (`CampaignProgress`), nicht eine eigene Erfahrung: Ein
Rang lässt sich so nie verlieren und nie doppelt verdienen.

## Talente **[VORSCHLAG, Zahlen HYPOTHESE]**

Jede Reihe verschiebt die Fähigkeit entlang einer Achse, beide Seiten tauschen etwas
ein. Die Grundform bleibt die Mitte.

**Zwerge, Bollwerk** (Mauer sperrt den Weg)

| Reihe | Seite A | Seite B |
|---|---|---|
| 1 Reichweite oder Wucht | **Fernwurf:** die Mauer darf weiter neben dem Weg gesetzt werden (Fangweite 1,6 statt 1,0), steht 3,5 s | **Granit:** steht 5 s, Fangweite 1,0 |
| 2 Takt oder Dauer | **Schnell gemauert:** Abklingzeit 25 s, steht 30 % kürzer | **Bergfest:** Abklingzeit 45 s, steht 30 % länger |

**Elfen, Mondmal** (Getroffene nehmen mehr Schaden)

| Reihe | Seite A | Seite B |
|---|---|---|
| 1 Reichweite oder Wucht | **Weiter Schein:** Radius 2,0, Faktor 1,35 | **Scharfes Mal:** Radius 1,1, Faktor 1,75 |
| 2 Takt oder Dauer | **Flüchtig:** Abklingzeit 25 s, hält 3 s | **Tief:** Abklingzeit 45 s, hält 5,5 s |

„Gleich stark“ heißt messbar gleich: Die Balancetests rechnen jede Bauweise aus
`simStrategies` mit **jeder** Kombination (Grundform, je Reihe A oder B, also neun je
Volk) und verlangen, dass die Reserve jeder Kombination höchstens um eine feste
Toleranz von der Grundform abweicht. Die Toleranz steht in der Konfiguration. Was
die Tests nicht halten, wird nachgestellt, bevor es ausgeliefert wird.

## Architektur

- **Daten:** `races.json` bekommt je Volk `talents`: zwei Reihen mit je zwei Spielarten.
  Eine Spielart ist eine **Teilüberschreibung** von `AbilityConfig` (nur die Felder,
  die sie ändert, als Faktor oder Wert). Dazu `ranks` mit den Sternschwellen. Keine
  Zahl im Code (Regel 7).
- **Kern:** `RaceConfig.ability(talents:)` liefert die fertige `AbilityConfig`;
  `BalanceConfig.applying(_:talents:)` setzt sie ein wie heute das Volk. Die
  Simulation bleibt unverändert und kennt weder Rang noch Talent (Regel 1, 3).
  `AvatarRank.rank(stars:ranks:)` rechnet den Rang, rein und getestet.
- **Prüfung:** `ConfigValidation` prüft jede Kombination wie eine eigene Konfiguration
  (Felder vorhanden, Werte im Rahmen). Eine Talentwahl im Spielstand wird beim Laden
  geprüft: unbekannte Reihe oder Seite, oder eine Reihe über dem Rang, fällt auf die
  Grundform zurück, ohne Avatar oder Fortschritt zu verlieren.
- **Spielstand:** `Avatar` bekommt `talents: [Int: TalentSide]` als geordnete Liste
  (`[TalentChoice]`, keine Iteration über ein Dictionary, Regel 6). Schema 3,
  Migration von 2: keine Wahl, also Grundform beziehungsweise Seite A in freien Reihen.
- **App:** `AppFlow.chooseTalent(row:side:)` speichert sofort, `battleMission` reicht
  die Wahl an `applying`. Neue `AvatarPanel` (Tafel nach UI-01), geöffnet über das
  Schild. Ergebnistafel meldet einen neuen Rang.

## Bedienentscheidungen

- **Frei umstellbar, ohne Kosten**, wie in D-064 entschieden. Damit ist eine Wahl
  kein Risiko, und der Spieler probiert beide Seiten.
- **Neue Reihe vorgewählt auf Seite A**, damit ein Spieler, der die Tafel nie öffnet,
  nichts verpasst und nichts falsch macht. Der Hinweis am Schild lädt zum Ansehen ein.
- **Werte sichtbar:** Jede Karte nennt die Änderung in Zahlen („Radius 2,0 · ×1,35“),
  weil eine Wahl ohne Zahlen geraten wäre (Säule „fair“).

## Sicherheit

Talentwahl kommt aus dem Spielstand und wird beim Laden gegen `races.json` geprüft,
bevor sie eine Konfiguration erreicht. Kein Netz, keine neue Abhängigkeit.

## Tests

- **Kern:** Rang aus Sternen an den Schwellen; jede Kombination ergibt eine gültige
  Konfiguration; Spielarten ändern nur ihre Felder; Laden verwirft unbekannte oder
  noch gesperrte Wahl einzeln; Migration Schema 2 → 3.
- **Balance:** Reserve jeder Kombination innerhalb der Toleranz der Grundform, für
  beide Völker.
- **App:** `chooseTalent` speichert, gesperrte Reihe lässt sich nicht wählen, die
  Mission trägt die Spielart.
- **E2E:** Spielstand mit 3 Sternen → Schild zeigt Rang II → Tafel → Seite B der ersten
  Reihe → Mission zeigt die geänderte Fähigkeit; nach Neustart bleibt die Wahl. Dazu
  eine Überlappungsprobe der Tafel auf dem kleinsten iPhone.
- Jeder neue Test wird einmal rot gesehen.

## Offen

1. Ränge und Reihen wie oben (Empfehlung) oder anders gestuft: Entscheidungskarte.
2. Rangabzeichen und Talentbilder kommen aus dem Grafik-Thread; bis dahin Symbole.
