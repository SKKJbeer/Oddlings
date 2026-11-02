# R-7 Ausrüstung des Avatars

**Stand:** 01.11.2026 · Grundlage D-066 (Steffen, 27.10.2026: „Ausrüstung mit kleinen
Boni“), Vorgänger [R-6](r-6-avatarrang.md). **R-7a umgesetzt in 0.17.0**, R-7b
(Schmiede) folgt mit eigenem Konzept.

## Ziel

Steffen will im Avatar-Menü einen Charakter aufbauen, der sich cool und wertvoll
anfühlt. Talente machen ihn anders (D-064). Ausrüstung macht ihn **ein wenig
stärker**: Gegenstände mit kleinen Boni, sichtbar am Porträt und im Menü. Damit gilt
die Leitplanke „anders, nicht stärker“ aus
[05](../game-design/05-campaign-and-progression.md#fortschritt) für Ausrüstung nicht
mehr. Für Talente gilt sie weiter.

Die Säulen bleiben bestehen und begrenzen, was Ausrüstung darf:

- **Kombination statt Masse (Säule 1).** Ausrüstung darf eine verlorene Bauweise nicht
  zum Sieg tragen. „Nur Blitztürme“ verliert auch mit der stärksten Ausrüstung.
- **Fair (Säule 5).** Pay-to-win ist ausgeschlossen
  ([06](../game-design/06-monetization.md#leitplanken-entschieden)), also **keine
  Ausrüstung gegen Echtgeld** und **keine Zufallstruhen** (Marktanalyse E13, E15). Jede
  Mission ist ohne Ausrüstung mit drei Sternen zu schaffen.

## Was der Spieler erlebt **[VORSCHLAG]**

1. Im Avatar-Menü kommt neben „Talente“ ein zweiter Reiter **„Ausrüstung“**. Links
   bleibt der Charakter stehen; die angelegten Stücke erscheinen als Rahmen um das
   Porträt.
2. Drei Plätze: **Banner** (wirkt auf Türme), **Amulett** (wirkt auf die
   Festungsfähigkeit) und **Siegel** (wirkt auf Festung und Gold).
3. Je Platz gibt es mehrere Stücke. Jedes nennt seinen Bonus in Zahlen („Wachtürme:
   Reichweite +4 %“) und woher es kommt. Noch nicht erhaltene Stücke sind sichtbar,
   aber gesperrt: Der Spieler weiß, worauf er hinspielt.
4. Anlegen und Tauschen kostet nichts und gilt ab der nächsten Mission.
5. Ein neues Stück meldet das Avatarschild wie ein neues Talent.

## Offene Entscheidungen (Karten an Steffen)

1. **Woher kommen die Stücke?** **Entschieden (D-070): beides.** Grundstücke kommen
   als feste Belohnung aus bestimmten Missionen und Sternschwellen, ohne Zufall.
   Bessere Stücke stellt der Spieler in der **Schmiede** im Avatar-Menü her, mit einer
   Spielwährung aus Missionen. Gebaut wird in zwei Paketen:
   - **R-7a Feste Belohnungen:** Plätze, Grundstücke, Anlegen, Balance. Braucht keine
     Währung und kommt zuerst.
   - **R-7b Schmiede:** eigenes Konzept zur Spielwährung (Name, woher, wofür, wie viel
     je Mission, Schutz gegen veränderte Spielstände). Auch das stärkste
     geschmiedete Stück bleibt unter der Obergrenze aus Entscheidung 2.
2. **Wie stark höchstens?** **Entschieden (D-069): volle Ausrüstung zusammen
   höchstens +10 %** Reserve gegenüber ohne. Das ist spürbar, wiegt aber keine
   Bauweise auf (die Mischung liegt heute rund 0,2 vor der Monokultur).

## Architektur

- **Daten:** neue Datei `Balance/equipment.json`. Stücke mit `id`, `slot`, `source`
  (Mission oder Sternschwelle) und Boni als Faktoren auf benannte Felder:
  Turmschaden, Turmreichweite, Turmpreis, Startgold, Festungsleben, Abklingzeit der
  Fähigkeit. Keine Zahl im Code (Regel 7).
- **Kern:** `BalanceConfig.applying(_ race:, talents:, equipment:)` setzt die Boni ein,
  wie heute Volk und Talente. Die Simulation kennt keine Ausrüstung (Regeln 1, 3).
  `EquipmentTable.issues()` prüft Felder, Faktoren und Quellen wie `RaceTable`.
- **Spielstand:** Was man besitzt, wird nicht gespeichert, sondern aus dem Fortschritt
  abgeleitet (feste Belohnungen). So lässt sich nichts doppelt verdienen oder durch
  einen veränderten Spielstand erschleichen. `Avatar.equipment` speichert nur, welches
  Stück je Platz angelegt ist. Beim Laden wird jede Wahl geprüft: unbekannt oder nicht
  erhalten heißt leerer Platz, ohne Avatar oder Fortschritt zu verlieren. Umgesetzt
  in zwei Stufen: Beim Laden prüft `EquipmentLoadout` die Form jeder Kennung (eine
  kaputte kostet nur ihren Platz); beim Anwenden lässt `EquipmentTable.effective`
  unbekannte, fremde oder noch nicht erhaltene Stücke weg. So braucht der Spielstand
  die Tabelle nicht zum Lesen.
- **Belohnung:** Ein Sieg, der ein Stück freigibt, legt es auf einen freien Platz
  und setzt den Hinweis „Neue Ausrüstung“ am Avatarschild.
- **App:** Reiter im Avatar-Menü (`AvatarScreen`), eine Spalte je Abschnitt.

## Balance

- Jede Mission bleibt **ohne** Ausrüstung mit drei Sternen schaffbar (Bot, Mischung).
- Die stärkste erlaubte Ausrüstung hebt die Reserve höchstens um die Obergrenze von
  +10 % (D-069).
- „Nur Blitztürme“ und „Nur Sporentürme“ verlieren **beim ersten Spielen** einer
  Mission, also mit dem, was frühere Missionen gaben (D-071). Mit voller Ausrüstung
  und Rang V darf eine frühe Mission leicht werden. Die Mischung bleibt mit der
  stärksten Ausrüstung mehr als 0,05 vor „Nur Wachtürme“.
- Gemessen und Werte: [04](../game-design/04-economy-and-balance.md#ausrüstung-r-7a-hypothese).
- Die Balancetests rechnen dafür die stärkste Ausrüstung je Platz mit jedem Volk und
  der stärksten Talentwahl.

## Sicherheit

Die Ausrüstungswahl kommt aus dem Spielstand und wird beim Laden gegen
`equipment.json` und den Fortschritt geprüft. Es gibt keinen Kauf, kein Netz und keine
neue Abhängigkeit.

## Tests

- **Kern:** Prüfung der Tabelle, Besitz aus Fortschritt, Boni wirken nur auf ihre
  Felder, Laden verwirft fremde oder noch nicht erhaltene Stücke einzeln, Balance wie
  oben.
- **App:** Anlegen speichert, gesperrte Stücke lassen sich nicht anlegen, die Mission
  trägt den Bonus.
- **E2E:** Reiter „Ausrüstung“, ein Stück anlegen, Neustart behält es. Dazu eine
  Überlappungsprobe.
- Jeder neue Test wird einmal rot gesehen.

## Offen

1. ~~Herkunft der Stücke~~: beides, in R-7a und R-7b (D-070).
2. ~~Obergrenze der Boni~~: +10 % (D-069).
3. Bilder der Stücke und Rahmen am Porträt: Grafik-Thread, bis dahin Symbole.
