#!/bin/bash

PACKAGES="
bat
cmake
coreutils
cowsay
curl
deno
fd
fzf
fzy
git 
imagemagick
make
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
xclip
"

DEBIAN_PACKAGES="
apt-file
debian-handbook
devscripts
etherwake
fd-find
fortunes-debian-hints
info
net-tools
texinfo
wakeonlan
"

ARCH_PACKAGES="
alacritty
bitwarden
bitwarden-cli
fd
neovide
"

MANJARO_ONLY_PACKAGES="
libpamac-flatpack-plugin
libpamac-snap-plugin
"

AUR_ARCH_PACKAGES="
google-chrome
neovim-nightly
obsidian
"

ask_confirmation() {
  read -p "You are running this script as root. Are you sure you want to continue? (yes/no): " response
  case "$response" in
    [yY][eE][sS]|[yY])
      return 0  # User confirmed to continue
      ;;
    *)
      echo "Exiting the script."
      exit 1  # User chose not to continue
      ;;
  esac
}

function get_platform_packages() {
  if [[ "$OSTYPE" =~ linux* ]]; then
    if [[ -f /etc/debian_version ]]; then
      echo "$DEBIAN_PACKAGES"
    elif [[ -f /etc/arch-release ]]; then
      echo "$ARCH_PACKAGES"

      # Also manjaro packages if needed.
      if [ -x "$(command -v pamac)" ]; then
        echo "$MANJARO_ONLY_PACKAGES"
      fi
    fi
    exit 1
  else
    echo "Error: Unknown OS: $OSTYPE" >&2
    exit 1
  fi
}

function get_aur_packages() {
  if [[ "$OSTYPE" =~ linux* ]]; then
    if [[ -f /etc/arch-release ]]; then
      echo "$AUR_ARCH_PACKAGES"
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
	sudo apt update >&2
        [ "$EUID" -eq 0 ] && echo "apt install -y" || echo "sudo apt install -y"
      fi
      if [[ -f /etc/arch-release ]]; then
        echo "Arch based OS detected, updating system" >&2
        if [ -x "$(command -v pamac)" ]; then
          if [[ "$EUID" -eq 0 ]]; then
            pamac update >&2
          else
            sudo pamac update >&2
          fi

          if [[ "$EUID" -eq 0 ]]; then
            echo "pamac install --no-confirm"
          else
            echo "sudo pamac install --no-confirm"
          fi
        elif [ -x "$(command -v yay)" ]; then
          if [[ "$EUID" -eq 0 ]]; then
            yay -Syu >&2
          else
            sudo yay -Syu >&2
          fi

          if [[ "$EUID" -eq 0 ]]; then
            echo "yay -S --noconfirm"
          else
            echo "sudo yay -S --noconfirm"
          fi
        else
          if [[ "$EUID" -eq 0 ]]; then
            pacman -Syu >&2
          else
            sudo pacman -Syu >&2
          fi

          if [[ "$EUID" -eq 0 ]]; then
            echo "pacman -S --noconfirm"
          else
            echo "sudo pacman -S --noconfirm"
          fi
        fi
      fi
    else
        echo "Error: Unknown OS: $OSTYPE" >&2
        exit 1
    fi
}

function get_aur_install_command() {
  if [[ "$OSTYPE" =~ linux* ]]; then
    if [[ -f /etc/debian_version ]]; then
      echo "apt install -y"
    elif [[ -f /etc/arch-release && -x "$(command -v pamac)" ]]; then
      echo "pamac build --no-confirm"
    elif [[ -f /etc/arch-release && -x "$(command -v yay)" ]]; then
      echo "yay -S --noconfirm"
    elif [[ -f /etc/arch-release ]]; then
      echo "pacman -S --noconfirm"
    fi
  else
    echo "Error: Unknown OS: $OSTYPE" >&2
    exit 1
  fi
}

