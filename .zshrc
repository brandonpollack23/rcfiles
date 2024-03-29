#!/bin/zsh

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
autoload -Uz compinit && compinit
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/bin/google-cloud-sdk/bin:$HOME/.pulumi/bin:$HOME/.emacs.d/bin:$HOME/bin:/usr/games/:$HOME/.local/bin:$PATH:$HOME/.local/scripts"
if ! [[ "$OSTYPE" =~ darwin* ]]; then
    export PATH=/opt/homebrew/bin:$PATH
fi
export MANPATH="$HOME/man/":$MANPATH

#rustup
source $HOME/.cargo/env

#export EDITOR="emacsclient -t -a ''" # opens in terminal
#export VISUAL="emacsclient -c -a emacs" # opens in gui mode
export EDITOR="vim" # opens in terminal
export VISUAL="gvim" # opens in gui mode
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
    catimg
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
    gradle
    lein
    npm
    repo
    rust
    sudo
    systemd
    tmux
    vi-mode
)

# Vi Mode Setup
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true
MODE_INDICATOR='%B%F{red}<<<NORMAL MODE%b%f'

# fzf setup
export FZF_BASE=$(which fzf)

# ccat setup
export ZSH_COLORIZE_TOOL=pygmentize
export ZSH_COLORIZE_STYLE=monokai
alias catraw=/bin/cat

# but im using bat now
if [ -x "$(command -v bat)" ]; then
    alias cat=bat
fi

source $ZSH/oh-my-zsh.sh

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
local JST_DATE=$(TZ=Asia/Tokyo date "+%X (%Z)")
PROMPT=$'%{$fg_bold[green]%}%n@%M %{$fg[blue]%}%D{[%X (%Z) | ${JST_DATE}]} %{$reset_color%}%{$fg[white]%}[%~] $(emoji_status_prompt)%{$reset_color%} $(git_prompt_info)\
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
alias vzsh="emacsclient -t ~/.zshrc"
alias vimrc="emacsclient -t ~/.vimrc"
# git (commit) amend  no edit
alias gammend="gca --amend --no-edit"
alias gpf="gp -f"
# repo aliases
alias rco="repo checkout"
function rcob() {
    # repo create branch and checkout, setting upstream
}
# wireguard aliases
alias wgup="sudo wg-quick up wg0"

alias e="emacsclient -t -a ''" # (t)erminal mode, (a)lternate editor is emacs
alias ec="emacsclient -c -n -a ''" # (c)reates a frame (n)o wait for return, (a)lternate editor is emacs itself

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
fi

# Application default arguments
alias mdless="mdless -I"
export LESS="-R -I"

# Key bindings (like normal to insert mode in vi mode)
bindkey -M viins 'jj' vi-cmd-mode

# Override some common aliases
alias -g G='| rg'
alias -g L='| bat'
alias -g LL='2>&1 | bat'

# Override date to print both EST and JST
function dates() {
    echo "CTZ: $(date)\n"
    echo "JST: $(TZ=Asia/Tokyo date)\n"
    echo "PST: $(TZ=America/Los_Angeles date)\n"
    echo "EST: $(TZ=America/New_York date)"
}

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

# Environmental Variables
export COWPATH=$HOME/.cowfiles
# WSL specific configuration
if echo $(uname -a) | grep -q WSL; then
    echo "WSL Environment Detected..."
    function chrome { "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" $@ }
    export BROWSER="chrome"

    function debian-handbook-chrome() {
        pushd /usr/share/doc/debian-handbook/html/en-US
        chrome index.html
        popd
    }

    # Windows native neovide here
fi

# Git aliases
# Print a pretty git log up to each local branches tracking branch
# $1 is the upstream branch youd like to build from
function gitxl() {
    local upstream=$1
    local branches=$(git branch | tr -d '*' | awk '{print "'"$upstream"^\!' " $1}' | tr '\n' ' ')
    echo $branches | xargs git --no-pager log --pretty=oneline --graph --abbrev-commit --decorate
}
function gitsync() {
    local branches=$(git branch | tr -d '*' | sed 's/^ *//g' | sed 's/\n/ /g')
    for b in $branches; do
        git checkout $b
        git rebase
    done
}
alias gitxl_rvc='gitxl "goog/rvc-arc"'
alias gitxl_master='gitxl "goog/master"'
alias gamc='git am --continue'
alias gama='git am --abort'
alias gamd='git am --show-current-patch=diff'

