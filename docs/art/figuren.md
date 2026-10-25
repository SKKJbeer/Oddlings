# Figuren und Türme: Konzeptblätter

Status: **[VORSCHLAG]** · Stil nach D-016, Farben nach
[art-direction.md](art-direction.md#farbwelt). Jede Figur wird erst hier
beschrieben, dann gemalt. Prompt, Seed und verworfene Fassungen stehen in
`art/<bereich>/ENTSTEHUNG.md`.

Ein Blatt nennt: Rolle im Spiel, Persönlichkeit in einem Satz, Silhouette (was
man einfarbig erkennt), Farben, Bewegung in der Szene und was das Bild
**nicht** zeigen darf.

## Türme (MVP)

### Wachturm `tower_watch`
- **Rolle:** zuverlässiger Einzelschaden, der „Grundturm".
- **Persönlichkeit:** solide, ein bisschen stolz auf sich.
- **Silhouette:** runder Steinturm, Holzplattform, Armbrust, rote Fahne.
- **Farben:** Grau, warmes Holz, Rot.
- **Bewegung:** Fahne weht (leichtes Schwingen), Rückstoß beim Schuss.
- **Nicht:** Kanonen, Feuer, Leuchtfarben (die gehören Blitz und Sporen).

### Blitzturm `tower_lightning`
- **Rolle:** Schaden gegen Gruppen, Kettenblitz.
- **Persönlichkeit:** nervös, knisternd, immer geladen.
- **Silhouette:** schlanker Turm mit Kupferring, schwebender Kristall oben.
- **Farben:** Schiefergrau, Kupfer, leuchtendes Blau. Funken blau, nie orange
  (Rohbild hatte orange Funken, werden umgefärbt).
- **Bewegung:** Kristall schwebt auf und ab und dreht sich langsam; leuchtet vor
  dem Schuss auf.
- **Nicht:** Grün, Feuer.

### Sporenturm `tower_spore`
- **Rolle:** Kontrolle, verlangsamt alle in Reichweite.
- **Persönlichkeit:** gemütlich, verschlafen, harmlos aussehend.
- **Silhouette:** großer Pilzhut auf dickem Stiel mit Tür, Steinsockel.
- **Farben:** Violett, Creme, leuchtendes Grün in den Flecken.
- **Bewegung:** Hut „atmet" (Squash) im Pulstakt, Sporenring breitet sich aus.
- **Nicht:** Blau, Totenköpfe, Giftsymbole (es ist Verlangsamung, kein Gift).

## Gegner (MVP)

### Plünderer `enemy_raider`
- **Rolle:** Referenzgegner, mittlere Geschwindigkeit und Zähigkeit.
- **Persönlichkeit:** gierig, frech, eher Dieb als Krieger.
- **Silhouette:** klein, Kapuze, Beutesack über der Schulter.
- **Farben:** Grünhaut, braunes Leder.
- **Bewegung:** gleichmäßiges Hüpfen, Sack schwingt nach.

### Flitzer `enemy_runner`
- **Rolle:** schnell, wenig Leben.
- **Persönlichkeit:** hektisch, übermütig.
- **Silhouette:** schmal, lange Ohren, stark vorgebeugt, wehender Schal.
- **Farben:** Orange, Rot (Warnfarbe für „schnell").
- **Bewegung:** schnelles, flaches Hüpfen, starkes Vorkippen.

### Panzerbestie `enemy_brute` (MVP optional)
- **Rolle:** langsam, sehr zäh.
- **Persönlichkeit:** stur, schwerfällig.
- **Silhouette:** breit, Hörner, Hauer, Panzerplatten.
- **Farben:** Eisen, Dunkelbraun.
- **Bewegung:** langsames, schweres Stampfen mit Bildschütteln beim Auftreten
  (sehr schwach, nur bei Nahsicht).

## Festung `fortress`
- Torhaus aus Stein und dunklem Holz, zwei rote Banner. Steht am rechten Rand
  am Wegende. Bebt bei `enemyLeaked`.

## Spätere Phasen: nur Konzept, nicht im Spiel

Nach dem Scope-Verbot werden diese Figuren nicht gebaut, bis Steffen die
Phase freigibt. Konzeptbilder helfen aber, früh zu sehen, ob alles zusammen
eine Welt ergibt. Sie liegen unter `art/konzept/`, nie im Atlas.

| Figur | Phase | Idee für das Bild |
|---|---|---|
| Zwergenbank | 2 | gedrungenes Steinhaus mit Goldkessel und Kran, Zwerg mit Lupe am Tresen; Farben Stein, Messing, warmes Gold (keine Münzen mit Währungszeichen) |
| Schattenflieger | später | Fledermaus-Kobold mit Laterne; Violett-Schwarz, damit er sich vom Boden abhebt |
| Völker | 3+ | je ein Porträt im Avatar-Stil der Fortress-Linie, Grundlage [03](../game-design/03-races-and-avatar.md) |
