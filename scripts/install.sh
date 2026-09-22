#!/usr/bin/env bash
#MISE description="Set up a new machine: dependencies, links, plugins, fonts, secrets, gh login"
#MISE depends=["deps", "stow", "plugins", "fonts", "sops-bootstrap", "setup"]
# Also ./install.sh at the repo root (a symlink to this). Run that way, outside
# mise, it installs mise and then runs this as the `install` task.
set -euo pipefail
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/os.sh"

mac_install_mise() {
  ensure_brew
  brew install mise
}
arch_install_mise() { sudo pacman -S --needed mise; }
# mise's own installer, into ~/.local/bin (on PATH in .zshrc).
linux_install_mise() {
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
}

mac_login_shell() { dscl . -read "$HOME" UserShell | awk '{print $2}'; }
linux_login_shell() { getent passwd "$USER" | cut -d: -f7; }

# Outside mise: install it, then rerun this as the `install` task.
if [[ -z "${MISE_TASK_NAME:-}" ]]; then
  cd "$(dirname "$(realpath "$0")")/.."
  command -v mise >/dev/null || for_os install_mise
  mise trust
  exec mise run install
fi

# mise depends handles installations, now just set up shell

login_shell=$(for_os login_shell)
if [[ "$(basename "$login_shell")" != zsh ]]; then
  zsh_path=$(command -v zsh)
  if [[ -t 0 ]]; then
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    chsh -s "$zsh_path"
  else
    echo "Your login shell is $login_shell. Switch to zsh with: chsh -s $zsh_path"
  fi
fi
