function cliproxy-models --description 'List the text models CLIProxyAPI serves'
    set -l key (secret CLIPROXYAPI_ACCESS_API_KEY); or return 1
    curl -sf -H "Authorization: Bearer $key" (cliproxy-url)/v1/models \
        | jq -r '.data[].id | select(startswith("gpt-image") | not)'
end
