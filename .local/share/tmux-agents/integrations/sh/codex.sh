# tmux-agents: a codex wrapper for bash and zsh. Source it from ~/.bashrc or
# ~/.zshrc. Inside tmux it pins this pane's identity, because Codex runs
# shell commands in a shared daemon that keeps the environment of
# whichever pane started it. For an extra account (a TMUX_AGENTS_CODEX_HOMES
# profile such as work=$HOME/.codex-work), define one like:
#   codex-work() {
#     local IFS='
# '
#     CODEX_HOME="$HOME/.codex-work" command codex $(__codex_tmux_pins work) "$@"
#   }

__codex_tmux_pins() {
  [ -n "${TMUX_PANE:-}" ] || return 0
  printf '%s\n' \
    -c "shell_environment_policy.set.TMUX_PANE=\"$TMUX_PANE\"" \
    -c "shell_environment_policy.set.TMUX=\"$TMUX\"" \
    -c 'shell_environment_policy.set.TMUX_AGENTS_PINNED="1"' \
    -c "shell_environment_policy.set.TMUX_AGENTS_KIND=\"${1:-codex}\""
}

codex() {
  local IFS='
'
  command codex $(__codex_tmux_pins codex) "$@"
}
