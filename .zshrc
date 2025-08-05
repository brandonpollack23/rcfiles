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

fpath=($HOME/zsh-plugins/zsh-completions/src $fpath)
fpath+=$HOME/zsh-my-completions
if [[ -f $HOME/nix-zsh-completions/nix-zsh-completions.plugin.zsh ]]; then
    source $HOME/nix-zsh-completions/nix-zsh-completions.plugin.zsh
fi
fpath+=$HOME/nix-zsh-completions
autoload -Uz compinit && compinit

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export PATH="$PATH:$HOME/.local/scripts:$HOME/bin:$HOME/.pulumi/bin:$HOME/.ghcup/bin:$HOME/.emacs.d/bin:$HOME/bin:/usr/games/:$HOME/.local/bin"
if ! [[ "$OSTYPE" =~ darwin* ]]; then
    export PATH=/opt/homebrew/bin:$PATH
fi
export MANPATH="$HOME/man/":$MANPATH

#rustup
source $HOME/.cargo/env

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

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    bun
    colorize
    command-not-found
    common-aliases
    docker
    docker-compose
    emoji
    fzf
    gcloud
    git
    git-extras
    gitignore
    golang
    gradle
    mix
    mise
    npm
    rebar
    repo
    rust
    sudo
    systemd
    tmux
)

if [[ "$VIM" == "" ]]; then
  plugins+=vi-mode

  # Vi Mode Setup
  VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
  VI_MODE_SET_CURSOR=true
  MODE_INDICATOR='%B%F{red}<<<NORMAL MODE%b%f'

  # Key bindings (like normal to insert mode in vi mode)
  bindkey -M viins 'jj' vi-cmd-mode
fi

# fzf setup
export FZF_BASE=$(which fzf)

source $ZSH/oh-my-zsh.sh

################### Extra self managed plugins ###############################

# Syntax highlighting
source $HOME/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# ZFS
source $HOME/zsh-plugins/zfs-completion/zfs-completion.plugin.zsh
# Alias reminding
source $HOME/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh
# better cd
#source $HOME/zsh-plugins/enhancd/enhancd.plugin.zsh
# better history search
source $HOME/zsh-plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
# Better brew for mac
if [[ "$OSTYPE" =~ darwin* ]]; then
    source $HOME/zsh-plugins/omz-homebrew/omz-homebrew.plugin.zsh
fi

################### Extra self managed Plugin configurations ###############################
# History search
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down


#################### User configuration ###############################
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# This is my modified candy theme
function emoji_status_prompt() {
    local LAST_EXIT_CODE=$?
    if [[ $LAST_EXIT_CODE -eq 0 ]]; then
        echo ""
    else
        echo 😡
    fi
}
local UTC_DATE=$(TZ=UTC date "+%H:%M (%Z)")
PROMPT=$'%{$fg_bold[green]%}%n@%M %{$fg[blue]%}%D{[%X (%Z) | ${UTC_DATE}]} %{$reset_color%}%{$fg[white]%}[%~] $(emoji_status_prompt)%{$reset_color%} $(git_prompt_info)\
%{$fg[green]%}%h%{$fg[blue]%}->%{$fg_bold[blue]%} %#%{$reset_color%} '
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[green]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$fg[red]%}*%{$fg[green]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""

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
# git (commit) amend  no edit
alias gammend="gca --amend --no-edit"
alias gpf="gp -f"
alias gitraw=$(which git)
function git() { git-branchless wrap -- "$@" }
alias gbli="git branchless init"
alias g='git'
alias g-b='git-branchless'
# alias gd="git difftool --tool 'branchless' --dir-diff"
alias gsl='git sl --reverse'
alias gsw='git-branchless switch -i'
alias gitsl='git sl --reverse'
alias gxl='git sl --reverse'
alias gitxl='git sl --reverse'
source ~/.zshrc.githubcopilot

# ls aliases
alias ls="eza --git"
alias ll="eza -l --git"
alias la="eza -la --git"
alias tree="eza -T --git"

# pulumi aliases and env
alias pctl=pulumictl
export AWS_DEFAULT_PROFILE="pulumi-dev-sandbox"

export UNDERLYING_TERM=$(tmux display-message -p "#{client_termname}")
alias cati='TERM=$UNDERLYING_TERM chafa'

# Used for neovim workspaces.
export PROJECT_DIRS="$HOME/src"

# wireguard aliases
alias wgup="sudo wg-quick up wg0"

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

# Git aliases
# Print a pretty git log up to each local branches tracking branch
# $1 is the upstream branch youd like to build from
function gitrawxl() {
  local base=${1:-"origin/master"}
  git log --graph --oneline --decorate --simplify-by-decoration \
    --boundary master..${base} $(git for-each-ref --format="%(refname:short)" refs/heads/) $@
}
function gitsync() {
    local branches=$(git branch | tr -d '*' | sed 's/^ *//g' | sed 's/\n/ /g')
    for b in $branches; do
        git checkout $b
        git rebase
    done
}
alias gamc='git am --continue'
alias gama='git am --abort'
alias gamd='git am --show-current-patch=diff'
alias grbi='git rebase -i --update-refs --autosquash'
alias gfu='git commit --fixup'

function qemu-kill() {
    ps aux G qemu-system-x86_64 | grep -v grep | head -n 1 | awk '{print $2}' | xargs kill -9
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

# mise setup
eval "$(mise activate zsh)"

# Nix stuff
prompt_nix_shell_setup

# # Python/Rye stuff
# if [[ -f $HOME/.rye/env ]]; then
#   source "$HOME/.rye/env"
# fi
# function rye_activate() {
#   source "$HOME/.venv/bin/activate"
# }
# function rye_deactivate() {
#   # if we are in a virtualenv deactivate it
#   if [[ -n "$VIRTUAL_ENV" ]]; then
#     deactivate
#   fi
# }
# function rye_pytorch_setup() {
#   # mlxtend is for plotting confusion matrix
#   rye add torch torchvision torchaudio matplotlib pillow onnx onnxruntime pdbplus pandas mlxtend torchmetrics
#   rye add -d ipython notebook jupyter-console pyqt5 pynvim nbclassic jupynium ipywidgets
# }

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

# Finally, show a welcome message and fortune!
if [ -x "$(command -v lolcat)" ]; then
    echo "Welcome to $HOST!" | lolcat
else
    echo "Welcome to $HOST!"
fi

# Added by Windsurf
export PATH="/Users/brpol/.codeium/windsurf/bin:$PATH"

# zprof
