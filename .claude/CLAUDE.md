# Global Claude Instructions

- Always reply to the user in Chinese (中文). Code, commands, file paths and identifiers stay as they are; commit messages and repo docs follow the repo's existing language.
- Before changing anything in another project (a repo other than the one you started in), run `tmux-connect --list --from <your name>`, show the user the agents open for that project, and ask whether to hand the change to that project's agent chain or do it yourself. Reading other projects needs no ask.
- Own skills: after pushing a change in ~/Source/Projects/skills, always update the dotfiles copy in the same task, without asking, as in ~/AGENTS.md "Own skills".
- Never use absolute paths in shell commands. Always use `.` or relative paths. The working directory is already set correctly.
- For git commands, always just run `git` directly. Never `cd` into the directory first, and never use `git -C <path>`. Just `git status`, `git commit`, etc.
- Never backslash-escape spaces in paths. Always quote paths that contain spaces (e.g. `"dir/with spaces/file"`).
- So instead of `find /Users/foo/Bar\ Baz -type f`, write `find . -type f`.
- Avoid em dashes. Rewrite the sentence, split it in two, or use a comma instead.
