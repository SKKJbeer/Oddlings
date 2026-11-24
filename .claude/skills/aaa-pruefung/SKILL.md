---
name: aaa-pruefung
description: Oddlings mit dem Auge eines Spiel- und Grafikdesigners prüfen – Stimmigkeit (Kamera, Licht, Maßstab, Malweise), Bewegung, Bauen, Lesbarkeit und Leveldesign – an echten Bildern statt am Code. Verwenden für ein Review, vor der Abnahme eines Grafik-, FX- oder Missionspakets und immer, wenn Steffen sagt, etwas wirke „nicht stimmig“, „billig“ oder „nicht perfekt“.
---

# AAA-Prüfung

Entstanden mit dem Review vom 16.11.2026 ([`docs/konzepte/aaa-review.md`](../../../docs/konzepte/aaa-review.md)).
Grundsatz: **ansehen, nicht vermuten.** Ein Befund ohne Bild oder Zahl ist keiner.

## 1 Bilder holen

1. Neuestes CI-Artefakt `simulator-probe` (bzw. `kontaktabzug`, sobald D-145 gebaut ist):
   ```bash
   gh api "repos/SKKJbeer/Oddlings/actions/artifacts?per_page=20" \
     --jq '.artifacts[] | select(.name=="simulator-probe") | [.id,.created_at] | @tsv' | head -3
   gh api repos/SKKJbeer/Oddlings/actions/artifacts/<id>/zip > probe.zip
   ```
   Im Scratchpad entpacken, nicht im Repo. Die Bilder sind hochkant gespeichert: um 90° drehen,
   auf 1100 px Breite verkleinern, bevor man sie ansieht (spart Kontext).
2. Vorschauen der Grafik-Threads unter `/mnt/project-files/` (grafik/, moorkoenig/, fx-02/,
   tuerme-in-der-welt/).
3. Missionsdateien auszählen (Weglänge, Ecken, Bauland, Wellen, Gegnermischung); das Skript
   steht im Review-Thread und ist in einer Minute nachgebaut: Bauland = Felder, deren
   Mitte mindestens `minDistanceFromPath` vom Weg liegt.

## 2 Prüfen, in dieser Reihenfolge

| Frage | Woran sehen | Regel |
|---|---|---|
| Eine Kamera? | Weg, Bäume, Türme, Figuren, Festung im selben Bild vergleichen | alles aus dem Blickwinkel im Asset-Vertrag |
| Ein Licht? | Schattenrichtung, Farbton von Turm und Boden | Lichtton aus `kampfplatzlicht.json` |
| Steht es oder schwebt es? | Gemaltes neben 3D-Teilen: hat es eine Schattenseite wie die Bäume, ist sein Schatten so dunkel wie deren, verdeckt Boden die Fußlinie? | Muster „Gemaltes in die 3D-Welt setzen“ im Skill `spielgrafik` (D-200 bis D-202); kein Sockel (D-196) |
| Ein Maßstab? | Höhen in Feldern aus `BattleStyle` | Festung > Boss > Turm > Panzerbestie > Plünderer > Flitzer |
| Eine Malweise? | Kontur und Schärfe von Figur zu Figur; Vektorformen auf der Karte | keine `SKShapeNode` in der Welt |
| Laufen | Blick in Laufrichtung auf senkrechten Stücken, Ecken, übereinanderliegende Gegner | Konzept A-1 |
| Bauen | Vorschau vor dem Kauf, Raster, Auftritt, Tafel auf Weg oder Festung, abgeschnittener Text | Konzept A-2 |
| Lesbarkeit | Gegner unter Effekten (Kontaktabzug „verdeckt“, höchstens 2 % der Bilder), Wellenvorschau, sichere Ränder | Säule 2, D-181 bis D-184 |
| Leveldesign | Frage, Moment, Bauinseln, mehr als ein Siegort, Wellenbogen | `aaa-leveldesign.md` |

## 3 Aufschreiben

- Jeder Befund: Nummer, Gewicht (A jede Sekunde, B jedem Spieler mehrmals, C Kennern),
  Beleg (Bild oder Zahl), Ursache (Datei, Paket). Gutes ausdrücklich nennen, damit es
  beim Umbau bleibt.
- Markierte Bilder (rote Kreise und Zahlen, Legende darunter) nach `art/review/`, Herkunft
  in `art/review/README.md`.
- Maßnahmen als Pakete mit Abhängigkeiten in die Roadmap; Entscheidungen als Karten an
  Steffen (D-Nummer aus dem Block des Threads, Karte im selben Zug an den Coordinator
  melden, Zeile unter „Wartet auf Steffen“).

## 4 Fallen

- Die Bilder des Probelaufs zeigen die Vorführung im dreifachen Tempo: Bewegungsfehler
  (Gleiten, Spiegeln) sieht man dort nur im Clip, nicht im Standbild.
- Eine Vorschau auf freigestelltem Hintergrund beweist nichts. Immer auf dem Kampfplatz,
  in Spielgröße, mit Nachbarn.
- Ein Befund aus dem Code („die Funktion fehlt“) wird am Bild bestätigt, bevor er im
  Review steht. 07-ui-ux.md versprach eine Turmvorschau, die nie gebaut wurde: Das sah
  man erst am Bild.
