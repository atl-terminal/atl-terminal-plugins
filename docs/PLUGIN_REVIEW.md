# Plugin Review

Review plugins for:

- valid manifest fields
- known permissions only
- safe command grouping
- no secrets or customer data
- no destructive commands marked as read-only
- clear prompt guidance
- portable paths and filenames
- literal activation terms and negative/unrelated request tests
- complete entry-file validation, not just successful card rendering
- finite time and byte limits for diagnostics
- command smoke tests and honest records of unavailable tools/devices
- correct minimum integration requirement (new guidance is after v1.0.7)
- documentation that permissions do not bypass host execution controls

Unknown permissions or invalid JSON should disable the plugin, not the app.
