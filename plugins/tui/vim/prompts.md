# Vim TUI Guidance

- Prefer `VIM_APPEND`, `VIM_INSERT_AFTER`, `VIM_REPLACE_LINE`, and
  `VIM_REPLACE_BUFFER` over raw insert-mode keystrokes.
- Line-number edits must be based on the current buffer state.
- Do not issue the same write/edit action twice unless the user asks.
- Use save-and-quit only when the task is complete and the user did not ask to
  keep Vim open.
