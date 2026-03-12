# clwatch Skill

Changelog intelligence for AI coding agents. Detects new releases at session start and merges updates into local reference files so your agent always has current tool documentation.

## What it does

```
Session starts
    │
    ▼
check-updates.sh          ← silent if up-to-date
    │
    ├── No changes → continue normally
    │
    └── Changes detected
         │
         ▼
    tier2-merge.sh <tool>  ← fetches delta + payload
         │
         ▼
    LLM merge prompt      ← rendered automatically
         │
         ▼
    Agent merges ref file ← applies 8 merge rules
         │
         ▼
    clwatch ack <tool> <v> ← mark as seen
```

### What it tracks

- New features, commands, flags, env vars
- Deprecations (with migration paths)
- Breaking changes (requires user confirmation before merge)
- Version compatibility updates

## Requirements

- `clwatch` CLI v1.0+ ([install](https://github.com/cyperx84/clwatch#install))
- Bash shell

## Install

### Automatic installer

```bash
bash scripts/install-skill.sh              # install to all detected agents
bash scripts/install-skill.sh --agent claude   # Claude Code only
bash scripts/install-skill.sh --agent gemini   # Gemini CLI only
bash scripts/install-skill.sh --agent openclaw # OpenClaw only
bash scripts/install-skill.sh --scope project  # project-local (not user-wide)
```

Supported agent locations:
- **Claude Code (user):** `~/.claude/skills/clwatch/`
- **Claude Code (project):** `.claude/skills/clwatch/`
- **Gemini CLI:** `~/.gemini/skills/clwatch/`
- **OpenClaw:** `~/.openclaw/skills/clwatch/`

### Manual install

Copy the entire `clwatch-skill/` directory to your agent's skill location:

```bash
# Claude Code
cp -r clwatch-skill/ ~/.claude/skills/clwatch/

# Gemini CLI
cp -r clwatch-skill/ ~/.gemini/skills/clwatch/

# OpenClaw
cp -r clwatch-skill/ ~/.openclaw/skills/clwatch/
```

## Scripts

### `scripts/check-updates.sh`

Run at session start. Silent if nothing changed. Prints update summary if changes found.

```bash
# Exit 0 = all current, no output
# Exit 1 = updates available
bash scripts/check-updates.sh
```

Output when updates found:
```
📦 claude-code: 2.1.74 → 2.1.75 [medium]
📦 opencode: 1.2.24 → 1.3.0 [small]
```

Use in agent hooks or session-start scripts.

### `scripts/tier2-merge.sh`

Fetches the latest delta for a tool and renders a complete merge prompt. The agent feeds this prompt to its LLM to produce an updated reference file.

```bash
# Render merge prompt for claude-code (output goes to stdout)
bash scripts/tier2-merge.sh claude-code

# With explicit reference file path
bash scripts/tier2-merge.sh claude-code references/claude-code-features.md
```

**Merge flow:**
1. Fetches delta via `clwatch refresh <tool> --diff-only`
2. Fetches full payload via `clwatch refresh <tool> --json`
3. Discovers reference file (or uses `templates/new-reference.md`)
4. Substitutes placeholders in `templates/merge-prompt.md`
5. Outputs ready-to-use merge prompt

### `scripts/install-skill.sh`

Multi-agent installer.

```bash
# Install to all detected agents
bash scripts/install-skill.sh

# Specific agent
bash scripts/install-skill.sh --agent claude
bash scripts/install-skill.sh --agent gemini
bash scripts/install-skill.sh --agent openclaw

# Project scope (creates .claude/skills/clwatch/ in cwd)
bash scripts/install-skill.sh --scope project
```

## Templates

### `templates/merge-prompt.md`

The merge prompt template. When rendered and given to an LLM, it produces a complete updated reference file. Contains:

- Open instruction: "Output ONLY the updated file content"
- Full delta JSON
- Current reference file content
- All 8 merge rules
- Close instruction: no preamble or explanation

**Merge rules:**
1. Preserve existing structure and formatting
2. Add new items to appropriate sections
3. Update existing items that changed
4. Mark deprecated items with `@deprecated` + version
5. Mark breaking changes with ⚠️ icon + version
6. Don't delete unless superseded by a replacement
7. Don't reformat the entire file
8. Only surface agent-relevant changes

### `templates/new-reference.md`

Template for creating a reference file when none exists yet. Used on first-time setup.

## Configuration

Create `.clwatch.json` in your workspace root:

```json
{
  "schema": "clwatch.config.v1",
  "tools": [
    "claude-code",
    "codex-cli",
    "gemini-cli",
    "opencode",
    "openclaw"
  ],
  "manifestUrl": "https://changelogs.info/api/refs/manifest.json",
  "referenceDir": "references/",
  "tier2Threshold": "medium",
  "notifyOnBreaking": true,
  "stateFile": "~/.clwatch/state.json"
}
```

| Field | Default | Description |
|---|---|---|
| `tools` | all 5 | Which tools to track |
| `manifestUrl` | changelogs.info | Where to fetch manifests |
| `referenceDir` | `references/` | Where reference files live |
| `tier2Threshold` | `medium` | Minimum scope to trigger Tier 2 (`small`, `medium`, `large`) |
| `notifyOnBreaking` | `true` | Alert on breaking changes before merging |
| `stateFile` | `~/.clwatch/state.json` | Local state tracking file |

## Agent integration examples

### Claude Code

Add to `.claude/agents/changelog-watcher.md`:

```markdown
## Agent: Changelog Watcher

At the start of each session:
1. Run `bash .claude/skills/clwatch/scripts/check-updates.sh`
2. If updates found, run `tier2-merge.sh` for each updated tool
3. Review the output — if breaking changes, ask user before merging
4. Write the merged content back to the reference file
5. Run `clwatch ack <tool> <version>`
```

### OpenClaw

The skill auto-installs to `~/.openclaw/skills/clwatch/`. OpenClaw's agent system picks it up automatically and runs `check-updates.sh` at session start if configured.

### Custom agent

Any agent that can run shell scripts can use this skill:

```bash
# In your agent's session-start hook
UPDATES=$(bash /path/to/skill/scripts/check-updates.sh 2>&1)
if [ $? -ne 0 ]; then
  # Parse the output and run tier2-merge for each tool
  echo "$UPDATES" | while read -r line; do
    TOOL=$(echo "$line" | grep -oP '📦 \K\S+')
    bash /path/to/skill/scripts/tier2-merge.sh "$TOOL" | \
      your-agent-process --prompt - --output "references/${TOOL}-features.md"
    clwatch ack "$TOOL" "$(echo "$line" | grep -oP '→ \K\S+')"
  done
fi
```

## Troubleshooting

### `clwatch: command not found`

Install clwatch first:
```bash
brew install cyperx84/tap/clwatch
# or
npm install -g clwatch
```

### `manifest returned HTTP 404`

Set a custom manifest URL:
```bash
export CLWATCH_MANIFEST_URL="https://changelogs.info/api/refs/manifest.json"
```

### Reference file not found

Run `clwatch init` to scaffold the workspace:
```bash
clwatch init --dir references/
```

### Merge prompt looks wrong

Verify the delta JSON is valid:
```bash
clwatch refresh <tool> --diff-only | python3 -m json.tool
```

## License

MIT
