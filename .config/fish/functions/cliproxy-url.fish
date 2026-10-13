function cliproxy-url --description 'Base URL of the local CLIProxyAPI'
    set -q CLIPROXY_URL; and echo $CLIPROXY_URL; or echo http://127.0.0.1:8317
end
