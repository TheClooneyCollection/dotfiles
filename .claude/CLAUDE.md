# Global Claude Instructions

- Always reply to the user in Chinese (中文). Code, commands, file paths and identifiers stay as they are; commit messages and repo docs follow the repo's existing language.
- Never use absolute paths in shell commands. Always use `.` or relative paths. The working directory is already set correctly.
- For git commands, always just run `git` directly. Never `cd` into the directory first, and never use `git -C <path>`. Just `git status`, `git commit`, etc.
- Never backslash-escape spaces in paths. Always quote paths that contain spaces (e.g. `"dir/with spaces/file"`).
- So instead of `find /Users/foo/Bar\ Baz -type f`, write `find . -type f`.
- Avoid em dashes. Rewrite the sentence, split it in two, or use a comma instead.
