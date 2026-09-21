# brpol-waybard

The one process behind every scripted button in this waybar config: the 32
taskbar slots and their overflow, the 20 workspace buttons, the 6 hidden
(special) workspace buttons, and four status buttons -- PIA, weather, night
light and the screen recording indicator -- that have nothing to do with windows but would otherwise each be a
script of their own.

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
    scripts/launch.sh --once weather

prints exactly the JSON that button is being given.

## Control channel

`scripts/ctl.sh` writes one line to the daemon's control FIFO. It is how clicks
come back in and how Lua asks for a redraw after a group change, which Hyprland
has no event for:

    ctl.sh refresh
    ctl.sh focus 3
    ctl.sh toggle 2
    ctl.sh nightlight

It is a silent no-op when the daemon is not running.

## Checking it

    uv run pytest                   # the tests; about two seconds
    uv run mypy                     # type-check; strict, and expected to stay clean
    uv run ruff check src tests     # lint
    uv run ruff format src tests    # format

None of these touch the running session. `tests/conftest.py` points the package
at a scratch runtime directory before it is imported, so the tests pass the same
inside Hyprland, outside it, or over ssh.

| tests | what |
| --- | --- |
| `test_labels.py`, `test_layout.py`, `test_windows.py`, `test_workspaces.py`, `test_hidden.py`, `test_snapshot.py` | the pure functions, fed snapshots made by `builders.py` |
| `test_fade.py` | the fade and focus-hold timeline, one render at a time with a made-up clock |
| `test_fifos.py` | real pipes in a temp directory, read the way `cat` reads them |
| `test_control.py` | each control command, with Hyprland and the snapshot stubbed out |
| `test_status.py` | the status buttons: the renderers, and `Status` against scripts standing in for `piactl` and `curl`, a socket for hyprsunset, and a PID file for hyprcap |
| `test_daemon.py` | the whole daemon against `fake_hyprland.py`: real sockets, pipes, debounce and timers |

`test_layout.py` also arranges a few hundred random workspaces and checks the
two things the layout exists for: both sides of the master draw the same width,
and every window is drawn or overflowed exactly once. When a layout bug turns
up, add the arrangement that showed it to that file as a plain test.

Every function is annotated and `mypy --strict` passes, so a change that breaks
a shape is a failed check rather than a button that quietly stops drawing.

The one place types cannot help is the IPC boundary: `ipc.query` returns `Any`
because JSON decoding cannot know what came back, and `snapshot.py` names the
shapes on the way in. Nothing validates them at runtime, so a field Hyprland
renames is still a `KeyError` at 2am -- `types.py` is a record of what is
expected, not a guarantee. Everything downstream of that boundary is checked.

## Adding a dependency

    uv add <package>          # or: uv add --group dev <package>
    uv lock

`uv.lock` and `.python-version` are committed, so the bar runs the same
interpreter and the same dependency versions on every machine this config is
cloned to -- and an Arch Python major bump cannot break it.

## Layout

One render, start to finish -- every arrow is a plain function call:

    Hyprland event or ctl.sh line
      -> __main__   debounce, then Daemon.render()
      -> snapshot   take(): the five queries
      -> layout     arrange(): which window is in which slot
      -> fade       Fader.step(): which windows are fresh, where focus is drawn
      -> windows / workspaces / hidden   render(): the JSON for each button
      -> fifos      Bar.publish(): written only where a button changed

The renderers are pure functions of a snapshot. The only state that outlives a
render is in `Daemon` (the urgency set, the debounce) and `Fader`.

The status buttons stay out of that flow, since none of them is drawn from a
snapshot. `Status` keeps its own pipes and timers, the select loop watches them
beside the event socket, and what `Status.step()` returns is published as is:

    `piactl monitor` line, `curl` finishing, or a timer
      -> status     Status.step(): the buttons that may have changed
      -> fifos      Bar.publish()

`conftest.py` takes `piactl`, `curl` and the l1p0-menus config away from every
test, so none of them reaches the real VPN, network or API key.

| file | what |
| --- | --- |
| `src/brpol_waybard/types.py` | the shapes Hyprland's `j/` replies come back in |
| `src/brpol_waybard/ipc.py` | the request socket, the event socket, the Lua REPL |
| `src/brpol_waybard/snapshot.py` | everything the 39 buttons need, fetched once |
| `src/brpol_waybard/layout.py` | which window goes in which taskbar slot, and the ghosts that balance it |
| `src/brpol_waybard/labels.py` | a window's icon, title and application name |
| `src/brpol_waybard/windows.py` | the taskbar buttons: classes, group and lock icons, tooltips, overflow |
| `src/brpol_waybard/workspaces.py` | the workspace buttons and the urgency set |
| `src/brpol_waybard/hidden.py` | the special-workspace buttons |
| `src/brpol_waybard/status.py` | the PIA, weather, night light and recording buttons, and where each gets its state |
| `src/brpol_waybard/fifos.py` | the pipes, and why they are opened O_RDWR |
| `src/brpol_waybard/control.py` | what a line on the control FIFO means |
| `src/brpol_waybard/fade.py` | fading a new window in, and holding the focus colours meanwhile |
| `src/brpol_waybard/__main__.py` | the event loop |

Two counts are contracts with the waybar config: `layout.SLOTS` must equal the
number of `custom/winN` modules in `windows.jsonc`, and `workspaces.SLOTS` /
`hidden.SLOTS` the number of `custom/wsN` / `custom/hiddenN` in
`workspaces.jsonc`.
