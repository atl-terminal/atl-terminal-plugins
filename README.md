# ATL Terminal Plugins

Nine reviewed data-first helper packages for terminal troubleshooting.

**Compatibility:** manifests use API 1.0. The new chat-guidance integration
requires the development app after v1.0.7; it is not in the published v1.0.7
installer. In that installer, community packages are displayed as cards while
built-in helpers work independently. A future installer is required for the
new guidance behavior.

| Family | Helper | Status / behavior |
| --- | --- | --- |
| Device | Linux Server | Beta diagnostic guidance |
| Device | Cisco IOS / IOS XE | Beta show-command guidance; hardware verification still required |
| Tool | Docker Diagnostics | Beta container discovery and bounded log guidance |
| Tool | systemd Diagnostics | Beta service state and finite journal guidance |
| Tool | Git Inspection | Beta status, bounded history, and diff guidance |
| Tool | Nmap | Beta; authorized targets only |
| TUI | GNU nano | Unstable automation; prefer manual editing |
| TUI | Vim | Beta; deterministic built-in VIM_* actions |
| Code | Code Inspect | Built-in bounded CODE_* inspection guidance |

## What They Actually Do

Validated local command catalogs and guidance are selected for relevant user
requests and supplied to chat. They are not autonomous agents, executable
plugins, new native helpers, or deterministic output parsers. No plugin may
bypass command safety or execute code simply because it is installed.

New helper badges are text labels, not official vendor logos. Existing logo
rights remain subject to the [logo policy](docs/LOGO_POLICY.md).

## Validate and Test

```sh
perl tools/validate_all.pl
perl -MTest::Harness -e 'runtests sort glob(q(t/*.t))'
```

Opt-in Linux command smoke tests use a disposable Git repository and read-only
Docker/systemd commands. They require git, Docker CLI, systemctl, timeout, head,
and Bash:

```sh
ATL_PLUGIN_COMMAND_SMOKE=1 perl t/command_smoke.t
```

A missing Docker daemon is tested as an error path, not called successful
container inspection. [Verification record](docs/VERIFICATION.md) distinguishes
fixtures, real commands, and unverified device/LLM behavior.

## Installation and Contributions

Follow [installation and compatibility guidance](https://github.com/atl-terminal/atl-terminal-docs/blob/main/docs/plugins/installing-plugins.md).
Refresh Catalog does not install plugins. Review the full package before
copying it into an app's plugins directory.

Use the [SDK](https://github.com/atl-terminal/atl-terminal-plugin-sdk) and
[review checklist](docs/PLUGIN_REVIEW.md). Each catalog entry must point to an
existing manifest with the same ID. No API keys, connection profiles, logs,
customer data, native DLLs, or application core belong here.
