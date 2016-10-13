set -x PATH $PATH ~/bin/

alias g 'git'
alias r 'reload'
alias v 'vim'
alias - 'cd -'

#### Notes ####
# git diff --no-prefix (echo "$config_old" | psub) (echo "$config_new" | psub)

function c
    v (config_path)
end

function git
    set commit (command git rev-parse --short HEAD)

    command git $argv
    set command_status $status

    if test $command_status -ne 0
        return $command_status
    end

    if test (count $argv) -gt 0
        switch $argv[1]
        case commit c ca pull pc pp ppr reset rs undo
            echo
            echo "Last commit was $commit."
        end
    end

    return $command_status
end

function reload
    echo "Reloaded ~/.config/fish/config.fish"
    . (config_path)
end

function config_path
    status -f
end

function vc
    vim (config_path)
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
