# Konzept: Wahl zwischen zwei Spezialisierungen, Mission 6a und 6b (P3-3)

Stand 03.11.2026 · Kennzeichnung nach [CLAUDE.md](../../CLAUDE.md#kennzeichnung)
Grundlage: D-077 (Karte S14: je Weg drei, Wahl ab M6), D-078, D-079 (S15, S16), [P3-1](p3-1-spezialisierungen-sumpfpfad.md),
[P3-2](p3-2-ruinen-spezialisierungen.md), [07 „Turm antippen, je nach Stufe“](../game-design/07-ui-ux.md#turm-antippen-je-nach-stufe),
[05 Region 1](../game-design/05-campaign-and-progression.md).

## Ziel

Ab Mission 6 bietet jede Mission je Turm **beide** Spezialisierungen an. Die
Neuheit von M6 ist die Wahl selbst: Salve oder Falkenhorst, Gewitterkrone oder
Funkensäule, Moorherz oder Fäulnis. M6a setzt den Sumpfpfad fort (Flitzer), M6b
die Ruinen (Panzerbestien); beide brauchen gemischte Antworten, damit die Wahl
eine echte ist und nicht immer dieselbe Seite gewinnt.

## Umfang

| Teil | Inhalt |
|---|---|
| Kern | Nichts Neues an den Regeln: `specializations(for:)` liefert schon alle angebotenen je Turm, `specialize` prüft gegen das Angebot (P3-1). Neu nur Tests, dass zwei angeboten werden und genau eine gewählt bleibt |
| Missionen | `mission-06a.json` (Flitzer und Panzerbestien gemischt, Flitzer vorn) und `mission-06b.json` (umgekehrt), je sechs Spezialisierungen. Werte **[HYPOTHESE]**. Wege: Vorschlag des Grafik-Threads (`art/karten/wegvorschlaege/mission-06a.json`, `-06b.json`) |
| Gewitterkrone | Ohne Sporen-Vorteil (S16, siehe unten); M5a dafür nachgestimmt |
| Kampagne | Knoten `m6a`, `m6b` bekommen ihre Missionsdateien; M7 (Boss) bleibt in Arbeit |
| Bedienung | Kreismenü auf Stufe 2 mit zwei Sternknöpfen, siehe unten |
| Labor | Bots spezialisieren je nach Bauweise mal so, mal so; Zielwerte M6a/M6b |
| Tests | Kern, Balance, App, Ende-zu-Ende |

**Nicht drin:** M7 (Boss). Gemalte Kampfplätze M6 (Grafik-Thread). Turmbilder der Stufe 3.

## Bedienung [ENTSCHIEDEN] Steffen, 03.11.2026, Karte S15 „Zwei Sterne nebeneinander“

Nach dem Entwurf in 07: **Zwei Sternknöpfe nebeneinander** an der Stelle
von „Aufwerten“, je mit Anfangsbuchstabe und Preis. Erstes Tippen auf einen Stern
zeigt in der Tafel Name, Satz und „Endgültig: <die andere> fällt weg“, der Kreis zeigt
schon die neue Reichweite. Zweites Tippen auf **denselben** Stern kauft. Tippen auf den
anderen Stern schaltet die Vorschau um, ohne zu kaufen. Der Bogen hat dann vier Knöpfe
(zwei Sterne, Zielwahl, Verkaufen); `HudLayout` legt bis zu vier schon heute (Bauen
mit Bank).

Andere Wege, die auf der Karte zur Wahl standen:
- Ein Stern öffnet einen zweiten Bogen mit beiden. Ein Tippen mehr, dafür bleibt der
  erste Bogen klein.
- Eine Tafel mit zwei Karten. Verdeckt die Karte, während die Mission weiterläuft (D-019),
  deshalb in 07 schon verworfen.

## Architektur

- `BattleController.selection` merkt sich neben `upgradeArmed` **welche**
  Spezialisierung vorgemerkt ist (`choice: Specialization?`). Neu
  `specializations(for:)` (Liste in der Reihenfolge des Codes, Regel 6);
  `specialization(for:)` bleibt als die erste davon, damit M5a/M5b unverändert
  laufen. `specialize(_:)` merkt beim ersten Tippen vor und kauft beim zweiten auf
  denselben Stern; `upgrade()` tut bei zwei zur Wahl nichts. Der Preis kommt aus
  `cost(of:)` (`specializations[...]`), die Vorschau aus `armedSpecialization`.
- `RingMenu`: je angebotene Spezialisierung ein `UpgradeRingButton` mit eigener
  Kennung (`specialize.<name>`); bei genau einer bleibt die Kennung `specialize`,
  damit M5a/M5b und ihre Tests unverändert bleiben.
- Darstellung ändert keinen Zustand: Gekauft wird über den Befehl `specialize`.

## Sicherheit

Missionsdateien im Bündel, beim Laden geprüft (Angebot nur passende Türme, Werte).
Gesicherte Missionen prüfen die Spezialisierung gegen das Angebot der Mission. Kein
Netz, keine Fremdbibliothek.

## Testplan

| Ebene | Test |
|---|---|
| Kern | `MissionSixTests` (je für 6a und 6b): je Turm zwei Spezialisierungen, Weg = Vorschlag, Mischungen gewinnen, Monokulturen verlieren, in M6a lohnt die Sumpf-, in M6b die Ruinen-Mischung mehr, die Krone ohne Sporen-Vorteil und keine Kombination mehr als 0,3 vor der besten Mischung (S16), Determinismus, Völker; `CampaignTests` (M6 offen, Weiter) |
| App | `SpecializationControllerTests`: zwei Sterne, Aufwerten tut nichts, Vorschau wechselt, zweites Tippen auf denselben kauft, ohne Gold Warnung; `AppFlowTests` (Start und Weiter M6) |
| E2E | M6a: Wachturm aufwerten, Stern Falkenhorst antippen, dann Salve, Salve kaufen, Tafel „Salve“, Gold stimmt |

## Risiken

- Sechs Spezialisierungen in einer Mission sind schwerer abzustimmen; die Funkensäule
  war schon in M5b knapp. Das Labor misst je Bauweise.
- Ohne gemalten Kampfplatz zeigt die Szene die schlichte Karte, bis das Bild kommt.

## Gewitterkrone ohne Sporen-Vorteil [ENTSCHEIDUNG OFFEN, Karte S16; umgesetzt nach Empfehlung]

Mit allen sechs Spezialisierungen schlug im Labor „Gewitterkronen mit Fäulnis“ jede
andere Bauweise, Abstand 0,4 bis 0,68 über der Dominanzgrenze 0,35. Ablation: Treiber
ist `keepsDamageOnSlowed` (Sprünge auf von Sporen gebremste Ziele verlieren keinen
Schaden). Preise oder eine schwächere Fäulnis halfen nicht.

Umgesetzt nach Empfehlung: Die Krone verliert diesen Vorteil überall (M5a und M6),
sie springt dafür öfter und weiter. In M5a kostet sie dafür 30 statt 45 Gold und
springt drei- statt zweimal zusätzlich (Radius ×1,5), damit sie dort die Kombination
mit Sporen weiter trägt. Das Feld `keepsDamageOnSlowed` bleibt in der Regel, nur
keine Mission nutzt es. Wählt Steffen anders, wird nachgezogen.

## Ergebnis

| Mission | Labor (Volk-Abstand Zwerge / Elfen) | Mensch gewinnt beim ersten Spielen | Beobachtung |
|---|---|---|---|
| M6a | 0,13 / 0,29 | 83 % | Sumpf-Mischung 1,13 vor Ruinen-Mischung 1,03; Gewitterkronen mit Fäulnis 1,37 |
| M6b | 0,09 / 0,12 | 50 % | Ruinen-Mischung 1,12 vor Sumpf-Mischung 1,03; „Mix mit Aufwertung“ und „Salven mit Moorherz“ verlieren |

Alle Monokulturen verlieren in beiden. Werte [HYPOTHESE] bis zum Spieltest (04).
