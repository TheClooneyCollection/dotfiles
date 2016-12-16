#!/bin/sh

main() {
    no_bouncing_dock_icons
}

no_bouncing_dock_icons() {
    defaults write com.apple.dock no-bouncing -bool TRUE
    killall Dock
}

main
