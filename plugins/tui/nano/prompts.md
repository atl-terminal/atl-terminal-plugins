# GNU nano TUI Helper

Use the built-in nano helper vocabulary when nano is the active interactive app.

- nano is modeless, so text inserts directly.
- Release status: unstable for full automation. Prefer manual nano for production edits.
- Use `NANO_SAVE_EXIT` only for simple test files or explicit user experiments.
- At `File Name to Write:` send Enter once, wait for the screen, then exit.
- Avoid repeating save actions if the visible screen has not changed.
