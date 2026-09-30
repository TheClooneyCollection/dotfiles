function codex-2nd --wraps codex --description "Run Codex CLI with a second account (CODEX_HOME=~/.codex-2nd)"
    set -l codex_home "$HOME/.codex-2nd"
    test -d "$codex_home"; or mkdir -p "$codex_home"
    CODEX_HOME="$codex_home" command codex (__codex_tmux_pins) $argv
end
