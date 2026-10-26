# Herkunft der Schriften

Entschieden in D-032 (Steffen, 25.10.2026). Beide stehen unter der SIL Open
Font License 1.1; die Lizenztexte liegen daneben und gehen mit in die App.

| Datei | Schrift | Lizenz | Quelle | SHA-256 |
|---|---|---|---|---|
| `LilitaOne-Regular.ttf` | Lilita One 1.002 (Juan Montoreano) | `OFL-lilita-one.txt` | fonts.gstatic.com/s/lilitaone/v17 (Google Fonts) | `26ad0d77404141ff7af714353cdf23c980841829dd270fc26e6c2dfcf654bd6d` |
| `Nunito-Bold.ttf` | Nunito 3.602, Gewicht 700 | `OFL-nunito.txt` | fonts.gstatic.com/s/nunito/v32 (Google Fonts) | `1a025dfce6e6e03bbe31ba82277ec5ed96df8b8dd58b3df6267269490b90b1dc` |
| `Nunito-ExtraBold.ttf` | Nunito 3.602, Gewicht 800 | `OFL-nunito.txt` | fonts.gstatic.com/s/nunito/v32 (Google Fonts) | `c5776505c7b3df3c3ca763477b795d6bbc6517760bede0462ab77d1fb44954a6` |

Geladen am 25.10.2026 als feste TTF-Dateien (keine variable Schrift, kein
WOFF2: iOS liest WOFF2 nicht). Die App lädt nichts aus dem Netz; die Dateien
werden beim Start aus dem eigenen Bündel angemeldet (`AppFonts.swift`).

Eine neue Schriftdatei braucht eine Zeile hier und eine Lizenzdatei;
`scripts/regeln-pruefen.sh` hält das fest.
