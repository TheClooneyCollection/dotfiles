function ts-serve --description 'Serve a local port over Tailscale HTTPS on the same port'
    if test (count $argv) -lt 1
        echo 'usage: ts-serve <port> [off]' >&2
        return 1
    end
    set -l port $argv[1]
    if test "$argv[2]" = off
        tailscale serve --https=$port off
    else
        tailscale serve --bg --https=$port $port
    end
end
