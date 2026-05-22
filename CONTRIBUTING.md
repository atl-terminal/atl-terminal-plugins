# Contributing

Plugin contributions should be safe, portable, and easy to review.

## Rules

- Keep plugins data-first.
- Do not include credentials, private inventories, customer data, or logs.
- Do not include third-party artwork unless source and usage notes are included.
- Group commands by risk.
- Mark destructive actions as confirmation-required.
- Add or update validation tests when plugin rules change.

## Local Checks

```bat
perl tools\validate_all.pl
perl t\validate_plugins.t
```
