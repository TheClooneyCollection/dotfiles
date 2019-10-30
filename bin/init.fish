function generate_ssh_key
    echo "Generate a ssh key for you"
    echo "What's your email address?"

    read -l email
    ssh-keygen -t rsa -b 4096 -C $email

    echo ""
    echo "Done!"
end

function brew_core
    brew bundle --file=~/.Brewfiles/core
end

function brew_essential
    brew bundle --file=~/.Brewfiles/essential
end

function brew_optional
    brew bundle --file=~/.Brewfiles/optional
end

function mac_init
    echo "Initializing your Mac :)"

    init_local_fish_config
    init_folders

    set_fish_as_default_shell

    disable_bouncing_dock_icons
    only_show_running_apps_in_dock

    for option in $argv
        switch "$option"
            case --no-nix --skip-nix
                echo "Skipping nix"
            case \*
                install-and-set-up-nix
        end
    end

    echo "Your mac is set up and ready!"
end

function init_local_fish_config
    touch ~/.config/fish/local.fish
end

function init_folders
    mkdir ~/proj
    mkdir ~/fork
    mkdir ~/work
end

function set_fish_as_default_shell
    echo "Setting fish as default shell"
    echo "Adding fish shell to /etc/shells"
    echo (which fish) | sudo tee -a /etc/shells
    echo ""

    chsh -s (which fish)

    echo ""
    echo "Done!"
    echo ""
end

function disable_bouncing_dock_icons
    echo "Disabling bouncing dock icons"

    defaults write com.apple.dock no-bouncing -bool TRUE
    killall Dock

    echo ""
    echo "Disabled bouncing dock icons. 😝"
    echo ""
end

function only_show_running_apps_in_dock
    defaults write com.apple.dock static-only -bool TRUE; killall Dock
end

function install-and-set-up-nix
    echo "Installing nix and setting it up"

    install-nix
    install-fisher
    install-foreign-env

    echo "Remember to either put this line into your fish shell config"
    echo "  fenv source ~/.nix-profile/etc/profile.d/nix.sh"
    echo "or run this in your fish shell"
    echo "  echo \"fenv source ~/.nix-profile/etc/profile.d/nix.sh\" >> ~/.config/fish/config.fish"

    fenv source ~/.nix-profile/etc/profile.d/nix.sh

    echo "You should be able to run `nix repl` now."

    echo ""
    echo "Nix is installed 😝"
    echo ""
end

function install-nix
    curl https://nixos.org/nix/install | sh
end

function install-fisher
    curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
end

function install-foreign-env
    fisher add oh-my-fish/plugin-foreign-env
end

function install_essential_packages
    install_fish_plugins
    install_python_packages
    install_ruby_gems
end

function install_fish_plugins
    echo "Installing fish shell plugins"
    echo ""

    fisher

    echo ""
    echo "Done!"
    echo ""
end

function install_python_packages
    echo "Installing Python packages"
    echo ""

    set packages cdiff ipython virtualenv pip-tools tox pygments

    # pip2 install $packages
    pip3 install $packages

    # echo "Installing pygments with system default python (need sudo)"
    # echo ""
    # sudo /usr/bin/easy_install pygments

    echo ""
    echo "Done!"
    echo ""
end

function install_ruby_gems
    echo "Installing Ruby gems"
    echo ""

    gem install bundler cocoapods rcodetools jekyll

    echo ""
    echo "Done!"
    echo ""
end
