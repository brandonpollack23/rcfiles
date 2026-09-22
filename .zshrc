#!/bin/zsh
# To profile uncomment below and the last line of the config
# zmodload zsh/zprof
#
# Most of the environment and aliases are written in Amber, in scripts/zshrc/,
# and compiled to scripts/zshrc/build/*.zsh (mise run build). What stays here
# is what has to be zsh: oh-my-zsh and its settings, key bindings, the prompt,
# functions you call by name, and anything that sources third-party zsh.
# Programs that append to ~/.zshrc can keep doing so below.

# The repo, found through the ~/.zshrc symlink.
export RCFILES_DIR="${${(%):-%x}:A:h}"

# Sources Amber's zsh output. Its ksh emulation stays inside this function, and
# the helper functions and variables it leaves behind are removed: only its
# exported variables and aliases outlive it.
rc_source_amber() {
    emulate -L zsh
    local name
    local -a before_vars after_vars before_funcs after_funcs
    before_vars=(${(k)parameters})
    before_funcs=(${(k)functions})
    [[ -r "$1" ]] && source "$1"
    emulate -L zsh  # the file switched to ksh emulation for the rest of this function
    after_vars=(${(k)parameters})
    after_funcs=(${(k)functions})
    for name in ${after_vars:|before_vars}; do
        [[ ${parameters[$name]} == *export* ]] || unset "$name"
    done
    for name in ${after_funcs:|before_funcs}; do
        unfunction "$name"
    done
}

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
    if [[ "$EUID" -eq 0 ]]; then
        PS1='# '
    else
        PS1='$ '
    fi
fi

# Each directory once, however many shells deep (tmux panes inherit PATH).
# -U only dedupes assignments to the arrays, and most tools assign the PATH
# string, so `path=($path)` re-applies it (keeping each first occurrence).
typeset -U path fpath manpath

# PATH, the chroot marker in HOST, EDITOR and the other exports.
rc_source_amber "$RCFILES_DIR/scripts/zshrc/build/env.zsh"
path=($path)

fpath=($RCFILES_DIR/zsh-custom/plugins/zsh-completions/src $fpath)
fpath+=$RCFILES_DIR/zsh-my-completions

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes; starship draws the prompt.
# ZSH_THEME="candy"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# The command execution time stamp shown in the history command output.
HIST_STAMPS="mm/dd/yyyy"

export ZSH_CUSTOM=$RCFILES_DIR/zsh-custom

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(
    aws
    bun
    colorize
    common-aliases
    docker
    docker-compose
    emoji
    fzf
    fzf-tab
    gcloud
    git
    git-extras
    gitignore
    golang
    gradle
    jj
    mise
    mix-fast
    nix-zsh-completions
    npm
    rebar
    repo
    rust
    sudo
    systemd
    tmux
    zfs-completion
    zoxide
    zsh-autosuggestions
    zsh-history-substring-search
    zsh-syntax-highlighting
    zsh-you-should-use
)
if [[ "$OSTYPE" =~ darwin* ]]; then
  plugins+=(omz-homebrew)
fi

if [[ "$VIM" == "" ]]; then
  plugins+=vi-mode

  # Vi Mode Setup
  VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
  VI_MODE_SET_CURSOR=true
  MODE_INDICATOR='%B%F{red}<<<NORMAL MODE%b%f'

  # Key bindings (like normal to insert mode in vi mode)
  bindkey -M viins 'jk' vi-cmd-mode
fi

source $ZSH/oh-my-zsh.sh

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

# This is my modified candy theme
function emoji_status_prompt() {
    local LAST_EXIT_CODE=$?
    if [[ $LAST_EXIT_CODE -eq 0 ]]; then
        echo ""
    else
        echo 😡
    fi
}

# Setup JJ Theme and git theme
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

ZSH_THEME_JJ_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_JJ_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_JJ_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_JJ_PROMPT_CLEAN=""

# Wrapper to prioritize JJ over Git if inside a JJ root
function git_or_jj_prompt() {
    if command -v jj >/dev/null 2>&1 && jj root >/dev/null 2>&1; then
      local jj_status=$(jj_prompt_template 'change_id.shortest(4) ++ if(bookmarks, " " ++ bookmarks.join(", "))' 2>/dev/null)
      echo "${ZSH_THEME_JJ_PROMPT_PREFIX}${jj_status}${ZSH_THEME_JJ_PROMPT_SUFFIX}"
    else
        _omz_git_prompt_info
    fi
}
local UTC_DATE=$(TZ=UTC date "+%H:%M (%Z)")
PROMPT=$'%{$fg_bold[green]%}%n@%M %{$fg[blue]%}%D{[%X (%Z) | ${UTC_DATE}]} %{$reset_color%}%{$fg[white]%}[%~] $(emoji_status_prompt)%{$reset_color%} $(git_or_jj_prompt)\
%{$fg[green]%}%h%{$fg[blue]%}->%{$fg_bold[blue]%} %#%{$reset_color%} '

# Global aliases (zsh only)
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

# Show a pamac package's PKGBUILD
if (( $+commands[pamac] )); then
  function display_pkg_build() {
    pamac clone $1
    bat /var/tmp/pamac-build-$USER/$1/PKGBUILD
  }
  function pP() {
    display_pkg_build "$@"
  }
fi

# jujutsu completions
(( $+commands[jj] )) && source <(COMPLETE=zsh jj)
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

# Third-party setup scripts, sourced as zsh
# Nix
if [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/nix.sh"; fi # added by Nix installer

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# asdf setup if it exists
[[ -f ~/.asdf/asdf.sh ]] && . ~/.asdf/asdf.sh || true

# source vulkan sdk if present
if [[ -f $HOME/bin/vulkan/setup-env.sh ]]; then
    echo "Sourcing vulkan sdk"
    source $HOME/bin/vulkan/setup-env.sh
fi

# press f to pay respects
(( $+commands[pay-respects] )) && eval "$(pay-respects zsh --alias)"

# mise setup
(( $+commands[mise] )) && eval "$(mise activate zsh)"

# Aliases, ELIXIR_SRC_DIR, the welcome message and the Hacker News MOTD. After
# oh-my-zsh and mise, so these aliases win and mise's tools are on PATH.
rc_source_amber "$RCFILES_DIR/scripts/zshrc/build/rc.zsh"

# source any machine specific stuff
if [[ -f $HOME/.zshrc.local ]]; then
    echo "Sourcing zshrc local only file..."
    source $HOME/.zshrc.local
fi

path=($path) manpath=($manpath)

# new prompt starship
(( $+commands[starship] )) && eval "$(starship init zsh)"

# Hook to pass the current history event number to Starship
update_starship_histcmd() {
  export STARSHIP_HISTCMD="$HISTCMD"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd update_starship_histcmd
