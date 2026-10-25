#!/usr/bin/env bash
# Prüft Architektur- und Sicherheitsregeln, die kein Compiler sieht.
# Läuft in der CI (Job „regeln") und lokal: scripts/regeln-pruefen.sh
# Jede Regel hier hat einen Grund in CLAUDE.md; wer eine lockert, trägt das
# dort und im Entscheidungsprotokoll ein.
set -uo pipefail
cd "$(dirname "$0")/.."

fehler=0
melde() { echo "✗ $1"; fehler=1; }

CORE=Packages/OddlingsCore/Sources

# Regel 1: Die Simulation importiert nur Foundation. Ein Apple-Rahmenwerk dort
# würde Linux-Tests und Wiederholbarkeit kosten.
treffer=$(grep -rnE '^\s*(@testable\s+)?import\s+' "$CORE" | grep -vE 'import\s+Foundation\s*$')
[ -n "$treffer" ] && melde "Simulation importiert mehr als Foundation:
$treffer"

# Regel 6: kein Uhrzeit-, Zufalls- oder Umgebungszugriff in der Simulation.
# Sonst laufen zwei Geräte mit gleichem Startwert auseinander.
treffer=$(grep -rnE 'Date\(|Date\.now|\.random\(|SystemRandomNumberGenerator|UUID\(|ProcessInfo|UserDefaults|URLSession|DispatchQueue|Thread\.' "$CORE")
[ -n "$treffer" ] && melde "Nicht deterministischer Zugriff in der Simulation:
$treffer"

# MVP ist offline (CLAUDE.md, Scope-Verbot): kein Netzcode in der App.
treffer=$(grep -rnE 'URLSession|NWConnection|URLRequest|WKWebView' App Packages 2>/dev/null)
[ -n "$treffer" ] && melde "Netzcode gefunden (MVP ist offline):
$treffer"

# Geheimnisse gehören in GitHub-Secrets, nie ins Repository.
treffer=$(git ls-files | grep -iE '\.(p8|p12|pfx|mobileprovision|cer|pem|key)$|(^|/)\.env$')
[ -n "$treffer" ] && melde "Schlüssel- oder Zertifikatsdatei eingecheckt:
$treffer"
treffer=$(git grep -nIE -- '-----BEGIN [A-Z ]*PRIVATE KEY-----|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|github_pat_[0-9A-Za-z_]{40,}' -- ':!scripts/regeln-pruefen.sh')
[ -n "$treffer" ] && melde "Möglicher Schlüssel im Quelltext:
$treffer"

# Abläufe: knappe Rechte, und fremde Actions nur an einem festen Commit.
# Eine Action an einer Marke wie @v3 kann ihr Besitzer jederzeit austauschen,
# und sie sieht die Secrets des Laufs.
for wf in .github/workflows/*.yml; do
  grep -qE '^permissions:' "$wf" || melde "$wf: keine Rechte auf oberster Ebene festgelegt"
  while IFS= read -r zeile; do
    ziel=$(echo "$zeile" | sed -E 's/.*uses:\s*//; s/\s+#.*//')
    case "$ziel" in
      actions/*|./*) ;;
      *@*) [[ "${ziel##*@}" =~ ^[0-9a-f]{40}$ ]] || melde "$wf: $ziel nicht an einen Commit gebunden" ;;
      *) melde "$wf: $ziel ohne Version" ;;
    esac
  done < <(grep -E '^\s*-?\s*uses:' "$wf")
done

# Dokumente verweisen aufeinander statt sich zu wiederholen. Ein toter Verweis
# macht eine Entscheidung unauffindbar.
python3 scripts/links-pruefen.py || melde "Tote Verweise oder doppelte Entscheidungsnummern (siehe oben)"

if [ "$fehler" -eq 0 ]; then
  echo "✓ Architektur- und Sicherheitsregeln eingehalten"
fi
exit "$fehler"
