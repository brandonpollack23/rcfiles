#!/usr/bin/env bash
#MISE description="Stow a package over existing files in $HOME, moving them into the repo (review with `jj diff` after)"
#USAGE arg "<package>..." var=#true
set -euo pipefail
eval "set -- $usage_package"
mkdir -p ~/.config ~/.config/git ~/.config/systemd/user ~/.local/bin ~/.local/share ~/.claude
stow -v -d $DOTFILES -t ~ --adopt "$@"
echo "Adopted. The repo now has the files that were in \$HOME; review them with 'jj diff' and restore what you don't want."
