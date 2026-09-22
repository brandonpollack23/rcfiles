#!/usr/bin/env zsh
# GENERATED from scripts/zshrc/rc.ab by scripts/build.ab. Edit the .ab sources, then run: mise run build
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
# file_exists(path: Text)
file_exists__39_v0() {
    local path_30="${1}"
    [ -f "${path_30}" ]
    __status=$?
    ret_file_exists39_v0="$(( __status == 0 ))"
    return 0
}

# Aliases, and the checks that pick them.
# Defines `name` in the interactive shell that sources the build output. The
# value is stored as given: nothing in it expands until the alias runs.
# set_alias(name: Text, value: Text)
set_alias__54_v0() {
    local name_17="${1}"
    local value_18="${2}"
    alias -- "${name_17}=${value_18}"
    __status=$?
}

# set_aliases(names: [Text], values: [Text])
set_aliases__55_v0() {
    local names_25=("${(P)1}")
    local values_26=("${(P)2}")
    i_28=0;
    for name_27 in "${names_25[@]}"; do
        set_alias__54_v0 "${name_27}" "${values_26[${i_28}]?"Index out of bounds (at scripts/zshrc/./src/aliases.ab:11:32)"}"
        (( i_28++ )) || true
    done
}

# Whether `program` runs here: a command, function or alias. Unlike
# std/env's is_command this forks nothing, which matters at shell startup.
# has(program: Text)
has__56_v0() {
    local program_20="${1}"
    command -v "${program_20}" >/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_has56_v0=0
        return 0
    fi
    ret_has56_v0=1
    return 0
}

# eza in place of ls and tree.
__LS_NAMES_3=("ls" "ll" "la" "tree")
__LS_VALUES_4=("eza --group-directories-first --git" "eza -l --group-directories-first --git" "eza -la --group-directories-first --git" "eza -T --group-directories-first --git")
__APT_NAMES_5=("sau" "saup" "sai" "sar" "as" "asho")
__APT_VALUES_6=("sudo apt update" "sudo apt upgrade" "sudo apt install" "sudo apt remove" "apt search" "apt show")
__PAMAC_NAMES_7=("p" "pi" "pb" "pI" "pr" "pu")
__PAMAC_VALUES_8=("pamac" "pamac install" "pamac build" "pamac info" "pamac remove" "pamac update")
# Aliases, per-machine settings and the greeting, sourced by .zshrc AFTER
# oh-my-zsh and `mise activate` (so these aliases win over the plugins', and
# mise's tools are on PATH). Compiled to build/rc.zsh. The same rules as
# env.ab apply: no `main`, export what must survive (aliases do), and keep to
# inline commands, since this runs on every new shell.
# 
# In amber text a bare $ is literal, so "$HOME" below reaches the alias as
# written and expands when the alias runs. (Inside $ ... $ it is \$.)
set_alias__54_v0 "pls" "sudo \$(fc -ln -1)"
# rerun the last command with sudo
set_alias__54_v0 "fuck" "pls"
set_alias__54_v0 ":q" "exit"
set_alias__54_v0 "grbi" "git rebase -i --update-refs --autosquash"
set_alias__54_v0 "j" "jj"
set_alias__54_v0 "mdless" "mdless -I"
set_alias__54_v0 "hn" "\$RCFILES_DIR/scripts/hacker-news/hacker-news.sh"
# Claude Code writes the selected model and other machine state to
# ~/.claude/settings.json; the tracked settings load separately.
set_alias__54_v0 "claude" "command claude --settings \"\$HOME/.claude/settings.shared.json\""
set_alias__54_v0 "cati" "TERM=\$UNDERLYING_TERM chafa"
has__56_v0 "eza"
ret_has56_v0__24_4="${ret_has56_v0}"
if [ "${ret_has56_v0__24_4}" != 0 ]; then
    set_aliases__55_v0 __LS_NAMES_3[@] __LS_VALUES_4[@]
fi
# Package manager shortcuts: apt on Debian, else pamac where there is one.
file_exists__39_v0 "/etc/debian_version"
ret_file_exists39_v0__30_5="${ret_file_exists39_v0}"
has__56_v0 "pamac"
ret_has56_v0__31_5="${ret_has56_v0}"
if [ "${ret_file_exists39_v0__30_5}" != 0 ]; then
    set_aliases__55_v0 __APT_NAMES_5[@] __APT_VALUES_6[@]
elif [ "${ret_has56_v0__31_5}" != 0 ]; then
    set_aliases__55_v0 __PAMAC_NAMES_7[@] __PAMAC_VALUES_8[@]
fi
[[ "$OSTYPE" == darwin* ]]
__status=$?
if [ "${__status}" = 0 ]; then
    set_alias__54_v0 "python" "python3"
fi
# The outer terminal, for chafa (cati) inside tmux, whose TERM hides it.
if [ -n "$TMUX" ]; then
          export UNDERLYING_TERM="$(tmux display-message -p '#{client_termname}' 2>/dev/null)"
      else
          export UNDERLYING_TERM="$TERM"
      fi
__status=$?
# The Elixir install mise manages, for tools that read its sources.
# `command`: mise activate made `mise` a shell function.
if command -v elixir >/dev/null 2>&1; then
          export ELIXIR_SRC_DIR="$(command mise where elixir 2>/dev/null || dirname "$(dirname "$(command -v elixir)")")"
      fi
__status=$?
# Greeting, then a Hacker News story (the script never waits on the network).
if command -v lolcat >/dev/null 2>&1; then
          echo "Welcome to $HOST!" | lolcat
      else
          echo "Welcome to $HOST!"
      fi
__status=$?
[ -x "$RCFILES_DIR/scripts/hacker-news/hacker-news.sh" ] && "$RCFILES_DIR/scripts/hacker-news/hacker-news.sh"
__status=$?
