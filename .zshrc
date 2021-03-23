fpath=($HOME/zsh-plugins/zsh-completions/src $fpath)
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

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
    cargo
    catimg
    colorize
    command-not-found
    common-aliases
    docker
    docker-compose
    emoji
    fzf
    git
    git-extras
    mix
    sudo
    tmux
    vi-mode
)

# Vi Mode Setup
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true
MODE_INDICATOR='%B%F{red}<<<NORMAL MODE%b%f'

# Colorize setup, use ccat
ZSH_COLORIZE_CHROMA_FORMATTER=terminal256

# fzf setup
export FZF_BASE=$(which fzf)

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
local JST_DATE=$(TZ=Japan date "+%X (%Z)")
PROMPT=$'%{$fg_bold[green]%}%n@%m %{$fg[blue]%}%D{[%X (%Z) | ${JST_DATE}]} %{$reset_color%}%{$fg[white]%}[%~] $(emoji_status_prompt)%{$reset_color%} $(git_prompt_info)\
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
alias vzsh="vim ~/.zshrc"

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

# Key bindings (like normal to insert mode in vi mode)
bindkey -M viins 'jj' vi-cmd-mode

################### Extra self managed plugins ###############################

# Syntax highlighting
source $HOME/zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# ZFS
source $HOME/zsh-plugins/zfs-completion/zfs-completion.plugin.zsh
# Alias reminding
source $HOME/zsh-plugins/zsh-you-should-use/you-should-use.plugin.zsh
# better cd
source $HOME/zsh-plugins/enhancd/enhancd.plugin.zsh
# better history search
source $HOME/zsh-plugins/zsh-history-substring-search
bindkey '^p' history-substring-search-up
bindkey '^n' history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Environmental Variables
export COWPATH=$HOME/.cowfiles
export EDITOR=vim
# WSL specific configuration
if echo $(uname -a) | grep -q WSL; then
    echo "WSL Environment Detected..."
    function chrome { "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe" $@ }

    function debian-handbook-chrome() {
        pushd /usr/share/doc/debian-handbook/html/en-US
        chrome index.html
        popd
    }
fi

# Finally, show a welcome message and fortune!
# add more cowsays! https://charc0al.github.io/cowsay-files/converter/
if [[ -f /etc/debian_version ]]; then
    PLATFORM_LOGIN_FORTUNES="debian-hints"
fi

echo "Welcome to $HOST!" | figlet | lolcat
fortune $PLATFORM_LOGIN_FORTUNES | cowsay -f $(ls $HOME/.cowfiles/ | shuf -n1)
