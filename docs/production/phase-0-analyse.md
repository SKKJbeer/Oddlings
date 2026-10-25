# Phase 0 – Analyse des Designstands

Stand: 25.10.2026 · Grundlage: Projektübergabe v0.1 · Verfasser: Claude Code

Diese Datei ist die Antwort auf Schritt 1 der Übergabe. Sie wird nicht laufend
gepflegt; der aktuelle Stand einer Entscheidung steht immer im jeweiligen
Fachdokument und im [Entscheidungsprotokoll](../decisions/decision-log.md).

Kennzeichnung in allen Dokumenten:

| Marke | Bedeutung |
|---|---|
| **[ENTSCHIEDEN]** | Von Steffen bestätigt (Übergabe oder spätere Freigabe) |
| **[HYPOTHESE]** | Richtung steht, muss sich im Prototyp oder Spieltest bewähren |
| **[VORSCHLAG]** | Von Claude vorgeschlagen, wartet auf Freigabe |
| **[OFFEN]** | Noch nicht entschieden |

## 1. Was entschieden ist

- Natives iOS-Spiel für iPhone, Fantasy-Tower-Defense, Einzelspieler offline zuerst.
- Gegner laufen im MVP auf festen Wegen; Türme blockieren keine Wege.
- Türme stehen auf erlaubten Bauflächen.
- MVP-Türme: Wachturm (Einzelziel), Blitzturm (Kette), Sporenturm (Verlangsamung).
  Zwergenbank erst, wenn der Grundloop trägt.
- MVP-Gegner: mindestens Plünderer und Flitzer. Panzerbestie, Schattenflieger, Bosse später.
- Eine Missionswährung im Einzelspieler: Gold.
- Turmsynergien sind Kernprinzip, nicht Beiwerk.
- Völker verändern den Stil, sind aber keine Pflicht; Startvölker Zwerge und Elfen (nicht im MVP).
- Avatar ohne Kampffunktion; kein steuerbarer Held im MVP.
- Kampagne als verzweigte Knotenkarte, keine offene Welt.
- Multiplayer und PvP nicht im ersten Prototyp. Die Architektur soll sie nicht verbauen.
- Free-to-play mit fairer, vor allem kosmetischer Monetarisierung; ausdrücklich kein
  Pay-to-win, keine Energie-Sperren, keine Lootboxen, keine aufdringliche Werbung.
  Monetarisierung erst nach Validierung.
- Trennung von Simulation und Darstellung, datengetriebene Balance, reproduzierbare
  Simulation, Testbarkeit, offline-first.

## 2. Was nur Hypothese ist

| Hypothese | Wie sie geprüft wird |
|---|---|
| Missionsdauer 5–12 Minuten | Messung im Prototyp und Spieltest (Mission 1 rechnet aktuell ~5 Min.) |
| Swift + SwiftUI + SpriteKit ist der richtige Stack | Technischer Spike (Backlog WP-01) |
| 2.5D-Optik ohne 3D-Engine wirkt hochwertig genug | Grafikprobe vor Phase 2 |
| Zwergenbank erzeugt eine echte Entscheidung statt Schneeball | Wirtschaftssimulation + Spieltest in Phase 2 |
| Koop-Ressourcen: persönliches Gold + Teamressource | Erst vor einer Koop-Phase |
| Völker spielen sich spürbar unterschiedlich | Phase 3 |
| Kosmetik-F2P trägt das Projekt wirtschaftlich | Phase 5, siehe Risiko P4 |

## 3. Offene Fragen – was wirklich blockiert

Nur vier Fragen blockieren den nächsten Schritt (Phase 1). Alles andere kann warten.

| # | Frage | Warum blockierend | Vorschlag |
|---|---|---|---|
| B1 | Querformat oder Hochformat? | Bestimmt Kartenzuschnitt, HUD, Bedienung, alle Testmaße | Querformat ([D-004](../decisions/decision-log.md)) |
| B2 | „Frei platzierbar" wörtlich oder im Raster? | Bestimmt Kollisionsregeln, Eingabe, Datenmodell | Raster innerhalb von Bauzonen ([D-005](../decisions/decision-log.md)) |
| B3 | Minimale iOS-Version | Bestimmt verfügbare SwiftUI-APIs | iOS 17 ([D-006](../decisions/decision-log.md)) |
| B4 | Upgrades und Verkaufen im MVP? | Bestimmt Umfang von Phase 1 | Verkaufen ja, Upgrades nein ([D-008](../decisions/decision-log.md)) |

Nicht blockierend für Phase 1, aber vor Phase 2 zu klären: Grafikstil und
Asset-Weg, Speicherstand mitten in der Mission, Name.

## 4. Risiken

### Produktqualität

