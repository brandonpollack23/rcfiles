# Fedora: just what Homebrew needs from dnf, then common and homebrew
# (common.sh) from Homebrew. Ghostty is in a COPR, not the Fedora repos;
# install it yourself (https://ghostty.org/docs/install/binary).

dnf_groups=(
  development-tools # Compiler and make, for Homebrew and anything it builds
)

dnf=(
  procps-ng # ps and friends, which Homebrew uses
  curl      # Downloads the Homebrew installer
  file      # Identifies file types, which Homebrew uses
  git       # Homebrew fetches itself with git
)
