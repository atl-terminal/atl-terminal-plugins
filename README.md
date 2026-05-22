# ATL Terminal Plugins

Curated public plugin collection for ATL Terminal.

This repository contains data-first plugins that extend ATL Terminal with
device rules, safe command catalogs, prompt guidance, and UI metadata. Plugins
are designed to validate before use and to fail closed when a manifest is
invalid.

## Included Plugins

| Family | Plugin | Purpose |
| --- | --- | --- |
| devices | Linux Server | Linux shell awareness and diagnostics |
| devices | Cisco IOS / IOS XE | Network device prompts and safe show commands |
| tools | Nmap | Safe network discovery guidance |
| tui | GNU nano | Interactive nano helper metadata |
| tui | Vim | Interactive Vim helper metadata |
| code | Code Inspect | Read-only codebase inspection guidance |

## Validate

```bat
perl tools\validate_all.pl
perl t\validate_plugins.t
```

## Plugin Layout

```text
plugins/
  devices/
  tools/
  tui/
  code/
```

Each plugin folder contains:

- `plugin.json`
- optional `device_rules.json`
- optional `commands.json`
- optional `prompts.md`
- optional `logo.txt`

## Safety

Plugins should suggest safe actions by default. Destructive or hard-to-reverse
actions must be marked as confirmation-required.
