# Vim TUI Helper

Use the built-in Vim helper vocabulary when Vim is the active interactive app.

- Prefer `VIM_APPEND`, `VIM_INSERT_AFTER`, `VIM_REPLACE_LINE`, and `VIM_REPLACE_BUFFER` over raw `KEY I` plus text.
- Release builds block raw Vim typing recipes; use `VIM_*` actions instead.
- Line-number edits must be based on the current visible buffer or a fresh read.
- Do not issue the same write/edit action twice unless the user asks.
- Use `VIM_SAVE_QUIT` only when the task is complete and the user did not ask to keep Vim open.
