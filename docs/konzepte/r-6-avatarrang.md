# R-6 Avatarrang mit Talentwahl

**Stand:** 27.10.2026 · Grundlage D-064 (Steffen, 26.10.2026: „Rang mit Talentwahl“
ohne Mehrkraft) und D-065 (Steffen, 27.10.2026: fünf Ränge, eigenes Avatar-Menü),
Vorgänger [R-5](r-5-avatar.md).

## Ziel

Der Avatar soll sich nach Rollenspiel anfühlen: Er wächst sichtbar, und der Spieler
trifft Entscheidungen, die seine Spielweise prägen. Stärker wird er dabei nicht
(Leitplanke aus [05](../game-design/05-campaign-and-progression.md#fortschritt)).
Ein Rang schaltet eine **Wahl** frei, keine Zahl. Jede Wahl ist eine andere Spielart
der Volksfähigkeit, gleich stark wie die andere Seite, und lässt sich jederzeit
umstellen.

## Was der Spieler erlebt

1. Das Avatarschild im Hauptmenü und auf der Karte zeigt den Rang (römische Ziffer am
   Porträt).
2. Ein Tippen auf das Schild öffnet das **Avatar-Menü**, einen eigenen Schirm: links
   der Charakter mit großem Porträt, Name, Volk, Rang und einem Sternbalken zum
   nächsten Rang („6 von 12 Sternen bis Rang III“), rechts die Talentreihen.
   „Zurück“ führt dorthin, wo es geöffnet wurde.
3. Jede Talentreihe hat zwei Karten nebeneinander. Gesperrte Reihen zeigen, ab
   welchem Rang sie frei werden. In einer freien Reihe ist eine Karte gewählt; ein
   Tippen auf die andere stellt um. Umstellen kostet nichts und gilt ab der nächsten
   Mission.
4. Erreicht der Spieler mit einem Sieg einen neuen Rang, trägt das Avatarschild auf
   Karte und Hauptmenü „Neues Talent“, bis das Avatar-Menü einmal offen war. Die
   Ergebnistafel bleibt unverändert: Dort zählt der Sieg, und das Schild ist der
   erste Blick danach.

## Avatar-Menü zum Ausbauen (D-065)

Steffen will ein eigenes Avatar-Menü, in dem man sich über die Zeit einen coolen und
wertvollen Charakter aufbaut. Deshalb ist es ein Schirm und keine Tafel: Links steht
immer der Charakter, rechts seine Abschnitte. Heute gibt es einen, die Talente. Was
später dazukommt, bekommt einen eigenen Abschnitt daneben (Reiter über der rechten
Spalte), ohne den Charakter zu verdrängen. Als Nächstes kommt dort **Ausrüstung mit
kleinen Boni** (D-066, Steffen 27.10.2026). Sie ist ein eigenes Paket mit eigenem
Konzept; R-6 baut davon nichts vor (Scope-Verbot).

## Ränge **[ENTSCHIEDEN, D-065]**

| Rang | ab Sternen | frei wird |
|---|---|---|
| I | 0 | Grundform der Fähigkeit |
| II | 6 | Talentreihe 1 |
| III | 12 | Talentreihe 2 |
| IV | 18 | Talentreihe 3 |
| V | 24 | Talentreihe 4 |

Region 1 bringt 27 Sterne (sieben Haupt- und zwei Nebenmissionen), Rang V ist also
erst kurz vor ihrem Ende erreicht. Heute ist nur Mission 1 spielbar (3 Sterne): Die
erste Wahl wartet auf Mission 2, das Avatar-Menü zeigt bis dahin den Weg. Gezählt werden die besten Sterne je
Mission aus dem Spielstand (`CampaignProgress`), nicht eine eigene Erfahrung: Ein
Rang lässt sich so nie verlieren und nie doppelt verdienen.

## Talente **[VORSCHLAG, Zahlen HYPOTHESE]**

Jede Reihe verschiebt die Fähigkeit entlang einer Achse, beide Seiten tauschen etwas
ein. Die Grundform bleibt die Mitte.

Alle Werte sind Faktoren auf die Grundform des Volks und stehen in `races.json`;
die Tabelle nennt den Stand nach der ersten Messung.

**Zwerge, Bollwerk** (Mauer sperrt den Weg; Grundform 4 s, Abklingzeit 35 s, Fangweite 1,0)

| Reihe | Seite A | Seite B |
|---|---|---|
| 1 Reichweite oder Wucht | **Fernwurf:** Fangweite ×1,6, steht ×0,9 | **Granit:** steht ×1,2, Fangweite ×0,8 |
| 2 Takt oder Dauer | **Schnell gemauert:** Abklingzeit ×0,8, steht ×0,7 | **Bergfest:** Abklingzeit ×1,3, steht ×1,2 |
| 3 Wurf oder Takt | **Langer Arm:** Fangweite ×1,4, Abklingzeit ×1,15 | **Ruhige Hand:** Abklingzeit ×0,88, Fangweite ×0,85 |
| 4 Festung oder Feld | **Festungswall:** Fangweite ×1,2, steht ×1,1, Abklingzeit ×1,15 | **Feldmauer:** Fangweite ×0,9, steht ×0,9, Abklingzeit ×0,9 |

**Elfen, Mondmal** (Getroffene nehmen mehr Schaden; Grundform Radius 1,5, ×1,5, 4 s, 35 s)

| Reihe | Seite A | Seite B |
|---|---|---|
| 1 Reichweite oder Wucht | **Weiter Schein:** Radius ×1,3, Schadensfaktor ×0,9 | **Scharfes Mal:** Radius ×0,8, Schadensfaktor ×1,07 |
| 2 Takt oder Dauer | **Flüchtig:** Abklingzeit ×0,8, hält ×0,7 | **Tief:** Abklingzeit ×1,25, hält ×1,15 |
| 3 Glut oder Schleier | **Glut:** Schadensfaktor ×1,05, hält ×0,8 | **Schleier:** hält ×1,25, Schadensfaktor ×0,95 |
| 4 Weite oder Takt | **Mondweite:** Radius ×1,2, Abklingzeit ×1,15 | **Mondsichel:** Abklingzeit ×0,85, Radius ×0,85 |

„Gleich stark“ heißt messbar gleich: Die Balancetests rechnen jede spielbare
Kombination (Grundform und jede Wahl über eine bis vier freie Reihen: 31 je Volk)
mit den vier gewinnenden Mischungen aus `simStrategies` und nehmen den Schnitt. Ein
einzelner Lauf springt schon, wenn ein Wurf eine Welle früher fällt; über die 31
Kombinationen eines Volks streut der Schnitt um etwa ±0,05. Deshalb wird jede
Kombination mit der **Mitte** ihres Volks verglichen (höchstens 0,06 daneben), und die
Mitte darf höchstens 0,05 über der Grundform liegen: Im Schnitt macht ein Rang nicht
stärker. Dazu muss jede Kombination helfen und die Mischung mehr als 0,05 vor „Nur
Wachtürme“ lassen. Gemessen am 27.10.2026: Mitte über der Grundform bei Zwergen 0,028,
bei Elfen 0,020; größte Abweichung von der Mitte 0,054 (Zwerge) und 0,028 (Elfen);
kleinster Abstand der Mischung zur Monokultur 0,062.

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
- **Spielstand:** `Avatar` bekommt `talents: [TalentSide]`, eine Seite je Reihe in
  Reihenfolge (keine Iteration über ein Dictionary, Regel 6). Das Feld ist optional
  und kommt nur dazu, deshalb bleibt Schema 2: Ein alter Stand hat keine Wahl, also
  Seite A in freien Reihen. Eine kaputte Wahl (unbekannte Seite, mehr als acht
  Reihen) verwirft nur die Wahl.
- **App:** `AppFlow.chooseTalent(row:side:)` speichert sofort, `battleMission` reicht
  die Wahl an `applying`. Neue `AvatarPanel` (Tafel nach UI-01), geöffnet über das
  Schild. Das Schild meldet einen neuen Rang. Das Avatar-Menü ist ein eigener
  Schirm (`AppFlow.Screen.avatar`), „Zurück“ führt zum Schirm, von dem es kam.

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
- **E2E:** Testschalter legt drei Sterne auf Mission 2, Sieg in Mission 1 → Schild
  zeigt Rang II und „Neues Talent“ → Avatar-Menü → Seite B der ersten Reihe, drei
  Reihen gesperrt → Zurück zur Karte; nach Neustart bleibt die Wahl. Dazu eine
  Überlappungsprobe des Menüs.
- Jeder neue Test wird einmal rot gesehen.

## Offen

1. Ausrüstung (D-066): eigenes Paket nach R-6.
2. Rangabzeichen und Talentbilder kommen aus dem Grafik-Thread; bis dahin Symbole.
