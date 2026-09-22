#!/usr/bin/env bash
#MISE description="Move files or directories from $HOME into a package (new or existing) and link them back"
#USAGE arg "<package>" help="Package name, e.g. btop"
#USAGE arg "<path>..." var=#true help="Files or directories under $HOME, e.g. ~/.config/btop"
set -euo pipefail
pkg=$usage_package
eval "set -- $usage_path"
for path in "$@"; do
  abs=$(realpath -s "$path")
  rel=${abs#"$HOME"/}
  if [[ "$rel" == "$abs" ]]; then
    echo "$path is not under $HOME" >&2; exit 1
  fi
  if [[ -L "$abs" ]]; then
    echo "$path is already a symlink (-> $(readlink "$abs")); skipping" >&2; continue
  fi
  if [[ -e "$DOTFILES/$pkg/$rel" ]]; then
    echo "$DOTFILES/$pkg/$rel already exists" >&2; exit 1
  fi
  mkdir -p "$DOTFILES/$pkg/$(dirname "$rel")"
  mv "$abs" "$DOTFILES/$pkg/$rel"
  echo "Moved ~/$rel into $pkg"
done
stow -v -d $DOTFILES -t ~ "$pkg"
