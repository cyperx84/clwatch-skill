# clwatch OpenClaw Skill

Monitor changelog-impact on your local AI harness configs.

## What it does
- checks watched harnesses for updates
- scans local config files
- prepares daily digest output

## Files
- `SKILL.md` skill metadata + usage
- `scripts/check-updates.sh` update/checkpoint runner
- `scripts/scan-configs.sh` config discovery and harness detection
- `templates/daily-report.md` report template
- `clwatch-config.example.json` sample config

## Quick start
```bash
cp clwatch-config.example.json clwatch-config.json
./scripts/check-updates.sh ./clwatch-config.json
./scripts/scan-configs.sh ./clwatch-config.json
```

## Cron idea
Run daily and announce the rendered report in your preferred channel.