# Chrome OS development helpers
function cros_build_chrome() {
    autoninja -C out_$SDK_BOARD/Release chrome chrome_sandbox nacl_helper
}
function cros_deploy_chrome() {
    ./third_party/chromite/bin/deploy_chrome \
        --strip-flags=-S \
        --build-dir=out_$SDK_BOARD/Release \
        --device=\[$DUT\] \
        --target-dir=/usr/local/chrome \
        --mount-dir=/opt/google/chrome
}
function cros_build_deploy() {
    cros_build_chrome && cros_deploy_chrome
}

function qemu-kill() {
    ps aux G qemu-system-x86_64 | grep -v grep | head -n 1 | awk '{print $2}' | xargs kill -9
}

# adb aliases
function perfetto_pull_trace {
    local tracename
    if [ ! -z $1 ]; then
        tracename=$1
    else
        local datetime=$(date +"%Y_%m_%d_%H:%M")
        tracename=trace_${datetime}
    fi
    adb pull /data/misc/perfetto-traces/trace ~/traces/${tracename}
    echo "Copied trace to $HOME/traces/${tracename}"
}


# source any machine specific stuff
if [[ -f $HOME/.zshrc.local ]]; then
    echo "Sourcing zshrc local only file..."
    source $HOME/.zshrc.local
fi

# source vulkan sdk if present
if [[ -f $HOME/bin/vulkan/setup-env.sh ]]; then
    echo "Sourcing vulkan sdk"
    source $HOME/bin/vulkan/setup-env.sh
fi

# Setup chromeos go stuff
export GOPATH=$HOME/go
if [[ ! -z $CHROMEOS_SRC ]]; then
    echo "ChromeOS path detected, setting up..."
    export GOPATH=$GOPATH:$CHROMEOS_SRC/src/platform/tast-tests:$CHROMEOS_SRC/src/platform/tast
    export GOPATH=$GOPATH:$CHROMEOS_SRC/chroot/usr/lib/gopath
    alias cros_boards="ls -l $CHROMEOS_SRC/src/overlays/ | sed -n '/^d.*/p' | cut -d ' ' -f10 | cut -d '-' -f2 G -v '^$' | sort -u"
fi

export PATH=$PATH:$HOME/bin/go/bin

# Setup kernel stuff
alias gitmail_drm='git send-email --to=dri-devel@lists.freedesktop.org --cc=maarten.lankhorst@linux.intel.com,mripard@kernel.org,tzimmermann@suse.de,airlied@gmail.com,daniel@ffwll.ch --bcc=brpol@google.com,mduggan@google.com --annotate'

# Finally, show a welcome message and fortune!
# add more cowsays! https://charc0al.github.io/cowsay-files/converter/
if [ -f /etc/debian_version ] && [ ! -d /google ]; then
    PLATFORM_LOGIN_FORTUNES="debian-hints"
fi

if [ -x "$(command -v lolcat)" ]; then
    echo "Welcome to $HOST!" | lolcat
else
    echo "Welcome to $HOST!"
fi
#echo "Welcome to $HOST!" | figlet | lolcat
# Disable icon for now
#fortune $PLATFORM_LOGIN_FORTUNES | cowsay -f $(ls $HOME/.cowfiles/ | shuf -n1)

if [ -e /home/brpol/.nix-profile/etc/profile.d/nix.sh ]; then . /home/brpol/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

# tabtab source for packages
# uninstall by removing these lines
[[ -f ~/.config/tabtab/zsh/__tabtab.zsh ]] && . ~/.config/tabtab/zsh/__tabtab.zsh || true

# asdf setup if it exists
[[ -f ~/.asdf/asdf.sh ]] && . ~/.asdf/asdf.sh || true

function cros_qemu() {
      --enable-kvm \
      -smp 4 \
      -m 16384 \
      -cpu Haswell-noTSX,-invpcid,-tsc-deadline,check,vmx=on,svm=on \
      -usb \
      -device usb-tablet \
      -device virtio-rng \
      -net nic,model=virtio \
      -net user,hostfwd=tcp:127.0.0.1:9222-:22 \
      -drive file=./src/build/images/betty-arc-r/chromiumos_test_image.bin \
      -vga none \
      -display none \
      -nographic
}

function adb_start_shizuku() {
    adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh
}

# add Pulumi to the PATH
export PATH=$PATH:/home/brpol/.pulumi/bin

# add neovim to the PATH
export PATH=$PATH:/opt/nvim-linux64/bin

# add nvm (node version manager) to the PATH
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PROJECT_DIRS="$HOME/src"
