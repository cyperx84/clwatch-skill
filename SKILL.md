---
name: clwatch
description: "Monitor AI coding tool changelogs and alert when updates affect your configs. Checks for breaking changes, deprecated features, and recommended actions across all tracked agent harnesses."
metadata:
  openclaw:
    emoji: "📡"
    requires:
      bins: ["node", "jq"]
---

# clwatch — Changelog Monitor Skill

## Overview

Monitors changelogs.info release data and cross-references against your local configs to detect:
- Breaking changes that need attention
- Deprecated features with migration paths
- New recommended features to enable
- Model compatibility changes

## Usage

The skill runs as a cron job (configurable frequency). On each run it:
1. Checks for new releases across all tracked harnesses
2. Scans configured paths for local config files
3. Cross-references changes against your configs
4. Reports findings via configured channel

## Configuration

Set these in your OpenClaw agent workspace:

**clwatch-config.json:**
```json
{
  "watchHarnesses": ["claude-code", "aider", "cursor", "openclaw"],
  "configPaths": [
    "~/.claude/settings.json",
    "~/projects/**/CLAUDE.md",
    "~/projects/**/.cursorrules",
    "~/projects/**/.aider.conf.yml"
  ],
  "alertLevel": "warning",
  "checkFrequency": "daily"
}
```

## Cron Setup

Add to OpenClaw cron:
- **Schedule:** daily at 8am local
- **Task:** Check for harness updates affecting my configs
- **Delivery:** announce to configured channel

## Alert Levels

- **critical**: Breaking changes affecting your setup
- **warning**: Deprecated features, recommended migrations
- **info**: New features, minor updates

## Tracked Harnesses

By default monitors:
- Claude Code
- Aider
- Cursor
- OpenClaw
- Cline
- Windsurf
- Continue

Add custom harnesses in config.

## State Management

The skill maintains state in `.clwatch-state.json`:
- Last check timestamp
- Known release versions
- Acknowledged alerts

## Manual Invocation

Run manually:
```bash
./scripts/check-updates.sh
```

Scan configs only:
```bash
./scripts/scan-configs.sh
```

## Output Format

Reports are generated using the daily-report template and can be:
- Posted to OpenClaw channels
- Saved to file
- Sent via notification

## Dependencies

- `jq` for JSON processing
- `node` for changelogs.info data access
- Standard POSIX shell utilities (grep, sed, awk)
