# Package lists, sourced by deps.sh along with the one for this OS
# (scripts/packages/<os>.sh). Not executable, so mise doesn't list them as tasks.

# Named the same in Homebrew and pacman, so installed on every OS.
common=(
  stow            # Symlink farm manager; links dotfiles/ into $HOME
  git             # Version control system
  git-delta       # Syntax-highlighting pager for git diffs (.gitconfig)
  git-lfs         # Git extension for versioning large files
  zsh             # Powerful shell with scripting language
  tmux            # Terminal multiplexer
  neovim          # Hyperextensible Vim-based text editor
  starship        # Cross-shell prompt (starship.toml)
  fzf             # General-purpose command-line fuzzy finder
  zoxide          # Smarter cd that remembers the directories you use
  eza             # A replacement for ls with more features
  bat             # A clone of cat(1) with syntax highlighting and Git integration
  ripgrep         # Recursively searches directories for a regex pattern
  jq              # Command-line JSON processor
  curl            # Command line tool for transferring data with URLs
  chafa           # Displays images in the terminal (the cati alias in .zshrc)
  lolcat          # Rainbow-colors text; the .zshrc welcome message
  sops            # Encrypts this repo's secrets (sops-bootstrap.sh)
  age             # Keys sops encrypts this repo's secrets to (sops-bootstrap.sh)
  difftastic      # Structural, syntax-aware diff (difft; git and jj diffs)
  lazygit         # Terminal UI for git, opened from a neovim keymap
  fd              # A simple, fast and user-friendly alternative to find
  tree-sitter-cli # Builds neovim's tree-sitter parsers
  unzip           # Extracts .zip archives (neovim plugin and tool downloads)
)

# The rest, by their Homebrew names. The Mac, Debian and Fedora install these
# and common from Homebrew: Debian's and Fedora's own repos lack or lag many
# of them (jj, starship, sops, difftastic, lazygit...).
homebrew=(
  jj           # Jujutsu, a Git-compatible VCS, with its own config in dotfiles/jj
  gh           # GitHub's official command line tool
  node         # JavaScript runtime (with npm); neovim language servers need it
  pay-respects # Suggests a fix for the last failed command (a thefuck replacement)
)
