#!/bin/bash

PACKAGES="
bat
cmake
coreutils
cowsay
curl
deno
fd-find
fzf
fzy
git 
imagemagick
info
neovim
pandoc
ripgrep
ruby
shellcheck
sqlite3
tmux
tree
vim
zsh
"

DEBIAN_PACKAGES="
apt-file
debian-handbook
devscripts
etherwake
fortunes-debian-hints
net-tools
texinfo
wakeonlan
"
ARCH_PACKAGES=""

function get_platform_packages() {
  if [[ "$OSTYPE" =~ linux* ]]; then
    if [[ -f /etc/debian_version ]]; then
      echo $DEBIAN_PACKAGES
    elif [[ -f /etc/arch-release ]]; then
      echo $ARCH_PACKAGES
    fi
    exit 1
  else
    echo "Error: Unknown OS: $OSTYPE" >&2
    exit 1
  fi
}

function update_and_get_package_manager() {
    if [[ "$OSTYPE" =~ linux* ]]; then
      if [[ -f /etc/debian_version ]]; then
        echo "Debian based system detected"
        [ "$EUID" -eq 0 ] && echo "apt install -y" || echo "sudo apt install -y"
      fi
      if [[ -f /etc/arch-release ]]; then
        echo "Arch based OS detected, updating system"
        if [ -x "$(command -v pamac)" ]; then
          [ "$EUID" -eq 0 ] && (pamac update || sudo pamac update)
          [ "$EUID" -eq 0 ] && (echo "pamac install -a" || echo "sudo pamac install -a")
        elif [ -x "$(command -v yay)" ]; then
          [ "$EUID" -eq 0 ] && (yay -Syu || sudo yay -Syu)
          [ "$EUID" -eq 0 ] && (echo "yay -S" || echo "sudo yay -S")
        else
          [ "$EUID" -eq 0 ] && (pacman -Syu || sudo pacman -Syu)
          [ "$EUID" -eq 0 ] && echo "pacman -S" || echo "sudo pacman -S"
        fi
      fi
    else
        echo "Error: Unknown OS: $OSTYPE" >&2
        exit 1
    fi
}

function handle_mac_setup() {
  echo "Package manager is brew--Macintosh, baby!"
  echo "Gotta install it first"
  if ! command -v brew &> /dev/null; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      PATH=/opt/homebrew/bin:$PATH
  fi
  # Run brew bundle, this installs all the needed packages (such better than a list)
  brew bundle --file="$RCFILES_DIR/Brewfile"
}

function handle_linux_setup() {
  INSTALL_COMMAND=$(update_and_get_package_manager)

  # Install all the packages
  for package in $PACKAGES; do
    echo "Installing $package"
    $INSTALL_COMMAND "$package"
    # If there was an error let the user know
    if [ $? -ne 0 ]; then
      echo "Error installing $package"
    fi
  done

  for package in $(get_platform_packages); do
    echo "Installing $package"
    $INSTALL_COMMAND "$package"
    # If there was an error let the user know
    if [ $? -ne 0 ]; then
      echo "Error installing $package"
    fi
  done
}

function setup_home_dir() {
  mkdir -p $HOME/.vim/backupdir
  mkdir -p $HOME/.vim/swapdir
  touch ~/.vimrc.local
  mkdir -p $HOME/.config
  mkdir -p $HOME/.local

  ln -sfn $RCFILESDIR/.zshrc $HOME/.zshrc
  ln -sfn $RCFILESDIR/zsh-plugins $HOME/zsh-plugins
  ln -sfn $RCFILESDIR/zsh-my-completions $HOME/zsh-my-completions
  ln -sfn $RCFILESDIR/nix-zsh-completions $HOME/nix-zsh-completions
  ln -sfn $RCFILESDIR/.oh-my-zsh $HOME/.oh-my-zsh
  ln -sfn $RCFILESDIR/.vimrc $HOME/.vimrc
  ln -sfn $RCFILESDIR/.tmux.conf $HOME/.tmux.conf
  ln -sfn $RCFILESDIR/.tmux $HOME/.tmux
  ln -sfn $RCFILESDIR/.gitconfig $HOME/.gitconfig
  ln -sfn $RCFILESDIR/.vim/pack $HOME/.vim/pack
  ln -sfn $RCFILESDIR/.vim/colors $HOME/.vim/colors
  ln -sfn $RCFILESDIR/.config/nvim $HOME/.config/nvim
  ln -sfn $RCFILESDIR/.cowrc $HOME/.cowrc
  ln -sfn $RCFILESDIR/.cowfiles $HOME/.cowfiles
}

# Debugging enabled
set -x # Print commands to terminal
set -e # Exit on error

if [[ -z $HOME ]];then
  echo "must have a home directory!"
fi

echo "Executing install.sh for $USER"

RCFILES_DIR="${BASH_SOURCE[0]}"

echo "Installing to home directory: $HOME"

if [[ "$OSTYPE" =~ darwin* ]]; then
  handle_mac_setup
elif [[ "$OSTYPE" =~ linux* ]]; then
  handle_linux_setup
else
  echo "Error: Unknown OS: $OSTYPE" >&2
  exit 1
fi


# Install node version manager and latest node version
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install node

# Install Nix package manager
echo "Installing nix package manager..."
sudo sh <(curl -L https://nixos.org/nix/install) --daemon

# Install golang
curl https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash

# Install rust etc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
cargo install cargo-binstall
cargo install --locked cargo-outdated
cargo binstall --no-confirm mdcat
cargo binstall --no-confirm bat
cargo binstall --no-confirm git-delta
cargo install --git https://github.com/neovide/neovide # NVim gui

# Install python stuff and rye
curl -sSf https://rye.astral.sh/get | bash
rye install pylint
rye install mypy

# Install asdf, erlang, and elixir
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
. "$HOME/.asdf/asdf.sh"
asdf plugin add erlang
asdf plugin add elixir
# Install elixir and erlang from source and set them as global
asdf install erlang ref:OTP-26.2.1
asdf global erlang ref:OTP-26.2.1
asdf reshim
# Set them as global
asdf install elixir ref:v1.17.0
asdf global elixir ref:v1.17
asdf reshim

setup_home_dir

# Setup shell
chsh -s `which zsh` $USER

# TODO setup fortunes
