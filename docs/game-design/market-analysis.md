# Marktanalyse: führende mobile Tower-Defense-Spiele

Stand: 25.10.2026 · Status: **Analyse und [VORSCHLAG]**. Nichts hier ist entschieden.
Empfehlungen, die eine bestehende Entscheidung berühren, nennen sie ausdrücklich.
Werden sie angenommen, kommen sie als eigener Eintrag ins
[Entscheidungsprotokoll](../decisions/decision-log.md) und an die maßgebliche
Stelle in 00–06; dieses Dokument wiederholt dann nicht, sondern verlinkt.

## Quellenlage – bitte zuerst lesen

Studios veröffentlichen kaum Zahlen. Jede Zahl hier trägt ihre Herkunft:

- **Herstellerangabe**: vom Studio oder Verlag selbst, nicht unabhängig geprüft.
- **Schätzung Dritter**: Marktforscher oder Datenseiten, oft nur eine Plattform.
- **Beobachtung**: aus dem Spiel, dem Store oder Rezensionen, ohne Zahl.
- **Erfahrungswissen**: Branchenmuster, nicht gemessen. Als solches gekennzeichnet.

Was nicht belegt werden konnte, steht als „—" da. Ausdrücklich **nicht belegt**:
Jahresumsatz von Bloons TD 6, Verkaufszahlen von Kingdom Rush 5, Umsatz von
Plants vs. Zombies 2. Die Marktgröße „mobile Tower Defense" schwankt zwischen
zwei Berichten um mehr als 50 % (3,08 bzw. 4,75 Mrd. USD für 2025) und taugt
deshalb nur als Größenordnung.

## 1 Wer den Markt prägt

| Spiel | Studio | Modell | Belegte Kennzahl | Art der Zahl |
|---|---|---|---|---|
| Bloons TD 6 (2018) | Ninja Kiwi (seit 2021 MTG, Kaufpreis 142 Mio. USD) | Premium 6,99 USD mobil + Käufe (Spielwährung, Komfort); zusätzlich Apple Arcade und Netflix ohne Käufe | Steam allein ~8,8 Mio. Verkäufe / ~74 Mio. USD brutto; App Store 4,9 bei >335 000 Bewertungen; laut MTG „eines der größten Spiele bei Apple" | Schätzung Dritter / Beobachtung / Herstellerangabe |
| Kingdom Rush (1–5, seit 2011) | Ironhide (seit 2021 Tencent) | Premium (KR5: 7,99 €) + Käufe für Helden und Zusatztürme | >63 Mio. Downloads über alle Teile und Plattformen | Herstellerangabe (Interview 2024) |
| Rush Royale (2020) | My.Games | F2P, PvP und Koop, Kartensammlung mit Zufallskisten | >500 Mio. USD Lebenszeitumsatz, >105 Mio. Downloads (Juni 2026) | Herstellerangabe |
| Random Dice (2019) | 111 % | F2P, PvP, Würfel-Deck, Zufallselemente | ~240 Mio. USD Lebenszeitumsatz, 21,6 Mio. Downloads (Juni 2026) | Pressebericht nach Herstellerdaten |
| Arknights (2019/2020) | Hypergryph / Yostar | F2P-Gacha um Figuren, starke Erzählung | knapp 1 Mrd. USD mobil, 62 % davon Japan | Schätzung Dritter |
| Plants vs. Zombies 2 (2013) | PopCap / EA | F2P mit Käufen und Werbung | — | — |

**Lesart:** Es gibt zwei Märkte, die sich kaum überschneiden.

1. **Premium-Qualitäts-TD** (Kingdom Rush, Bloons TD 6): Einmalpreis, faire
   Zusatzkäufe, Jahre an Pflege, sehr hohe Bewertungen, treue Spieler. Bloons TD 6
   zeigt, dass ein kostenpflichtiges Spiel über sieben Jahre Spitzenumsatz halten
   kann, wenn es kostenlos Inhalte nachliefert.
2. **F2P-Wettkampf- und Sammel-TD** (Rush Royale, Random Dice, Arknights): die
   größten Umsätze, aber getragen von PvP, Sammeln, Zufallskisten und
   Live-Betrieb mit Team. Das sind genau die Hebel, die Oddlings ausschließt
   ([06](06-monetization.md), MVP-Grenze).

Oddlings gehört von seinen Säulen her klar in Markt 1. Das ist eine gute
Nachricht: Dort entscheidet Qualität, nicht Marketingbudget oder Live-Team.

