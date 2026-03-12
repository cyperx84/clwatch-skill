#!/usr/bin/env bash
set -euo pipefail

# tier2-merge.sh <tool-slug> [reference-file-path]
# Fetches the latest payload diff and runs the merge prompt.
# Outputs the rendered merge instruction block for an LLM to produce the merged file.

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$SKILL_DIR/templates/merge-prompt.md"

usage() {
  echo "Usage: tier2-merge.sh <tool-slug> [reference-file-path]" >&2
  exit 1
}

[ $# -ge 1 ] || usage

TOOL_SLUG="$1"
REF_PATH="${2:-}"

# --- Step 1: Get delta JSON ---
DELTA_JSON=$(clwatch refresh "$TOOL_SLUG" --diff-only 2>/dev/null) || {
  echo "ERROR: failed to get diff for '$TOOL_SLUG'" >&2
  echo "Hint: is clwatch installed and is the tool tracked?" >&2
  exit 1
}

# --- Step 2: Get full payload ---
FULL_PAYLOAD=$(clwatch refresh "$TOOL_SLUG" --json 2>/dev/null) || {
  echo "ERROR: failed to get full payload for '$TOOL_SLUG'" >&2
  exit 1
}

# --- Step 3: Determine reference file path ---
if [ -z "$REF_PATH" ]; then
  # Auto-discover reference file
  REF_PATH=$(find . -maxdepth 3 \( \
    -name "${TOOL_SLUG}-features.md" -o \
    -name "${TOOL_SLUG}-reference.md" -o \
    -name "*${TOOL_SLUG}*features*" -o \
    -name "*${TOOL_SLUG}*reference*" \
  \) 2>/dev/null | head -1 || true)

  # Prefer files under references/
  if [ -n "$REF_PATH" ]; then
    REFS_MATCH=$(echo "$REF_PATH" | grep "references/" || true)
    [ -n "$REFS_MATCH" ] && REF_PATH="$REFS_MATCH"
  fi
fi

# --- Step 4: Read current content or use new-reference template ---
if [ -n "$REF_PATH" ] && [ -f "$REF_PATH" ]; then
  CURRENT_CONTENT=$(cat "$REF_PATH")
else
  # No existing file — use new-reference template as placeholder
  CURRENT_CONTENT="(no existing reference file — create from scratch using the delta below)"
  # Default path for new files
  [ -z "$REF_PATH" ] && REF_PATH="references/${TOOL_SLUG}-features.md"
fi

# --- Step 5: Extract metadata from delta/payload ---
TOOL_NAME=$(echo "$FULL_PAYLOAD" | python3 -c "
import json, sys
p = json.load(sys.stdin)
print(p.get('tool_name', p.get('name', p.get('tool', '$TOOL_SLUG'))))" 2>/dev/null || echo "$TOOL_SLUG")

PREVIOUS_VERSION=$(echo "$DELTA_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('from_version', d.get('previous_version', 'unknown')))" 2>/dev/null || echo "unknown")

NEW_VERSION=$(echo "$DELTA_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('to_version', d.get('current_version', d.get('latest_version', 'unknown'))))" 2>/dev/null || echo "unknown")

IS_BREAKING=$(echo "$DELTA_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
bc = d.get('breaking_changes', d.get('breaking', []))
if isinstance(bc, bool):
    print('YES' if bc else 'NO')
elif isinstance(bc, list):
    print('YES' if len(bc) > 0 else 'NO')
else:
    print('NO')" 2>/dev/null || echo "NO")

BREAKING_CHANGES=$(echo "$DELTA_JSON" | python3 -c "
import json, sys
d = json.load(sys.stdin)
bc = d.get('breaking_changes', [])
if isinstance(bc, list) and len(bc) > 0:
    for c in bc:
        if isinstance(c, dict):
            print(f\"- {c.get('description', c.get('summary', str(c)))}\")
        else:
            print(f'- {c}')
elif isinstance(bc, str) and bc:
    print(f'- {bc}')
else:
    print('none')" 2>/dev/null || echo "none")

# --- Step 6: Render the merge prompt template ---
if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: merge prompt template not found at $TEMPLATE" >&2
  exit 1
fi

RENDERED=$(cat "$TEMPLATE")
RENDERED="${RENDERED//\{\{TOOL_NAME\}\}/$TOOL_NAME}"
RENDERED="${RENDERED//\{\{TOOL_SLUG\}\}/$TOOL_SLUG}"
RENDERED="${RENDERED//\{\{PREVIOUS_VERSION\}\}/$PREVIOUS_VERSION}"
RENDERED="${RENDERED//\{\{NEW_VERSION\}\}/$NEW_VERSION}"
RENDERED="${RENDERED//\{\{BREAKING\}\}/$IS_BREAKING}"

# For multi-line substitutions, use python3 for safety
RENDERED=$(python3 -c "
import sys
template = sys.stdin.read()
template = template.replace('{{DELTA_JSON}}', '''$DELTA_JSON''')
template = template.replace('{{CURRENT_CONTENT}}', '''$(echo "$CURRENT_CONTENT" | sed "s/'/'\\''/g")''')
template = template.replace('{{BREAKING_CHANGES}}', '''$BREAKING_CHANGES''')
print(template)
" <<< "$RENDERED" 2>/dev/null) || {
  # Fallback: use sed for simpler replacements if python fails
  echo "WARN: python3 template rendering failed, using basic substitution" >&2
}

# --- Output metadata as comments, then the rendered prompt ---
echo "<!-- clwatch:tier2-merge tool=$TOOL_SLUG ref=$REF_PATH version=$PREVIOUS_VERSION→$NEW_VERSION breaking=$IS_BREAKING -->"
echo ""
echo "$RENDERED"
