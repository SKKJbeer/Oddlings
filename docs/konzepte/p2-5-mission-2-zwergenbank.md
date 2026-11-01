# Konzept: Mission 2 mit Zwergenbank (P2-5)

Stand 01.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-026 (Zwergenbank für alle, Regeln in
[04](../game-design/04-economy-and-balance.md#zwergenbank-phase-2)), D-027
(Region 1 mit 7 + 2 Missionen, M2 lehrt „Ernten oder verteidigen“,
[05](../game-design/05-campaign-and-progression.md#region-1-flüsterwald-kostenlos)),
D-009/E8 (Bonus für frühes Rufen), D-080 (Mission 2 jetzt, Spieltest parallel).
Bedienung nach [07](../game-design/07-ui-ux.md#zwergenbank).

## Ziel

Nach Mission 1 geht es auf der Kampagnenkarte weiter. Mission 2 bringt genau eine
neue Entscheidung: **jetzt verteidigen oder später ernten.** Die Zwergenbank kostet
Gold, das in den ersten Wellen fehlt, und zahlt es mit Gewinn zurück, wenn man
die Zeit übersteht. Dazu kommt der Bonus für frühes Rufen: Wer sich stark fühlt,
ruft die nächste Welle früher und bekommt ein paar Münzen dafür.

Mit drei Sternen in M1 und M2 erreicht der Avatar Rang II (6 Sterne, `rankStars`)
und bekommt seine erste Talentwahl. Das kommt ohne eigene Arbeit aus der Kampagne.

## Umfang

| Teil | Inhalt |
|---|---|
| Regel Bank | Neuer Turm `bank`: kein Kampf, Ertrag nach Verzögerung, Deckel, Höchstzahl, Ereignisse `bankPaid`, `bankEmptied` |
| Regel frühes Rufen | `callNextWave` schreibt Gold für die eingesparten Sekunden gut, Ereignis `earlyCallBonus` |
| Mission 2 | `mission-02.json`: eigener Weg, 10 Wellen, Bank und Bonus, Sterngrenzen wie M1. Alle Werte **[HYPOTHESE]** bis nach WP-15 |
| Kampagne | Knoten M2 bekommt seine Missionsdatei und ist nach M1 spielbar |
| Bedienung | vierter Knopf im Kreismenü, Warnsatz in der Infotafel, Füllbalken und „+5“ an der Bank (keine Münzen, die gehören den Kills), „leer“, Goldschild am Welle-Knopf |
| Grafik | Bank `tower_bank` und `ui_tower_bank` aus der freigestellten Vorlage der Grafik 02 in Atlas und Symbolkatalog. Der gemalte Kampfplatz `map_mission02_ground` kommt aus dem Thread „Kampfplätze für Mission 2 bis 4 malen“ in einem eigenen PR; bis dahin zeigt M2 den gezeichneten Ersatzboden |
| Tests | Regeln im Paket, Darstellung in `AppTests`, Ende-zu-Ende: M2 von der Karte starten, Bank bauen, Auszahlung sehen, früh rufen |

**Nicht drin:** Aufwertungen und Zielwahl (P2-6, Mission 3), Panzerbestie und
Fähigkeit nach M4 verschieben, ein Volksbonus an der Bank (03 nennt ihn als
„vielleicht später“), Fortsetzen einer laufenden Mission (P2-2). Mission 1 bleibt
**unverändert**: Sie ist die Mission des Spieltests WP-15, und eine neue Regel
dort mischt die Ergebnisse. Ob Bank und frühes Rufen nach dem Spieltest auch in
M1 kommen, entscheidet die Auswertung.

## Regel Zwergenbank

Aus 04, dort entschieden. Die Missionsdatei trägt die Werte in einem eigenen
Abschnitt `bank`; fehlt er, gibt es in der Mission keine Bank (Mission 1).

| Wert | Bedeutung | Erster Wert **[HYPOTHESE]** |
|---|---|---|
| `cost` | Baupreis | 100 |
| `delay` | Sekunden ab Bau bis zum Beginn des Ertrags | 20 |
| `interval` | Sekunden zwischen zwei Auszahlungen | 4 |
| `payout` | Gold je Auszahlung | 5 |
| `cap` | Gold, das eine Bank insgesamt auszahlt | 300 |
| `limit` | Höchstzahl je Mission | 2 |

- Die erste Auszahlung kommt nach `delay + interval`, dann alle `interval`
  Sekunden. Damit stimmt die Rechnung aus 04: 20 s + 20 × 4 s ≈ 100 s bis die
  Bank ihr Geld zurück hat.
- Die letzte Auszahlung wird auf den Rest gekürzt, nie über den Deckel. Danach
  meldet die Simulation `bankEmptied`, die Bank steht leer und tut nichts mehr.
- Verkaufen erstattet `sellRefundRate` der Baukosten wie bei jedem Turm,
  unabhängig vom Ertrag.
- Kein Zins, kein Wachstum, keine Aufwertung (04).
- Bau über `limit` wird abgelehnt (`limitReached`). Eine verkaufte Bank zählt
  nicht mehr mit.
- Die Bank schießt nicht und hat keine Reichweite. Sie belegt eine Zelle wie
  jeder Turm.

## Regel frühes Rufen

**[HYPOTHESE]** `mission.earlyCallBonus` = Gold je eingesparter Sekunde, erster
Wert 0,5. Beim Befehl `callNextWave` zählt die Zeit bis zum geplanten Start
(`nextWaveTick − tick`), mal dem Wert, abgerundet auf ganze Münzen. Bei 15 s
Wellentakt sind das höchstens 7 Gold, ein Siebtel eines Wachturms: spürbar, aber
Abwarten ist nie ein Fehler (04). Das Gold kommt im selben Tick, Ereignis
`earlyCallBonus(gold:)`. Fehlt der Wert, gibt es keinen Bonus (Mission 1).

## Mission 2 „Zwergenbank“

- **Karte:** 16 × 9 Felder wie M1, damit Bildschirmaufteilung, Rand und
  Werkzeuge gleich bleiben. Der Weg kommt links in der Mitte aus der Höhle, zieht
  einen großen Bogen nach oben, quer nach unten und wieder hoch zur Festung
  rechts. Zwischen den Schleifen liegen zwei große Taschen weit weg vom Weg:
  dorthin passt eine Bank, ohne Verteidigungsplatz zu nehmen. Das ist Absicht,
  die Entscheidung soll ums Gold gehen, nicht um den Platz.
- **Wellen:** 10, Plünderer und Flitzer wie in M1, die Menge wächst stärker als
  in M1, weil die Bank Gold dazubringt. Welle 7 und 9 haben je eine Panzerbestie
  als Spitze (die Werte stehen schon in der Datei), damit sich Ernten gegen Ende
  auszahlen muss. **[VORSCHLAG]**
- **Startgold 180, erste Welle nach 25 s:** Wer sofort eine Bank baut, hat noch
  80 Gold, gerade einen Turm. Das ist der „ungeschützte Moment“ aus 04.
- **Fähigkeit:** wie M1 aus dem Volk des Avatars.
- **Zielgröße Balance** (Kennzahl aus 04): Die beste Bauweise mit Bank liegt
  höchstens 0,05 Reserve über oder unter der besten ohne Bank. `BalanceTests`
  rechnet das für M2, Ergebnis in 04.

## Architektur

```
Kreismenü ─▶ Controller.choose(.bank) ─▶ enqueue(.build(.bank, cell))
          ─▶ Simulation.step: apply(build) prüft limit, Gold, Zelle
                              payBanks() nach collectKills: bankPaid / bankEmptied
Welle-Knopf ─▶ enqueue(.callNextWave) ─▶ apply: Gold gutschreiben, earlyCallBonus
Szene ◀── Ereignisse („+5“, Leer-Zustand)    HUD ◀── Controller-Kopien
```

- **Eigener Abschnitt statt `TowerConfig`:** `BalanceConfig.bank: BankConfig?`.
  `TowerConfig` beschreibt Kampftürme (Reichweite, Schaden, Takt); eine Bank hat
  nichts davon. Die Anmerkung in [data-models.md](../technical/data-models.md)
  sah den Umbau für den vierten Rollentyp vor; so bleibt jeder Typ ohne Felder,
  die für ihn nichts bedeuten. **[gilt]**, D-083 im Entscheidungsprotokoll.
- `TowerKind.bank` kommt dazu, damit Bau, Verkauf, Befehl und Spielstand
  dieselben Wege nehmen wie jeder Turm. `TowerKind.combat` nennt die drei
  Kampftürme; Prüfung und Feuern laufen nur über sie. Welche Türme eine Mission
  anbietet, sagt `BalanceConfig.buildable` (Kampftürme, dazu die Bank, wenn es
  den Abschnitt gibt), der Preis kommt aus `BalanceConfig.cost(of:)`. Die App
  fragt nur diese beiden, nie die Tabellen direkt.
- **Zustand:** `Tower` bekommt `builtTick` und `paid` (beide mit Vorgabe, alte
  Zustände bleiben lesbar). Ertrag ist eine reine Funktion von Tick und Bau-Tick;
  Zufall und Uhr bleiben draußen (Regeln 4 bis 6).
- **Reihenfolge im Tick:** Befehle → Fähigkeit → Wellen → Türme feuern → Tote
  auswerten → **Banken zahlen** → Bewegung → Durchbrüche → Ende. Banken nach den
  Toten, damit eine Auszahlung im selben Tick wie ein Abschuss eindeutig
  danach gebucht ist.
- **Völker:** `costFactor` wirkt auch auf `bank`, falls ein Volk ihn dort setzt.
  Heute setzt keins einen.
- **Kampagne:** `region-01.json`, Knoten `m2` bekommt `"mission": "mission-02"`.
  Die Regeln der Karte (offen nach M1) gibt es seit R-2.
- **Bodenbild je Mission:** `BattleSprites.groundName` leitet den Namen schon aus
  der Missionskennung ab (`map_mission02_ground`). Das Hauptmenü zeigt weiter M1.

## Bedienung

Nach [07](../game-design/07-ui-ux.md#zwergenbank), dort steht sie schon fest:

- Vierter Knopf im Bogen, nur in Missionen mit Bank. Infotafel: Name, Rolle
  („Zahlt nach 20 s Gold“), Ertrag und Deckel, darunter in Orange „Die 100 Gold
  fehlen dir in den nächsten Wellen.“ Zahlen aus der Datei.
- Höchstzahl erreicht: Knopf gedimmt, Schild „2/2“ statt Preis, Tippen gibt die
  Gold-Rückmeldung nicht, sondern sagt „Höchstens 2 Banken“.
- An der Bank: Füllbalken für den ausgezahlten Anteil, „+5“ steigt auf, Münzen
  fliegen zum Goldzähler. Leer: Bank grau, Schild „leer“, Infotafel „Leer.
  Verkaufen gibt den Platz frei.“
- Welle-Knopf: kleines Goldschild mit dem Bonus, den Rufen jetzt brächte, nur in
  Missionen mit Bonus und nur, wenn er größer als 0 ist. Beim Rufen erscheint
  „+N“ am Goldzähler.

## Sicherheit

Die neue Datei läuft durch dieselbe Prüfung wie M1, bevor sie die Simulation
erreicht: `BankConfig` braucht positive Werte und `delay ≥ 0`, `earlyCallBonus`
darf nicht negativ sein, Strategien für die Balancetests dürfen `bank` nur
nennen, wenn es den Abschnitt gibt. Die Kampagne prüft beim Laden, dass jede
genannte Missionsdatei gültig ist (seit R-2). Kein Netz, keine neue Bibliothek.

## Testplan

| Ebene | Was |
|---|---|
| Paket | `BankTests`: Bau, Ablehnung über `limit` und bei zu wenig Gold, erste Auszahlung genau nach `delay + interval`, Deckel mit gekürzter letzter Auszahlung, `bankEmptied` einmal, Verkauf erstattet nach Baukosten, Bank schießt nicht, Mission ohne Abschnitt lehnt `bank` ab. `EarlyCallTests`: Bonus abgerundet, kein Bonus ohne Wert, kein Bonus ohne ausstehende Welle. `ConfigValidation` für die neuen Felder. `CampaignTests`: M2 nach M1 offen, Datei gültig. Determinismus und `BalanceTests` für M2 |
| App | `BankControllerTests`: Bank im Angebot nur mit Abschnitt, Höchstzahl dimmt und sendet nichts, Bonus wie die Simulation, Füllbalken folgt `paid`, leer wird grau, Szene zählt Auszahlungen ohne Münzen. `BattleSpritesTests`/`UIArtTests`: Bild für `tower_bank`. `HudLayoutTests`: vier Knöpfe auf jeder Zelle von M2 |
| Ende-zu-Ende | `BankE2ETests`: M2 über `--play` mit `--e2e-knoten m2` starten, Bank bauen (Warnsatz, Preis), früh rufen bringt Gold, an der Höchstzahl nennt der Knopf sie und baut nichts. `CampaignE2ETests`: nach dem Sieg in M1 ist M2 offen und startbar |
| Grafik | `tools/art-check`: Vertrag für `tower_bank` und `ui_tower_bank`. Der Boden M2 bringt seinen Vertrag im PR des Kampfplatz-Threads mit |

Jeder neue Test wird einmal rot gesehen.

## Risiken

- **Balance ohne Spieltest:** Alle Werte sind Hypothesen. Die Balancetests halten
  die Kennzahl aus 04, das Spielgefühl klärt erst ein Mensch. Nach WP-15 werden
  M1 und M2 zusammen nachgezogen.
- **Bodenbild:** Der teure Teil, deshalb in einem eigenen Thread. Bis es da ist,
  sieht M2 schlichter aus als M1; die Regeln hängen nicht daran.
- **Vier Knöpfe im Bogen** am oberen und unteren Rand: `HudLayout.ring` kennt
  beliebige Anzahlen; `HudLayoutTests` bekommt den Fall mit vier.