## 2 Was den Spaß ausmacht

### Kingdom Rush – Charme, Handarbeit, aktiver Spieler

- **Wenige Turmtypen, tiefe Äste.** Vier Grundtürme (Bogen, Kaserne, Magie,
  Artillerie), jeder mit Aufwertung und zwei Spezialisierungen. Man versteht das
  System in einer Minute.
- **Der Spieler hat etwas zu tun.** Zwei Zauber mit Abklingzeit (Feuerregen,
  Verstärkung), ein steuerbarer Held, Sammelpunkte der Kaserne. Das hält die Hände
  beschäftigt, wenn die Türme stehen. **Beobachtung.**
- **Gegner mit Persönlichkeit.** Jeder neue Gegner bekommt eine Karte im
  Bestiarium und einen Auftritt. Humor und Anspielungen überall.
- **Wiederspielwert über Modi:** drei Sterne je Karte, dazu „Heldenhaft" und
  „Eisern" mit Turmverboten. Dieselbe Karte, neue Frage.
- **Feste Bauplätze.** Wenige, gut gesetzte Plätze machen jede Wahl gewichtig.

### Bloons TD 6 – Zerstörung als Belohnung, endlose Tiefe

- **Das Platzen.** Jeder Treffer platzt sichtbar und hörbar, Ballons zerfallen
  in kleinere. Späte Runden sind ein Feuerwerk. Diese Rückmeldung ist der Kern
  des Spielgefühls. **Beobachtung.**
- **Gegner lesbar über Farbe und Form.** Jede Ballonart hat eine Farbe; Eigenschaften
  (Tarnung, Blei, Regeneration) haben ein Symbol. Man liest die Welle auf einen Blick.
- **Drei Aufwertungspfade je Turm mit Kombinationsregel** (ein Pfad bis 5, ein
  zweiter bis 2). Daraus entstehen hunderte Bauweisen aus wenigen Türmen.
- **Freie Platzierung, Zielwahl je Turm** (erster, letzter, stärkster, nächster).
- **Rundenbasiert mit Schnellvorlauf.** Spieler bestimmen das Tempo.
- **Langlebigkeit durch kostenlose Updates:** neue Türme, Helden, Karten, Bosse,
  wöchentliche Wettbewerbe, Koop, Herausforderungseditor. 2025 kam mit „Rogue
  Legends" eine große Erweiterung. **Herstellerangabe MTG.**

### Arknights – Platzierung als Rätsel

- Begrenzte Einsatzpunkte, Figuren mit Blockzahl und **Blickrichtung**. Jede
  Karte ist ein Rätsel mit wenigen guten Lösungen.
- Nach einem Sieg lässt sich die Mission **automatisch wiederholen**. Das nimmt
  den Frust aus dem Sammeln. Für Oddlings relevant als Komfortidee, nicht als
  Sammelschleife.
- Hohe Produktionsqualität bei Figuren, Musik und Benutzeroberfläche trägt die
  Bindung mindestens so stark wie das Spiel selbst. **Erfahrungswissen.**

### Rush Royale und Random Dice – drei Minuten, ein Gegner

- Sehr kurze Runden, Zusammenführen gleicher Einheiten (Merge), Deckbau vor dem
  Spiel. Zufall bei der Einheitenwahl erzeugt Spannung und Ausreden.
- Der Fortschritt hängt an Kartenstufen, die man kauft oder sammelt. Genau das
  ist Pay-to-win im Sinne von Säule 5. Lehrreich nur für **Sitzungslänge und
  Zugänglichkeit**, nicht für das Geschäftsmodell.

### Plants vs. Zombies – Lehren ohne Text

