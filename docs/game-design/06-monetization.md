# 06 – Monetarisierung

**Nicht Teil des MVP. Kein Code vor Phase 5.**

## Leitplanken [ENTSCHIEDEN]

- Free-to-play, fair.
- Primär Kosmetik: Turm-Skins, Effekte, Festungsvarianten, Avatar-Kosmetik,
  Embleme, Banner, Titel; später ggf. Erweiterungen.
- Ausgeschlossen: Pay-to-win, kaufbares Gold, Energie- und Wartesperren,
  Lootboxen zum Start, aufdringliche Werbung im ersten Release.
- Reihenfolge: Spaß nachweisen → Vertical Slice → echte Spieler → Wiederkehr
  messen → dann erst Monetarisierung.

## Kritischer Hinweis [VORSCHLAG zur Prüfung in Phase 5]

Rein kosmetische Einnahmen tragen erfahrungsgemäß erst bei großer Spielerzahl.
Ein kleines, gutes Einzelspieler-TD erreicht diese Zahl oft nicht. Deshalb in
Phase 5 neben Kosmetik-F2P auch prüfen:

- **Kostenlos anspielen, Vollversion einmalig kaufen** (z. B. erste Region frei).
  Fair, einfach, passt zu offline. Zählora hat sich aus ähnlichen Gründen für
  Einmalkäufe statt Abo entschieden (PulseMeter, `docs/04-monetarisierung.md`).
- **Bezahlte Erweiterungsregionen** zusätzlich zur kostenlosen Kampagne.

Beides verträgt sich mit den Leitplanken. Entscheidung erst mit Daten aus Phase 4.

## Was die Architektur jetzt schon tun muss

Nichts außer: Kosmetik muss sich später von Spielwerten trennen lassen. Das ist
erfüllt, wenn Darstellung (Skin) und Konfiguration (Werte) getrennte Daten sind –
was die Architektur ohnehin vorsieht.
