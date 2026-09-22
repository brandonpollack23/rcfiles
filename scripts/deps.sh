#!/usr/bin/env bash
#MISE description="Install the programs in packages.txt (Homebrew, casks and the App Store on the Mac, pacman/AUR on Arch, Homebrew on Debian and Fedora, cargo binstall everywhere), Rust (rustup), Erlang and Elixir (mise)"
#USAGE flag "-n --dry-run" help="Print the install commands instead of running them"
#USAGE arg "[group]..." var=#true help="Groups from packages.txt to install besides core (and mac on the Mac), or all. Default: the ones picked last time, asking the first time"
# Bash 3.2 compatible: this runs on a fresh Mac before Homebrew's bash is there.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/os.sh"
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/packages.sh"

saved_groups="${XDG_CONFIG_HOME:-$HOME/.config}/rcfiles/groups"
dry_run=${usage_dry_run:-false}

run() {
  if [[ "$dry_run" == true ]]; then
    echo "$*"
  else
    "$@"
  fi
}

# The optional groups to install: named on the command line, else the ones
# picked last time, else asked for (and saved).
pick_groups() {
  local picked=() name desc answer
  eval "set -- ${usage_group:-}"
  if (($#)); then
    [[ "$*" == all ]] && set -- $(all_groups | cut -f1 | grep -vxE 'core|mac')
    for name in "$@"; do
      all_groups | cut -f1 | grep -qxF "$name" || {
        echo "deps: no group $name in packages.txt" >&2
        exit 1
      }
    done
    picked=("$@")
  elif test -f "$saved_groups"; then
    cat "$saved_groups"
    return
  elif [[ -t 0 ]]; then
    echo "core goes on every machine$([[ "$OS" != mac ]] || echo ", and mac on every Mac"). Which of these should this one have?" >&2
    while IFS=$'\t' read -r name desc; do
      [[ "$name" == core || "$name" == mac ]] && continue
      read -rp "  $name: $desc? [y/N] " answer </dev/tty
      [[ "$answer" == [yY]* ]] && picked+=("$name")
    done < <(all_groups)
  else
    echo "deps: installing core only; name more groups with: mise run deps <group>..." >&2
  fi
  [[ "$dry_run" == true ]] || {
    mkdir -p "$(dirname "$saved_groups")"
    printf '%s\n' ${picked[@]+"${picked[@]}"} >"$saved_groups"
    echo "deps: saved the groups in $saved_groups" >&2
  }
  printf '%s\n' ${picked[@]+"${picked[@]}"}
}

picked=$(pick_groups)
groups="core $([[ "$OS" != mac ]] || echo mac) $(echo $picked)"
echo "deps: installing" $groups >&2

read_packages $groups

brew_deps() {
  run ensure_brew
  ((${#brew[@]} == 0)) || run brew install "${brew[@]}"
}

mac_deps() {
  brew_deps
  ((${#cask[@]} == 0)) || run brew install --cask "${cask[@]}"
  ((${#mas[@]} == 0)) || run mas install "${mas[@]}"
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
  command -v yay >/dev/null || command -v paru >/dev/null || run install_yay
  local aur_helper=yay
  command -v yay >/dev/null || aur_helper=paru
  run "$aur_helper" -S --needed "${pacman[@]}"
}

# Debian and Fedora: just what Homebrew needs from the system, then everything
# else from Homebrew; their own repos lack or lag many of these (jj, starship,
# sops, difftastic, lazygit...).
debian_deps() {
  run sudo apt-get update
  run sudo apt-get install -y build-essential procps curl file git
  brew_deps
}

fedora_deps() {
  run sudo dnf group install -y development-tools
  run sudo dnf install -y procps-ng curl file git
  brew_deps
}

for_os deps

# Rust, through rustup (its own installer, so it's the same on every OS).
# ~/.cargo/env puts cargo on PATH; .zshrc sources it too.
if [[ "$dry_run" != true ]]; then
  if ! test -x ~/.cargo/bin/rustup && ! command -v rustup >/dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  fi
  test -f ~/.cargo/env && source ~/.cargo/env
  rustup default >/dev/null 2>&1 || rustup default stable
fi

((${#cargo[@]} == 0)) || run cargo binstall -y "${cargo[@]}"

# Erlang and Elixir: the latest stable releases, pinned in ~/.config/mise/config.toml.
run mise use -g erlang@latest elixir@latest
