# tmux dev layouts, ported to zsh from Omarchy's bash functions
# (/usr/share/omarchy/default/bash/fns/tmux) with --help and tab completion.
# Sourced from ~/.zshrc after compinit.
#
#   tdl  <ai> [<ai2>]    editor, AI pane(s) on the right, terminal below
#   tds                  editor, diff watch, terminal and opencode in a square
#   tdlm <ai> [<ai2>]    a tdl window for every subdirectory of $PWD
#   tsl  <n> <command>   n tiled panes all running the same command
#
# Each lays out the tmux window it is run in, so start tmux first. <ai> is any
# command; `c` and `cx` are Omarchy's shorthands (see _tmux_layout_ai).
#
# Declarative session managers (tmuxinator, tmuxp, smug) build whole sessions
# from a YAML file per project; these are for splitting the window you're
# already in, anywhere, with nothing to write first.

# `tmux` is an alias from the omz tmux plugin; these want the real one.
function _tmux_layout_tmux() { command tmux "$@" }

# Usage for each layout, printed by -h/--help and on bad arguments.
typeset -gA _tmux_layout_usage=(
  tdl  "Usage: tdl <ai> [<ai2>]
Split this window: \$EDITOR on the left, <ai> on the right (30%), a terminal
along the bottom (15%). With <ai2>, the AI column is split between the two.
<ai> is any command; c = opencode --auto, cx = claude --permission-mode auto."
  tds  "Usage: tds
Split this window into a square: \$EDITOR top left, 'hunk diff --watch' top
right, a terminal bottom left, opencode bottom right."
  tdlm "Usage: tdlm <ai> [<ai2>]
Rename the session after \$PWD and open a tdl window for each subdirectory,
reusing this window for the first."
  tsl  "Usage: tsl <pane_count> <command>
Split this window into <pane_count> tiled panes, each running <command>
(quote it if it has spaces), e.g. tsl 4 claude."
)

# Prints a layout's usage. Returns 0 when it was asked for with -h/--help and
# 1 when it's shown for bad arguments, for the layout to return.
function _tmux_layout_help() { # <layout> <first argument>
  print -r -- "${_tmux_layout_usage[$1]}"
  [[ $2 == (-h|--help) ]]
}

function _tmux_layout_require_tmux() { # <layout>
  [[ -n $TMUX ]] && return
  print -u2 -r -- "$1: run this inside tmux."
  return 1
}

# The command line for an AI argument: Omarchy's shorthands expand to what
# its bash aliases run, anything else is used as is.
function _tmux_layout_ai() { # <ai>
  case $1 in
    c)  print -r -- "opencode --auto" ;;
    cx) print -r -- "claude --permission-mode auto" ;;
    *)  print -r -- "$1" ;;
  esac
}

# Types a command into a pane and presses enter. -l sends it literally, so a
# word like "Enter" in it stays text.
function _tmux_layout_run() { # <pane> <command>
  _tmux_layout_tmux send-keys -t "$1" -l -- "$2"
  _tmux_layout_tmux send-keys -t "$1" C-m
}