- Jede Mission führt höchstens **eine** neue Pflanze oder einen neuen Gegner ein,
  und die Mission ist so gebaut, dass man ihn braucht. Kein Tutorialtext nötig.
  Das ist dasselbe Prinzip, das [02](02-combat-and-towers.md#die-kernsynergie-und-wie-mission-1-sie-lehrt)
  für Welle 5 und 6 vorsieht.

## 3 Was „AAA-Anmutung" bei diesen Spielen konkret heißt

Kein Marktführer ist AAA im Umfang. Was sie hochwertig wirken lässt, sind
wiederkehrende Einzelheiten. **Erfahrungswissen**, aus den Spielen beobachtet:

| Bereich | Was die Besten tun |
|---|---|
| Rückmeldung | Jede Handlung hat Bild, Ton und (auf dem iPhone) Haptik: Bauen mit kleinem Aufbau-Effekt, Treffer mit Aufblitzen, Tod mit Zerfall, Goldzahl springt hoch. Nichts passiert stumm. |
| Ton | Eigene Klangfarbe je Turm, Treffer- und Todesgeräusche, die sich bei Massen nicht übertönen (Begrenzung gleichzeitiger Klänge). Musik wechselt mit der Lage (Bosswelle). |
| Lesbarkeit | Gegnertyp an Umriss und Farbe erkennbar, Zustände als Symbol am Gegner (verlangsamt, markiert), Lebensbalken nur bei Schaden. Effekte sind kräftig, aber kurz. |
| Bewegung | Figuren haben Laufzyklen und Gewicht; Türme drehen sich zum Ziel. Kleine Übertreibung (Squash and Stretch) statt Realismus. |
| Oberfläche | Wenige, große Knöpfe; Menüs mit Übergängen; Zahlen zählen hoch statt zu springen. Keine Ladezeit zwischen Mission und Ergebnis. |
| Stabilität | 60 Bilder/s auch in späten Wellen. Ein Ruckeln in Welle 20 kostet mehr Ansehen als ein fehlender Turm. |
| Persönlichkeit | Gegner und Türme haben Namen, Sprüche, Bestiariumseintrag. Charme ist billiger als Umfang. |

Das passt zu 00 („AAA bei Spielgefühl, Lesbarkeit, Animation, Ton, nicht im
Umfang") und gibt ihm eine prüfbare Liste.

## 4 Monetarisierung und Umsätze

| Modell | Beispiel | Was es trägt | Was es verlangt | Passt zu Oddlings? |
|---|---|---|---|---|
| Premium + faire Käufe | Bloons TD 6, Kingdom Rush | Einmalpreis 5–8 €, Käufe für Komfort, Helden, Spielwährung | Hohe Qualität ab Tag 1, Jahre an kostenloser Pflege | **Ja**, mit Vorsicht bei Käufen, die Vorteile bringen |
| Kostenlos anspielen, einmal freischalten | viele Indie-Strategiespiele | Erster Abschnitt frei, Rest per Einmalkauf | Gute erste Viertelstunde | **Ja**, bereits in [06](06-monetization.md) als Option genannt |
| Abo-Kataloge | Apple Arcade (BTD6+), Netflix Games | Vertragszahlung statt Verkauf, keine Käufe | Verhandlung, Qualitätsruf | **Ja, als zweiter Kanal**, nicht als Start |
| F2P mit Sammeln/PvP | Rush Royale, Random Dice | Größte Umsätze im Genre | Live-Team, Server, Ereignisse, Zufallskisten | **Nein**, widerspricht Säule 5 und 06 |
| F2P-Gacha | Arknights | Höchster Umsatz je Spieler | Großes Studio, ständig neue Figuren | **Nein** |
| Werbung | PvZ 2, Hypercasual-TD | Breite ohne Kaufhürde | Viele Downloads, stört Spielgefühl | **Höchstens** freiwillige Belohnungswerbung, später |

**Befund:** Die zwei Premium-Marktführer verdienen ohne Pay-to-win, aber
**nicht nur mit Kosmetik**. Kingdom Rush verkauft Helden und Zusatztürme; der
Unmut darüber in Rezensionen (nur zehn Türme ohne Kauf, Rest 17,99 €) zeigt, wo
die Grenze zur Verärgerung liegt. Bloons TD 6 verkauft vor allem Spielwährung
und Komfort, das ganze Spiel ist aber erspielbar. **Beobachtung.**

Das bestätigt den kritischen Hinweis in [06](06-monetization.md): Reine Kosmetik
trägt erst bei großer Spielerzahl. Für ein Solo-Projekt ist „anspielen und
freischalten" plus spätere bezahlte Regionen der realistischere Weg.

## 5 Wiederkehr (Retention)

Branchenwerte (Schätzung Dritter, verschiedene Jahre und Definitionen):

| Kennzahl | Strategie/Genre-Mittel | Oberes Viertel aller Spiele |
|---|---|---|
| Tag 1 | ~25 % | ~27 % |
| Tag 7 | ~8 % | — |
| Tag 30 | ~3 % | — (75 % aller Spiele liegen unter 3 %) |

Premium-Spiele messen anders (wer zahlt, ist schon gebunden), deshalb taugen die
Werte für Oddlings nur als Untergrenze für eine kostenlose Anspielversion.

**Was bei den Marktführern Spieler zurückholt** (Beobachtung):

1. **Nächstes Ziel ist sichtbar:** Sterne, gesperrter Weg auf der Karte, neuer
   Turm hinter der nächsten Mission.
2. **Dieselbe Karte, neue Frage:** Modi mit Einschränkungen (KR „Eisern", BTD6
   Schwierigkeiten und Modi je Karte). Billig in der Herstellung, weil Karten
   wiederverwendet werden.
3. **Tägliche oder wöchentliche Herausforderung** mit festem Startwert, für alle
   gleich (BTD6 tägliche Herausforderung, Rennen, Bossereignisse).
4. **Inhalt nachliefern:** Bloons TD 6 lebt seit Jahren von kostenlosen Updates.
5. **Gemeinschaft:** Koop, Bestenlisten, Herausforderungseditor. Für Oddlings
   vorerst nicht im Umfang.

## 6 Lücken im Markt

Aus den Spielen und Rezensionen abgeleitet. **Erfahrungswissen, nicht gemessen.**

1. **Synergie als erklärter Kern.** Bei den Marktführern sind Kombinationen ein
   Nebeneffekt (BTD6-Unterstützertürme, KR-Kaserne staut Gegner für Artillerie).
   Ein TD, das jeden Turm über sein Zusammenspiel definiert und das sichtbar
   macht, ist selten. Genau das ist Säule 1 von Oddlings.
2. **Hochwertig und fair zugleich, ohne Vorteilskäufe.** Spieler beklagen bei KR
   gekaufte Helden und Türme, bei F2P-TD das Stufensystem. Ein Spiel, in dem
   man alles erspielt und nur für Inhalt oder Aussehen zahlt, ist eine klare
   Botschaft im Store.
3. **Wirklich kurze Missionen im Premium-Bereich.** KR- und BTD6-Partien dauern
   oft 15–40 Minuten. Fünf bis zwölf Minuten (Säule 4) sind bei Premium-TD
   ungewöhnlich und passen zur Nutzung am Telefon.
4. **Für das iPhone gebaut.** Viele Marktführer stammen aus Flash/PC und tragen
   das in der Bedienung. Haptik, 120 Hz, Querformat-Bedienung mit Daumen, sofortiges
   Fortsetzen nach Unterbrechung sind Felder, auf denen ein natives Spiel
   sichtbar besser sein kann.
5. **Offline und ohne Konto.** F2P-TD verlangt fast immer Netz. Ein Spiel, das im
   Flugzeug vollständig funktioniert, ist ein Argument.
6. **Charmante Fantasy ohne Grimdark und ohne Anime-Gacha.** KR besetzt das Feld
   fast allein; zwischen KR-Teilen liegen Jahre.

## 7 Empfehlungen für Oddlings

Alle **[VORSCHLAG]**. Spalte „Berührt" nennt, welche Entscheidung oder welches
Dokument betroffen wäre. Nichts davon ändert den MVP-Umfang, solange Steffen es
nicht freigibt.

### Spielgefühl und Lesbarkeit (Phase 1–2)

| # | Empfehlung | Vorbild, ohne Kopie | Berührt |
|---|---|---|---|
| E1 | **Rückmeldeliste je Ereignis** als Abnahmekriterium: jedes Simulationsereignis (Bau, Treffer, Kettensprung, Verlangsamung, Tod, Durchbruch, Gold) hat Bild, Ton und gegebenenfalls Haptik. Prüfbar als Tabelle, nicht als Gefühl. | BTD6-Platzen, KR-Aufbau | Architekturregel 3 (Ereignisse) passt bereits; Abnahme Phase 2 in [roadmap](../production/roadmap.md) |
| E2 | **Synergie sichtbar machen:** Wenn ein Blitz ein verlangsamtes Ziel trifft, ein eigener, kräftigerer Effekt und Ton („Sporenfunke"). So lernt der Spieler die Kernsynergie über Rückmeldung statt Text. Reine Darstellung, keine neue Regel. | eigenes Element, Lücke 1 | [02](02-combat-and-towers.md) Kernsynergie; Säule 1 und 2 |
| E3 | **Zustände als Symbol am Gegner**, Gegnertyp an Umriss erkennbar, Lebensbalken nur bei Schaden. | BTD6-Eigenschaftssymbole | Säule 2; Grafikstil Phase 2 |
| E4 | **Leistungsgrenze früh festlegen:** späteste Welle mit 2× auf dem ältesten Zielgerät (iPhone XS/XR, D-006) bei 60 Bilder/s. Die WP-01-Messung sollte diese Last enthalten. | – | WP-01, Phase 4 Abnahme |
| E5 | **Zielwahl je Turm** (erster/letzter/stärkster) als Kandidat für Phase 2. Billig in der Simulation, viel Tiefe. | BTD6 | [02](02-combat-and-towers.md) „Zielwahl erster" bleibt im MVP |

### Tiefe und Wiederspielwert (Phase 2–3)

| # | Empfehlung | Vorbild, ohne Kopie | Berührt |
|---|---|---|---|
| E6 | **Aufwertungen mit genau einer Gabelung je Turm** (zwei Stufen, dann Wahl zwischen zwei Spezialisierungen, die je eine andere Synergie verstärken). Weniger als BTD6, mehr Entscheidung als ein reines „+Schaden". | KR-Äste, BTD6-Pfade | **D-008** (keine Upgrades im MVP) bleibt; Vorschlag ist, Upgrades für Phase 2 fest einzuplanen, weil alle Marktführer davon leben |
| E7 | **Eine aktive Festungsfähigkeit** mit Abklingzeit (z. B. kurzer Sporenregen oder Wall), damit der Spieler bei stehender Verteidigung etwas zu tun hat. Kein Held. | KR-Zauber | MVP-Grenze „kein steuerbarer Held" bleibt unberührt; **D-Vorschlag** für Phase 2; [03](03-races-and-avatar.md) Option 3 „aktive Volksfähigkeit" könnte daraus wachsen |
| E8 | **„Nächste Welle" mit Goldbonus** in Phase 2 prüfen, wie in [01](01-core-gameplay.md) schon vorgesehen. Marktstandard bei KR. | KR | D-009 |
| E9 | **Sterne plus ein Einschränkungsmodus je Mission** (z. B. „nur zwei Turmtypen", „Festung hat 1 Leben"). Erhöht Spielzeit je Karte stark bei geringem Aufwand und stärkt Säule 1. | KR „Eisern", BTD6-Modi | [05](05-campaign-and-progression.md) Kandidat „Sterne je Mission" |
| E10 | **Tägliche Herausforderung mit festem Startwert**, offline erzeugt aus dem Datum. Möglich, weil die Simulation deterministisch ist (Architekturregel 6). Bestenliste erst später und nur über Game Center, kein eigenes Backend. | BTD6 tägliche Herausforderung | Scope-Verbot: frühestens Phase 3, Freigabe nötig |
| E11 | **Bestiarium und Turmbuch** mit Charaktertext. Billig, trägt Persönlichkeit. | KR | Phase 2–3, Grafik und Text |

### Geschäftsmodell (Phase 5, Entscheidung mit Daten)

| # | Empfehlung | Berührt |
|---|---|---|
| E12 | **Bevorzugt: kostenlos anspielen (erste Region), Vollversion einmalig**, danach bezahlte Regionen. Kosmetik als Zugabe, nicht als Grundlage. Begründung: Abschnitt 4. | [06](06-monetization.md) nennt beides; die Analyse stützt diese Reihenfolge |
| E13 | **Keine Helden oder Türme gegen Geld.** Der KR-Unmut zeigt, dass schon Komfortvorteile als unfair gelesen werden. Fairness offen im Store benennen (Lücke 2). | Säule 5, [06](06-monetization.md) Leitplanken (bestätigt sie) |
| E14 | **Apple Arcade als zweiter Kanal** ab Phase 4 prüfen: Apple sucht hochwertige Spiele ohne Käufe, BTD6+ ist dort. Passt zu offline, fair, iPhone. | Phase 5, neue Option |
| E15 | **Kein PvP, keine Zufallskisten**, auch wenn Rush Royale und Random Dice die größten Umsätze zeigen. Ihr Modell braucht ein Live-Team und verletzt Säule 5. | bestätigt MVP-Grenze und 06 |

### Positionierung in einem Satz

> Das Tower Defense, bei dem die Kombination gewinnt: kurze Missionen,
> handgemachter Charme, alles erspielbar, offline.

Abgrenzung: nicht „Kingdom Rush mit anderen Figuren". KR lebt von Helden und
festen Plätzen, Oddlings von Synergien und Zonen-Raster (D-005). BTD6 lebt von
Masse und Zerstörung, Oddlings von Lesbarkeit und wenigen, klaren Türmen.

## 8 Bestehende Entscheidungen im Licht des Marktes

| Entscheidung | Marktbild | Bewertung |
|---|---|---|
| D-004 Querformat | KR und BTD6 Querformat, F2P-PvP-TD Hochformat | Passt zu Markt 1 |
| D-005 Raster in Bauzonen | KR feste Plätze, BTD6 frei, Arknights Raster | Eigene Mitte, gut abgrenzbar |
| D-008 keine Upgrades im MVP | Alle Marktführer haben Upgrades | Für den MVP richtig, für Phase 2 fest einplanen (E6) |
| D-009 Wellentakt mit Abkürzung | KR-Standard | Passt; Bonus in Phase 2 (E8) |
| MVP: kein Held | KR hat Helden, BTD6 auch, beide verkaufen welche | Richtig für Fokus und Fairness; aktive Fähigkeit (E7) schließt die Lücke „nichts zu tun" |
| 06 Kosmetik zuerst | Marktführer verdienen über Einmalpreis und Inhalt | Reihenfolge prüfen (E12) |
| Säule 4: 5–12 min | Premium-TD meist länger | Eine Stärke (Lücke 3), beibehalten |

## Quellen

- Bloons TD 6, Preise und Plattformen: [Wikipedia](https://en.wikipedia.org/wiki/Bloons_TD_6), [Bloons Wiki: Netflix-Fassung](https://www.bloonswiki.com/Bloons_TD_6_NETFLIX), [App Store](https://apple.co/2pafLeo)
- Bloons TD 6, Steam-Schätzung: [raijin.gg](https://raijin.gg/app/960090/Bloons_TD_6)
- Ninja Kiwi, Kaufpreis und Studio: [Epic Games Store, Feature](https://store.epicgames.com/news/inside-bloons-the-multimillion-dollar-tower-defense-empire-built-on-monkeys?lang=it), [MTG Jahresbericht 2025](https://mb.cision.com/Main/56/4336272/4042753.pdf), [MTG Q4 2025](https://www.mtg.com/press-releases/all-time-high-revenues-and-adjusted-ebitda-underscore-strong-finish-to-the-year-with-8-organic-growth-for-q4-and-9-for-2025/)
- Kingdom Rush: [PocketGamer.biz, Interview Pablo Realini](https://www.pocketgamer.biz/ironhide-co-founder-pablo-realini-talks-kingdom-rush-5-and-premiums-place-in-2024), [appgefahren, KR5](https://www.appgefahren.de/?p=362555), [Wikipedia](https://en.wikipedia.org/wiki/Kingdom_Rush), [GameRefinery Podcast](https://www.gamerefinery.com/episode-27-what-makes-a-successful-game-franchise-with-ironhide-games/)
- Rush Royale: [My.Games](https://about.my.games/news/567), [PocketGamer.biz](https://www.pocketgamer.biz/rush-royale-surpasses-500m-in-lifetime-revenue/)
- Random Dice: [Diandian](https://www.diandian.com/en/news/K62Fr6rLzfihMzH8EAp2), [Digital Today](https://www.digitaltoday.co.kr/cn/view/92661/111percent-launches-random-dice-2-removes-gacha-system)
- Arknights: [PocketGamer.biz](https://www.pocketgamer.biz/arknights-endfield-surpasses-125m-in-six-months-on-mobile/), [Game World Observer](https://gameworldobserver.com/2023/12/21/19-mobile-games-reached-1-billion-in-revenue-in-2023)
- Marktgröße (nur Größenordnung): [SNS Insider](https://www.snsinsider.com/press-release/global-mobile-tower-defense-games-market), [Diligence Insights](https://www.dri.co.jp/auto/report/Dili/250715-mobile-tower-defense-games-market-size.html)
- Wiederkehr: [GameAnalytics Benchmarks 2025](https://investgame.net/wp-content/uploads/2025/02/2025-GameAnalytics-Mobile-Gaming-Benchmarks.pdf), [Business of Apps](https://businessofapps.com/?p=96421), [Segwise](https://segwise.ai/blog/mobile-gaming-app-user-retention-strategies)
