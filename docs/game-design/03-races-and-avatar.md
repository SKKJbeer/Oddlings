# 03 – Völker, Fähigkeiten und Avatar

**Nicht Teil des MVP.** Dieses Dokument hält die Richtung fest, damit sie nicht
verloren geht und damit spätere Entscheidungen sie nicht still verändern.

## Grundsätze [ENTSCHIEDEN]

- Völker verändern den Spielstil, sind aber nie Voraussetzung für Erfolg.
- Grundlegende Turmrollen bleiben für alle zugänglich.
- Kein Volk darf Pflichtwahl werden.
- Startvölker: Zwerge und Elfen. Weitere werden über die Kampagne freigeschaltet,
  nicht gekauft.

## Völker

| Volk | Stil | Status |
|---|---|---|
| Zwerge | Wirtschaft, Konstruktion, lange Planung; Zwergenbank als Kennzeichen | Startvolk, Phase 3 |
| Elfen | Reichweite, Kontrolle, Präzision; Markieren, Verlangsamen | Startvolk, Phase 3 |
| Goblins | Fallen, Geländekontrolle, Überraschung | Idee, nach Release |
| Arkanisten | Elementarmagie, Verstärkung von Synergien | Idee, nach Release |

## Festungsfähigkeit und wie ein Volk wirkt

**[ENTSCHIEDEN D-025]** Steffen, 25.10.2026 (E-2). Zahlen sind Zielgrößen für die erste Rechnung; die Werte kommen in die Missionsdatei.

Herkunft: Übergabe Nr. 9, Marktanalyse E7.

### Eine aktive Festungsfähigkeit (Phase 2)

**Warum.** Steht die Verteidigung, hat der Spieler nichts zu tun außer
zuzusehen. Kingdom Rush löst das mit Zaubern und Helden. Ein Held ist bei uns
ausgeschlossen; eine Fähigkeit an der Festung schließt dieselbe Lücke, ohne
Figur, Steuerung und Wegfindung.

**Regel.** Ein Knopf im HUD. Antippen, dann eine Stelle am Weg antippen. Nach
kurzer Verzögerung (sichtbarer Schatten) trifft **Steinregen** alle Gegner im
Kreis: Schaden und ein kurzes Anhalten. Danach Abklingzeit. Kostet kein Gold,
ist ab der ersten Welle bereit.

Warum Steinregen: Er belohnt dieselbe Lage wie der Blitz (dichte, verlangsamte
Gruppen), stärkt also Säule 1, statt eine zweite Spielidee zu öffnen. Er ist
ein Befehl wie `build` (`useAbility(point)`), also determinierbar und testbar.

**Prüfung.** Der Balance-Bot setzt ihn auf die dichteste Stelle. Die Reserve
darf dadurch um höchstens etwa 0,1 steigen; sonst ersetzt die Fähigkeit Türme.

### Wie ein Volk wirkt (Phase 3)

Zur Wahl standen drei Möglichkeiten: passive Boni, eigener
Turm, aktive Volksfähigkeit. **Ein Volk bestimmt die
Festungsfähigkeit und hat einen kleinen passiven Zug.** Kein eigener Turm vor
dem Release.

| Volk | Festungsfähigkeit | Passiver Zug | Spielstil |
|---|---|---|---|
| ohne Volk (Phase 2) | Steinregen | – | Grundspiel |
| Zwerge | **Bollwerk:** eine Mauer sperrt den Weg kurz, Gegner stauen sich | Wachtürme 10 % billiger (D-062); später vielleicht die Zwergenbank mit höherem Ertragsdeckel | Wirtschaft, planen, stauen |
| Elfen | **Mondmal:** Gegner im Kreis sind kurz verwundbar | Sporentürme mit etwas mehr Reichweite | Kontrolle, Präzision |

Begründung:
- Spürbar verschieden, ohne die Grundtürme zu verändern. Die Grundsätze in 03
  („Grundrollen für alle", „keine Pflichtwahl") bleiben unberührt.
- Billig: eine Fähigkeit und ein Zahlenwert je Volk, statt eines Turms mit
  drei Stufen, zwei Spezialisierungen und Grafik.
- Testbar: Ein Volk ist eine zweite Konfiguration derselben Mission. Die
  Balancetests rechnen jede Mission mit jedem Volk; kein Volk darf mehr als
  etwa 0,05 Reserve vor dem anderen liegen.
- Mondmal nutzt denselben Zustand „verwundbar" wie die Spezialisierung Fäulnis
  ([02](02-combat-and-towers.md#aufwertungen-mit-einer-gabelung-je-turm-phase-2)). Eine Regel, zwei Verwendungen.

**Wahl [ENTSCHIEDEN D-063].** Das Volk gehört zum Avatar und wird einmal
gewählt, beim ersten „Spielen“, zusammen mit Porträt und Name. Danach gilt es
für jede Mission. Fortschritt hängt nicht am Volk, und beide Völker stehen von
Anfang an zur Wahl; so wird keins zur Pflicht. Einen Wechsel gibt es erst mit
einer Spielwährung ([R-5](../konzepte/r-5-avatar.md)).

Ein volkseigener Turm (Möglichkeit 2) bleibt als Inhalt für eine spätere
Erweiterungsregion denkbar. Goblins und Arkanisten ebenso.

Die Festungsfähigkeit kommt in Phase 2, die Völker in Phase 3.

## Avatar [ENTSCHIEDEN]

Identität und Personalisierung: Volk, Name, Porträt, einmal am Anfang aufgebaut
(D-063, [R-5](../konzepte/r-5-avatar.md)); später Embleme, Banner, Titel als
Kosmetik. Kein steuerbarer Held im MVP.

Rollenspielartig wird der Avatar über einen **Rang mit Talentwahl ohne
Mehrkraft** (D-064): Sterne heben den Rang, je Rang eine Wahl zwischen zwei gleich
starken Spielarten der Volksfähigkeit. Der Avatar wird anders, nicht stärker. Umsetzung, Ränge und Talente:
[R-6](../konzepte/r-6-avatarrang.md).

**Avatar-Menü [ENTSCHIEDEN D-065].** Fünf Ränge (ab 6, 12, 18, 24 Sternen), je Rang
eine Talentreihe, vier Reihen je Volk. Der Avatar hat einen eigenen Schirm: links der
Charakter mit Porträt, Rang und Sternbalken, rechts seine Abschnitte. Heute gibt es
einen (Talente); weitere kommen als Reiter daneben. Umgesetzt in 0.12.0.

**Ausrüstung [ENTSCHIEDEN D-066, Ausgestaltung OFFEN].** Als nächster Abschnitt des
Avatar-Menüs kommen Gegenstände mit kleinen Werteboni (Größenordnung +5 % auf Türme).
Das ist die einzige Ausnahme von „anders, nicht stärker“; Talente bleiben ohne
Mehrkraft. Offen und von Steffen zu entscheiden: woher die Gegenstände kommen und wie
hoch die Boni höchstens gehen. Eigenes Paket mit Konzept nach R-6
([Roadmap](../production/roadmap.md)).
