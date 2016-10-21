set -x PATH $PATH ~/bin/

alias b 'bundle'
alias o 'open'
alias o7 'open -a Xcode\ 7 *.xcworkspace'
alias o8 'open -a Xcode\ 8 *.xcworkspace'
alias oo 'open .'
alias g 'git'
alias v 'vim'
alias - 'cd -'

#### Notes ####

## Show diff after reloading config
#
# save new config to variable
# when reloading diff current config

# cat (config_path) | read -z __config
# git diff --no-prefix (echo "$__config" | psub) (cat (config_path) | psub)

function c --description "Edit fish shell's config file in vim"
    v (config_path)
end

function t
    z "$argv"
end

function jo
    zo "$argv"
end

function r --description "Reload fish shell's config file"
    echo "Reloaded ~/.config/fish/config.fish"
    . (config_path)
end

function config_path
    status -f
end

function git --description "After running git commands that would affect HEAD, print out the last commit hash"
    set commit (command git rev-parse --short HEAD)

    command git $argv

    set command_status $status
    set commit_after_command (command git rev-parse --short HEAD)

    if command test $commit = $commit_after_command
        return $command_status
    end

    if test $command_status -ne 0
        return $command_status
    end

    if test (count $argv) -gt 0
        switch $argv[1]
        case amend amd commit c ca pull pc pp ppr reset rs undo
            echo
            echo -n "Last commit was "
            set_color yellow
            echo $commit
            set_color normal
        end
    end

    return $command_status
end

function fish_right_prompt
    set_color green
    echo -n (date "+%H:%M")
    set_color normal
end

function fish_prompt
    if not set -q __fish_git_prompt_show_informative_status
        set -g __fish_git_prompt_show_informative_status 1
    end
    if not set -q __fish_git_prompt_hide_untrackedfiles
        set -g __fish_git_prompt_hide_untrackedfiles 1
    end

    if not set -q __fish_git_prompt_color_branch
        set -g __fish_git_prompt_color_branch magenta --bold
    end
    if not set -q __fish_git_prompt_showupstream
        set -g __fish_git_prompt_showupstream "informative"
    end
    if not set -q __fish_git_prompt_color_dirtystate
        set -g __fish_git_prompt_color_dirtystate blue
    end
    if not set -q __fish_git_prompt_color_stagedstate
        set -g __fish_git_prompt_color_stagedstate yellow
    end
    if not set -q __fish_git_prompt_color_invalidstate
        set -g __fish_git_prompt_color_invalidstate red
    end
    if not set -q __fish_git_prompt_color_untrackedfiles
        set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
    end
    if not set -q __fish_git_prompt_color_cleanstate
        set -g __fish_git_prompt_color_cleanstate green --bold
    end

    set -l last_status $status

    if not set -q __fish_prompt_normal
        set -g __fish_prompt_normal (set_color normal)
    end

    set -l color_cwd
    set -l prefix
    switch $USER
    case root toor
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        else
            set color_cwd $fish_color_cwd
        end
        set suffix '#'
    case '*'
        set color_cwd $fish_color_cwd
        set suffix '$'
    end

    # PWD
    set_color $color_cwd
    echo -n (prompt_pwd)
    set_color normal

    printf '%s ' (__fish_vcs_prompt)

    if not test $last_status -eq 0
    set_color $fish_color_error
    end

    set_color yellow

    set commit (command git rev-parse --short HEAD)
    echo -n "$commit "

    set_color normal

    echo -n "$suffix "

    set_color normal
end
