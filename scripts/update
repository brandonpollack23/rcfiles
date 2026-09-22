#!/usr/bin/env bash
#MISE description="Update zsh, tmux and neovim plugins (neovim's new versions land in lazy-lock.json)"
set -euo pipefail
zsh -c "source ${XDG_DATA_HOME:-$HOME/.local/share}/antidote/antidote.zsh && antidote update"
~/.tmux/plugins/tpm/bin/update_plugins all
nvim --headless "+Lazy! sync" +qa
