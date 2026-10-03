# `tmux-ask --any` is unchanged by it

**Decision.** Spawning with `--for` doesn't add any new restriction on messaging. As before, an agent messages a named agent it isn't connected to with `tmux-ask --any` only when the user asks. So main can still reach the worker that way if the user wants it to.
