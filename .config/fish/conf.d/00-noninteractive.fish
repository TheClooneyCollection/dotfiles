# Non-interactive fish (`fish -c`, e.g. every tmux popup) skips interactive
# setup. Sorted first, so this runs before Homebrew's vendor conf.d
# mise-activate.fish, which checks this variable. Interactive shells still
# auto-activate mise as before.
status is-interactive; or set -g MISE_FISH_AUTO_ACTIVATE 0
