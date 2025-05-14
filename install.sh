#!/bin/bash

# Define an array to hold the package names
PACKAGES=(
  asciinema    # Record and share terminal sessions
  bat          # A clone of cat(1) with syntax highlighting and Git integration
  chafa        # An Image display program that will use the best way to display an image
  cmake        # Cross-platform open-source make system
  coreutils    # Basic file, shell, and text manipulation utilities
  cowsay       # Configurable talking cow (or other character) in terminal
  curl         # Command line tool for transferring data with URLs
  deno         # A secure runtime for JavaScript and TypeScript
  eza          # A replacement for ls with more features
  fcitx5       # Input method framework
  fcitx5-mozc  # Mozc engine for Fcitx5, typically used for Japanese input
  fd           # A simple, fast and user-friendly alternative to find
  firefox      # Popular open-source web browser
  fzf          # General-purpose command-line fuzzy finder
  fzy          # A better fuzzy finder for the command line
  git          # Version control system
  git-absorb   # Automatically fix up commits with the knowledge of Git history
  geckodriver  # WebDriver for Firefox
  gource       # Visualize Git repositories as a tree
  gum          # A tool for making fancy terminal scripts
  imagemagick  # Software suite to create, edit, compose, or convert images
  luajit       # Just-In-Time Compiler (JIT) for the Lua programming language
  luarocks     # Package manager for Lua modules
  make         # Utility for directing compilation
  maven        # Build automation tool used primarily for Java projects
  mise         # A fast alternative to direnv, asdf, etc in rust
  neovim       # Hyperextensible Vim-based text editor
  jdk-openjdk  # OpenJDK Development Kit
  pandoc       # Universal document converter
  ripgrep      # Recursively searches directories for a regex pattern
  ruby         # Dynamic, open source programming language
  shellcheck   # Static analysis tool for shell scripts
  sqlite3      # Command line interface for SQLite databases
  tmux         # Terminal multiplexer
  tree         # Display directories as trees
  ts-node      # TypeScript execution environment for Node.js
  vim          # Highly configurable text editor
  xclip        # Command line interface to the X clipboard
  zsh          # Powerful shell with scripting language
)

DEBIAN_PACKAGES=(
  apt-file                  # Search for files within Debian packages
  debian-handbook           # Comprehensive guide to Debian system administration
  devscripts                # Scripts to assist with Debian packaging
  etherwake                 # Tool for sending Wake-On-LAN packets
  fd-find                   # A simple, fast and user-friendly alternative to find
  fortunes-debian-hints     # Collection of Debian-related fortune cookies
  info                      # Read Info documents
  libgraphicsmagick1-dev    # Development files for the GraphicsMagick library
  libmagickwand-dev         # Development files for the ImageMagick Wand API
  net-tools                 # Networking utilities like ifconfig and netstat
  texinfo                   # GNU documentation system for on-line information and printed output
  wakeonlan                 # Send Wake-On-LAN magic packets
)

ARCH_PACKAGES=(
  alacritty       # A fast, cross-platform, OpenGL terminal emulator
  bitwarden       # Secure, open source password manager for all of your devices
  bitwarden-cli   # Command-line interface for Bitwarden
  fd              # A simple, fast and user-friendly alternative to find
  git-branchless  # Perform branchless version control operations with Git
  github-cli      # GitHub’s official command line tool
  inotify-tools   # Command-line utilities for monitoring file system events
  kio-gdrive      # KIO slave for Google Drive integration with KDE
  neovide         # Neovim client in a fully featured graphical user interface
  tlp             # Advanced power management tool for Linux
  tlpui           # Graphical user interface for TLP

  # Erlang stuff
  fop             # XSL-FO print formatter for Erlang
  glu             # Mesa OpenGL utility library (needed for erlang)
  libpng          # Library for manipulating PNG images (needed for erlang)
  libxslt         # XML stylesheet language transformation library (needed for erlang)
  mesa            # Open-source implementation of the OpenGL specification (needed for erlang)
  unixodbc        # Open Database Connectivity standard for Erlang
  wxwidgets-gtk3  # C++ library for writing GUI applications (needed for erlang)
)

