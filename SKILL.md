---
name: clwatch
description: "Detect coding tool updates at session start and merge changelog deltas into local reference files using a two-tier diff/refresh workflow."
metadata:
  openclaw:
    emoji: "📡"
    triggers:
      - session_start
      - manual
    requires:
      bins: [clwatch]
---

# clwatch — Changelog Intelligence Skill

Detects new releases of tracked coding tools and merges updates into local reference files.
Uses the `clwatch.payload.v1` schema from changelogs.info.

---

## Tier 1 — Fast Detection (session start)

Run automatically at every session start. Must be silent when nothing changed.

### Steps

1. Run `clwatch diff --json`
2. **Exit 0** → no changes. Stop silently.
3. **Exit 1** → changes detected. Parse the JSON output:

```json
{
  "schema": "clwatch.diff.v1",
  "updates": [
    {
      "tool": "claude-code",
      "current": "1.0.30",
      "latest": "1.0.35",
      "scope": "small|medium|large",
      "breaking": false,
      "delta_summary": "..."
    }
  ]
}
```

4. For each update, check `scope`:
   - **`small`** and `breaking: false` → apply direct metadata patch (version, date, install command in reference file). No LLM merge needed.
   - **`medium`**, **`large`**, or `breaking: true` → queue for Tier 2.

5. If any tools queued for Tier 2, proceed immediately.

---

## Tier 2 — Deep Refresh (only when needed)

1. Fetch the full payload:
   ```bash
   clwatch refresh <tool> --json
   ```
   Fallback: `curl -sf https://changelogs.info/api/refs/<tool>.json`

2. Locate the local reference file (see Reference File Discovery below).

3. Read the current reference file content.

4. Apply the merge prompt template (`templates/merge-prompt.md`) with:
   - The full delta block from the payload
   - The current reference file content
   - The tool metadata (version, date, breaking changes)

5. **If `breaking: true`**: surface changes to the user and wait for confirmation before applying.

6. Write the merged content back to the reference file.

7. Update local version tracking: `clwatch ack <tool> <version>`

---

## Reference File Discovery

Find the agent's existing reference file for a tool:

1. Search the working directory for files matching:
   - `references/<tool-slug>-features.md` (canonical path)
   - `references/<tool-slug>*`
   - `*<tool-slug>*features*`
   - `*<tool-slug>*reference*`
2. If multiple matches, prefer the one under `references/`.
3. If no match found, create `references/<tool-slug>-features.md` using the `templates/new-reference.md` template populated from the payload.

---

## Merge Prompt Template

The merge prompt is defined in `templates/merge-prompt.md`. It instructs the LLM to:

1. Preserve existing structure, headings, voice, and conventions
2. ADD items from `delta.new_features`, `delta.new_commands`, `delta.new_flags`
3. UPDATE items that changed (compare `key_details`, descriptions)
4. MARK deprecated items: `(deprecated since vX.Y.Z — use X instead)`
5. MARK breaking changes with `⚠️ BREAKING`
6. Do NOT delete existing content unless explicitly superseded
7. Do NOT change file format or structure
8. Only surface agent-relevant changes (skip pure bug fixes unless notable)

---

## Configuration

See `clwatch-config.example.json`:

| Field | Description |
|---|---|
| `tools` | Tool slugs to track |
| `manifestUrl` | Manifest endpoint |
| `referenceDir` | Where reference files live |
| `tier2Threshold` | Minimum scope to trigger Tier 2 (`small`, `medium`, `large`) |
| `notifyOnBreaking` | Always surface breaking changes to user |
| `stateFile` | Path to version state file |

---

## Error Handling

- If `clwatch` binary not found: log once, skip silently. Do not block the session.
- If network fetch fails: log warning, skip. Reference files remain unchanged.
- If reference file is read-only or missing write permissions: warn user, skip merge.
