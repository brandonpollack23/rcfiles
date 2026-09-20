#!/bin/sh
# Starts the waybar taskbar daemon. See ../README.md.
#
# Resolves its own project directory rather than hard-coding one, so this tree
# can move.
DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Bring the venv in line with uv.lock -- this is what puts the pinned
# interpreter and the locked dependencies in place on a fresh clone -- and then
# get out of the way. `uv run` would stay resident as the daemon's parent for
# the life of the session, and it is nearly three times the size of the daemon
# it would be babysitting.
uv sync --project "$DIR" --frozen --quiet || exit 1

exec "$DIR/.venv/bin/brpol-waybard" "$@"
