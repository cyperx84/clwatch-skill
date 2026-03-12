#!/usr/bin/env bash
set -euo pipefail

# install-skill.sh [--scope project|user] [--agent claude|codex|gemini|openclaw|all]
# Installs or symlinks the clwatch skill to the correct agent location.

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCOPE="user"
AGENT="all"

usage() {
  cat <<EOF
Usage: install-skill.sh [--scope project|user] [--agent claude|codex|gemini|openclaw|all]

Options:
  --scope   project  Install into current project directory
            user     Install into user home directory (default)
  --agent   claude   Claude Code (~/.claude/skills/clwatch/ or .claude/skills/clwatch/)
            codex    Codex CLI (~/.codex/skills/clwatch/)
            gemini   Gemini CLI (~/.gemini/skills/clwatch/)
            openclaw OpenClaw (~/.openclaw/skills/clwatch/)
            all      All supported agents (default)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --agent) AGENT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

link_skill() {
  local target="$1"
  local target_dir
  target_dir="$(dirname "$target")"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$SKILL_SRC" ]; then
      echo "  already linked: $target"
      return
    fi
    rm "$target"
  fi

  mkdir -p "$target_dir"
  ln -sf "$SKILL_SRC" "$target"
  echo "  linked: $target -> $SKILL_SRC"
}

install_agent() {
  local agent="$1"
  case "$agent" in
    claude)
      if [ "$SCOPE" = "project" ]; then
        link_skill ".claude/skills/clwatch"
      else
        link_skill "$HOME/.claude/skills/clwatch"
      fi
      ;;
    codex)
      if [ "$SCOPE" = "project" ]; then
        link_skill ".codex/skills/clwatch"
      else
        link_skill "$HOME/.codex/skills/clwatch"
      fi
      ;;
    gemini)
      if [ "$SCOPE" = "project" ]; then
        link_skill ".gemini/skills/clwatch"
      else
        link_skill "$HOME/.gemini/skills/clwatch"
      fi
      ;;
    openclaw)
      if [ "$SCOPE" = "project" ]; then
        link_skill ".openclaw/skills/clwatch"
      else
        link_skill "$HOME/.openclaw/skills/clwatch"
      fi
      ;;
    *)
      echo "Unknown agent: $agent" >&2
      return 1
      ;;
  esac
}

echo "Installing clwatch skill (scope=$SCOPE, agent=$AGENT)"
echo ""

if [ "$AGENT" = "all" ]; then
  for a in claude codex gemini openclaw; do
    echo "[$a]"
    install_agent "$a"
  done
else
  echo "[$AGENT]"
  install_agent "$AGENT"
fi

echo ""
echo "Done. Skill source: $SKILL_SRC"
