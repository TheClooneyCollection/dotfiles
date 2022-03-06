# dotfiles

## Usage

#### Initiailize!

(These **could** be automated as simple as `make bootstrap`.)

##### (`if macOS`) Install Git with [Homebrew](https://brew.sh)

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` (Updated in 2022 March)

#### Set up your `~`

```sh
cd ~
git init
git remote add origin https://github.com/NicholasTD07/dotfiles.git
git pull origin main

# You should have all the files :)
```

#### You'd need to download Xcode manually tho...

From here: https://developer.apple.com/download/all/?q=xcode

#### Log into your Apple ID in App Store

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
