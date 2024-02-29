if test -e ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end

fish_add_path /opt/homebrew/bin ~/bin

# Set up poetry shell on start up

if type -q poetry
    # poetry shell --quiet
    # clear
    source (poetry env info --path)/bin/activate.fish
    if test $status -ne 0
        echo "Please run poetry install --no-root first."
    end
end

# Set up zoxide

zoxide init fish | source
zoxide init --cmd cd fish | source

# Set up invoke auto complete on start up

if type -q invoke
    invoke --print-completion-script=fish | source
end

# Load rbenv automatically by appending
# the following to ~/.config/fish/config.fish:

if type -q rbenv
    status --is-interactive; and source (rbenv init -|psub)
end

# aliases

alias b 'bundle'
alias bb 'brew bundle --global'

alias clean_derived_data 'rm -rf ~/Library/Developer/Xcode/DerivedData'
alias xo 'open -a Xcode *.xcworkspace'
alias xoo 'open -a Xcode *.xcodeproj'

alias o 'open'
alias oo 'open .'
alias g 'git'

alias e 'emacs -nw'
alias v 'vim'

alias ig 'v (git rev-parse --show-toplevel)/.gitignore'

alias mkdir 'mkdir -p'

alias va 'vagrant'
alias vu 'va up'
alias vup 'va up --provision'
alias vsh 'va ssh'

alias gitignore-from-pasteboard 'pbpaste | cat > .gitignore'

alias weather 'curl "wttr.in?m"'

# fish

function c --description "Edit fish shell's config file in nvim"
    v (config_path)
end

function r --description "Reload fish shell's config file"
    echo "Reloaded ~/.config/fish/config.fish"
    . (config_path)
end

function config_path
    status -f
end

# shell

function mkcd
    command mkdir -p $argv
    cd $argv
end

# git wrapper

function git --description "After running git commands that would affect HEAD, print out the last commit hash"
    set commit (command git rev-parse --short HEAD)

    if test (count $argv) -eq 0
        command git s
    else
        command git $argv
    end

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
        case amend amd commit c ca merge m pull pc pp ppr rebase ri revert reset rs undo hard-reset
            switch $argv[1]
            case merge m pull pc pp ppr
                echo

                echo -n "Between last commit ("
                set_color yellow
                echo -n "$commit"
                set_color normal
                echo ") and HEAD,"
                echo -n "there have been "
                set_color yellow
                echo -n (git rev-list --count $commit..HEAD)
                set_color normal
                echo " commits."
            case '*'
                echo
                echo -n "Last commit was "
                set_color yellow
                echo $commit
                set_color normal
            end
        end
    end

    return $command_status
end

# fish prompt

function fish_right_prompt
    if test -n "$IN_NIX_SHELL"
        if test $IN_NIX_SHELL != ""
            if test $name != ""
                set_color white
                echo -n "[$name] "
                set_color normal
            end
        end
    end

    set_color green
    echo -n (date "+%H:%M")
    set_color normal
end

function fish_prompt
    set -l last_status $status

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

    # switch (uname)
    #     case Darwin
    #         echo -n 'macOS '
    #     case '*'
    #         echo -n (uname)
    #         echo -n ' '
    # end

    # username
    switch $USER
        case nicholas.tian
        case '*'
            set_color cyan
            echo -n $USER
            echo -n ' '
    end

    # PWD
    set_color $color_cwd
    echo -n (prompt_pwd)
    set_color normal

    # git status
    git_repo_exists
    if test $status -eq 0
        printf '%s ' (__fish_vcs_prompt)
    end

    if not test $last_status -eq 0
        set_color $fish_color_error
    end

    # # git commit
    # git_repo_exists
    # if test $status -eq 0
    #     set_color yellow
    #     set commit (command git rev-parse --short HEAD)
    #     echo -n "$commit"
    #     set_color normal
    # end

    echo
    echo -n "$suffix "

    set_color normal
end

function git_repo_exists
    command git rev-parse --is-inside-work-tree  > /dev/null 2> /dev/null
end
