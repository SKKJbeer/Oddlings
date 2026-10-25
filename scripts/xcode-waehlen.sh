#!/usr/bin/env bash
# Apple nimmt seit 28.04.2026 nur Uploads an, die mit dem iOS-26-SDK gebaut
# sind. Das Standard-Xcode des Läufers ist älter, übersetzt trotzdem sauber und
# wird erst beim Hochladen abgelehnt. Deshalb das neueste Xcode wählen und
# abbrechen, wenn es keins ab 26 gibt. CI und TestFlight nutzen dasselbe Skript,
# damit der Simulatorbau mit demselben SDK prüft, das später hochgeladen wird.
set -euo pipefail
beste=""; bestev=""
for app in /Applications/Xcode*.app; do
  [ -d "$app" ] || continue
  v=$(defaults read "$app/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo 0)
  if [ -z "$bestev" ] || [ "$(printf '%s\n%s\n' "$bestev" "$v" | sort -V | tail -1)" = "$v" ]; then
    bestev="$v"; beste="$app"
  fi
done
[ -n "$beste" ] || { echo "::error::Kein Xcode auf dem Läufer."; exit 1; }
if [ "${bestev%%.*}" -lt 26 ]; then
  echo "::error::Neuestes Xcode ist $bestev, Apple verlangt 26 oder neuer. In runs-on auf ein neueres macOS-Bild wechseln."
  exit 1
fi
sudo xcode-select -s "$beste/Contents/Developer"
echo "Gewählt: $beste ($bestev)"
xcodebuild -version
