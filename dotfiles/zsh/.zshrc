#!/bin/zsh
# To profile uncomment below and the last line of the config
# zmodload zsh/zprof

# Detect if in chroot (good for prompt and cros development)
if [[ "$(ls -di /)" != "2 /" ]]; then
    export HOST="$HOST-chroot"
fi

# Fix dumb terminal usage for emacs TRAMP
if [[ "$TERM" == "dumb" ]]; then
    unsetopt zle
    unsetopt prompt_cr
    unsetopt prompt_subst
    if whence -w precmd >/dev/null; then
        unfunction precmd
    fi
    if whence -w preexec >/dev/null; then
        unfunction preexec
    fi
    if [[ "$UUID" -eq 0 ]]; then
        PS1='# '
    else
        PS1='$ '
    fi
fi

export PATH="$PATH:$HOME/.local/scripts:$HOME/bin:$HOME/.pulumi/bin:$HOME/.ghcup/bin:$HOME/.emacs.d/bin:$HOME/bin:/usr/games/:$HOME/.local/bin"
if ! [[ "$OSTYPE" =~ darwin* ]]; then
    export PATH=/opt/homebrew/bin:$PATH
fi
export MANPATH="$HOME/man/":$MANPATH

#rustup
[[ -f $HOME/.cargo/env ]] && source $HOME/.cargo/env

export EDITOR="nvim" # opens in terminal
export ALTERNATE_EDITOR="vi"

export CLOUDSDK_HOME=$HOME/bin/google-cloud-sdk

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="candy"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="mm/dd/yyyy"

# Plugins are listed in ~/.zsh_plugins.txt and loaded by antidote below.
# These tell its conditional: annotations whether to load a plugin.
function is-macos() { [[ "$OSTYPE" == darwin* ]] }
function is-not-vim() { [[ -z "$VIM" ]] }

if is-not-vim; then
  # Vi Mode Setup
  VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
  VI_MODE_SET_CURSOR=true
  MODE_INDICATOR='%B%F{red}<<<NORMAL MODE%b%f'

  # Key bindings (like normal to insert mode in vi mode)
  bindkey -M viins 'jk' vi-cmd-mode
fi

# fzf setup
export FZF_DEFAULT_OPTS='--bind ctrl-f:page-down,ctrl-b:page-up'

# zoxide setup
export ZOXIDE_CMD_OVERRIDE="cd"

# antidote clones itself and the plugins on first start. It keeps them in
# ~/.cache/antidote (~/Library/Caches/antidote on the Mac).
ANTIDOTE_DIR=${XDG_DATA_HOME:-$HOME/.local/share}/antidote
if [[ ! -d $ANTIDOTE_DIR ]]; then
    git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_DIR"
fi
zstyle ':antidote:bundle' use-friendly-names 'yes'
source $ANTIDOTE_DIR/antidote.zsh
antidote load

# Keybinds

# vi-mode resets keymaps, so restore fzf-tab after all plugins have loaded.
bindkey -M emacs '^I' fzf-tab-complete
bindkey -M viins '^I' fzf-tab-complete
bindkey '^R' fzf-history-widget

# History search
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

#################### User configuration ###############################
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

# The prompt is starship; see the bottom of this file and ~/.config/starship.toml.

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias pls='sudo $(fc -ln -1)'
alias fuck=pls
alias :q="exit"

# ls aliases
alias ls="eza --group-directories-first --git"
alias ll="eza -l --group-directories-first --git"
alias la="eza -la --group-directories-first --git"
alias tree="eza -T --group-directories-first --git"

export UNDERLYING_TERM=$(tmux display-message -p "#{client_termname}")
alias cati='TERM=$UNDERLYING_TERM chafa'

# Used for neovim workspaces.
export PROJECT_DIRS="$HOME/src"

# node/js/deno stuff
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

if [[ -f /etc/debian_version ]]; then
    # Apt
    alias sau="sudo apt update"
    alias saup="sudo apt upgrade"
    alias sai="sudo apt install"
    alias sar="sudo apt remove"
  alias as="apt search"
    alias asho="apt show"
elif [ -x "$(command -v pamac)" ]; then
  function display_pkg_build() {
    pamac clone $1
    bat /var/tmp/pamac-build-$USER/$1/PKGBUILD
  }
  function pP() {
    display_pkg_build
  }

  alias p="pamac"
  alias pi="pamac install"
  alias pb="pamac build"
  alias pI="pamac info"
  alias pr="pamac remove"
  alias pu="pamac update"
fi

