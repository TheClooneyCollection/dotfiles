set -x PATH $PATH ~/bin/

alias g 'git'
alias r 'reload'

function reload
    echo Reloaded ~/.config/fish/config.fish
    . ~/.config/fish/config.fish
end

function config_path
    status -f
end

function vc
    vim (config_path)
end

#### Notes ####
# git diff --no-prefix (echo "$config_old" | psub) (echo "$config_new" | psub)