function install_aur_packages() {
  AUR_INSTALL_COMMAND=$(get_aur_install_command)

  echo "Install command set to '$AUR_INSTALL_COMMAND'" >&2

  FAILED_PACKAGES=""
  # Install all the packages
  for package in $(get_aur_packages); do
    echo "Installing $package"
    $AUR_INSTALL_COMMAND "$package"
    # If there was an error let the user know
    if [ $? -ne 0 ]; then
      FAILED_PACKAGES="$package $FAILED_PACKAGES"
      echo "Error installing $package"
    fi
  done

  # If there were any failed packages, let the user know
  if [ -n "$FAILED_PACKAGES" ]; then
    echo "Failed to install the following packages: $FAILED_PACKAGES" >&2
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

  echo "Install command set to '$INSTALL_COMMAND'" >&2

  FAILED_PACKAGES=""
  # Install all the packages
  for package in $PACKAGES; do
    echo "Installing $package"
    $INSTALL_COMMAND "$package"
    # If there was an error let the user know
    if [ $? -ne 0 ]; then
      FAILED_PACKAGES="$package $FAILED_PACKAGES"
      echo "Error installing $package"
    fi
  done

  for package in $(get_platform_packages); do
    echo "Installing $package"
    $INSTALL_COMMAND "$package"
    # If there was an error let the user know
    if [ $? -ne 0 ]; then
      FAILED_PACKAGES="$package $FAILED_PACKAGES"
      echo "Error installing $package"
    fi
  done

  # If arch do aur packages
  if [[ -f /etc/arch-release ]]; then
    install_aur_packages
  fi

  # If there were any failed packages, let the user know
  if [ -n "$FAILED_PACKAGES" ]; then
    echo "Failed to install the following packages: $FAILED_PACKAGES" >&2
  fi
}

function setup_home_dir() {
  mkdir -p "$HOME/.vim/backupdir"
  mkdir -p "$HOME/.vim/swapdir"
  touch ~/.vimrc.local
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local"

  ln -sfn "$RCFILES_DIR/.zshrc" "$HOME/.zshrc"
  ln -sfn "$RCFILES_DIR/zsh-plugins" "$HOME/zsh-plugins"
  ln -sfn "$RCFILES_DIR/zsh-my-completions" "$HOME/zsh-my-completions"
  ln -sfn "$RCFILES_DIR/nix-zsh-completions" "$HOME/nix-zsh-completions"
  ln -sfn "$RCFILES_DIR/.oh-my-zsh" "$HOME/.oh-my-zsh"
  ln -sfn "$RCFILES_DIR/.vimrc" "$HOME/.vimrc"
  ln -sfn "$RCFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  ln -sfn "$RCFILES_DIR/.tmux" "$HOME/.tmux"
  ln -sfn "$RCFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  ln -sfn "$RCFILES_DIR/.vim/pack" "$HOME/.vim/pack"
  ln -sfn "$RCFILES_DIR/.vim/colors" "$HOME/.vim/colors"
  ln -sfn "$RCFILES_DIR/.config/nvim" "$HOME/.config/nvim"
  ln -sfn "$RCFILES_DIR/.cowrc" "$HOME/.cowrc"
  ln -sfn "$RCFILES_DIR/.cowfiles" "$HOME/.cowfiles"
}

# Debugging enabled
# set -x # Print commands to terminal
# set -e # Exit on error

# Check if the script is running as root
if [ "$EUID" -eq 0 ]; then
  ask_confirmation
fi

if [[ -z $HOME ]];then
  echo "must have a home directory!"
fi

echo "Executing install.sh for $USER"

echo "Installing to home directory: $HOME"

if [[ "$OSTYPE" =~ darwin* ]]; then
  handle_mac_setup
elif [[ "$OSTYPE" =~ linux* ]]; then
  handle_linux_setup
else
  echo "Error: Unknown OS: $OSTYPE" >&2
  exit 1
fi

RCFILES_DIR="$(dirname "$(realpath "$0")")"

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
if [[ -x "$(command -v fd)" ]]; then
  cargo binstall --no-confirm fd-find
fi
cargo install --git https://github.com/neovide/neovide # NVim gui

# Install python stuff and rye
curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash
rye install pylint
rye install mypy
if [[ "$XDG_CURRENT_DESKTOP" -eq "KDE" ]]; then
  rye install konsave
  konsave -i $RCFILES_DIR/kde_konsave_profile.knsv
  konsave -a kde_konsave_profile
fi

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
