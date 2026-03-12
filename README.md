# clwatch Skill

Changelog intelligence for AI coding tools. Detects new releases at session start and merges updates into local reference files.

## Requirements

- `clwatch` CLI ([install](https://changelogs.info/cli))

## Install

Copy this skill into your agent's skill directory:

```bash
# Claude Code / OpenClaw
cp -r clwatch-skill/ .claude/skills/clwatch/
```

## Setup

```bash
cp clwatch-config.example.json clwatch-config.json
# Edit tools list and paths to match your setup
```

## How it works

**Tier 1 — Fast detection** runs at every session start:
- `clwatch diff --json` checks for updates across tracked tools
- Small-scope changes (version bumps) are patched directly
- Medium/large changes queue a Tier 2 refresh

**Tier 2 — Deep refresh** runs only when needed:
- Fetches full payload from `changelogs.info/api/refs/<tool>.json`
- LLM merges delta into your local reference file
- Breaking changes are surfaced to the user before applying

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Skill definition and workflow spec |
| `clwatch-config.example.json` | Configuration template |
| `templates/merge-prompt.md` | LLM merge prompt template |
| `templates/new-reference.md` | Template for new reference files |
| `scripts/check-updates.sh` | Legacy update checker |
| `scripts/scan-configs.sh` | Legacy config scanner |

## Payload schema

Uses `clwatch.payload.v1` JSON from:
- Manifest: `https://changelogs.info/api/refs/manifest.json`
- Per-tool: `https://changelogs.info/api/refs/<tool>.json`

## Configuration

See `clwatch-config.example.json` for all options:

- `tools` — tool slugs to track
- `referenceDir` — where reference files are stored (default: `references/`)
- `tier2Threshold` — minimum scope to trigger deep refresh (`small`, `medium`, `large`)
- `notifyOnBreaking` — always prompt user for breaking changes
- `stateFile` — version tracking state file path
