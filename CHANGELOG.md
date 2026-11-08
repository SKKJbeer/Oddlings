# Änderungsprotokoll

Jede Auslieferung auf `main` bekommt hier einen Eintrag, neueste oben.

- **Version** = `MARKETING_VERSION` in `project.yml`. Neue Funktion oder neues
  Arbeitspaket: zweite Stelle (0.2.0 → 0.3.0). Korrektur, Doku, Werkzeug: dritte
  Stelle (0.2.0 → 0.2.1).
- **Bau** = Laufnummer von `testflight.yml`, wird beim Archivieren als
  `CURRENT_PROJECT_VERSION` gesetzt. Ein Bau zählt erst, wenn Apple ihn als VALID
  meldet. Gescheiterte Bauten stehen mit Grund dabei, weil ihre Nummer verbraucht ist.
- Ein Eintrag, der nichts an der App ändert (nur Dokumente), hebt die Version
  nicht und löst keinen Bau aus. Dort steht „Dokumente, kein Bau“ (D-023).

## 0.28.2 – 08.11.2026 (Grafik 09: Kampfplatz Bosslichtung)

- **Gemalter Kampfplatz für Mission 7 „Der Moorkönig“**: die Lichtung im Reich des Bosses,
  im Rand hohle Sumpfbäume, Steinkreis, Geweih-Totems, Schlammbecken und eine rostige Krone
  zwischen Knochen, dazu fahles Sturmlicht. Die Lichtung selbst ist frei und hell; der Weg läuft
  als Hufeisen herum (`mission-07.json`).
- Tests: `test_weg_und_wald_liegen_richtig` deckt die Karte ab (einmal rot gesehen mit dem Weg
  von M5b), `testEveryBundledMissionHasItsPaintedGround` um `mission-07` ergänzt.
- Herkunft in `art/karten/ENTSTEHUNG.md`, Konzept
  [Grafik 09](docs/konzepte/grafik-09-bosslichtung-m7.md).

## 0.28.1 – 08.11.2026 (Grafik 08: Kampfplätze Tiefes Moor und Tempelplatz) · Bau 52

- **Gemalte Kampfplätze für Mission 6a und 6b** statt der schlichten Karte. 6a „Sumpfpfad II“
  führt tiefer ins Moor: Nacht, blaugrünes Licht, Mangroven, Trauerweiden, leuchtende Pilze.
  6b „Ruinen II“ liegt auf dem Tempelplatz: Mondlicht, Feuerschalen, türkise Kristalle,
  eingestürzte Wände und Treppen. Das Feld bleibt hell, Weg und Gegner sind so gut zu sehen wie in M5.
- Wege unverändert aus `mission-06a.json` und `mission-06b.json`.
- Tests: `test_weg_und_wald_liegen_richtig` deckt beide Karten ab (einmal rot gesehen mit
  dem Weg von M5a), `testEveryBundledMissionHasItsPaintedGround` um `mission-06a`/`-06b` ergänzt.
- Herkunft, Prompts und Seeds in `art/karten/ENTSTEHUNG.md`, Konzept
  [Grafik 08](docs/konzepte/grafik-08-kampfplaetze-m6.md).

## 0.28.0 – 03.11.2026 (P3-4: Mission 7, der Moorkönig) · Bau 51

- **Mission 7 „Der Moorkönig“** ist spielbar und schließt Region 1 ab. Offen nach
  Sumpfpfad II **oder** Ruinen II, Weg vom Grafik-Thread (Hufeisen um die Bosslichtung).
  Alle sechs Spezialisierungen stehen zur Wahl. Werte [HYPOTHESE].
- **Der Boss** (Empfehlung zu Karte S17): langsam, gepanzert, Verlangsamung wirkt nur halb.
  Bei halbem Leben bleibt er stehen und hebt einen Schild: Er nimmt keinen Schaden und
  ruft im Takt Flitzer an seiner Stelle. Danach fällt der Schild. Läuft er durch, ist die
  Mission verloren. Wer nur Gruppen- oder nur Einzelschaden baut, verliert an ihm.
- **Darstellung:** Lebensleiste des Bosses oben über der Karte mit Strich an der
  Schildschwelle, Kuppel während des Schilds, Banner beim Auftritt und beim Schild, grüner
  Dunst beim Ruf, tiefe Klänge aus dem Vorhandenen. Bis der Moorkönig gemalt ist, steht
  eine große, umgefärbte Panzerbestie für ihn.
- Kampagne: Weiter führt nach Mission 6 zum Moorkönig und bleibt nach dem Sieg dort.
- Tests: `BossTests`, `MissionSevenTests`, `CampaignTests`, `AppFlowTests`,
  `BossAppTests`, `SoundMapTests`, `FeedbackPlayerTests`, `BossE2ETests`. Labor ohne neue
  Verletzung, Menschenbot 42 % bei Ziel 40 %.

## 0.27.0 – 03.11.2026 (P3-3: Wahl zwischen zwei Spezialisierungen, Mission 6a und 6b) · Bau 50

- **Mission 6a „Sumpfpfad II“ und 6b „Ruinen II“** sind spielbar, Wege vom Grafik-Thread.
  Jeder Turm bietet hier beide Spezialisierungen: Salve oder Falkenhorst, Gewitterkrone oder
  Funkensäule, Moorherz oder Fäulnis. In 6a lohnen eher die Formen des Sumpfpfads, in 6b
  die der Ruinen. Werte [HYPOTHESE].
- **Zwei Sterne nebeneinander** (Karte S15): Erstes Tippen zeigt die Vorschau und
  „Endgültig: … fällt weg“, der andere Stern wechselt nur die Vorschau, das zweite Tippen
  auf denselben kauft.
- **Gewitterkrone ohne Sporen-Vorteil** (Empfehlung zu Karte S16): Mit ihm schlug
  Gewitterkrone plus Sporen in Mission 6 alles andere. Die Krone springt jetzt öfter und
  weiter; in Mission 5a kostet sie 30 statt 45 Gold.
- Kampagne: Weiter führt nach 5a zu 6a, nach 5b zu 6b. Die gemalten Kampfplätze für
  Mission 6 folgen (Grafik 08), bis dahin die schlichte Karte.
- Tests: `MissionSixTests` (für 6a und 6b), `CampaignTests`, `AppFlowTests`,
  `SpecializationControllerTests` (zwei Sterne), `SpecializationE2ETests` (Mission 6a).
  Labor ohne neue Verletzung, Zielwerte M6a/M6b 45 %.

## 0.26.1 – 03.11.2026 (Grafik 07: Kampfplätze Sumpfpfad und Ruinen) · Bau 49

- **Mission 5a „Sumpfpfad“ hat ihren gemalten Kampfplatz:** feuchte Moorinsel mit toten
  Bäumen, Stümpfen, Tümpeln und einer Irrlicht-Laterne im Waldrand, grünliches
  Dämmerlicht, olives Moorgras. Das Feld bleibt Gras und Weg, überall bebaubar.
- **Mission 5b „Ruinen“ ebenso:** Ruinenhof mit Torbogen, Säulen und Steinbecken, kühles
  Abendlicht, der Weg wie aus Steinplatten.
- Werkzeug: `kampfplatz.py` mit `DEKO_BREITE`, hohe Deko wird nach ihrer Höhe bemessen
  (ragte sonst über Bauzellen). Kunstprüfung: Wegvorschläge müssen spielbar sein.
- Werkzeug: Apple-Lesezugriffe bei Serverfehlern wiederholt.
- Tests: `test_wegvorschlaege_sind_spielbar`, hohe Deko in `test_deko_nur_im_rand`,
  `testEveryBundledMissionHasItsPaintedGround` mit Mission 5a und 5b.

## 0.26.0 – 03.11.2026 (P3-2: Mission 5b „Ruinen“ mit Falkenhorst, Funkensäule, Fäulnis) · Bau 48

- **Mission 5b „Ruinen“** ist spielbar, der zweite Weg nach Mission 4: Panzerbestien in
  jeder Welle, Weg durch das Becken, den der Grafik-Thread vorgeschlagen hat. Werte [HYPOTHESE].
- **Drei neue Spezialisierungen** (D-078): **Falkenhorst** (Wachturm: weiter, schwerer Schuss,
  langsamer), **Funkensäule** (Blitz: ein schwerer Schlag, springt nur einmal weiter, lädt
  langsamer), **Fäulnis** (Sporen: was der Puls verlangsamt, nimmt so lange von allen Türmen
  mehr Schaden). Die Fäulnis teilt sich den Zustand mit dem Mondmal der Elfen; beide
  zusammen addieren sich nicht.
