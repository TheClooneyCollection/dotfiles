function __codex_tmux_pins --description "Codex -c args that pin this tmux pane's identity for tmux-agents (arg: codex or a TMUX_AGENTS_CODEX_HOMES profile)"
    # Codex runs shell commands in a shared app-server daemon that keeps the
    # env of whichever pane started it, so tmux-ask would act as that pane.
    set -q TMUX_PANE; or return 0
    set -l kind codex
    set -q argv[1]; and set kind $argv[1]
    printf '%s\n' \
        -c "shell_environment_policy.set.TMUX_PANE=\"$TMUX_PANE\"" \
        -c "shell_environment_policy.set.TMUX=\"$TMUX\"" \
        -c 'shell_environment_policy.set.TMUX_AGENTS_PINNED="1"' \
        -c "shell_environment_policy.set.TMUX_AGENTS_KIND=\"$kind\""
end
