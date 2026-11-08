# Konzept: Mission 7, der Boss von Region 1 (P3-4)

Stand 03.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: [K7 „Gegner, Bosse, Rüstung“](phase-2-3.md#k7--gegner-bosse-rüstung),
[05 Region 1](../game-design/05-campaign-and-progression.md) („M7 Boss, lehrt alles
zusammen“), D-027, D-079, [Marktanalyse](../game-design/market-analysis.md) Abschnitt 3
(„Gegner mit Persönlichkeit“, „Musik wechselt mit der Lage“) und E1, E3, E11.

## Ziel

Region 1 bekommt ihr Ende. M7 ist nach M6a **oder** M6b offen (`requiresAny`) und
fragt alles ab, was die Region gelehrt hat: Flitzer und Panzerbestien gemischt, Bank,
Aufwerten, Zielwahl, die Wahl zwischen zwei Spezialisierungen und die Festungsfähigkeit.
Dazu kommt **ein** neuer Gegner, der Boss, mit **einer** neuen Frage. Er soll sich anfühlen
wie ein Auftritt, nicht wie eine Panzerbestie mit mehr Leben.

## Bossregel [VORSCHLAG, Entscheidungskarte S17; gebaut ist die Empfehlung, D-090]

Empfehlung nach K7, **„Moorkönig“** (Name Platzhalter):

1. **Phase 1:** Ein großer, langsamer Gegner mit Rüstung. Er läuft den Weg wie alle.
2. **Bei halbem Leben** bleibt er stehen und hebt einen **Schild**: Für eine feste Zeit
   nimmt er keinen Schaden und ruft in festem Takt Gruppen Flitzer (im Labor besser als Plünderer: sie verlangen Gruppenschaden), die an
   seiner Stelle auf dem Weg erscheinen. Danach fällt der Schild, er läuft weiter.
3. **Verlangsamung wirkt halb** (K7): Sporen bleiben nützlich, halten ihn aber nicht auf.
4. Läuft er durch, ist die Mission verloren (er kostet alle Leben).

Was das prüft: Während des Schilds zählt Gruppenschaden (Blitz, Salve) gegen die
Gerufenen, danach Einzelschaden durch Rüstung (Falkenhorst, Funkensäule, Fäulnis). Wer nur
eine Seite gebaut hat, verliert entweder die Plünderer oder den König. Die Wahl der
Spezialisierungen aus M6 wird zur Frage „beides zugleich“.

Andere Wege, auf der Karte zur Wahl:
- **Ein großer, zäher Gegner ohne Phasen** (Rüstung, halbe Verlangsamung, viel Leben).
  Wenig Arbeit, aber kein Auftritt; im Grunde eine dicke Panzerbestie.
- **Drei Phasen** (Schild bei zwei Dritteln und einem Drittel, in der zweiten ruft er
  Flitzer statt Plünderer). Mehr Auftritt, doppelt so viel Abstimmung und Darstellung;
  besser für den Boss von Region 2.

## Umfang

| Teil | Inhalt |
|---|---|
| Kern | Neue Gegnerart `moorKing`. `EnemyConfig` bekommt ein optionales `boss` mit Schwelle, Schildzeit, Ruftakt, gerufener Art und Zahl, und `slowScale` (Anteil der Verlangsamung, die wirkt). `Enemy` bekommt optional `shieldUntilTick` und `shieldSpent`. Ereignisse `bossShieldRaised`, `bossSummoned`, `bossShieldDropped`, `shieldAbsorbed` |
| Mission | `mission-07.json`: alle sechs Spezialisierungen wie M6, Flitzer und Panzerbestien gemischt, der Boss in der letzten Welle, davor eine Welle als Vorbote. Weg: Vorschlag des Grafik-Threads (Hufeisen um die Bosslichtung, `art/karten/wegvorschlaege/mission-07.json`). Werte [HYPOTHESE] |
| Kampagne | Knoten `m7` bekommt `mission-07`. Nach dem Sieg bleibt „Weiter“ auf M7, bis Region 2 kommt; die Karte zeigt die Region als abgeschlossen |
| Darstellung | Boss deutlich größer als die Panzerbestie, Lebensleiste oben im Bild statt über dem Kopf, Schild als Kuppel, Ruf als kurzer Effekt mit Ton; Platzhalterbild, bis der Grafik-Thread malt |
| Ton | Bosswelle mit eigener Musik (Ton-Thread, eigener Auftrag); bis dahin ein Stich beim Auftritt aus den vorhandenen Klängen |
| Labor | Bots spielen M7 wie M6; Zielwert Menschenbot beim ersten Spielen 40 % (letzte Mission, schwerer als M6) |
| Tests | Kern, Balance, App, Ende-zu-Ende |

**Nicht drin:** Region 2, Abspann oder Belohnung über Sterne hinaus (eigene Frage, wenn
Region 2 ansteht), Bestiarium (E11), Musikstück selbst, gemalter Boss und Kampfplatz
(Grafik-Thread), N1/N2.

## Architektur

- **Regel im Kern, Werte in der Datei** (Regel 1, 7). `boss` ist optional; Missionen ohne
  Boss bleiben unverändert. Die Art `moorKing` steht im Code, damit Sprite, Ton und Text
  einen festen Namen haben; was er kann, steht in der Missionsdatei.
- **Ablauf je Tick, deterministisch** (Regel 5, 6): Fällt das Leben unter die Schwelle und
  ist der Schild noch nicht verbraucht, hält der Treffer an der Schwelle an; die Simulation setzt `shieldSpent`, `shieldUntilTick` und meldet
  `bossShieldRaised`. Solange der Schild steht: Bewegung ruht, jeder Treffer zieht nichts
  ab (gemeldet als geschluckt, wie die Rüstung), und alle `summonEveryTicks` entstehen
  Gerufene mit fortlaufenden Kennungen an seiner Weglänge (`bossSummoned`). Mit
  `shieldUntilTick` fällt der Schild (`bossShieldDropped`). Kein Zufall.
- **Halbe Verlangsamung:** Ein Sporenpuls setzt beim Boss den Faktor `1 - (1 - f) * slowScale`.
  Gilt ebenso für Steinregen? [VORSCHLAG] Nein: Der Steinregen ist die Fähigkeit des
  Spielers und soll sich gegen den Boss lohnen; er betäubt nur außerhalb des Schilds.
- **Sterne und Leben:** Der Boss hat `leakDamage` gleich den Festungsleben; ein Durchbruch
  beendet die Mission sofort, wie jede Niederlage.
- **Darstellung ändert keinen Zustand** (Regel 2, 3): Lebensleiste, Kuppel, Ruf und Ton
  hängen an Zustand und Ereignissen.
- **Zielwahl „stärkster“** nimmt den Boss, wie heute die Panzerbestie (größtes Höchstleben).

## Sicherheit

`boss` wird beim Laden geprüft: Schwelle zwischen 0 und 1, Zeiten und Zahlen positiv,
gerufene Art vorhanden und selbst ohne `boss` (kein Boss ruft Bosse), `slowScale`
zwischen 0 und 1, höchstens ein Boss je Welle. Gesicherte laufende Missionen (P2-2) laden
die neuen Felder als optional; ein alter Spielstand ohne sie bleibt gültig. Kein Netz,
keine Fremdbibliothek.

## Testplan

| Ebene | Test |
|---|---|
| Kern | `BossTests`: Schild bei der Schwelle, kein Schaden und kein Laufen währenddessen, Ruf im Takt mit der richtigen Zahl, Schild fällt nach der Zeit, halbe Verlangsamung, Steinregen wirkt außerhalb des Schilds, Durchbruch verliert, Prüfung beim Laden (jeder Fehler einzeln), alter Spielstand lädt |
| Balance | `MissionSevenTests`: Weg = Vorschlag, Mischungen mit beiden Seiten gewinnen, reine Gruppen- und reine Einzelziel-Bauweise verlieren am Boss, Monokulturen verlieren, Determinismus, Völker; Labor ohne neue Verletzung |
| Kampagne | `CampaignTests`/`AppFlowTests`: M7 nach M6a oder M6b offen, Weiter bleibt danach auf M7 |
| App | Lebensleiste oben nur bei Boss, Kuppel während des Schilds, Ereignisse lösen Effekt und Ton aus |
| E2E | M7 mit gehaltenen Wellen startet, Bossleiste erscheint in der Bosswelle (schnellgespult) |

## Risiken

- Der Schild kann sich als Pause anfühlen. Gegenmittel: kurz halten und die Gerufenen
  geben etwas zu tun; der Spieltest entscheidet die Länge.
- Ein Boss, der alle Leben kostet, macht die Mission hart. Darum der niedrigere Zielwert
  und eine Vorbotenwelle, die zeigt, ob die Verteidigung trägt.
- Ohne gemalten Boss wirkt der Auftritt schwächer. Bis der Grafik-Thread liefert, eine
  vergrößerte Panzerbestie in eigener Farbe.

## Ergebnis (0.28.0)

Gebaut wie oben. Abweichungen und Werte:

- Ein schwerer Treffer zieht nur bis zur Schwelle ab; der Schild steigt im selben Tick
  (`runBosses` nach den Türmen). Sonst sprang ein großer Treffer über die Hälfte hinweg.
- Mit dem Schild endet eine laufende Verlangsamung; nach dem Schild gilt wieder die halbe.
- Gerufen werden acht Flitzer alle 1,5 s für 10 s, mit vollem Leben (`summonHPScale` 1).
  Werte und Abstimmung: [04](../game-design/04-economy-and-balance.md#mission-7--der-moorkönig-ergebnis-der-prüfung-0280-hypothese).
- Darstellung: Leiste oben (`BossBar`, Kennung `hud.boss`), Kuppel an der Figur,
  Banner bei Auftritt und Schild, Dunst beim Ruf, Klänge aus dem Vorhandenen tiefer
  (`AudioStyle.bossSemitones`), Stoß schwer beim Schild. Bild: die Panzerbestie, groß
  und umgefärbt (`BattleSprites.standIn`), bis der Grafik-Thread den Moorkönig malt.
- Labor: Menschenbot 42 % (Ziel 40 %), keine neue Verletzung. `--e2e-bosswelle` lässt
  im Oberflächentest nur die letzte Welle laufen.