- Kern: Feld `vulnerableFactor`, negative `extraJumps` (Kette bleibt ≥ 0), Prüfung beim Laden.
- Tests: `RuinSpecializationTests`, `MissionFiveBTests`, App-Test für das Angebot in M5b,
  E2E „Sporenturm zur Fäulnis“; Kampagne, Ablauf und Labor kennen Mission 5b.
- Offen für den Spieltest (04): Funkensäule schwer abzustimmen, Bank lohnt in den Ruinen kaum,
  Elfen passen besonders gut zur Fäulnis.

## 0.25.0 – 03.11.2026 (P3-1: Spezialisierungen und Mission 5a „Sumpfpfad“) · Bau 47

- **Stufe 3:** Ein Turm auf Stufe 2 lässt sich auf dem Sumpfpfad spezialisieren, je Turm
  eine Wahl (Steffens Karte S14 „Je Weg drei, Wahl ab M6“, D-077): **Salve** (Wachturm,
  zwei Ziele je Schuss), **Gewitterkrone** (Blitz springt öfter und weiter, gebremste Ziele
  schwächen ihn nicht), **Moorherz** (Sporen mit größerem Kreis, bremsen stärker und länger).
  Im Kreismenü steht dafür ein Stern an der Stelle von „Aufwerten“, zweimal tippen, die
  Tafel warnt „Endgültig“. Schild „III“ am Turm. Verkaufen erstattet 70 % von allem.
- **Mission 5a „Sumpfpfad“** nach Mission 4: Flitzerschwärme auf einem Mäander-Weg,
  den der Grafik-Thread für den gemalten Kampfplatz vorgeschlagen hat. Werte [HYPOTHESE].
- Kern: Befehl `specialize`, `Specialization`, Abschnitt `specializations` der
  Missionsdatei mit Prüfung beim Laden; Mitspieler und Labor spezialisieren mit.
- Tests: `SpecializationTests`, `MissionFiveATests`, `SpecializationControllerTests`,
  E2E `SpecializationE2ETests`; Kampagne, Ablauf und Labor kennen Mission 5a.
- Bau 47 ist VALID und in der Gruppe „Team“; der Lauf meldete trotzdem Rot, weil Apple
  danach beim Lesen der Gruppen einmal mit HTTP 500 antwortete. Die Wiederholung dafür in
  `scripts/apple.py` kommt mit der nächsten App-Änderung, weil sie sonst einen eigenen Bau auslöst.

## 0.24.1 – 03.11.2026 (Korrektur: 0.24.0 im Release-Bau) · Bau 46

- **0.24.0 ließ sich für TestFlight nicht übersetzen** (Bau 45 gescheitert): Die Prüfung
  „Mission 1 zeigt den Einstieg“ stand versehentlich im Teil, den es nur im Testbau gibt.
  Sie gilt jetzt in jedem Bau; das Verhalten ist unverändert.
- CI: neuer Schritt „App als Release übersetzen“, damit so etwas schon im PR auffällt.

## 0.24.0 – 03.11.2026 (P2-8: Synergie sichtbar, Einstieg ohne Erklärtext) · Bau 45 gescheitert (Release übersetzte nicht, siehe 0.24.1)

- **Sporenfunke sichtbar:** Trifft der Blitz einen verlangsamten Gegner, leuchtet das
  Kettenglied grün-türkis und dicker, am Ziel platzen Sporenwölkchen mit Ring und
  Lichtpunkt. Beim ersten Funken jeder Mission springt „Sporenfunke!“ auf, beim
  allerersten einmal mit dem Satz „Gebremst rücken sie zusammen – der Blitz trifft mehr.“
- **Verlangsamt lesbar:** grüner Sporenschimmer unter jedem gebremsten Gegner.
- **Einstieg ohne Erklärtext** (Steffens Wahl auf Karte S13: „nur wenn man zögert“, D-076):
  In Mission 1 zeigt eine Hand auf eine gute Bauzelle, wenn 6 s lang kein Turm steht,
  danach ein Pfeil auf „Nächste Welle“, wenn der Knopf 5 s unberührt bleibt. Jedes
  Zeichen einmal je Gerät, Tippen überspringt, nichts wird abgefangen. Wer Mission 1
  schon gewonnen hat, sieht sie nicht. Neuer Schalter „Hinweise“ in den Einstellungen.
- Kern: `MissionMap.bestCell` (vorher privat im Mitspieler), Hand und Mitspieler
  wählen Zellen auf dieselbe Art.
- Tests: `BattleGuideTests`, `BestCellTests`, neue Fälle in `FxDirectorTests` und
  `BattleSpritesTests`, E2E `GuideE2ETests`; `EffectsE2ETests` zählt Funken und Wort.

## 0.23.0 – 03.11.2026 (P2-11: Blitz allein verliert Mission 2 und 3) · Bau 44

- **Mission 2 und 3:** Flitzer laufen 2,6 statt 2,2 Felder je Sekunde, Mission 2 hat
  dazu 10 % mehr Lebenspunkte je Welle. Wer nur Blitztürme baut, verliert jetzt beim
  ersten Spielen (D-071); Mischungen gewinnen weiter, die Bank bleibt eine Wahl.
  Gebaut mit der Empfehlung der Karte S11 (D-075). Mission 2 ist dadurch spürbar
  schwerer, Mission 4 bleibt unverändert.
- Balance-Labor: die vier bekannten Befunde zu Mission 2 und 3 sind gestrichen, übrig
  bleibt Mission 1 mit Elfen.
- Tests: `BalanceTests.monocultureLosesOnEveryFirstPlay` prüft D-071 für jede Mission
  mit jedem Volk (rot mit den alten Werten).

## 0.22.0 – 03.11.2026 (P2-2: Fortsetzen nach App-Neustart) · Bau 43

- **Eine laufende Mission geht nicht mehr verloren.** Geht die App in den Hintergrund,
  wird die Mission gesichert. Beendet iOS die App danach oder startet das Telefon neu,
  öffnet die App direkt in dieser Mission, angehalten, mit „Hier warst du stehen
  geblieben.“ auf der Pausentafel. Gebaut ist die Empfehlung der Karte S12 (D-074).
- Hat ein Update die Mission geändert oder ist der Stand beschädigt, beginnt sie neu,
  mit Hinweis (D-022). „Zurück“ aus der Schlacht beendet die Mission wie bisher.
- Spielstand Schema 3 (`battle`), Migration aus Schema 2 ohne Verlust; der gesicherte
  Zustand wird vor dem Fortsetzen gegen die Mission geprüft. Grenze der Datei 512 KB.
- Ein stehendes Bollwerk wird nach einer Größenänderung und beim Fortsetzen wieder
  gezeigt.
- Tests: `SuspendedBattleTests` (Determinismus über das Speichern, Prüfregeln, Migration,
  Fingerabdruck), Fortsetzen in `AppFlowTests`, `ResumeE2ETests` in der echten App
  (Home, Beenden, neu öffnen).

## 0.21.1 – 03.11.2026 (P2-6b: Balance-Labor, Grundstock) · Bau 42

- **Werkzeug, die App spielt sich unverändert.** `oddlings-balance` lässt gierige,
  zufällige und menschenähnliche Bots alle vier Missionen beim ersten Spielen durchspielen
  und schreibt einen Bericht (Markdown, CSV). Bot-Eigenschaften und Zielwerte in
  `labor.json`, vorläufig nach D-073.
- **CI**: Stufe pr im Linux-Job, rot bei neuer Dominanz, siegreicher Monokultur,
  ungenutztem Turm oder verletzter Invariante; Bericht in der Zusammenfassung und als
  Artefakt `balance-labor`.
- **Erster Befund**: Blitz allein gewinnt Mission 2 und 3 beim ersten Spielen (gegen
  D-071), Blitz + Sporen dominiert Mission 1 bei Elfen. Stehen als bekannte Befunde mit
  Grund im Labor; Karte an Steffen, wie behoben wird.
- Tests: `LabTests` (8, jeder einmal rot gesehen); der Bot der `BalanceTests` lebt jetzt
  im Labor, keine zweite Umsetzung. `regeln-pruefen.sh` erlaubt dem Labor nur die
  eigenen Module.

## 0.21.0 – 02.11.2026 (R-7b: Schmiede mit Erz) · Bau 41

- **Erz**: Jeder Sieg gibt 4, jeder neue Stern 7 dazu, eine Niederlage nichts. Die
  Ergebnistafel nennt den Ertrag („+25 Erz“). Gebaut mit den drei Empfehlungen (D-072),
  die Karten an Steffen sind noch offen.
