# Global Claude Instructions

- Never use absolute paths in shell commands. Always use `.` or relative paths. The working directory is already set correctly, so never `cd` into it before running commands like `git`.
- Never backslash-escape spaces in paths. Always quote paths that contain spaces (e.g. `"dir/with spaces/file"`).
- So instead of `find /Users/foo/Bar\ Baz -type f`, write `find . -type f`.
- Avoid em dashes. Rewrite the sentence, split it in two, or use a comma instead.
