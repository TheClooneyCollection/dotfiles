#!/bin/zsh

function clone_dotfiles_to_home {
    cd ~
    git init
    git remote add origin https://github.com/NicholasTD07/dotfiles.git
    git fetch origin
    git switch main
}

function set_up_PATH_for_pip {
    # This sets up the PATH variable by evaluating something like:
    # `export PATH="$HOME/Library/Python/3.9/bin:/opt/homebrew/bin:$PATH"`

    eval $(\
        python3 -c 'import sys; info = sys.version_info; print(f"export PATH='$HOME/Library/Python/{info.major}.{info.minor}/bin:/opt/homebrew/bin:$PATH'")'
    )
}

function upgrade_pip {
    python3 -m pip install --upgrade pip
}

function install_ansible {
    python3 -m pip install ansible
}

function run_playbook {
    cd ~/ansible-playbook
    ansible-playbook -K main.yml
}

clone_dotfiles_to_home
set_up_PATH_for_pip
upgrade_pip
install_ansible
run_playbook
