#!/usr/bin/env bash
#MISE description="Dry run: show what stow would link, and any conflicts with files in $HOME"
#USAGE arg "[package]..." var=#true help="Packages to check (default: all)"
set -euo pipefail
eval "set -- ${usage_package:-}"
test $# -gt 0 || set -- $(ls $DOTFILES)
stow -n -v -d $DOTFILES -t ~ -R "$@"
