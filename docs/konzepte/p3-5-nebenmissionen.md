# Konzept: Nebenmissionen N1 und N2 (P3-5)

Stand 08.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: [05 Kampagne](../game-design/05-campaign-and-progression.md) (Karte: N1 ab 6,
N2 ab 15 Sternen; „Sterne öffnen Nebenmissionen, nie Hauptmissionen“; D-027),
[Marktanalyse](../game-design/market-analysis.md) Abschnitt 7, E9 („Dieselbe Karte, neue
Frage“), [R-6 Avatarrang](r-6-avatarrang.md) (Region 1 = 27 Sterne),
[R-Spielrahmen](r-spielrahmen.md) (Platzhalternamen „Nebenmission 1/2“).

**Nur Konzept.** Gebaut wird erst nach Steffens Antworten auf die Karten S21 bis S23.

## Ziel

Region 1 bekommt die beiden Nebenmissionen, die auf der Karte schon als Knoten stehen
(`region-01.json`, `kind: side`, `novelty: specialRule`). Sie geben **Wiederspielwert**:
Wer Sterne sammelt, bekommt eine neue Frage auf bekanntem Boden, keine neue Lektion.
Hauptmissionen bleiben der Weg durch die Region; niemand muss N1 oder N2 spielen.

Was sie nicht sind: kein Eisern-Modus. Der Eisern-Modus (E9) ist eine Einschränkung
**je Mission** nach dem ersten Sieg und bleibt ein eigener Kandidat. N1 und N2 sind zwei
eigene Missionen mit eigener Sonderregel, eigenen Sternen und eigenem Ort auf der Karte.

## Sonderregel [VORSCHLAG, Karte S21]

Empfehlung: **je Nebenmission eine andere Art Einschränkung, beide nur aus Daten**.

| | Sonderregel (Platzhalter) | Frage an den Spieler | Lage |
|---|---|---|---|
| **N1** ab 6 Sternen | **„Zwei Türme“**: nur Wachturm und Sporenturm baubar | Wie halte ich Flitzer ohne Gruppenschaden? Verlangsamen plus Einzelschaden, Zielwahl | früh, nach M2/M3 erreichbar |
| **N2** ab 15 Sternen | **„Leere Kasse“**: Gegner bringen kein Gold, nur Startgold und Zwergenbank | Wann lohnt die Bank, wann Aufwerten statt Neubau, wann verkaufen? | spät, nach M5 erreichbar |

Warum so:
- **E9 sagt „dieselbe Karte, neue Frage“** und nennt Turmverbote als Vorbild (KR „Eisern“,
  BTD6-Modi). Beides sind die günstigsten Modi mit dem meisten Spiel je Aufwand.
- **Beides ist reine Konfiguration.** Welche Türme eine Mission kennt, steht schon in der
  Missionsdatei (`towers`); das Gold je Gegner ebenso (`reward`). Keine neue Regel in der
  Simulation, also kein neues Risiko für Determinismus und Balance.
- **Säule 1 bleibt:** Auch mit zwei Türmen gewinnt eine Mischung, nicht ein Turm. Das
  Labor prüft es wie überall (Monokultur verliert beim ersten Spielen, D-071).
- **Zwei verschiedene Arten**, damit die zweite Nebenmission nicht wie die erste wirkt.

Andere Wege, auf der Karte zur Wahl:
- **Beide als Turmverbot** (N1 „zwei Türme“, N2 „ein Turm plus Bank“). Am wenigsten
  Arbeit, aber zweimal dieselbe Art Frage.
- **Sonderregeln mit neuem Verhalten** (z. B. Nebel, der Reichweite halbiert; Wellen ohne
  Pause; Festung mit einem Leben). Mehr Auftritt, braucht neue Regeln in der Simulation,
  neue Darstellung und eigene Tests. „Ein Leben“ macht Sterne sinnlos (alle oder keiner).

## Ort und Karte [VORSCHLAG, Karte S22]

Empfehlung: **bekannte Kampfplätze mit neuem Weg**. N1 auf dem Kampfplatz von M1, N2 auf
dem von M3, je mit einem neuen Wegverlauf aus dem Wegwerkzeug (wie D-081).

- Kein neuer gemalter Kampfplatz nötig; der Grafik-Thread kann später einen eigenen malen,
  Grafiken sind tauschbar.
- Der neue Weg macht aus „bekannt“ trotzdem eine neue Aufgabe.

Andere Wege: **genau dieselbe Karte wie M1/M3** (noch weniger Arbeit, aber Wiederholung
fühlt sich wie Strafe an) oder **zwei neue Kampfplätze** (am schönsten, bindet den
Grafik-Thread für zwei Bilder; verschiebt P3-5 um dessen Dauer).

## Belohnung [VORSCHLAG, Karte S23]

Empfehlung: **drei Sterne und Erz wie jede Mission, dazu ein Banner für den Avatar beim
ersten Sieg**.

