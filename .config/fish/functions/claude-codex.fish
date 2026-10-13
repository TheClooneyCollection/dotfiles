function claude-codex --description 'Claude Code via CLIProxyAPI, pick a model with fzf'
    set -l default gpt-6-astra
    set -l models (cliproxy-models)
    if test (count $models) -eq 0
        echo "claude-codex: can't list models; is the proxy running?" >&2
        return 1
    end
    set -l model (begin
            echo $default
            printf '%s\n' $models | string match -v -- $default
        end | fzf --height 40% --reverse --prompt 'model> ')
    or return 1
    claude-proxy $model $argv
end