# Application default arguments
alias mdless="mdless -I"
export LESS="-R -I"

# Override some common aliases
alias -g G='| rg'
alias -g L='| bat'
alias -g LL='2>&1 | bat'

# Override date to print many dates
function dates() {
    echo "UTC: $(TZ=UTC date)\n"
    echo "JST: $(TZ=Asia/Tokyo date)\n"
    echo "PST: $(TZ=America/Los_Angeles date)\n"
    echo "EST: $(TZ=America/New_York date)"
}

# vcs (jj and git) aliases
# Print a pretty git log up to each local branches tracking branch
# $1 is the upstream branch youd like to build from
alias grbi='git rebase -i --update-refs --autosquash'
alias j=jj
# jujutsu completions
source <(COMPLETE=zsh jj)

# Completions for tools with no zsh plugin that can print their own. Many come
# from a project's mise.toml, so instead of generating them at startup, each
# gets a stub that asks the tool for its script on the first tab.
typeset -gA _lazy_completions
function lazy_completion() { # <command> <command line that prints its zsh completion script>
  _lazy_completions[$1]=$2
  compdef _lazy_completion $1
}
function _lazy_completion() {
  local generator=${_lazy_completions[$service]}
  local program=${generator%% *}
  (( $+commands[$program] )) || return 1
  # The script registers its own completion function with compdef.
  source <(${(z)generator} 2>/dev/null)
  local fn=$_comps[$program]
  [[ -n $fn && $fn != _lazy_completion ]] || return 1
  compdef $fn $service
  $fn "$@"
}
lazy_completion flyctl "flyctl completion zsh"
lazy_completion fly "flyctl completion zsh"
lazy_completion esc "esc completion zsh"
lazy_completion pnpm "pnpm completion zsh"
# JJ Workspace switcher
function jjws() {
  local selection
  selection=$(jj workspace list -T 'self.name() ++ "\t" ++self.root() ++ "\n"' \
    | fzf --prompt="workspace> " \
          --delimiter='\t' \
          --with-nth=1 \
          --preview 'jj log -T "builtin_log_comfortable" -R {2}') \
    || return

  local dir
  dir=$(echo "$selection" | cut -f2)
  cd "$dir"
}

# Golang stuff
# Go bin path
export PATH=$HOME/go/bin:$PATH
# export GOFUMPT_SPLIT_LONG_LINES="on"

# Nix
if [ -e /home/brpol/.nix-profile/etc/profile.d/nix.sh ]; then . /home/brpol/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# asdf setup if it exists
[[ -f ~/.asdf/asdf.sh ]] && . ~/.asdf/asdf.sh || true

# press f to pay respects
eval "$(pay-respects zsh --alias)"

# mise setup
eval "$(mise activate zsh)"

# Elixir/erlang stuff
# alias mixnew="mix gen bpollack_elixir_template"
export ERL_AFLAGS="-kernel shell_history enabled" # enable shell history
export PATH="$HOME/.mix/escripts:$PATH"
# Two directories up from elixir executable
export ELIXIR_SRC_DIR=$(which elixir | xargs dirname | xargs dirname)

# source vulkan sdk if present
if [[ -f $HOME/bin/vulkan/setup-env.sh ]]; then
    echo "Sourcing vulkan sdk"
    source $HOME/bin/vulkan/setup-env.sh
fi

# source any machine specific stuff
if [[ -f $HOME/.zshrc.local ]]; then
    echo "Sourcing zshrc local only file..."
    source $HOME/.zshrc.local
fi
# If This is a mac, source any machine specific stuff
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Sourcing mac zshrc file..."
    source $HOME/.zshrc.mac
fi

# AI stuff
#
# Claude Code persists the selected model and machine-specific settings here.
# Load the tracked shared layer separately so those writes stay local.
alias claude='command claude --settings "$HOME/.claude/settings.shared.json"'

# show a welcome message and fortune!
if [ -x "$(command -v lolcat)" ]; then
    echo "Welcome to $HOST!" | lolcat
else
    echo "Welcome to $HOST!"
fi

# Hacker News MOTD
_hn_output=$(source "$HOME/.local/bin/hacker-news.sh")
if [[ -n "$_hn_output" ]]; then
    echo "$_hn_output"
else
    echo "⏳ Fetching Hacker News in the background..."
fi
unset _hn_output

# new prompt starship

eval "$(starship init zsh)"

# Hook to pass the current history event number to Starship
update_starship_histcmd() {
  export STARSHIP_HISTCMD="$HISTCMD"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_starship_histcmd
