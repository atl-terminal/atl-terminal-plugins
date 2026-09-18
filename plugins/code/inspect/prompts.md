# Code Inspect Helper

Use the built-in code helper for read-only codebase discovery inside terminal
sessions.

- Start with `pwd`, top-level files, and dependency manifests.
- Prefer `CODE_SEARCH literal IN path` for bounded ripgrep search with core-Perl fallback.
- Use `CODE_SEARCH_REGEX pattern IN path` only when a regular expression is needed (requires ripgrep).
- Use `CODE_FILE file start end` for numbered text and a whole-file SHA256.
- Do not treat a capped or timed-out search as exhaustive. Narrow the path before continuing.
- Do not force binary files to text, follow live logs, or execute code just to inspect it.
- Do not edit files until the user asks for implementation.