- **Schmiede** als dritter Reiter im Avatar-Menü: erhaltene Stücke auf Stufe II
  (20 Erz) und III (40 Erz), jede Stufe mit etwas mehr Bonus. Die Stufe gilt ab der
  nächsten Mission, Bestand und Stufen stehen im Spielstand und werden beim Laden geprüft.
- Stufe I ist etwas schwächer als die Stücke aus 0.19.0, damit Stufe III unter
  +10 % bleibt (D-069); Prozente stehen jetzt mit einer Nachkommastelle.
- Tests: `ForgeTests` und Spielstand im Kern, Balance mit Stufe III, Erz und Schmieden
  in `AppFlowTests`, Schmiede und Ergebnistafel in den E2E-Tests.

## 0.20.0 – 02.11.2026 (P2-10: Mission 4 mit gepanzerter Panzerbestie)

- **Mission 4 „Ruinenrand“** spielbar, nach dem Sieg in Mission 3 offen: U-förmiger
  Weg auf dem gemalten Kampfplatz (D-081), zehn Wellen mit Panzerbestien ab Welle 2,
  Welle 6 nur Panzerbestien. Aufwerten, Bank und Bonus wie in Mission 3.
- **Rüstung** (K7, D-087, Entscheidung S8 steht noch aus): Die Panzerbestie zieht
  in Mission 4 von jedem Turmtreffer 8 ab, ein Viertel bleibt immer. Viele kleine
  Treffer verlieren viel, der aufgewertete Wachturm wenig. Der Steinregen schlägt
  durch, das Mondmal vervielfacht, was durchkommt. Mission 1 bis 3 bleiben unverändert.
- Graues Schild an gepanzerten Gegnern, heller Funke und tieferer Trefferklang, wenn
  die Panzerung schluckt, Hinweis beim ersten gepanzerten Gegner.
- Mitspieler und Balance-Bot richten aufgewertete Wachtürme gegen Panzerung auf
  „stärkster“.
- Tests: `ArmorTests`, `MissionFourTests` im Kern, Schild, Klang und Ablauf in der
  App, `ArmorE2ETests` in der echten App.

## Dokumente, kein Bau – 02.11.2026 (Bauten 38 und 39)

- Bau 38 (0.18.0) und Bau 39 (0.19.0) von Apple als VALID gemeldet, in Roadmap und
  Stand eingetragen.
- Konzept [R-7b Schmiede](docs/konzepte/r-7b-schmiede.md) mit drei offenen Karten an
  Steffen (Karte S9 in der Roadmap).

## 0.19.0 – 02.11.2026 (R-7a: Ausrüstung aus festen Belohnungen) · Bau 39

**Neu**
- Das Avatar-Menü hat Reiter: „Talente“ und neu „Ausrüstung“. Drei Plätze (Banner für
  Türme, Amulett für die Festungsfähigkeit, Siegel für die Kasse), je zwei Stücke.
  Jedes Stück nennt seinen Bonus in Prozent; noch nicht erhaltene stehen gesperrt da
  und sagen, woher sie kommen (D-066, D-070).
- Feste Belohnungen ohne Zufall: Mission 1 gibt mit einem, zwei und drei Sternen
  Wachbanner, Beutelsiegel und Flinkes Amulett; Sturmbanner, Mondamulett und
  Schatzsiegel kommen mit 9, 15 und 21 Sternen der Region.
- Ein neues Stück wandert auf einen freien Platz, das Avatarschild meldet „Neue
  Ausrüstung“. Anlegen und Ablegen per Tippen kostet nichts und gilt ab der nächsten
  Mission.

**Regeln**
- Werte in `Balance/equipment.json`, Prüfung beim Laden (`EquipmentTable.issues`).
  Besitz wird nicht gespeichert, sondern aus den besten Sternen abgeleitet; der
  Spielstand hält nur die Belegung und verwirft kaputte Kennungen einzeln.
- Volle Ausrüstung hebt die Reserve gemessen um 3 bis 9 %, höchstens erlaubt sind
  10 % (D-069). Beim ersten Spielen verliert jede Monokultur außer Wachtürmen (D-071).

**Tests**
- Kern: Besitz, Belegung, Boni nur auf ihre Felder, Prüfung der Tabelle, Laden,
  Amulette halten jede Fähigkeit gültig, Obergrenze je Volk und Talentwahl,
  Monokultur beim ersten Spielen (alle rot gesehen).
- App: Belohnung, Anlegen, Ablegen, Neustart, Texte. E2E: Reiter „Ausrüstung“,
  Anlegen und Ablegen, Belegung übersteht den Neustart, nichts überlappt.

## 0.18.0 – 02.11.2026 (P2-6: Mission 3 mit Aufwertungen) · Bau 38

- **Mission 3 „Pilzhain“** spielbar, nach dem Sieg in Mission 2 auf der Kampagnenkarte
  offen: Weg mit Haarnadel auf dem gemalten Kampfplatz (D-081), zehn Wellen etwas
  härter als in Mission 2, Welle 6 mit zwei Panzerbestien. Zwergenbank und Bonus fürs
  frühe Rufen wie in Mission 2.
- **Aufwerten auf Stufe 2**: Turm antippen, Aufwerten zweimal tippen. Die Tafel sagt,
  was Stufe 2 bringt, der Kreis zeigt schon die neue Reichweite. Wach- und Blitzturm
  treffen härter, der Sporenturm verlangsamt stärker in größerem Kreis. Eigenes Bild
  für jeden Turm der Stufe 2, Schild „II“, Klang und Stoß beim Aufwerten.
- **Zielwahl** ab Stufe 2 für Wach- und Blitzturm: Erster, Letzter, Stärkster, ein
  Tippen schaltet weiter, kostet nichts. Der Blitz beginnt seine Kette am gewählten Ziel.
- Stufe 2 steht als Faktoren in der Missionsdatei (D-084), damit Volk und Ausrüstung
  in beiden Stufen wirken. Mission 1 und 2 bleiben unverändert.
- Tests: Aufwerten, Zielwahl und Mission 3 im Kern, `UpgradeControllerTests` und
  Kreismenü auf jeder Zelle von Mission 3 in der App, `UpgradeE2ETests` mit echtem Tippen.

## Dokumente, kein Bau – 02.11.2026 (Mission 3 nach R-7a, D-085)

- Steffen hat Karte S7 entschieden: nach der Ausrüstung kommt Mission 3 mit
  Aufwertungen (D-085). Karte aus Roadmap und Stand gestrichen.

## Dokumente, kein Bau – 02.11.2026 (Karte S7: was nach R-7a kommt)

- Neue Entscheidungskarte für Steffen in Roadmap und Stand eingetragen (D-067).

## Dokumente, kein Bau – 01.11.2026 (Bau 37)

- Bau 37 (0.16.1) von Apple als VALID gemeldet, in Roadmap und Stand eingetragen.

## 0.16.1 – 01.11.2026 (Grafik 06: Kampfplätze für Mission 2 bis 4) · Bau 37

- **Mission 2 hat ihren gemalten Kampfplatz**: eine Lichtung am alten Zwergenstollen,
  Morgenlicht, Lore, Holzstapel und Erz im Waldrand. Statt der gezeichneten Weglinie
  liegt der Weg jetzt gemalt im Gras, wie in Mission 1.
- **Kampfplätze für Mission 3 (Pilzhain) und Mission 4 (Ruinenrand)** liegen schon im
  Katalog, auf den Wegen aus dem Vorschlag (D-081). Sie erscheinen, sobald die
  Missionen gebaut sind.
- Höhle der Goblins in jeder Mission dieselbe wie auf der Kampagnenkarte; Deko nur im
  Wald, nie auf einem Bauplatz.
- Werkzeug: `kampfplatz.py` mit Deko und Lichtton je Mission, `ebene.py` legt Höhle und
  Deko nach dem Übermalen wieder auf, `ausgleichen.py` gleicht Flecken im Gras aus.
  Kunstprüfung für jeden Kampfplatz, App-Test für den Boden jeder Mission.

## Dokumente, kein Bau – 01.11.2026 (Bauten 34 und 35)

- Bau 34 (0.13.0) und Bau 35 (0.15.0) von Apple als VALID gemeldet, in Roadmap
  und Stand eingetragen.

## 0.16.0 – 01.11.2026 (P2-5: Mission 2 mit Zwergenbank) · Bau 36

- **Mission 2** spielbar, nach dem Sieg in Mission 1 auf der Kampagnenkarte offen:
  eigener Weg mit ruhigen Feldern für Banken, zehn Wellen, etwas härter als
  Mission 1. Alle Werte [HYPOTHESE] bis zum Spieltest (D-080).
