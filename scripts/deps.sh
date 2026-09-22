#!/usr/bin/env bash
#MISE description="Install the programs these dotfiles need (lists in scripts/packages: Homebrew and the Brewfile on the Mac, pacman/AUR on Arch, Homebrew on Debian and Fedora), Rust (rustup), Erlang and Elixir (mise)"
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/os.sh"

scripts=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
source "$scripts/packages/common.sh"
source "$scripts/packages/$OS.sh"

mac_deps() {
  ensure_brew
  brew install "${common[@]}" "${homebrew[@]}"
  brew install --cask "${cask[@]}"
  brew bundle --file "$MISE_CONFIG_ROOT/Brewfile"
}

# yay isn't in the official repos, so build yay-bin from the AUR.
install_yay() {
  sudo pacman -S --needed git base-devel
  local build
  build=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$build/yay-bin"
  (cd "$build/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$build"
}

arch_deps() {
  command -v yay >/dev/null || command -v paru >/dev/null || install_yay
  local aur_helper=yay
  command -v yay >/dev/null || aur_helper=paru
  "$aur_helper" -S --needed "${common[@]}" "${arch[@]}" "${aur[@]}"
}

debian_deps() {
  sudo apt-get update
  sudo apt-get install -y "${apt[@]}"
  brew_deps
}

fedora_deps() {
  sudo dnf group install -y "${dnf_groups[@]}"
  sudo dnf install -y "${dnf[@]}"
  brew_deps
}

brew_deps() {
  ensure_brew
  brew install "${common[@]}" "${homebrew[@]}"
}

for_os deps

# Rust, through rustup (its own installer, so it's the same on every OS).
# ~/.cargo/env puts cargo on PATH; .zshrc sources it too.
if ! test -x ~/.cargo/bin/rustup && ! command -v rustup >/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
test -f ~/.cargo/env && source ~/.cargo/env
rustup default >/dev/null 2>&1 || rustup default stable

# The prompt's jj module (see starship.toml) isn't packaged anywhere; it's a crate.
if ! command -v starship-jj >/dev/null; then
  if command -v cargo-binstall >/dev/null; then
    cargo binstall -y starship-jj
  else
    cargo install --locked starship-jj
  fi
fi

# Erlang and Elixir: the latest stable releases, pinned in ~/.config/mise/config.toml.
mise use -g erlang@latest elixir@latest
