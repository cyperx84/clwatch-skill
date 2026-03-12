You are updating a coding tool reference file. Output ONLY the updated file content, no explanation.

# Task

Merge changelog delta for **{{TOOL_NAME}}** (`{{TOOL_SLUG}}`) into the existing reference file.

Version transition: `{{PREVIOUS_VERSION}}` → `{{NEW_VERSION}}`
Breaking changes: {{BREAKING}}

## Merge Rules — follow exactly

1. **Preserve** the existing file structure, headings, voice, and formatting conventions. Do not reorganize.
2. **ADD** new items from the delta: `new_features` → features section, `new_commands` → commands section, `new_flags` → flags/options section.
3. **UPDATE** items where descriptions or key_details have changed. Replace old description with new in-place.
4. **MARK deprecated** items inline: `(deprecated since v{{NEW_VERSION}} — use <replacement> instead)`
5. **MARK breaking changes** prominently with: `⚠️ BREAKING (v{{NEW_VERSION}}): <description>`
6. **Do NOT delete** existing content unless it is explicitly superseded by the delta.
7. **Do NOT change** the file format, heading structure, or indentation style.
8. **Only surface agent-relevant changes** — skip pure bug fixes and internal changes unless notable.

## Breaking Changes

{{BREAKING_CHANGES}}

## Delta (what changed)

```json
{{DELTA_JSON}}
```

## Current Reference File Content

```markdown
{{CURRENT_CONTENT}}
```

## Output

Output the complete updated file content now. Do not include any preamble or explanation.
