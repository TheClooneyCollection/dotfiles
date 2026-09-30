# Global instructions

- Always reply to the user in Chinese (中文). Code, commands, file paths and identifiers stay as they are; commit messages and repo docs follow the repo's existing language.
- Whenever you would start a sub agent (spawned, delegated or parallel agents), use `tmux-spawn --from <your name> --name <task-name>` from the `tmux-agents` skill instead, then end your turn; the answer arrives as `[reply from <name> to <you> via tmux-ask]`. When you have everything you need from a sub agent, close it with `tmux-dismiss --from <your name> <name>`.
- To talk to, ask, delegate to, or check on another agent, use the `tmux-agents` skill (`tmux-ask`, `tmux-peers`, `tmux-peek`). Do not use the `open-maestri` skills unless the user explicitly names open-maestri or maestri.
