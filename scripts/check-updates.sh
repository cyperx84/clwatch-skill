#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_FILE="$ROOT_DIR/.cliwatch-state.json"
CFG_FILE="${1:-$ROOT_DIR/cliwatch-config.example.json}"

[ -f "$CFG_FILE" ] || { echo "config missing: $CFG_FILE"; exit 1; }

LAST_CHECK="$(jq -r ".lastCheck // empty" "$STATE_FILE" 2>/dev/null || true)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

WATCH_HARNESSES=$(jq -r ".watchHarnesses[]" "$CFG_FILE")

echo "## cliwatch update check"
echo "time: $NOW"
[ -n "$LAST_CHECK" ] && echo "since: $LAST_CHECK"

echo "\nwatched harnesses:"
while IFS= read -r h; do
  echo "- $h"
done <<< "$WATCH_HARNESSES"

jq -n --arg now "$NOW" "{lastCheck:$now}" > "$STATE_FILE"
echo "\nstate updated: $STATE_FILE"
