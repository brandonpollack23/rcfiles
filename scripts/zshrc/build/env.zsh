#!/usr/bin/env zsh
# GENERATED from scripts/zshrc/env.ab by scripts/build.ab. Edit the .ab sources, then run: mise run build
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
emulate ksh
setopt BSD_echo
__read_args='-A'
if [ -n "$ZSH_VERSION" ]; then
    EXEC_SHELL="zsh"
    IFS='.' read -A EXEC_SHELL_VERSION <<< "$ZSH_VERSION"
elif [ -n "$KSH_VERSION" ]; then
    EXEC_SHELL="ksh"
    __exec_shell_version="${.sh.version##*/}"
    IFS='.' read -a EXEC_SHELL_VERSION <<< "${__exec_shell_version%% *}"
else
    EXEC_SHELL="bash"
    EXEC_SHELL_VERSION=("${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}")
fi
# dir_exists(path: Text)
dir_exists__38_v0() {
    local path_9="${1}"
    [ -d "${path_9}" ]
    __status=$?
    ret_dir_exists38_v0="$(( __status == 0 ))"
    return 0
}

# Adding directories to PATH-style lists.
# 
# .zshrc marks path, fpath and manpath `typeset -U`, so zsh itself keeps each
# directory once, at its first position: prepending an entry that is already
# there moves it to the front, appending one leaves it where it was. These
# functions only add.
# 
# Kept to inline commands on purpose: in zsh startup code every amber
# comparison, env_var_get and $(...) forks a subshell, and a loop over PATH
# entries here once cost 170 ms per shell.
# path_prepend(dir: Text)
path_prepend__54_v0() {
    local dir_11="${1}"
    dir_exists__38_v0 "${dir_11}"
    local ret_dir_exists38_v0__15_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__15_8}" != 0 ]; then
        export PATH="${dir_11}:$PATH"
        __status=$?
    fi
}

# path_append(dir: Text)
path_append__55_v0() {
    local dir_8="${1}"
    dir_exists__38_v0 "${dir_8}"
    local ret_dir_exists38_v0__21_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__21_8}" != 0 ]; then
        export PATH="$PATH:${dir_8}"
        __status=$?
    fi
}

# The trailing colon keeps man's default search path after ours.
# manpath_prepend(dir: Text)
manpath_prepend__56_v0() {
    local dir_13="${1}"
    dir_exists__38_v0 "${dir_13}"
    local ret_dir_exists38_v0__28_8="${ret_dir_exists38_v0}"
    if [ "${ret_dir_exists38_v0__28_8}" != 0 ]; then
        export MANPATH="${dir_13}:${MANPATH#:}"
        __status=$?
        case "$MANPATH" in *:) ;; *) export MANPATH="$MANPATH:" ;; esac
        __status=$?
    fi
}

# Environment for interactive zsh, sourced by .zshrc BEFORE oh-my-zsh (its
# plugins look for the programs on this PATH). Compiled to build/env.zsh.
# 
# No `main` block: every line runs when .zshrc sources the output. .zshrc
# sources it through rc_source_amber, which keeps Amber's ksh emulation from
# leaking into the shell and afterwards drops every variable and function this
# file created except exported ones. So: export whatever must survive, and
# leave anything that sources third-party zsh (nix, asdf, ...) in .zshrc.
# 
# This runs on every new shell. Prefer `$ ... $` statements, which run inline,
# over amber comparisons, env_var_get and command expressions, which each fork
# a subshell (see src/paths.ab).
# A chroot (ChromeOS development and friends) shows in the prompt. The real
# root directory is inode 2 on ext4/xfs.
[ "$(command ls -di /)" = "2 /" ] || export HOST="$HOST-chroot"
__status=$?
# One fork, for everything below.
command_0="$(printf '%s' "$HOME")"
__status=$?
home_3="${command_0}"
# PATH, lowest priority first: the appends go after the system directories,
# the prepends in front, the last prepend first of all.
array_3=("${home_3}/.local/scripts" "${home_3}/bin" "${home_3}/.pulumi/bin" "${home_3}/.ghcup/bin" "${home_3}/.emacs.d/bin" "/usr/games" "${home_3}/.local/bin")
for dir_4 in "${array_3[@]}"; do
    path_append__55_v0 "${dir_4}"
done
[[ "$OSTYPE" == darwin* ]] && export PATH="/opt/homebrew/bin:$PATH"
__status=$?
path_prepend__54_v0 "${home_3}/.deno/bin"
path_prepend__54_v0 "${home_3}/go/bin"
path_prepend__54_v0 "${home_3}/.cargo/bin"
# what ~/.cargo/env does
path_prepend__54_v0 "${home_3}/.mix/escripts"
manpath_prepend__56_v0 "${home_3}/man"
export EDITOR=nvim
__status=$?
export ALTERNATE_EDITOR=vi
__status=$?
export CLOUDSDK_HOME="${home_3}/bin/google-cloud-sdk"
__status=$?
export DENO_INSTALL="${home_3}/.deno"
__status=$?
export PROJECT_DIRS="${home_3}/src"
__status=$?
# neovim workspaces
export LESS="-R -I"
__status=$?
export FZF_DEFAULT_OPTS="--bind ctrl-f:page-down,ctrl-b:page-up"
__status=$?
export ZOXIDE_CMD_OVERRIDE=cd
__status=$?
export ERL_AFLAGS="-kernel shell_history enabled"
__status=$?
# iex history
