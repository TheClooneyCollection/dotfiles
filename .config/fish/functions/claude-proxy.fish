function claude-proxy --description 'Claude Code via CLIProxyAPI: claude-proxy MODEL [claude args]'
    set -l model $argv[1]
    if test -z "$model"
        echo "usage: claude-proxy MODEL [claude args]" >&2
        return 1
    end
    set -l key (secret CLIPROXYAPI_ACCESS_API_KEY); or return 1

    set -l window 272000
    string match -q 'gpt-5.6-*' -- $model; and set window 921000

    env \
        ANTHROPIC_BASE_URL=(cliproxy-url) \
        ANTHROPIC_AUTH_TOKEN=$key \
        ANTHROPIC_MODEL=$model \
        ANTHROPIC_DEFAULT_OPUS_MODEL=$model \
        ANTHROPIC_DEFAULT_SONNET_MODEL=$model \
        ANTHROPIC_DEFAULT_HAIKU_MODEL=$model \
        CLAUDE_CODE_MAX_CONTEXT_TOKENS=$window \
        claude $argv[2..]
end
