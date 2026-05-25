# dotfiles

Personal macOS development environment and workstation config.

This repo tracks the parts of `~` that are worth keeping under version control: shell setup, editor config, terminal preferences, keybindings, small utility scripts, and a few workflow notes. It is intentionally selective rather than a full home directory snapshot.

## What this repo contains

- `~/.config/fish/` for shell startup, aliases, and CLI defaults.
- `~/.emacs.d/` for the main Emacs setup, including custom Lisp modules.
- `~/.config/nvim/` and `~/.vim*` for Neovim/Vim configuration.
- `~/.config/ghostty/` for terminal configuration and theme material.
- `~/.config/karabiner/` for keyboard remapping.
- `~/.tmux.conf` and `~/.gitconfig` for terminal and Git ergonomics.
- `~/.bin/` for lightweight personal scripts.
- `~/docs/` and a few root notes for workflow-specific documentation.
- `~/.archive/` for older config snapshots and migration history that are still useful for reference.

## Shape of the repo

This is a living workstation repo, not just a bootstrap script collection. The goal is to keep everyday tooling, editor behavior, and machine setup decisions visible and reproducible without tracking the entire home directory.

Most files in `~` are intentionally ignored. The tracked set is allowlisted through `.gitignore`, so anything new should be added deliberately.

## Usage

#### Initialize

(These could be automated into something like `make bootstrap`.)

##### (`if macOS`) Install Git with [Homebrew](https://brew.sh)

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

#### Set up your `~`

```sh
cd ~
git init
git remote add origin https://github.com/NicholasTD07/dotfiles.git
git pull origin main
```

Machine bootstrap has moved to [`TheClooneyCollection/ansible-macOS-playbook`](https://github.com/TheClooneyCollection/ansible-macOS-playbook).

Use this repo for the tracked home-directory configuration itself, and use the playbook to provision a new Mac and apply the wider machine setup.
