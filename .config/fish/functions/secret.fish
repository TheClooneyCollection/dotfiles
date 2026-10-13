function secret --description 'Read one variable from the 1Password-linked env file'
    set -l file (set -q SECRETS_ENV_FILE; and echo $SECRETS_ENV_FILE; or echo ~/.config/.env)
    set -l val (sed -n "s/^$argv[1]=//p" $file)
    if test -z "$val"
        echo "secret: $argv[1] not found in $file (is 1Password unlocked?)" >&2
        return 1
    end
    echo $val
end
