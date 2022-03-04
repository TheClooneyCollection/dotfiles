# dotfiles

## Usage

#### Install Git

##### (`if macOS`) Install Git with [Homebrew](https://brew.sh)

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` (Updated in 2022 March)

(`git` is installed when you installed Homebrew)

#### Set up your `~`

```sh
cd ~
git init
git remote add origin https://github.com/NicholasTD07/dotfiles.git
git pull origin master

# You should have all the files :)
```

#### Log into Your Apple ID in App Store

Log into your Apple ID in App Store.

#### Install fishshell

`brew install fish`

#### Init your Mac

```sh
fish
source bin/init.fish

# sets fish as default shell | disables dock bouncing icons | etc.
mac_init

# install core brews, casks, and Apps
brew_core # after this, start configuring Dropbox, 1Password (extensions), Alfred, iTerm, Firefox
brew_essential

# optional
install_essential_packages
generate_ssh_key

# optional optional
brew_optional
```
