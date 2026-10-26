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

**Wahl.** Das Volk gehört zum Avatar, lässt sich aber vor jeder Mission
wechseln. Fortschritt hängt nicht am Volk. So wird keins zur Pflicht, und wer
ausprobieren will, verliert nichts.

Ein volkseigener Turm (Möglichkeit 2) bleibt als Inhalt für eine spätere
Erweiterungsregion denkbar. Goblins und Arkanisten ebenso.

Die Festungsfähigkeit kommt in Phase 2, die Völker in Phase 3.

## Avatar [ENTSCHIEDEN]

Identität und Personalisierung: Volk, Name, Aussehen; später Embleme, Banner,
Titel als Kosmetik. Kein steuerbarer Held im MVP.
