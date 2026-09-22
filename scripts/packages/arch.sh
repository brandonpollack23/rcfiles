# Arch: common (common.sh) and these, all through yay or paru.

arch=(
  jujutsu    # Git-compatible VCS (jj), with its own config in dotfiles/jj
  github-cli # GitHub's official command line tool
  nodejs     # JavaScript runtime; neovim language servers need it
  npm        # Node package manager, for the same
  ghostty    # Fast, native, GPU-accelerated terminal emulator
  base-devel # Compiler, make and friends for building AUR and native packages
)

aur=(
  pay-respects # Suggests a fix for the last failed command (a thefuck replacement)
)
