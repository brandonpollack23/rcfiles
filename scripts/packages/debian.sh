# Debian and Ubuntu: just what Homebrew needs from apt, then common and
# homebrew (common.sh) from Homebrew. Ghostty has no .deb or formula;
# install it yourself (https://ghostty.org/docs/install/binary).

apt=(
  build-essential # Compiler and make, for Homebrew and anything it builds
  procps          # ps and friends, which Homebrew uses
  curl            # Downloads the Homebrew installer
  file            # Identifies file types, which Homebrew uses
  git             # Homebrew fetches itself with git
)