- **Zwergenbank** als vierter Knopf im Kreismenü, nur in Missionen mit Bank: zahlt
  ab 20 s nach dem Bau alle 4 s 5 Gold, bis 300; höchstens zwei. Infotafel nennt
  Ertrag und in Orange den Preis des Wartens; Füllbalken an der Bank, „+5“ bei
  jeder Auszahlung, leer wird sie grau. An der Höchstzahl zeigt der Knopf „2/2“.
- **Bonus fürs frühe Rufen** (D-009): Der Welle-Knopf trägt das Gold, das Rufen
  jetzt bringt (0,5 je eingesparter Sekunde); beim Rufen steigt es an der
  Goldanzeige auf. Mission 1 bleibt ohne Bonus und ohne Bank.
- Kern: `BankConfig` als eigener Abschnitt (D-083), `TowerKind.bank` und
  `.combat`, Ereignisse `bankPaid`, `bankEmptied`, `earlyCallBonus`, Ablehnung
  `limitReached`, Prüfung der neuen Felder; alte Spielstände lesen sich weiter.
- Tests: `BankTests`, `EarlyCallTests`, `MissionTwoTests` (Balance in
  [04](docs/game-design/04-economy-and-balance.md#mission-2--ergebnis-der-prüfung-0160-hypothese)),
  `BankControllerTests`, vier Knöpfe in `HudLayoutTests`, `BankE2ETests`;
  `CampaignE2ETests` startet jetzt Mission 2. Testschalter `--e2e-knoten`.
- Ton (mit 0.15.0 zusammengeführt): Auszahlung der Bank und Bonus fürs frühe Rufen
  klingen als leise Münze, die leere Bank bleibt stumm (`SoundMapTests`).
- `scripts/swift-linux.sh`: `/etc/os-release` überschrieb die Swift-Version.

## 0.15.0 – 01.11.2026 (P2-3: Ton und Musik), Bau 35

**Neu**
- Klänge an den Spielereignissen: Bauen, Verkaufen, Schüsse je Turm (der Blitz
  steigt mit jedem Sprung um einen Halbton), Treffer, Verlangsamung, Kombination,
  Gegnersturz mit Münze, Durchbruch, Wellengong, Steinregen, Mondmal, Bollwerk.
  30 Dateien, je Klang bis zu drei Fassungen und leicht gestreute Tonhöhe, damit
  nichts maschinell klingt. Ein Begrenzer hält gleichzeitige Stimmen je Klang knapp.
- Musik in fünf Lagen: Menü, Kampf, letzte Welle, Sieg, Niederlage, mit Überblendung.
  Pause dämpft die Musik, eigene Musik vom iPhone hat Vorrang, der Stummschalter gilt.
- Einstellungen: Regler für Klänge und Musik (statt „Ton folgt“), bleiben gespeichert.
- Nur CC0-Quellen (Steffens Wahl, D-082). Herkunft, Lizenz und Prüfsumme jeder Quelle
  in `art/ton/klaenge.json` und `art/ton/ENTSTEHUNG.md`; gebaut mit `tools/ton/ton_bauen.py`.

**Architektur**
- `App/Audio`: `SoundMap` (Moment → Klang, Musiklage), `SoundLimiter`, `AudioDirector`
  (wie `FxDirector`, liest keinen Spielzustand), `AudioEngine` (AVAudioEngine, `.ambient`).
  OddlingsCore unverändert. Konzept: [p2-3-ton-und-musik](docs/konzepte/p2-3-ton-und-musik.md).

**Tests**
- App-Tests für Zuordnung, Begrenzer, Regie, Dateien und Einstellungen; zwei
  Ende-zu-Ende-Fälle (`SoundE2ETests`: Musiklage und alle Klanggruppen im Demo-Kampf,
  Regler überleben den Neustart). CI: `tools/ton/ton_pruefen.py` lässt nur CC0 und
  gelistete Dateien durch.

## Dokumente, kein Bau – 01.11.2026 (Reihenfolge nach R-6: Mission 2 jetzt, D-080)

- Steffen hat entschieden: Mission 2 mit Zwergenbank kommt jetzt, der Spieltest
  WP-15 läuft parallel und korrigiert die Werte danach (D-080). Roadmap „Als
  Nächstes“ und Stand umgestellt, Karte S6 erledigt.
- Nummernblock D-080 bis D-089 an die Projektplanung vergeben.
- Konfliktmarken aus dem Zusammenführen von #52 und #53 in `CHANGELOG.md` und im
  Entscheidungsprotokoll entfernt; `scripts/regeln-pruefen.sh` bricht jetzt bei
  Konfliktmarken in eingecheckten Textdateien.

## Dokumente, kein Bau – 01.11.2026 (Bau 33, Konzept R-7 Ausrüstung)

- Bau 33 (0.12.0) von Apple als VALID gemeldet, in Roadmap und Stand eingetragen.
- Konzept [R-7 Ausrüstung](docs/konzepte/r-7-ausruestung.md): drei Plätze (Banner,
  Amulett, Siegel), nie gegen Echtgeld, keine Zufallstruhen.
- D-069: volle Ausrüstung macht den Avatar höchstens +10 % stärker.
- D-070: Ausrüstung kommt aus festen Belohnungen (R-7a) und einer Schmiede mit
  Spielwährung (R-7b, eigenes Konzept).

## 0.13.0 – 01.11.2026 (FX 02: Plünderer mit Gliedmaßen), Bau 34

**Neu**
- Der Plünderer geht, zuckt bei Treffern und stürzt als echte Figur mit Armen und
  Beinen: 17 Bilder aus einem 3D-Modell (Gehen 8, Treffer 3, Sturz 6), im
  Comic-Stil des Gemäldes. Von Steffen am Bild freigegeben (D-051).
- Das Laufbild folgt der gegangenen Strecke (`FxMath.walkFrame`), nicht der Zeit:
  bei 2× und bei Pause passt der Schritt zum Weg. Gegner ohne Bildfolge bleiben
  Gemälde und hüpfen wie bisher.
- `FxDirector` spielt Treffer- und Sturzbilder (Zähler `flinches`, `falls` für E2E).

**Werkzeuge**
- `tools/figuren-3d`: TRELLIS-Modell aus einer gemalten Vorlage, Skelett aus
  `rig.json`, Comic-Look (Sättigung, Eigenlicht, Umriss, Randlicht), `folge.py` legt
  Bildfolgen mit einem Maßstab in den Atlas. `angleichen.py` gleicht Farben an das
  Gemälde an (D-052).
- `check_assets.py` prüft Bildfolgen auf Lücken (Vertragsfeld `folge`).

**Tests**
- App: Bildwahl je Strecke, Unabhängigkeit von der Bildrate, Phase, Treffer- und
  Sturzfolge im Director, Plünderer hat Bildfolgen. E2E prüft `flinches` und `falls`.
- Grafik: Angleichen, Bildfolge vollständig, mit Lücke, zu lang (rot gesehen).

## Dokumente, kein Bau – 27.10.2026 (Architektur, Design und Roadmap nachgezogen, D-067)

- Architektur auf den Stand 0.12.0: Module der App, Kerndateien, Datenfluss beim
  Missionsstart, Grafikwerkzeuge; Datenmodelle mit Kampagne und Spielstand;
  Teststrategie mit allen 27 Ende-zu-Ende-Fällen und Testschaltern.
- Design: Avatar-Menü (D-065) und Ausrüstung (D-066) in 03, 05, 06; Schirmfolge,
  Avatar-Aufbau und Avatar-Menü in 07; Kampfplatz, Festung, Porträts und 3D-Weg in
  den Art-Dokumenten.
- Roadmap als gemeinsame Arbeitsliste: Phasen mit Stand, „Wartet auf Steffen“,
  „Als Nächstes“, alle Auslieferungen mit Version und Bau. Status und Register neu.
- Regel D-067: Doku wächst mit jeder Auslieferung, Entscheidungskarten werden sofort
  gemeldet. `regeln-pruefen.sh` prüft die neueste Version in `CLAUDE.md`, `status.md`
  und Roadmap sowie jeden App-Ordner und jede Kerndatei in der Architektur (rot gesehen).

## 0.12.0 – 27.10.2026 (R-6: Avatarrang mit Talentwahl), Bau 33

**Neu**
- Avatarrang (D-064, D-065, [Konzept](docs/konzepte/r-6-avatarrang.md)): fünf Ränge,
  alle 6 Sterne einer (aus den besten Sternen je Mission), als römische Ziffer am
  Avatarschild. Mit nur Mission 1 bleibt es vorerst bei Rang I.
- Avatar-Menü als eigener Schirm, über das Schild im Hauptmenü oder auf der Karte:
  links der Charakter mit Porträt, Rang und Sternbalken, rechts vier Talentreihen je
  Volk. Jeder Rang schaltet eine Reihe mit zwei gleich starken Spielarten der
  Volksfähigkeit frei; Umstellen kostet nichts.
- Nach einem neuen Rang trägt das Schild „Neues Talent“, bis das Avatar-Menü offen war.

**Geändert**
- `races.json` bekommt `rankStars` und je Volk vier Talentreihen (Faktoren auf die
  Fähigkeit). Der Spielstand merkt sich die Wahl im Avatar; Schema bleibt 2, eine
  kaputte Wahl kostet nur die Wahl.

**Tests**
- Kern: `SaveGameTests.testTalentChoiceSurvivesTheSaveFile` (Wahl übersteht die Datei,
  kaputte Wahl kostet nur die Wahl), `TalentTests` (Rang an den Schwellen, wirksame Wahl, Faktoren, Prüfung,
  Laden), `BalanceTests.talentsStayEven` (31 Kombinationen je Volk nah an der Mitte, die
  Mitte nah an der Grundform; Werte in 04). Die Kerntests laufen in der CI im
  Release-Bau.
- App: Rang schaltet ein Talent frei und prägt die Mission; Texte nennen jede Spielart.
- E2E: drei Sterne per Testschalter plus Sieg bringen Rang II, Avatar-Menü, Seite B
  wählen, zurück, Neustart behält die Wahl; Überlappungsprobe des Menüs.

## 0.11.1 – 27.10.2026 (Grafik 05: Kampfplatz und Festung), Bau 32 (VALID)

**Neu**
- Der Kampfplatz ist eine Lichtung im Flüsterwald, aus denselben gemalten Teilen
  wie die Kampagnenkarte: Waldrand bis an den Bildschirmrand (4 Zellen links und
  rechts, 2 oben und unten, auf iPhone und iPad ohne leere Streifen), Weg mit runden Ecken, die
  Goblinhöhle am Wegeingang, warmes Licht und Baumschatten.
- Neue Festung: Zwergenfeste mit zwei Ecktürmen, Fackeln und Bannern, im Stil
  der Türme. Sie steht im rechten Rand und verdeckt keine Bauzelle.
- Gemalte Porträts für die Avatarwahl: drei Zwerge, drei Elfen (statt Volkssymbol
  im Kreis).

**Behoben**
- Die Festung war unsichtbar: Boden und Festung hatten dieselbe `zPosition`, und
  mit `ignoresSiblingOrder` lag der Boden oben.

**Tests**
- App: Boden deckt die ganze Szene (iPhone und iPad, mit und ohne Kopfleiste),
  Festung über Boden und Bauzonen, Festung über keiner Bauzelle. Kunstprüfung:
  Vertrag 24 × 13 Zellen,
  Weg im Bild auf der Weggeometrie, Waldrand dunkler als das Feld, Collage legt
  keine Bäume auf Bauzellen. Jedes Avatar-Porträt ist gemalt und quadratisch.

## 0.11.0 – 26.10.2026 (R-5: Avatar einmal am Anfang), Bau 31 (VALID)

**Neu**
- Avatar-Aufbau beim ersten „Spielen“ (D-063, [Konzept](docs/konzepte/r-5-avatar.md)):
  Volk, Porträt und Name. Ein Namensvorschlag steht schon im Feld, der Würfel
  bringt einen anderen. Danach ist das Volk gesetzt und gilt für jede Mission.
- Avatarschild mit Porträt, Name und Volk im Hauptmenü und auf der Missionstafel.
- Porträts: je Volk drei. Bis die gemalten Brustbilder kommen, zeigen Platzhalter
  das Zeichen des Volks in drei Farben.

**Geändert**
- Die Volkswahl auf der Missionstafel entfällt (ersetzt D-061).
- Spielstand Schema 2: `avatar` statt `race`. Ein Stand aus 0.7.0 bis 0.10.x
  behält seinen Fortschritt, der Avatar wird einmal neu aufgebaut. Name und Porträt
  werden beim Laden geprüft; ein kaputter Avatar kostet nur den Avatar.

**Tests**
- Kern: Avatar, Migration von Schema 1, Namens- und Porträtprüfung.
- App: Aufbau genau einmal, Volk prägt die Mission, Porträtkatalog, Namensvorschläge.
- E2E: Aufbau bis zur Mission und Neustart ohne zweiten Aufbau, Zwergenpreis und
  Bollwerk, Überlappungsprobe für Aufbau und Tafel. Neuer Testschalter
  `--e2e-avatar` (nur DEBUG) für Tests, die zur Karte wollen.

## 0.10.3 – 26.10.2026 (Wackliger Fähigkeitstest behoben), Bau 30 (VALID)

**Behoben**
- `AbilityE2ETests.testCastOnPathChargesAndComesBack` schlug auf PR #42 und #43 je
  einmal fehl. Ursache: Der Test lief im zehnfachen Tempo, „lädt“ hielt damit nur
  3,5 s. Im fehlgeschlagenen Lauf brauchte der Test 52 statt 17 s, XCTest wartete
  nach einem Tippen lange auf Ruhe in der App, und als er ablas, war der Knopf
  schon wieder „bereit“. Neuer Testschalter `--e2e-abklingzeit` (nur DEBUG): Der
  Test wirkt bei langer Abklingzeit und ohne Welle. Dass die Fähigkeit wiederkommt,
  prüft `BattleControllerTests` ohne Uhr. Die Völkerprobe nutzt den Schalter auch.
- Die CI legt das ganze Testprotokoll mit Zeitstempeln ins Artefakt `simulator-probe`.

## 0.10.2 – 26.10.2026 (Grafik 04: gemalte Kampagnenkarte), Bau 29 (VALID)

**Neu**
- Gemalte Karte von Region 1 (`map_region01`): Flüsterwald mit Lichtungen unter
  jeder Mission, Erdwegen entlang der Spur, Teichen am Sumpfpfad, Ruinen am
  unteren Pfad und der Goblinhöhle über dem Bosskampf. Ersetzt den gezeichneten
  Ersatzwald.

**Werkzeug**
- `regionscollage.py` setzt die Karte aus gemalten Einzelteilen an die
  Knotenlagen aus `region-01.json`, `zerlegen.py` schneidet Teileblätter.
  `regionsvorlage.py` entfällt: Bild-zu-Bild über die Vorlage traf die Knoten nie.

**Tests**
- Grafikprüfung: kein Baum auf Knoten, Medaille oder Weg (einfarbige Teile), und
  im ausgelieferten Bild liegt unter jedem Knoten eine Lichtung.
- App-Test: Karte im Katalog, Seitenverhältnis wie `CampaignStyle.mapAspect`.

## 0.10.1 – 26.10.2026 (Zwerge: Wachtürme billiger, D-062), Bau 28 (VALID)

**Geändert**
- Die Zwerge haben jetzt einen passiven Zug: Wachtürme kosten bei ihnen 10 % weniger
  (50 → 45 Gold). Das Baumenü zeigt den Zwergenpreis, die Missionstafel nennt den
  Vorteil. Der Wert steht als `costFactor` in `races.json`.
- Balance nachgemessen ([04](docs/game-design/04-economy-and-balance.md)): Mischung
  Zwerge 1,40, Elfen 1,42; reine Wachtürme bei Zwergen 1,31, weiter hinter der Mischung.

**Tests**
- Kern: Preisfaktor je Volk, Rundung, Prüfung beim Laden, Mischung vor Monokultur je Volk.
- App: Baumenü liest den Zwergenpreis; E2E baut als Zwerg einen Wachturm und prüft
  Preis im Ring und Abbuchung.

## 0.10.0 – 26.10.2026 (Bewegung und Effekte, FX 01), Bau 27 (VALID)

**Neu**
- Gegner laufen: Hüpfen im Schritttakt je Gegnerart, Stauchen beim Aufsetzen,
  Wiegen, Vorneigung, Blick in Laufrichtung, Schatten wird in der Luft kleiner.
  Verlangsamte Gegner trippeln langsamer und sind grün getönt.
- Treffer blitzen hell auf, mit Rückstoß; der Lebensbalken hat ein nachlaufendes
  Schadensstück. Tod: Stauchen, Zerplatzen in Rauch und Splittern, drei Münzen
  springen heraus, `+Gold` springt auf.
- Wachturm schießt Pfeile im Bogen (Treffer erst bei Ankunft), Blitzturm einen
  gezackten Kettenblitz Glied für Glied mit leuchtendem Kristall, Sporenturm
  pumpt einen Sporenring aus. Blitz auf verlangsamtes Ziel: Sporenfunke (E2).
- Bau: Turm fällt auf seinen Platz und federt nach, Staubring. Verkauf: Turm
  versinkt in Staub, Münzen. Durchbruch: Festung bebt, Bild wackelt.
  Wellenbanner springt ein, Sieg mit Konfetti. Türme atmen leicht in Ruhe.
- Festungsfähigkeiten: Steinregen warnt mit wachsendem Schatten und pulsierendem
  Ring, Felsen prasseln genau zum Einschlag, Druckwelle, Staub, Splitter und
  Wackeln; Getroffene zeigen kreisende Sternchen, solange sie betäubt sind.
  Mondmal sammelt kühles Licht und leuchtet auf, das Mal am Gegner ist ein
  pulsierender Mond. Bollwerk schießt federnd als Steinmauer aus dem Boden und
  versinkt am Ende in Staub. Die Platzhalter aus 0.8.0 und 0.9.0 sind ersetzt.
- „Bewegung reduzieren" in iOS schaltet Wackeln und Atmen ab.
- Konzept: [fx-01-bewegung-und-effekte](docs/konzepte/fx-01-bewegung-und-effekte.md),
  Entscheidungen D-050 (Effekt-Uhr), D-051 (Gliedmaßen über 3D-Modelle zu Sprite-Blättern, von Steffen gewählt;
  folgt als eigenes Paket).

**Tests**
- `AppTests/FxMathTests`, `FxDirectorTests`, `FxBudgetTests` (ganze Mission bei
  2×: Obergrenze, keine `SKShapeNode`, Rechenzeit je Bild).
- `AppUITests/EffectsE2ETests`: alle Effektarten laufen in der echten App.
- CI-Probelauf misst die Bildrate im Simulator und wird unter 30 Bildern je
  Sekunde rot. Gemessen im Simulator ohne Grafikkarte: zuerst 49 Bilder je Sekunde
  mit einem Haker von 842 ms; seit die Effekttexturen beim Anlegen der Szene vorab
  gezeichnet werden, 59,7 Bilder je Sekunde, längstes Bild 37,9 ms.

## 0.9.1 – 26.10.2026 (Grafik 03: Titelbild und Oberflächensymbole), Bau 26 (VALID)

**Neu**
- Gemaltes Titelbild im Hauptmenü (`ui_keyart_menu`): Festung auf dem Hügel, die
  drei Türme am Weg, Plünderer, Panzerbestie und Flitzer im Anmarsch. Es sind die
  Figuren aus dem Spiel, nicht neu erfunden.
- Gemalte Turmsymbole im Baumenü (`ui_tower_*`), aus denselben Bildern wie auf dem
  Spielfeld.
- Gemalte Symbole für die Kopfleiste (Herz, Gold, Welle, Verkaufen, Pause,
  Horn) liegen im Katalog; die Leiste nimmt sie mit dem nächsten Oberflächenpaket.

**Werkzeug**
- `check_assets.py` prüft Symbole (Quadrat in Punkten, mittig) und große Bilder
  (Gerätepixel für @3x). `regionsvorlage.py` legt die Vorlage der Regionskarte
  aus `region-01.json` an.

**Tests**
- `UIArtTests` (App), neue Fälle in `tools/art-check/tests`; alle einmal rot gesehen.

## 0.9.0 – 26.10.2026 (Völkerwahl Zwerge und Elfen, R-4), Bau 25 (VALID)

**Neu**
- Auf der Missionstafel der Karte stehen Zwerge und Elfen über „Starten“. Ohne
  Wahl gilt der Steinregen. Die Wahl steht im Spielstand. Beide Völker sind
  sofort wählbar, solange nur Mission 1 spielbar ist (D-061).
- Zwerge: Bollwerk. Eine Mauer quer zum Weg, sofort und 4 s lang. Wer sie von
  vorn erreicht, bleibt dort stehen.
- Elfen: Mondmal. Nach 0,5 s nehmen Gegner im Kreis 4 s lang jeden Treffer
  ×1,5. Dazu reichen Sporentürme 10 % weiter.
- Knopf unten rechts mit Bild und Namen je Volk. Mauer, Mal und Effekte sind
  Platzhalter.
- Werte stehen in `Balance/races.json` und gelten als **[HYPOTHESE]**. Beim
  Laden wird die Datei geprüft wie die Missionsdatei.
- Ein passiver Zug der Zwerge fehlt, bis die Zwergenbank kommt. Die Frage an
  Steffen ist offen.
- Konzept: [r-4-voelker](docs/konzepte/r-4-voelker.md).

**Balance**
- Je Volk höchstens +0,1 Reserve, zwischen den Völkern höchstens 0,05. Gemessen:
  Zwerge +0,05, Elfen +0,07
  ([04](docs/game-design/04-economy-and-balance.md#völker-zwerge-und-elfen-r-4-26102026-hypothese)).

**Tests**
- Kern: `BulwarkTests` (5), `MoonMarkTests` (6) und `RaceTests` (6). Dazu
  Wiederholung je Volk, Prüfsumme mit Mauer und Mal und die Völkergrenze in
  `BalanceTests`. Jeder neue Test wurde einmal rot gesehen. Die feste
  Prüfsumme ist neu, weil sie Mauer und Mal mitzählt.
- App: Wahl und Spielstand in `AppFlowTests`, Fähigkeit je Volk in
  `BattleControllerTests`, Mauer und Mal in `BattleSceneTests`, Haptik.
- E2E: `RaceE2ETests`. Dort wird ein Volk gewählt und die Mission gestartet,
  dann die App neu gestartet und ein Bollwerk gesetzt. Ein zweiter Test prüft,
  dass die Tafel mit der Wahl ins Bild passt.
- Zwei ältere E2E-Tests liefen gegen die Uhr der Mission. Sie halten die erste
  Welle jetzt mit `--e2e-erste-welle` zurück (nur im Debug-Bau).

## 0.8.0 – 25.10.2026 (Festungsfähigkeit Steinregen, R-3), Bau 24 (VALID)

**Neu**
- Steinregen (D-025, D-060): Knopf unten rechts, dann auf den Weg tippen. Der
  Wurf rastet am Weg ein, nach 0,8 s schlägt er im Kreis ein, macht Schaden und
  hält Getroffene 1 s an. Danach lädt er 35 s. Daneben gezielt kostet nichts.
  Mission 1 hat ihn, solange sie die einzige spielbare ist. Werte
  **[HYPOTHESE]** bis zum Spieltest.
- Knopf und Effekt sind Platzhalter; Ladering, Zielansicht (Oberfläche) und
  Einschlag (Animation) folgen.
- Konzept: [r-3-steinregen](docs/konzepte/r-3-steinregen.md).

**Balance**
- Gemessen, bevor die Werte feststanden: Die ersten Werte (40 Schaden, 25 s)
  hoben die Reserve um 0,29, erlaubt sind 0,1. Jetzt +0,075
  ([04](docs/game-design/04-economy-and-balance.md#steinregen-r-3-25102026-hypothese)).

**Tests**
- Kern: `AbilityTests` (8), Wiederholung mit Würfen in `DeterminismTests`,
  Grenze der Reserve in `BalanceTests`; jeder einmal rot gesehen. Die feste
  Prüfsumme ist neu, weil sie Anhalten und Fähigkeit mitzählt.
- App: Zielen, Werfen, Laden und Zuschauen in `BattleControllerTests`, Haptik.
- E2E: `AbilityE2ETests` (bereit, daneben gezielt, Wurf, Laden, wieder bereit;
  nach dem Ende kein Knopf).

## 0.7.0 – 25.10.2026 (Spielrahmen R-1 und R-2), Bau 23 (VALID)

**Neu**
- Kampagnenkarte Region 1 „Flüsterwald“ (D-027, D-060): sieben Hauptmissionen mit
  Gabelung nach Mission 4 (Sumpfpfad oder Ruinen), Boss, zwei Nebenmissionen ab 6
  und 15 Sternen. Missionstafel rechts mit Art, Name, Sternen, was die Mission
  lehrt, ihrer Neuheit und dem Grund, warum sie noch zu ist. Mission 1 ist
  spielbar, die übrigen zeigen „gesperrt“ oder „in Arbeit“.
- Sterne nach Leben übrig (1 / ab 15 / alle 20, Grenzen in der Missionsdatei).
- Speicherstand nach D-022: lokal, atomar geschrieben, vorige Fassung bleibt,
  beim Laden geprüft; ein Stand einer neueren App wird nicht überschrieben.
  Gespeichert wird beim Ergebnis, nicht beim Verlassen der App.
- Hauptmenü: „Weiter mit Mission 1“ führt direkt in die nächste Mission, „Spielen“
  öffnet die Karte; nach dem Ergebnis geht es zur Karte zurück.
- Einstellungen mit Vibration an/aus (getrennt vom Spielstand).
- Konzept: [r-spielrahmen](docs/konzepte/r-spielrahmen.md).

**Tests**
- Kern: `StarRatingTests`, `CampaignTests`, `SaveGameTests`, `SaveStoreTests`
  (22 neu, jeder einmal rot gesehen), u. a. kaputte Datei, übergroße Datei,
  neueres Schema, Gabelung, Sternsumme.
- App: `AppFlowTests`, `AppSettingsTests`.
- E2E: `CampaignE2ETests` (Sieg → Sterne auf der Karte → App neu starten → Sterne
  noch da; gesperrte Missionen starten nicht und sagen warum), Einstellung bleibt
  nach Neustart, Weg Menü → Karte → Mission → Karte → Menü. Jeder Oberflächentest
  spielt mit eigenem Spielstand im temporären Ordner.

## 0.6.0 – 25.10.2026 (Spieloberfläche UI 01), Bau 22 (VALID)

**Neu**
- Kreismenü am Feld (D-031): drei runde Turmknöpfe im Bogen mit Preisschild,
  erstes Tippen zeigt Reichweite und Infotafel (Rolle, Zusammenspiel), zweites baut.
  Der Bogen weicht Rändern, Kamera und Home-Leiste aus (`HudLayout`).
- Verkaufen mit zweitem Tippen: „Verkaufen +N“, dann „Sicher?“.
- Zu wenig Gold: Schild „fehlt N“, Gold blinkt, Warnhaptik, kein Befehl.
- Kopfleiste neu: Leben, Gold, Welle mit Symbolen, Zahlen rollen bei Änderung,
  Leben wackeln bei Durchbruch; „Welle N“ mit Countdown-Ring; 2× goldfarben.
- Pausentafel mit Stand, „Weiter“, „Neu starten“ und „Aufgeben“.
- Ergebnistafel mit Band „Sieg!“ bzw. „Die Festung ist gefallen“ und hochzählenden
  Werten: Leben übrig, Dauer, Türme gebaut bzw. Wellen gehalten, Dauer, besiegte Gegner.
- Haptik zu jeder eigenen Handlung (07, Abschnitt 5), beim Zuschauen keine.
- Hauptmenü im Stil der Entwürfe, „Spielen“ groß im Daumenbereich.
- Schriften Lilita One und Nunito (D-032), mit Lizenz und Herkunft in `App/UI/Fonts/`.
- Konzept: [ui-01-hud-und-tafeln](docs/konzepte/ui-01-hud-und-tafeln.md).
- Nach Durchsicht der Bildschirmfotos: Band der Niederlage dunkler (Schiefer statt
  Hellgrau), damit die helle Schrift lesbar bleibt (Kontrast über 6 : 1).

**Tests**
- Neu: `HudLayoutTests` (jede Bauzelle auf vier iPhone-Größen), `FeedbackPlayerTests`,
  `AppFontsTests`; `BattleControllerTests` um Verkaufen mit Bestätigung, Aufgeben,
  Zähler, Dauer, Haptik und Countdown-Ring erweitert.
- E2E: `TablesE2ETests` (Pause, Neu starten, Aufgeben, Bildschirmfotos zum
  Vergleich mit dem Entwurf), Verkaufen mit Bestätigung, „fehlt N“, Werte der
  Ergebnistafel nach Sieg und Niederlage.
- `regeln-pruefen.sh`: keine Schriftdatei ohne Lizenz und Herkunftseintrag.

## Dokumente, kein Bau – 25.10.2026 (Grafik: Konzept Phase 2 und Spielrahmen)

- Konzept [Grafik 02](docs/konzepte/grafik-02-phase-2.md): Bilder für Aufwertungen,
  Spezialisierungen, Zwergenbank, Steinregen, Hauptmenü, Regionskarte und
  Volksbanner, mit Namen, Maßen und Qualitätsprüfung vor der Abgabe.

## 0.5.2 – 25.10.2026 (Grafik), Bau 21 (VALID)

**Neu**
- Gemalte Grafik im Stil „Stylized 3D" (D-016, aus drei Stilmustern gewählt):
  Wachturm, Blitzturm, Sporenturm, Plünderer, Flitzer, Panzerbestie, Festung und
  der Boden von Mission 1 mit eingemaltem Weg. Ersetzen die Platzhalterformen.
- Bildwerkzeug `.claude/skills/spielgrafik` (aus Stack & Siege übernommen),
  ergänzt um Freistellen mit Kontur, Atlas, Bild-zu-Bild und Karten aus der
  Weggeometrie. Konzept: [grafik-01-spielfeld](docs/konzepte/grafik-01-spielfeld.md).
- Art-Direction, Asset-Vertrag, Konzeptblätter der Figuren und Rückmeldung je
  Ereignis unter `docs/art/`.

**Tests**
- CI-Job `art`: 16 Tests der Bildpipeline (Atlas gegen Vertrag, Herkunft,
  Lizenz, Weg der Kartenvorlage) und die Prüfung des echten Atlas.
- `AppTests/BattleSpritesTests`: Bilder gefunden, Maße und Anker, Boden deckt
  die Karte, Weglinie entfällt.

## Dokumente, kein Bau – 25.10.2026 (Bedienung Phase 2, Kreismenü entschieden)

- Bedienung für Aufwerten und Gabelung, Zielwahl, Zwergenbank, Bonus für frühes Rufen und Steinregen ([07](docs/game-design/07-ui-ux.md#8-phase-2-aufwerten-fähigkeit-bank)), Kampagnenkarte nach K4. D-033 entschieden: Steinregen unten rechts, Tempo oben neben der Pause.
- D-031 entschieden: Türme werden im Kreismenü am Feld gewählt, Bauen und Verkaufen per zweitem Tippen ([07](docs/game-design/07-ui-ux.md#bauen)).

## Dokumente, kein Bau – 25.10.2026 (Oberfläche)

**Neu**
- Konzept für Oberfläche und Bedienung: [07-ui-ux.md](docs/game-design/07-ui-ux.md)
  mit Raster je iPhone, HUD-Ecken, Bauen und Verkaufen am Feld, Pause, Sieg,
  Niederlage, Hauptmenü, Richtung der Kampagnenkarte und der Architektur
  (neu `HudLayout` neben `BoardLayout`, `UITheme`, `FeedbackPlayer`; Auswahl und Kopien bleiben im `BattleController`).
- Klickbare Entwürfe aller Schirme: [Oddlings – Spieloberfläche](https://claude.ai/artifact/PKpZrLVV42wje1isSfvB8z).
- Vorschläge D-030 (HUD-Ecken), D-031 (Kreismenü), D-032 (Schriften).

**Tests**: keine, nur Dokumente. Die Tests der Bausteine stehen in 07 und kommen
mit der Umsetzung.

## Dokumente, kein Bau – 25.10.2026

**Neu**
- Projektplanung: Konzepte für Phase 2 und 3 (Aufwertungen mit Gabelung,
  Festungsfähigkeit, Völker, Zwergenbank, Kampagne mit kostenloser Region 1,
  Fortschritt, Speicherstand, Gegner und Bosse, Einstieg, Ton) in
  `docs/konzepte/phase-2-3.md`.
- Register aller offenen Fragen (`docs/production/offene-fragen.md`) und
  Statusübersicht für Steffen (`docs/production/status.md`).
- Roadmap mit Meilensteinen für Phase 1, Entwurf für Phase 2, Ausblick Phase 3
  und den Abhängigkeiten zwischen den Threads.
- Entscheidungen D-020 bis D-023 festgelegt, D-024 bis D-027 Steffen vorgelegt.

**Tests**: neue Prüfung `scripts/links-pruefen.py` im CI-Schritt `regeln`:
bricht ab, wenn ein Verweis in den Dokumenten auf eine fehlende Datei oder
einen fehlenden Abschnitt zeigt oder eine Nummer im Entscheidungsprotokoll
doppelt vergeben ist. Einmal rot gesehen (falscher Anker, falsche Datei,
doppelte Nummer).
- Nummern im Entscheidungsprotokoll vergibt die Projektplanung zentral, in Blöcken je Thread.
- Konzeptdatei liegt nach D-017 unter `docs/konzepte/phase-2-3.md`.

## 0.5.1 – 25.10.2026

**Neu**
- End-zu-End-Tests (D-029): Die CI spielt die App bei jedem PR wie ein Spieler
  durch, mit 13 Fällen in vier Dateien unter `AppUITests/`. Sie decken Menü
  und Zurück ab, Bauen und Verkaufen samt Gold, Vorschau, Ausgrauen,
  Kopfleiste, Welle rufen, Pause, 2×, Niederlage mit Nochmal, Sieg der
  Vorführung und den Wechsel in den Hintergrund. Konzept:
  `docs/konzepte/e2e-tests.md`.
- Die Mission hält an, wenn die App in den Hintergrund geht (D-034, Vorschlag).
- Die CI listet jeden App-Testfall mit Ergebnis. Bisher kürzte sie das
  Protokoll, und man sah nicht, ob ein Testziel gelaufen war.
- Zeitraffer `--e2e-zeitraffer N`, nur im Debug-Bau, damit ganze Missionen im
  Simulator in Sekunden durchlaufen.

**Tests**: Die App-Tests aus 0.5.0 und alle 13 neuen End-zu-End-Fälle sind
jeweils einmal rot gesehen worden, mit Probeläufen mit umgedrehten Prüfungen
(CI-Läufe 40205226937, 40208318048, 40208954005).

**Nachgereicht (nur Dokumente, kein Bau)**: Beobachtungsbogen für den
Spieltest WP-15 in `docs/production/playtests/beobachtungsbogen.md`.

Bau: **20 VALID**.

## 0.5.0 – 25.10.2026

**Neu**
- Mission 1 ist spielbar (WP-12 bis WP-14). Der Startbildschirm hat ein großes
  „Spielen“.
- Bauen: Bauzelle antippen, Turm wählen (zeigt die Reichweite), noch einmal
  tippen baut. Nicht leistbare Türme sind ausgegraut.
- Verkaufen: Turm antippen, „Verkaufen +Erstattung“.
- Abgelehnte Befehle erscheinen als roter Text an der Stelle.
- Kopfleiste: Gold, Leben, Welle n/m, „Nächste Welle“ mit Countdown, 1×/2×,
  Pause, Zurück.
- Ergebnistafel bei Sieg oder Niederlage mit „Nochmal“ und „Zurück“.
- Konzept vor Umsetzung: `docs/konzepte/wp-12-14-spielbare-mission.md`, Regel in
  `CLAUDE.md` und im Skill `arbeitspaket-ausliefern` (D-017).

**Tests**: `BattleControllerTests` (11 Fälle: Auswahl, Vorschau, Bauen,
Verkaufen, Gold, Zuschauen, Welle rufen, Countdown, Pause, 2×, Niederlage,
Neustart). Neues Oberflächentest-Ziel `OddlingsUITests`: bauen und verkaufen
mit echtem Tippen, Kopfleiste und Pause.

Bau: **19 VALID**.

## 0.4.0 – 25.10.2026

**Neu**
- WP-11: Die App zeigt die echte Simulation. Startbildschirm mit „Mission 1
  ansehen“: Ein Mitspieler baut nach der Demo-Bauweise aus der Konfiguration,
  Türme schießen, Blitze springen, Sporen verlangsamen, Gegner laufen den Weg
  entlang, die Festung nimmt Treffer. Neustart und Zurück.
- Fester Takt mit Zwischenbildern: Die Szene rechnet in festen Schritten und
  zeichnet zwischen zwei Zuständen weich, auch bei 2×.
- Platzhaltergrafik nach dem Asset-Vertrag der Grafik: Sobald die gemalten
  Bilder unter ihren Namen im Katalog liegen, ersetzen sie die Platzhalter ohne
  Codeänderung.
- Probelauf im Simulator startet direkt die Mission (`--demo`) und legt ein
  Bildschirmfoto ab.

**Tests**: `AutoplayerTests` (Paket), `BattleSceneTests` (App: Knoten passen
über eine ganze Mission zum Zustand, Neustart räumt auf, 2× macht doppelt so
viele Schritte). Neuer CI-Schritt „App testen“.

Bau: **18 VALID**.

## 0.3.1 – 25.10.2026

**Neu**
- CI-Schritt `regeln` (`scripts/regeln-pruefen.sh`): bricht ab, wenn die
  Simulation mehr als Foundation importiert oder Uhrzeit, Zufall oder Umgebung
  benutzt, bei Netzcode, bei eingecheckten Schlüsseln oder Zertifikaten, bei
  Abläufen ohne festgelegte Rechte und bei fremden Actions ohne festen Commit.
- `CLAUDE.md`: Abschnitt „Qualität und Sicherheit“ und die Absprachen mit Steffen
  (selbstständig arbeiten, Entscheidungen festhalten, Änderungsprotokoll führen).
- Skill `.claude/skills/arbeitspaket-ausliefern`: der Weg von der Änderung bis zum
  VALID-Bau in TestFlight.

**Tests**: Jede Prüfung in `regeln-pruefen.sh` einmal mit einem eingebauten
Verstoß rot gesehen.

Bau: **17 VALID**.

## 0.3.0 – 25.10.2026

**Neu**
- WP-10: Prüfsumme über den ganzen Spielzustand. Gleicher Startwert und gleiche
  Befehle ergeben dieselbe Prüfsumme, auch nach Speichern und Laden mitten in der
  Welle und bei doppelter Geschwindigkeit.
- Balance wird jetzt im Swift-Paket geprüft (`BalanceTests`), mit denselben
  Bot-Bauweisen wie vorher in Python. Die Bauweisen stehen in
  `mvp-mission-01.json` unter `simStrategies`.

**Entfernt**
- Python-Prüfskript `tools/balance-sim` und der CI-Schritt `balance`. Zwei
  Umsetzungen derselben Regeln wären auseinandergelaufen.

**Befund**: Rangfolge der Bauweisen wie in Phase 0, die Abstände sind kleiner,
weil Türme nicht mehr auf schon tote Ziele schießen (Einzelheiten in
`docs/game-design/04-economy-and-balance.md`).

**Tests**: `DeterminismTests`, `BalanceTests`.

Bau: **16 VALID**.

## 0.2.0 – 25.10.2026

**Neu**
- WP-09: Sieg, sobald alle Wellen erschienen und keine Gegner mehr da sind.
  Ein letzter Durchbruch zählt vorher, eine verlorene Festung gewinnt nicht mehr.
- Befehl „Nächste Welle“ (`callNextWave`): startet die nächste Welle sofort und
  schiebt den restlichen Takt mit. Ohne verbleibende Welle wird er abgewiesen.

**Tests**: `VictoryTests` (Sieg, Reihenfolge Durchbruch vor Sieg, Welle rufen).

Bau: **15 VALID**.

## 0.1.1 – 25.10.2026

**Behoben**
- TestFlight-Bau scheiterte seit Bau 6 beim Archivieren: Das Profil wurde über
  die Befehlszeile gesetzt und galt damit auch für das Ressourcenbündel von
  `OddlingsCore`. Es gilt jetzt nur noch für die App.

**Neu**
- Dieses Änderungsprotokoll, rückwirkend ab Phase 0.

Bau: **13 VALID** (Probebau vom Arbeitszweig vor dem Zusammenführen), **14 VALID** (von main).

## 0.1.0 – 25.10.2026

Alles bis hierher lief unter Version 0.1.0.

| PR | Inhalt | Bau |
|---|---|---|
| #12 | WP-08: Sporenturm mit Puls und Verlangsamung | 12 gescheitert (Profil) |
| #11 | WP-07: Blitzturm mit Kettenblitz | 11 gescheitert (Profil, siehe 0.1.1) |
| #10 | Marktanalyse in Doku, Backlog und Roadmap; D-015 Geschäftsmodell | kein Bau |
| #9 | WP-06: Wachturm, Schaden, Belohnung | 10 gescheitert (Profil) |
| #8 | WP-05: Bauen und Verkaufen, Gold | 9 gescheitert (Profil) |
| #7 | Marktanalyse der führenden mobilen Tower-Defense-Spiele | kein Bau |
| #6 | WP-04: Wellen, Bewegung, Festung | 8 gescheitert (Profil) |
| #5 | WP-03: Weggeometrie und Bauzonen | 7 gescheitert (Profil) |
| #4 | WP-02: Paket OddlingsCore, Konfiguration mit Prüfung | 6 gescheitert (Profil) |
| #3 | Bauen mit Xcode 26, damit TestFlight den Bau annimmt | **5 VALID** |
| #2 | WP-01: Technik-Spike (App-Hülle, Leistungsprobe, CI, TestFlight-Ablauf) | 1–3 gescheitert (Einrichtung), **4 VALID** |
| #1 | Phase 0: Designdokumentation, Balance für Mission 1, Backlog | kein Bau |

Bauten 6 bis 12 enthielten in der App nichts Neues gegenüber Bau 5: Die
Simulation ist bis WP-11 nicht an die Darstellung angebunden.
