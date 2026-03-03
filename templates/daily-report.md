## 📡 cliwatch Daily Report

### New Releases
{{#releases}}
- **{{harness}}** {{version}} ({{timeAgo}})
  {{#breaking}}⚠️ BREAKING: {{description}}{{/breaking}}
  {{#recommended}}⭐ Recommended: {{action}}{{/recommended}}
{{/releases}}

### Config Alerts
{{#alerts}}
- {{severity}} {{harness}}: {{message}}
  → {{migration}}
{{/alerts}}

### Status
{{totalHarnesses}} harnesses monitored | {{newReleases}} new releases | {{alerts}} config alerts
