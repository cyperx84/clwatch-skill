# Merge Prompt — clwatch Reference File Update

You are updating a local reference file for **{{tool_name}}** ({{tool_slug}}) based on changelog data from changelogs.info.

## Current version: {{current_version}} → New version: {{latest_version}}

## Rules — follow exactly

1. **Preserve** the existing file structure, headings, voice, and formatting conventions. Do not reorganize.
2. **ADD** new items from the delta:
   - `delta.new_features` → add under the appropriate existing section
   - `delta.new_commands` → add to the commands section
   - `delta.new_flags` → add to the flags/options section
3. **UPDATE** items where `key_details` or descriptions have changed. Replace the old description with the new one in-place.
4. **MARK deprecated** items inline: `(deprecated since v{{latest_version}} — use {{replacement}} instead)`
5. **MARK breaking changes** prominently with: `⚠️ BREAKING (v{{latest_version}}): {{description}}`
6. **Do NOT delete** existing content unless it is explicitly superseded by the delta.
7. **Do NOT change** the file format, heading structure, or indentation style.
8. **Skip** pure bug fixes and internal changes unless they are notable to agent users.
9. Keep entries concise — one line per feature/flag/command unless detail is needed.

## Delta block

```json
{{delta_json}}
```

## Current reference file content

```markdown
{{current_content}}
```

## Output

Return the complete updated reference file content. No preamble, no explanation — just the file.
