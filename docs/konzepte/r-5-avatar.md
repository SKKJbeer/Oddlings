# R-5 Avatar: Volk einmal am Anfang wählen

**Stand:** 26.10.2026 · Auftrag Steffen, 26.10.2026: „die völker dass man es am
anfang wählbar ist und nicht pro mission. man soll sich quasi seinen avatar
einmal aufbauen am anfang der erstmal gesetzt ist. mit ingame währung später kann
man das wechseln"

## Ziel

Der Spieler baut beim ersten Spielen einmal seinen Avatar auf: Er wählt sein Volk
und gibt ihm einen Namen. Danach ist das Volk gesetzt und gilt für jede Mission.
Die Wahl auf der Missionstafel (R-4, 0.9.0) entfällt. Das Volk wird Teil der
Identität des Spielers und hört auf, ein Schalter vor jeder Mission zu sein.
Das passt zu [03](../game-design/03-races-and-avatar.md#avatar-entschieden)
(„Identität: Volk, Name, Aussehen") und zu den Vorbildern aus der
[Marktanalyse](../game-design/market-analysis.md), wo ein Profil einmal angelegt
und dann ausgebaut wird.

## Was sich ändert

| Vorher (R-4) | Nachher (R-5) |
|---|---|
| Volk auf der Missionstafel, vor jeder Mission wechselbar | Volk einmal beim ersten „Spielen“, danach fest |
| Ohne Wahl: Steinregen | Jede Mission hat ein Volk. Der Steinregen bleibt die Fähigkeit des Grundspiels in der Simulation, im Spiel erscheint er nicht mehr |
| Kein Name | Name des Avatars, im Hauptmenü und auf der Kampagnenkarte sichtbar |

Es ändert sich **nicht**: Was ein Volk in der Mission bewirkt (Fähigkeit,
Reichweite, Preis), die Balance-Regeln und `BalanceConfig.applying(_:)`.

## Ablauf

1. Hauptmenü → „Spielen“. Gibt es noch keinen Avatar, öffnet sich der
   **Avatar-Aufbau** statt der Kampagnenkarte.
2. Aufbau, eine Tafel im Querformat: links die beiden Völker als große Karten mit
   Bild, Fähigkeit und Vorteil in einem Satz; rechts Name und „Los geht's“.
   Der Knopf ist erst aktiv, wenn ein Volk gewählt und ein Name eingetragen ist.
   Ein Vorschlag steht schon im Feld (je Volk ein zufälliger Name aus einer festen
   Liste), damit niemand an der Tastatur hängen bleibt.
3. Nach „Los geht's“: Kampagnenkarte. Die Missionstafel zeigt das Volk nur noch
   an, als Wappen und Fähigkeitsname, ohne Wahl.
4. Hauptmenü und Karte zeigen oben links das Avatarschild: Wappen des Volks und
   Name.

**Wechseln:** vorerst gar nicht (Entscheidungskarte 2). Später über eine
Spielwährung. Die gibt es noch nicht, und 05 schließt eine zweite Währung bisher
aus („Keine zweite Währung … Säule 5“). Womit der Wechsel bezahlt wird, ist eine
eigene Entscheidung, bevor er gebaut wird. **[OFFEN]**

## RPG-Anmutung

Ergänzung Steffen, 26.10.2026: „das soll so rpg like sein dass mit seinem avatar“.
Ein Rollenspiel fühlt sich durch drei Dinge so an: eine eigene Figur, sichtbares
Wachsen und Entscheidungen, die die Figur prägen. Die Leitplanke aus
[05](../game-design/05-campaign-and-progression.md#fortschritt) („keine dauerhaften
Werteboni, keine Erfahrungspunkte“) steht dem dritten Punkt im Weg, wenn Wachsen
Stärke heißt. Drei Möglichkeiten **[OFFEN, Entscheidungskarte 3]**:

| | Was der Spieler erlebt | Balance | Aufwand |
|---|---|---|---|
| A Rang und Kosmetik | Avatarrang wächst mit gesammelten Sternen; Ränge schalten Titel, Banner, Porträts frei | unberührt | klein |
| **B Rang mit Talentwahl ohne Mehrkraft** (Empfehlung) | wie A, dazu je Rang eine Wahl zwischen zwei gleichwertigen Spielarten der Volksfähigkeit (z. B. Bollwerk breiter und kürzer oder schmal und lang). Jederzeit umstellbar | jede Spielart ist eine geprüfte Konfiguration wie ein Volk; die Balancetests rechnen alle | mittel |
| C Stufen mit Werteboni | klassisch: Erfahrung, Stufen, der Avatar wird stärker | bricht die Leitplanke aus 05; Missionen sind nicht mehr für alle gleich, Balancetests müssten jede Stufe rechnen | groß |

Warum B: Es fühlt sich nach Rollenspiel an (Rang, Wahl, eigene Spielweise), der
Spieler wird aber nicht stärker, sondern anders. Technisch passt es zum Muster der
Völker (`RaceConfig` → `BalanceConfig.applying`), die Simulation bleibt frei von
Avatar-Wissen. Umgesetzt wird es nach dem Aufbau als eigenes Paket R-6; dieser
PR legt nur Volk und Name an, das Speicherformat lässt Platz für Rang und Talente.

## Architektur

- **Kern (OddlingsCore):** `SaveGame` bekommt `avatar: Avatar?` mit
  `Avatar { race: Race, name: String }`. Das Schema wird 2. `SaveGameCodec.migrate`
  macht aus Schema 1 mit `race` einen Avatar ohne Namen nicht automatisch, sondern
  lässt `avatar` leer: Wer schon getestet hat, baut seinen Avatar einmal neu auf.
  Die alte Wahl wird als Vorauswahl übernommen.
- **Prüfung beim Laden** (Sicherheitsregel „was von außen kommt“): Der Name wird
  getrimmt, ist 1 bis 16 Zeichen lang und enthält keine Steuerzeichen. Ein
  ungültiger Name aus der Datei macht den Avatar leer, nicht die ganze Datei
  ungültig. Den Fortschritt verliert dadurch niemand.
- **App:** `AppFlow` hält `avatar` statt `race`. `choose(_:)` entfällt und wird
  durch `createAvatar(race:name:)` ersetzt. Das geht nur, solange kein Avatar
  existiert. `battleMission(for:)` nimmt das Volk des Avatars. Eine neue Ansicht
  `AvatarSetupView` übernimmt den Aufbau, `StartView` leitet bei fehlendem Avatar
  dorthin.
- Die Simulation bleibt unverändert, sie kennt weiter keine Völker.

## Auswirkungen auf Entscheidungen

- **03 „Wahl“** („vor jeder Mission wechseln“) wird ersetzt: Das Volk wird
  einmal gewählt.
- **D-027** (Völker am Ende von Region 1 freischalten) und **D-061** (bis dahin
  beide sofort wählbar): Mit der Wahl am Anfang gibt es keine Freischaltung mehr,
  beide Völker stehen von Beginn an zur Wahl. Neuer Eintrag D-063.

## Tests

- **Kern:** Avatar codieren und decodieren, Migration von Schema 1 mit und ohne
  Volk, Namensprüfung (leer, zu lang, Steuerzeichen, Leerzeichen am Rand), ein
  ungültiger Name leert nur den Avatar.
- **App:** `AppFlow` ohne Avatar führt zum Aufbau, `createAvatar` speichert und
  geht nur einmal, die Mission trägt das Volk des Avatars.
- **E2E:** Erster Start → „Spielen“ → Aufbau → Volk und Name → Karte. Die Tafel
  zeigt das Volk ohne Wahl, die Mission hat die Fähigkeit des Volks. Nach einem
  Neustart der App kein zweiter Aufbau, Name und Volk bleiben. Dazu eine Probe,
  dass im Querformat auf dem kleinsten iPhone nichts überlappt.
- Jeder neue Test wird einmal rot gesehen.

## Offen (Entscheidungskarten)

1. Was gehört zum Aufbau: Volk und Name (Empfehlung), nur Volk, oder dazu ein
   wählbares Porträt.
2. Wechsel, solange es keine Währung gibt: gar nicht (Empfehlung, wie gewünscht
   „erstmal gesetzt“), oder kostenlos in den Einstellungen für die Testphase.
3. Wie rollenspielartig: Rang und Kosmetik, Rang mit Talentwahl ohne Mehrkraft
   (Empfehlung) oder Stufen mit Werteboni (siehe [RPG-Anmutung](#rpg-anmutung)).