MANJARO_ONLY_PACKAGES=(
  libpamac-flatpak-plugin  # Flatpak plugin for Pamac, the package manager for Manjaro
  libpamac-snap-plugin     # Snap plugin for Pamac, the package manager for Manjaro
)

AUR_ARCH_PACKAGES=(
  bazelisk-bin     # Bazelisk is a wrapper for Bazel that automatically downloads and uses the correct version of Bazel
  changie          # changelog generator used by pulumi
  neovim-nightly   # Latest nightly build of Neovim
  obsidian         # Powerful knowledge base on top of a local folder of plain text Markdown files
  tmux-mem-cpu-load
)

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
      echo "${DEBIAN_PACKAGES[@]}"
    elif [[ -f /etc/arch-release ]]; then
      echo "${ARCH_PACKAGES[@]}"

      # Also manjaro packages if needed.
      if [ -x "$(command -v pamac)" ]; then
        echo "${MANJARO_ONLY_PACKAGES[@]}"
      fi
    fi
    exit 1
  elif [[ "$OSTYPE" =~ darwin* ]]; then
    exit 1
  else
    echo "Error: Unknown OS: $OSTYPE" >&2
    exit 1
  fi
}

function get_aur_packages() {
  if [[ "$OSTYPE" =~ linux* ]]; then
    if [[ -f /etc/arch-release ]]; then
      echo "${AUR_ARCH_PACKAGES[@]}"
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
  for package in "${PACKAGES[@]}"; do
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

  ln -sfn "$RCFILES_DIR/.config/nvim" "$HOME/.config/nvim"
  ln -sfn "$RCFILES_DIR/.config/ghostty" "$HOME/.config/ghostty"
  ln -sfn "$RCFILES_DIR/.cowfiles" "$HOME/.cowfiles"
  ln -sfn "$RCFILES_DIR/.cowrc" "$HOME/.cowrc"
  ln -sfn "$RCFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  ln -sfn "$RCFILES_DIR/.oh-my-zsh" "$HOME/.oh-my-zsh"
  ln -sfn "$RCFILES_DIR/.tmux" "$HOME/.tmux"
  ln -sfn "$RCFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
  ln -sfn "$RCFILES_DIR/.vim/colors" "$HOME/.vim/colors"
  ln -sfn "$RCFILES_DIR/.vim/pack" "$HOME/.vim/pack"
  ln -sfn "$RCFILES_DIR/.vimrc" "$HOME/.vimrc"
  ln -sfn "$RCFILES_DIR/.wezterm.lua" "$HOME/.wezterm.lua"
  ln -sfn "$RCFILES_DIR/.zshrc" "$HOME/.zshrc"
  ln -sfn "$RCFILES_DIR/.zshrc.githubcopilot" "$HOME/.zshrc.githubcopilot"
  ln -sfn "$RCFILES_DIR/nix-zsh-completions" "$HOME/nix-zsh-completions"
  ln -sfn "$RCFILES_DIR/zsh-my-completions" "$HOME/zsh-my-completions"
  ln -sfn "$RCFILES_DIR/zsh-plugins" "$HOME/zsh-plugins"
  ln -sfn "$RCFILES_DIR/.golangci.yml" "$HOME/.golangci.yml"
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

# Nodejs
mise use -g node@latest
mise use -g deno@latest
mise use -g bun@latest
mise use -g pnpm@latest
mise use -g yarn@latest

# Install Nix package manager
echo "Installing nix package manager..."
sudo sh <(curl -L https://nixos.org/nix/install) --daemon

# Install golang
mise use -g go@latest

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
if [[ -x "$(command -v git-branchless)" ]]; then
  cargo binstall --no-confirm git-branchless
fi
cargo binstall tree-sitter-cli
cargo install --git https://github.com/neovide/neovide # NVim gui

# Install python stuff and uv
mise use -g uv@latest

# Erlang/Elixir setup
mise use --global elixir@1.18.2-otp-27
mise use --global erlang@27.2.4
yes | mix archive.install hex mix_templates
yes | mix archive.install hex mix_generator
yes | mix template.install hex gen_template_template
yes | mix template.install hex bpollack_elixir_template
mix do local.rebar --force, local.hex --force
mix escript.install hex livebook


setup_home_dir

# Setup shell
chsh -s `which zsh` $USER

# TODO setup fortunes
