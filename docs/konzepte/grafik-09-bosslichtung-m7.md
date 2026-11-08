# Konzept: Kampfplatz Bosslichtung für Mission 7 (Grafik 09)

Status: **umgesetzt in 0.28.3** · Stil D-016 · Thread „Kampfplätze für Mission 5 und 6 malen"
Anlass: Mission 7 „Der Moorkönig“ (P3-4, 0.28.0) schließt Region 1 ab und lief bisher auf
der schlichten Karte. Vorgehen wie [Grafik 08](grafik-08-kampfplaetze-m6.md); hier steht
nur, was neu ist. Die Figur des Moorkönigs ist ein eigenes Paket (Thread „Moorkönig als 3D-Boss bauen“).

## Ziel

Die letzte Karte der Region soll sich wie das Reich des Bosses anfühlen und trotzdem eine
freie Lichtung bleiben. Der Weg läuft als Hufeisen um die Lichtung, und Türme dort treffen
den Boss von drei Seiten. Deshalb darf auf dem Feld nichts stehen, was wie ein Hindernis wirkt.

## Ort

| Was | Wahl |
|---|---|
| Ort | Die Lichtung im Reich des Moorkönigs |
| Rand-Deko (neues Blatt `blatt-bosslichtung.jpg`) | hohler Sumpfbaum mit Wurzelthron, Steinkreis, Geweih-Totem, Schlammbecken, Knochen mit rostiger Krone, Schilf |
| Licht | fahles, grünliches Sturmlicht mit Dunst; Lichtung hell |
| Boden | Moorgras aus Grafik 07 |

Abgrenzung: M5a ist Dämmerung mit toten Bäumen, M6a Nacht mit Mangroven. M7 hat
Sturmlicht und die Zeichen eines Königs (Krone, Thron, Totems).

## Weg

Aus `mission-07.json` (Vorschlag dieses Threads, D-081):
`[[-1,1.5],[1.5,1.5],[1.5,7.5],[14.5,7.5],[14.5,1.5],[17,1.5]]`.

## Architektur

Unverändert: `map_mission07_ground`, 24 × 13 Zellen, 3096 × 1677 px @3x, JPEG in
`App/Assets.xcassets/Maps`, Vertragseintrag mit `mission`. Prompts, Seeds und Schritte stehen in
`art/karten/ENTSTEHUNG.md`.

## Tests

- `test_weg_und_wald_liegen_richtig` deckt die Karte ab. Einmal rot gesehen, als der Vertrag auf
  `mission-05b.json` zeigte.
- App: `testEveryBundledMissionHasItsPaintedGround` umfasst `mission-07`.
- Szene mit Türmen, Festung und Gegnern angesehen.

## Risiken

- **Hindernis auf der Lichtung.** Der erste Übermal-Versuch setzte einen riesigen Baum
  in die Mitte. Darum sagt der Prompt ausdrücklich, dass die Lichtung leer ist.
- **Versionsnummer.** Der Moorkönig-Thread liefert parallel. Wer zuerst auf main kommt,
  bekommt 0.28.2, der andere die nächste Nummer. Der Moorkönig kam zuerst, deshalb 0.28.3.
