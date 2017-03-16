# dotfiles

## Usage

#### Install Homebrew

`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

#### Clone this repo

(`git` is installed when you installed Homebrew)

`git clone https://github.com/NicholasTD07/dotfiles.git`

#### Move files into your home folder

`cp -rv /path/to/dotfiles/.* ~/`

#### Install tools and apps with Homebrew Bundle

`brew bundle --global -v`

#### Prep

- Start vim once
- Add fishshell to `/etc/shells`

#### Init your Mac

```sh
fish
source bin/macos.fish

# sets fish as default shell | compiles vim plugins | disables dock bouncing icons
# it also disables xcode indexing
mac_init

# optional
generate_ssh_key
```
