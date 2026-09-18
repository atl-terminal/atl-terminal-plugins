# Verification Record

Package revision 0.2.0; manifest API 1.0. Recorded 2026-09-18.

## Automated Coverage

- Complete manifest and entry-file validation, duplicate IDs, exact catalog coverage.
- Literal activation, transport/permission gates, unrelated requests, disabled data.
- Real catalog contents delivered to the selector, with bounded context.
- Host integration tests in the private app verify the outgoing chat payload,
  no terminal writes during selection, no UI-thread package reads, and background reload.
- Private app regression suite: 1,248 checks passed; isolated GUI suite:
  122 checks passed, including nine packages loaded by the background worker.
- JSON Schema 2020-12 validation passed for 22 SDK, collection, and bundled manifests.
- SDK tests cover malformed data, missing files, UTF-8, control characters,
  traversal/alternate-stream filenames, and oversized content.

Selection fixtures are synthetic requests, not captured production conversations.
These tests do not prove LLM reasoning or authorization decisions.

## Real Command Smoke Tests

Ubuntu 24.04 under WSL:

- Git discovery/status/diff commands execute in a disposable repository.
- Empty Git history produces the expected real error.
- systemd discovery and failed-service listing execute against the local system.
- Docker CLI discovery/version execute successfully.
- Docker daemon is unavailable on this host: the connection error is verified.
  Successful container listing/log retrieval is NOT verified here.

No remote customer machines were accessed, no services restarted, and no
containers or production repositories modified. The smoke test creates only a
temporary Git repository and deletes its own temporary directory afterwards.

## Still Required

- Docker daemon success-path and selected-container log testing.
- Real Cisco IOS/IOS XE hardware/firmware verification.
- Nano/Vim end-to-end interactive editing remains unstable/beta respectively.
- Live LLM trials with each helper in a controlled session.
- Packaged installer verification for the new integration before claiming release support.

Canonical SDK modules are vendored under lib/ATL/PluginSDK with their license.
