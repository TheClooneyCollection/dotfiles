function codex --wraps codex --description "Codex CLI; inside tmux, pins this pane's identity for tmux-agents"
    command codex (__codex_tmux_pins) $argv
end
