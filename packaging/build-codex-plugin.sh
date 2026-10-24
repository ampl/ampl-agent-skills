#!/usr/bin/env bash
# Builds the OpenAI/Codex plugin ZIP (Codex layout) from skill/ into dist/.
# Usage: packaging/build-codex-plugin.sh <version-tag>
set -euo pipefail
tag="$1"
root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/dist/codex/ampl"
rm -rf "$root/dist/codex"
mkdir -p "$out/.codex-plugin" "$out/skills" "$out/assets"
cp "$root/packaging/codex/plugin.json" "$out/.codex-plugin/plugin.json"
cp -r "$root/skill" "$out/skills/ampl-skill"
cp "$root/assets/icon.png" "$out/assets/icon.png"
cp "$root/README.md" "$out/README.md"
[ -f "$root/LICENSE" ] && cp "$root/LICENSE" "$out/LICENSE"
(cd "$out" && zip -qr "$root/dist/ampl-codex-plugin-$tag.zip" .)
echo "dist/ampl-codex-plugin-$tag.zip"