- Sterne: N1 und N2 tragen je drei zu den 27 Sternen der Region bei (R-6 rechnet schon so).
- Erz: wie überall nach R-7b (`winOre`, `newStarOre`), keine Sonderregel.
- Banner: 05 nennt „Abzeichen, Banner, Titel“ als Belohnung für Eisern-Modi und Bosse.
  N1 und N2 wären der erste Ort dafür. Das braucht ein **kleines neues System**
  (Liste verdienter Banner im Spielstand, Anzeige beim Avatar), deshalb auf der Karte.

Andere Wege: **nur Sterne und Erz** (kein neues System, aber kein eigener Grund, die
Nebenmission zu spielen außer Sternen) oder **ein festes Ausrüstungsstück** (D-070 kennt
feste Belohnungen; aber Ausrüstung gibt Werte, und eine freiwillige Mission sollte keinen
Vorteil verteilen, den Hauptmissions-Spieler nicht bekommen).

## Umfang (nach der Empfehlung)

- `mission-n1.json`, `mission-n2.json` mit Sonderregel als Daten; `region-01.json` zeigt
  auf sie. Namen bleiben Platzhalter, bis Steffen sie nennt.
- Sonderregel sichtbar machen: vor dem Start eine Zeile auf der Missionstafel
  („Nur Wachturm und Sporenturm“), im Bauen-Kreismenü nur die erlaubten Türme.
- Banner nur, wenn S23 so entschieden wird.

**Nicht drin:** Eisern-Modus je Mission (E9), tägliche Herausforderung (E10), neue
Gegner, neue Turmarten, Ranglisten.

## Architektur

- **Daten:** Die Sonderregel ist keine eigene Regel, sondern das, was in der
  Missionsdatei steht: erlaubte Türme = Schlüssel in `towers`; „Leere Kasse“ = `reward`
  0 je Gegner. Ein beschreibendes Feld `specialRule` (Kennung, keine Zahl) sagt der App,
  welche Zeile sie anzeigt.
- **Prüfung beim Laden** (`ConfigValidation`): eine Mission braucht mindestens zwei
  Turmarten (sonst verliert jede Mischung gegen Säule 1); `reward` 0 nur, wenn
  `specialRule` es erklärt; unbekannte `specialRule` wird abgewiesen.
- **Simulation:** unverändert. Befehle `build` mit einer nicht erlaubten Turmart werden
  schon heute mit `unknownTower` abgewiesen, weil die Art in der Mission fehlt; ein
  Test sichert es für N1 ab.
- **Fortschritt:** `CampaignProgress` kennt Sterne je Knoten; Nebenmissionen öffnen über
  `stars` im Kartenknoten (vorhanden). Banner kämen als `Codable`-Liste in den
  Spielstand, beim Laden gegen bekannte Kennungen geprüft.
- **App:** Missionstafel zeigt die Sonderregel, Kreismenü bietet nur Türme aus
  `config.towers` an (der Controller liest sie schon dort; beim Bau prüfen), Karte zeigt N1/N2 gesperrt mit Sternzahl.

## Sicherheit

Kein Netz, keine neuen Fremdbibliotheken. Neue Missionsdateien und ein neues Feld im
Spielstand laufen durch dieselbe Prüfung wie alles andere; ein manipulierter Spielstand
mit unbekanntem Banner wird abgewiesen, nicht übernommen.

## Testplan

| Ebene | Tests |
|---|---|
| Kern | `SideMissionTests`: N1 kennt nur zwei Türme, `build` einer dritten Art wird abgewiesen; N2 zahlt kein Gold je Gegner; Mischung gewinnt, Monokultur verliert (D-071); Determinismus; beide Völker |
| Prüfung | `ConfigValidationTests`: eine Turmart allein, `reward` 0 ohne `specialRule`, unbekannte `specialRule` werden abgewiesen |
| Kampagne | `CampaignTests`: N1 öffnet bei 6, N2 bei 15 Sternen, nie vorher; Hauptmissionen öffnen nie über Sterne; Sternsumme 27 |
| Labor | `labor.json`: Ziele für N1/N2, Reserve je Bauweise |
| App | Missionstafel zeigt die Sonderregel; Kreismenü in N1 zeigt zwei Türme |
| E2E | Karte: N1 gesperrt, nach 6 Sternen offen, Start, Sonderregel sichtbar |

Jeder neue Test wird einmal rot gesehen.

## Risiken

- **„Leere Kasse“ kann zu eng sein:** ohne Kopfgeld entscheidet das Startgold allein. Das
  Labor muss zeigen, dass mehrere Bauweisen gewinnen; sonst Startgold anheben.
- **N1 ohne Blitz gegen Flitzer** kann sich unfair anfühlen. Abhilfe: N1-Wellen mit mehr
  Plünderern als Flitzern; das Labor prüft es.
- **Banner** wäre das erste kosmetische System; es muss klein bleiben (keine Galerie,
  kein Laden).

## Aufwand (Schätzung, nicht gemessen)

Nach Empfehlung: etwa wie eine Hauptmission ohne neue Regel (M3/M4), zwei Missionen
Abstimmung im Labor, kleine App-Arbeit. Mit Banner etwas mehr. Version 0.29.0.
