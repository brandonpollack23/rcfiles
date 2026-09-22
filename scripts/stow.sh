#!/usr/bin/env bash
#MISE description="Link packages into $HOME (all of them if none are named)"
#MISE wait_for=["deps"]
#USAGE arg "[package]..." var=#true help="Packages to link (default: all)"
set -euo pipefail
eval "set -- ${usage_package:-}"
test $# -gt 0 || set -- $(ls $DOTFILES)
# Stow links a whole directory when it doesn't exist in $HOME yet. For these
# shared ones that would put other programs' files into this repo, so make
# sure they are real directories first.
mkdir -p ~/.config ~/.config/git ~/.config/systemd/user ~/.local/bin ~/.local/share ~/.claude
stow -v -d $DOTFILES -t ~ -R "$@"