# The current window, named after the directory:
#   +-----------------+------+
#   | $EDITOR .       | ai   |
#   |                 |------|
#   |                 | ai2  |
#   +-----------------+------+
#   | terminal               |
#   +------------------------+
function tdl() { # <ai> [<ai2>]
  if [[ -z $1 || $1 == (-h|--help) || $# -gt 2 ]]; then
    _tmux_layout_help $0 "$1"; return
  fi
  _tmux_layout_require_tmux $0 || return

  local dir=$PWD ai=$1 ai2=$2
  # TMUX_PANE is the pane this shell runs in, even if another window is active.
  local editor_pane=$TMUX_PANE ai_pane ai2_pane

  _tmux_layout_tmux rename-window -t "$editor_pane" "${dir:t}"
  _tmux_layout_tmux split-window -v -l 15% -t "$editor_pane" -c "$dir"
  ai_pane=$(_tmux_layout_tmux split-window -h -l 30% -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')

  if [[ -n $ai2 ]]; then
    ai2_pane=$(_tmux_layout_tmux split-window -v -t "$ai_pane" -c "$dir" -P -F '#{pane_id}')
    _tmux_layout_run "$ai2_pane" "$(_tmux_layout_ai "$ai2")"
  fi
  _tmux_layout_run "$ai_pane" "$(_tmux_layout_ai "$ai")"
  _tmux_layout_run "$editor_pane" "${EDITOR:-nvim} ."

  _tmux_layout_tmux select-pane -t "$editor_pane"
}

# The current window, named after the directory:
#   +------------+-------------------+
#   | $EDITOR .  | hunk diff --watch |
#   +------------+-------------------+
#   | terminal   | opencode          |
#   +------------+-------------------+
function tds() {
  if [[ $# -gt 0 ]]; then
    _tmux_layout_help $0 "$1"; return
  fi
  _tmux_layout_require_tmux $0 || return

  local dir=$PWD
  local editor_pane=$TMUX_PANE diff_pane terminal_pane opencode_pane

  _tmux_layout_tmux rename-window -t "$editor_pane" "${dir:t}"
  terminal_pane=$(_tmux_layout_tmux split-window -v -l 50% -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')
  diff_pane=$(_tmux_layout_tmux split-window -h -l 50% -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')
  opencode_pane=$(_tmux_layout_tmux split-window -h -l 50% -t "$terminal_pane" -c "$dir" -P -F '#{pane_id}')

  _tmux_layout_run "$editor_pane" "${EDITOR:-nvim} ."
  _tmux_layout_run "$diff_pane" "hunk diff --watch"
  _tmux_layout_run "$opencode_pane" "opencode"

  _tmux_layout_tmux select-pane -t "$editor_pane"
}

# One tdl window per subdirectory of $PWD, e.g. from a directory of worktrees
# or checkouts. Each window's own shell runs tdl, so it gets its own $PWD.
function tdlm() { # <ai> [<ai2>]
  if [[ -z $1 || $1 == (-h|--help) || $# -gt 2 ]]; then
    _tmux_layout_help $0 "$1"; return
  fi
  _tmux_layout_require_tmux $0 || return

  # (N): no error when there are no subdirectories. (q) quotes for the shell
  # the command is typed into.
  local -a dirs=( "$PWD"/*(N/) )
  if (( ! $#dirs )); then
    print -u2 -r -- "tdlm: no subdirectories in $PWD."
    return 1
  fi
  local layout="tdl ${(q)1}"
  [[ -n $2 ]] && layout+=" ${(q)2}"

  # tmux won't have dots or colons in a session name.
  _tmux_layout_tmux rename-session "${${PWD:t}//[.:]/-}"

  # The first goes in this window; its shell reads the line once tdlm returns.
  _tmux_layout_run "$TMUX_PANE" "cd ${(q)dirs[1]} && $layout"
  local dir pane
  for dir in $dirs[2,-1]; do
    pane=$(_tmux_layout_tmux new-window -c "$dir" -P -F '#{pane_id}')
    _tmux_layout_run "$pane" "$layout"
  done
}

# The current window, named after the directory, tiled into <pane_count>
# panes that all run <command>: a swarm of agents on one checkout.
function tsl() { # <pane_count> <command>
  if [[ $1 == (-h|--help) || $# -ne 2 || $1 != <1-> || -z $2 ]]; then
    _tmux_layout_help $0 "$1"; return
  fi
  _tmux_layout_require_tmux $0 || return

  local count=$1 cmd=$2 dir=$PWD pane
  local -a panes=( $TMUX_PANE )

  _tmux_layout_tmux rename-window -t "$TMUX_PANE" "${dir:t}"
  while (( $#panes < count )); do
    # Re-tile after every split, or the panes run out of room to split.
    panes+=( $(_tmux_layout_tmux split-window -h -t "$panes[-1]" -c "$dir" -P -F '#{pane_id}') ) || return
    _tmux_layout_tmux select-layout -t "$panes[1]" tiled
  done

  for pane in $panes; do
    _tmux_layout_run "$pane" "$cmd"
  done
  _tmux_layout_tmux select-pane -t "$panes[1]"
}

### Completion

# Omarchy's shorthands and the agents that are installed.
function _tmux_layout_ai_names() {
  local -a ais=(
    'c:opencode --auto'
    'cx:claude --permission-mode auto'
  )
  local ai
  for ai in claude codex opencode gemini aider crush amp cursor-agent copilot; do
    (( $+commands[$ai] || $+aliases[$ai] || $+functions[$ai] )) && ais+=( "$ai" )
  done
  _describe -t ai-commands 'AI command' ais
}

# An AI command: one of those, or when none matches what's typed, any other
# command, so the agents aren't buried under all of $PATH.
function _tmux_layout_ais() {
  _tmux_layout_ai_names || _command_names -e
}

function _tdl() {
  _arguments -S \
    '(- *)'{-h,--help}'[show usage]' \
    '1:AI command:_tmux_layout_ais' \
    '2::second AI command:_tmux_layout_ais'
}

function _tds() {
  _arguments '(- *)'{-h,--help}'[show usage]'
}

function _tsl() {
  _arguments -S \
    '(- *)'{-h,--help}'[show usage]' \
    '1:pane count:(2 3 4 6 8)' \
    '2:command for every pane:_tmux_layout_ais'
}

if (( $+functions[compdef] )); then
  compdef _tdl tdl tdlm
  compdef _tds tds
  compdef _tsl tsl
fi
