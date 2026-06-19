#!/usr/bin/env bash
# Generates the full macOS AppIcon set from a single 1024px render.
set -euo pipefail

cd "$(dirname "$0")/.."
ICONSET="Sources/Resources/Assets.xcassets/AppIcon.appiconset"
BASE="$ICONSET/icon_1024.png"
STYLE="${1:-warm}"   # dark | vibrant | indigo | light | warm

echo "Rendering 1024px master icon (style: $STYLE)…"
swift Tools/generate_icon.swift "$BASE" "$STYLE"

for size in 16 32 64 128 256 512; do
  echo "Deriving ${size}px…"
  sips -z "$size" "$size" "$BASE" --out "$ICONSET/icon_${size}.png" >/dev/null
done

echo "Done. Icon set written to $ICONSET"
