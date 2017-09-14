# dotfiles

## Usage

#### Install Git

##### (`if macOS`) Install Git with Homebrew

`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

(`git` is installed when you installed Homebrew)

#### Set up your `~`

```sh
cd ~
git init
git remote add origin https://github.com/NicholasTD07/dotfiles.git
git pull origin master

# You should have all the files :)
```

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
