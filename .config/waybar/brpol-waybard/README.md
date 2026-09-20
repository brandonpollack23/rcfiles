# brpol-waybard

The one process behind every scripted button in this waybar config: the 12
taskbar slots and their overflow, the 20 workspace buttons, and the 6 hidden
(special) workspace buttons.

## Why

Waybar has no module that lists windows, and a single label could not be clicked
per window, so each of those 39 buttons is its own `custom/*` module. Each ran
in continuous mode, which meant 39 Python processes, 39 subscriptions to
Hyprland's event socket, and ~129 IPC round trips every time a window opened --
575 MB resident, about 228 MB of it real, to draw one bar. Every one of the 12
taskbar renderers ran the same layout pass and kept one entry of it.

Waybar still needs a process per button. It just does not need it to be an
interpreter: the daemon computes all 39 from one snapshot and writes each
button's JSON line to its own FIFO, and the button becomes `cat`.

    before  Hyprland -> 39 python procs -> 39 buttons   (39 subscriptions, ~129 queries/event)
    after   Hyprland -> 1 daemon -> 39 `cat` on FIFOs -> 39 buttons   (1 subscription, 5 queries/event)

Measured here: 14 MB PSS against 228 MB, of which the 39 `cat` are 5 MB.

`scripts/launch.sh` syncs the venv and then execs the daemon rather than
running it under `uv run`, which would otherwise sit there as its parent for
the life of the session at 25 MB -- nearly three times the daemon itself.

## Running it

`scripts/launch.sh` is what `conf/programs.lua` points at, started from
`hyprland.lua` just before waybar. It runs the daemon through `uv`, which puts
the pinned interpreter and the venv in place on first run.

To restart it by hand, use `SUPER+SHIFT+R` -> "Restart taskbar daemon", or
`~/.config/hypr/scripts/system.sh restart-taskbar-daemon`. Waybar does not need
restarting with it: the FIFOs are recreated and `restart-interval` brings the
`cat`s back.

## Inspecting a button

A FIFO cannot be read from a terminal without stealing the line from waybar, so
the inspection is a flag:

    scripts/launch.sh --once win3
    scripts/launch.sh --once ws7
    scripts/launch.sh --once hidden1

prints exactly the JSON that button is being given.

## Control channel

`scripts/ctl.sh` writes one line to the daemon's control FIFO. It is how clicks
come back in and how Lua asks for a redraw after a group change, which Hyprland
has no event for:

    ctl.sh refresh
    ctl.sh focus 3
    ctl.sh toggle 2

It is a silent no-op when the daemon is not running.

## Adding a dependency

    uv add <package>          # or: uv add --group dev <package>
    uv lock

`uv.lock` and `.python-version` are committed, so the bar runs the same
interpreter and the same dependency versions on every machine this config is
cloned to -- and an Arch Python major bump cannot break it.

## Layout

| file | what |
| --- | --- |
| `src/brpol_waybard/ipc.py` | the request socket, the event socket, the Lua REPL |
| `src/brpol_waybard/snapshot.py` | everything the 39 buttons need, fetched once |
| `src/brpol_waybard/windows.py` | taskbar layout, group tabs, lock icon, overflow |
| `src/brpol_waybard/workspaces.py` | the workspace buttons and the urgency set |
| `src/brpol_waybard/hidden.py` | the special-workspace buttons |
| `src/brpol_waybard/fifos.py` | the pipes, and why they are opened O_RDWR |
| `src/brpol_waybard/control.py` | what a line on the control FIFO means |
| `src/brpol_waybard/__main__.py` | the event loop |

Two counts are contracts with the waybar config: `windows.SLOTS` must equal the
number of `custom/winN` modules in `windows.jsonc`, and `workspaces.SLOTS` /
`hidden.SLOTS` the number of `custom/wsN` / `custom/hiddenN` in
`workspaces.jsonc`.