| # | Risiko | Einschätzung | Gegenmaßnahme |
|---|---|---|---|
| P1 | **Der Sporenturm wird nicht verstanden oder nicht gebaut.** Unterstützende Türme wirken auf Spieler schwach, weil ihr Beitrag unsichtbar ist. In der ersten Rechnung mit naheliegenden Werten war er tatsächlich nutzlos (siehe [04](../game-design/04-economy-and-balance.md)). | hoch | Verlangsamung deutlich sichtbar machen (Einfärbung, Spur), Synergie in Mission 1 durch Wellenaufbau provozieren, im Spieltest gezielt beobachten |
| P2 | **Bedienung auf dem iPhone.** Finger verdeckt Bauplatz und Reichweite; kleine Ziele, Fehltipps im Gefecht. | hoch | Antippen statt Ziehen, Baumenü am Platz, Reichweitenvorschau vor dem Kauf, Raster (B2) |
| P3 | **Grafik, Animation und Ton sind der eigentliche Engpass.** Ein Solo-Projekt scheitert bei TD selten am Code, oft an Asset-Menge und -Qualität. | hoch | Phase 1 bewusst mit Platzhaltern; Stil und Asset-Weg vor Phase 2 entscheiden (in Fortress gibt es mit dem Skill `spielgrafik` bereits einen erprobten Weg für KI-gestützte Grafik) |
| P4 | **Kosmetik-F2P braucht Reichweite.** Rein kosmetische Einnahmen tragen nur bei sehr vielen Spielern. Ein kleines, gutes Einzelspieler-Spiel verdient damit wenig. | mittel | Kein Code dafür jetzt; in Phase 5 auch „kostenlos anspielen, Vollversion einmalig kaufen" prüfen |
| P5 | **Lesbarkeit bei vielen Gegnern** auf 6 Zoll: Kettenblitze, Verlangsamung, Treffer müssen auf einen Blick lesbar sein. | mittel | Gegnerzahlen gedeckelt halten, klare Farbsprache je Effekt |
| P6 | **Missionen von 5–12 Min. vertragen keine Unterbrechung.** iOS beendet Apps im Hintergrund. | mittel | Simulationszustand ist serialisierbar angelegt; Fortsetzen in Phase 2 |

### Technik

| # | Risiko | Einschätzung | Gegenmaßnahme |
|---|---|---|---|
| T1 | **Determinismus geht still verloren.** Swifts `Dictionary`/`Set` haben je Prozess eine andere Reihenfolge; wer darüber iteriert, bekommt unterschiedliche Ergebnisse. Ebenso Fließkomma-Pfade, `Date()` und unkontrollierter Zufall. | hoch | Entitäten in Arrays mit stabiler ID-Reihenfolge, fester Takt, eigener Seed-RNG, Replay-Test mit Prüfsumme (WP-10) |
| T2 | **Spiellogik wandert in SpriteKit-Knoten.** Bequem am Anfang, später nicht testbar und nicht multiplayerfähig. | hoch | Eigenes Paket `OddlingsCore` ohne SpriteKit-Import; Darstellung liest nur Zustand und Ereignisse |
| T3 | **SwiftUI rendert das HUD in jedem Frame neu.** | mittel | HUD bekommt nur geänderte Werte, nicht den ganzen Zustand |
| T4 | **Kein Swift im Cloud-Container.** Cloud-Sitzungen können Swift nicht übersetzen und nicht testen. | mittel | CI auf macOS als Gegenprobe; Swift-Toolchain für Linux per Startskript nachinstallieren prüfen (`OddlingsCore` braucht nur Foundation) |
| T5 | **Spätere Multiplayer-Architektur falsch vorweggenommen.** | niedrig, wenn befolgt | Nur zwei Dinge jetzt: Eingaben als Befehle, Zustand als Wert. Kein Netzcode |
| T6 | **Zwei Balancing-Quellen** (Python-Prüfskript und Swift-Kern) laufen auseinander. | mittel | Beide lesen dieselbe JSON-Datei; sobald der Swift-Kern rechnet, ersetzen Swift-Balancetests das Skript (WP-10) |

### Produktion

| # | Risiko | Gegenmaßnahme |
|---|---|---|
| R1 | Umfang wächst schleichend (Völker, Koop, Kampagne vor dem Spaßnachweis) | Scope-Verbot in [CLAUDE.md](../../CLAUDE.md), Backlog mit Phasengrenze |
| R2 | Werte werden nach Gefühl verteilt | Eine Konfigurationsdatei, Prüfskript, später Balancetests |
| R3 | Spieltests mit Fremden finden zu spät statt | Phase 1 endet mit einer Spieltest-Runde (WP-15), nicht mit „Code fertig" |
