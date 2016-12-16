#!/bin/sh

main() {
    setUp
    config
}

setUp() {
    echo "starting setup..."
    echo "bootstrapping brew..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    echo "installing brews..."
    brew bundle --global -v

    echo "setup is done!"
}

config() {
    echo "starting config..."
    no_bouncing_dock_icons
    echo "config is done!"
}

no_bouncing_dock_icons() {
    defaults write com.apple.dock no-bouncing -bool TRUE
    killall Dock
    echo "disabled bouncing icons. 😝"
}

main
