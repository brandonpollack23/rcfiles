#!/usr/bin/env bash
#MISE description="Log in to GitHub (gh), and check git, jj and neovim are ready to use (running deps, stow or plugins for whatever is missing)"
#MISE wait_for=["deps", "stow", "plugins"]
set -euo pipefail

# Anything missing that another task sets up, run that task, then check again.
test -f ~/.cargo/env && source ~/.cargo/env
cmds=(git git-lfs delta difft jj gh nvim lazygit fd rg node npm tree-sitter cc make starship starship-jj erl elixir)
missing() { for cmd in "${cmds[@]}"; do command -v "$cmd" >/dev/null || echo "$cmd"; done; }
linked() { test "$(realpath "$1")" = "$(realpath "$DOTFILES/$2")"; }
# Exits non-zero if a lazy-lock.json plugin is missing.
plugins_installed() {
  nvim --headless "+lua os.exit(#vim.tbl_filter(function(p) return not p._.installed end, require('lazy').plugins()))"
}

if test -n "$(missing)"; then
  echo "setup: missing $(missing | tr '\n' ' '); running deps"
  mise run deps
  test -f ~/.cargo/env && source ~/.cargo/env
  eval "$(mise env -s bash)"
fi
linked ~/.gitconfig git/.gitconfig && linked ~/.config/nvim nvim/.config/nvim || mise run stow
plugins_installed || mise run plugins

# gh: log in, and let git use it for github.com. ~/.gitconfig is in this repo,
# so the credential helper goes in ~/.gitconfig.local (which it includes).
gh auth status >/dev/null 2>&1 || gh auth login
GIT_CONFIG_GLOBAL=~/.gitconfig.local gh auth setup-git

problems=()
for cmd in $(missing); do problems+=("$cmd is not installed"); done
for key in user.name user.email; do
  test -n "$(git config --global "$key")" || problems+=("git $key is not set")
  test -n "$(jj config get "$key" 2>/dev/null)" || problems+=("jj $key is not set")
done
linked ~/.gitconfig git/.gitconfig || problems+=("~/.gitconfig is not linked from this repo")
linked ~/.config/nvim nvim/.config/nvim || problems+=("~/.config/nvim is not linked from this repo")
plugins_installed || problems+=("neovim plugins are missing")

if ((${#problems[@]})); then
  printf 'setup: %s\n' "${problems[@]}" >&2
  exit 1
fi
echo "setup: gh, git, jj and neovim are ready. Neovim installs its parsers and language servers the first time you open it."
