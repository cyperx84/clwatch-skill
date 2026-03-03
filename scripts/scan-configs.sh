#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG_FILE="${1:-$ROOT_DIR/cliwatch-config.example.json}"

[ -f "$CFG_FILE" ] || { echo "config missing: $CFG_FILE"; exit 1; }

mapfile -t patterns < <(jq -r ".configPaths[]" "$CFG_FILE")

detect_harness() {
  local file="$1"
  local base
  base="$(basename "$file" | tr "[:upper:]" "[:lower:]")"
  case "$base" in
    claude.md|settings.json) echo "claude-code" ;;
    .cursorrules) echo "cursor" ;;
    *.aider*|.aider.conf.yml) echo "aider" ;;
    *openclaw*|gateway*.yml|gateway*.yaml) echo "openclaw" ;;
    *) echo "unknown" ;;
  esac
}

echo "## cliwatch config scan"
for pat in "${patterns[@]}"; do
  for f in $pat; do
    [ -f "$f" ] || continue
    h="$(detect_harness "$f")"
    echo "- [$h] $f"
  done
done
