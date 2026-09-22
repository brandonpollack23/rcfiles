#!/usr/bin/env bash
# Sets up a new machine. Installs mise, has mise fetch amber and yq (the tasks
# in scripts/ are Amber, run from source), then runs `mise run install`.
# Bash 3.2 compatible: this runs on a fresh Mac. Safe to run again.
set -euo pipefail
cd "$(dirname "$0")"

os=linux
case "$OSTYPE" in darwin*) os=mac ;; esac
if [[ "$os" != mac && -f /etc/os-release ]]; then
  ID="" ID_LIKE=""
  # shellcheck disable=SC1091
  source /etc/os-release
  case " $ID $ID_LIKE " in *" arch "*) os=arch ;; esac
fi

if ! command -v mise >/dev/null; then
  case "$os" in
    mac)
      for brew in brew /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if command -v "$brew" >/dev/null; then
          eval "$("$brew" shellenv)"
          break
        fi
      done
      if ! command -v brew >/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
      fi
      brew install mise
      ;;
    arch) sudo pacman -S --needed mise ;;
    # mise's own installer, into ~/.local/bin (on PATH in .zshrc).
    *)
      curl -fsSL https://mise.run | sh
      export PATH="$HOME/.local/bin:$PATH"
      ;;
  esac
fi

mise trust
mise install
exec mise run install
