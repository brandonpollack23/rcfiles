#!/usr/bin/env bash
#MISE description="Remove a package's links from $HOME"
#USAGE arg "<package>..." var=#true
set -euo pipefail
eval "set -- $usage_package"
stow -v -d $DOTFILES -t ~ -D "$@"
