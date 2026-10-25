#!/usr/bin/env bash
# Swift für Cloud-Sitzungen (Linux, ohne Xcode). OddlingsCore braucht nur
# Foundation, also laufen die Simulationstests hier genauso wie auf dem Mac.
# Die App selbst (SwiftUI, SpriteKit) baut nur die macOS-CI.
#
# Aufruf ohne Argument: installieren, falls noch nicht da. Der Haken in
# .claude/settings.json startet das im Hintergrund, damit die Sitzung nicht
# eine Minute auf den Download wartet. Fortschritt: /tmp/swift-linux.log
set -euo pipefail
VERSION=6.2
ZIEL=/opt/swift
[ "$(uname)" = Linux ] || exit 0
if command -v swift >/dev/null 2>&1; then exit 0; fi
if [ -x "$ZIEL/usr/bin/swift" ]; then
  ln -sf "$ZIEL"/usr/bin/swift* /usr/local/bin/ 2>/dev/null || true
  exit 0
fi
. /etc/os-release
case "$VERSION_ID" in
  24.04) PLATTFORM=ubuntu2404; NAME=ubuntu24.04 ;;
  22.04) PLATTFORM=ubuntu2204; NAME=ubuntu22.04 ;;
  *) echo "Kein Swift-Paket für $PRETTY_NAME hinterlegt." >&2; exit 1 ;;
esac
URL="https://download.swift.org/swift-$VERSION-release/$PLATTFORM/swift-$VERSION-RELEASE/swift-$VERSION-RELEASE-$NAME.tar.gz"
mkdir -p "$ZIEL.tmp"
curl -sSfL "$URL" | tar xz --strip-components=1 -C "$ZIEL.tmp"
mv "$ZIEL.tmp" "$ZIEL"
ln -sf "$ZIEL"/usr/bin/swift* /usr/local/bin/
swift --version
