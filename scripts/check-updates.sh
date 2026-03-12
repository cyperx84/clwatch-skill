#!/usr/bin/env bash
set -euo pipefail

# check-updates.sh
# Run at session start. Silent if nothing changed. Prints update summary if changes found.
# Exit 0 = current (silent). Exit 1 = updates available (agent should run tier2-merge.sh).

# Bail silently if clwatch is not installed
command -v clwatch >/dev/null 2>&1 || exit 0

RESULT=$(clwatch diff --json 2>/dev/null) || exit 0

# Parse and display updates
UPDATES=$(echo "$RESULT" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    # Handle both {updates: [...]} wrapper and bare array
    if isinstance(data, dict):
        items = data.get('updates', [])
    elif isinstance(data, list):
        items = data
    else:
        sys.exit(0)

    updates = [r for r in items if r.get('status', r.get('scope', '')) in ['updated', 'new', 'stale', 'small', 'medium', 'large']]
    if not updates:
        sys.exit(0)

    for u in updates:
        tool = u.get('tool', 'unknown')
        prev = u.get('previous_version', u.get('current', 'new'))
        curr = u.get('current_version', u.get('latest', '?'))
        scope = u.get('scope', 'unknown')
        breaking = ' BREAKING' if u.get('breaking', False) else ''
        print(f'  {tool}: {prev} -> {curr} [{scope}]{breaking}')
except (json.JSONDecodeError, KeyError):
    sys.exit(0)
" 2>/dev/null) || exit 0

if [ -z "$UPDATES" ]; then
  exit 0
fi

echo "clwatch: updates available"
echo "$UPDATES"
echo ""
echo "Run: bash <skill-dir>/scripts/tier2-merge.sh <tool-slug>"
exit 1
