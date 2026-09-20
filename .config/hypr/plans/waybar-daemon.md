# Waybar taskbar daemon

Consolidate the waybar scripts into one daemon, then decide whether to port it.

## Why

Every waybar `custom/*` module here runs in continuous mode: no `interval`, so
waybar starts the script once and reads its stdout until the bar exits. That is
39 permanent processes -- 12 `custom/winN` plus overflow, 25 `custom/wsN`, 2
hidden-workspace buttons -- each holding its own subscription to Hyprland's
event socket and each recomputing the whole layout to keep one slice of it.

Measured on a live session:

| | value |
|---|---|
| processes | 39 |
| memory (PSS) | 228 MB |
| IPC round trips per window event | 129 |
| duplicate `repl` calls into Lua per event | 12 |

`openwindow` is in all three scripts' `EVENTS` sets, so one window opening wakes
all 39. The 12 renderers each run the same `entries()` -- sort by position,
collapse groups to one placement, expand tabs in order -- and discard all but
`items[slot - 1]`. Each also asks `conf.wm.lockedAddresses()` over the Lua REPL
for the same answer, because group lock state exists only inside the compositor.

The scatter is also why the refresh signal exists: `taskbar.lua` has to reach 12
separate processes, hence `pkill -RTMIN+8 -f "scripts/windows[.]py [0-9]"` with
a cmdline regex written to miss the short-lived `focus` process.

## Shape

    now     Hyprland --> 39 python procs --> 39 waybar buttons
            (39 event subscriptions, 129 queries/event)

    after   Hyprland --> 1 daemon --> 39 `cat` on FIFOs --> 39 waybar buttons
            (1 event subscription, 3 queries/event)

Waybar requires one process per button; that does not change. What changes is
that 39 of them stop being interpreters doing real work and become pipes. A
`cat` blocked on a FIFO measures 148 KB PSS, so all 39 cost about 6 MB.

## What changes

- One process connects to `.socket2.sock`, computes `entries()` once per event,
  and writes each slot's JSON line to that slot's FIFO.
- Queries drop to `monitors`, `clients`, `workspaces` -- three per event, shared
  by every module instead of re-fetched per module.
- One `lockedAddresses()` call per event instead of 12.
- `taskbar.lua` `M.refresh()` writes to the daemon's control socket instead of
  `pkill -RTMIN+8 -f`. The realtime signal, the cmdline regex, and the
  `set_wakeup_fd` self-pipe in `windows.py` all go away.
- `on-click` either writes to the control socket or stays a short-lived process.
- Supervision: `exec-once` alongside waybar, clients retry if it is not up yet.

## Phases

1. Daemon serving the 13 window modules only. Run it beside the current
   scripts and diff the JSON lines until they match.
2. Point `windows.jsonc` at the FIFOs. Delete the watch path from `windows.py`,
   keeping `focus` until phase 4.
3. Fold in the 25 workspace buttons and 2 hidden-workspace buttons.
4. Replace the signal with the control socket. Update `conf/wm/taskbar.lua`,
   `conf/wm/group.lua` and `DEPENDENCIES.md` (drops `procps-ng` for this use).

Do not change architecture and language in the same step -- if something breaks,
the cause should be unambiguous.

## Then: port, or not

Per-process memory for the one daemon, measured here:

| runtime | daemon PSS | total with 39 `cat` | note |
|---|---|---|---|
| python | ~6 MB | ~12 MB | no new dependency |
| rust | ~3-5 MB | ~10 MB | static binary, no runtime dep |
| bun | ~24 MB | ~30 MB | `/usr/bin/bun` 1.4.2, pacman `extra` |

The 39 -> 1 merge saves 216 MB. Every language choice after that moves single
digits, and the query count is identical in all three. Port only for reasons
that are not performance:

**Rust** -- a static binary drops `python` from `DEPENDENCIES.md` entirely, so
the bar stops caring that Arch rolls Python majors. The slot/group state machine
(`solo`/`gstart`/`gmid`/`gend`, `active`/`shown`/`locked`/`floating`) is a sum
type currently modelled as stringly-typed lists; Rust enums fit it properly.
`hyprland-rs` covers the IPC and event listener. Costs: a build step in a config
repo, and `ICONS`/`NAMES`/`SUFFIXES`/the length budgets become recompiles unless
they move to a TOML file, which is more code than it removes.

**Bun** -- only worth it if writing the bar logic in TypeScript is itself the
goal. Four times python's memory for no functional gain. Note that bun and deno
cannot listen for realtime signals (`SIGRTMIN+8` is rejected outright), which
rules them out today but is moot after phase 4 deletes the signal.

Considered and not planned: computing the taskbar inside the compositor in Lua,
where `hl.get_windows()` is in-process and the IPC disappears entirely. Blocked
by the `AGENTS.md` rule against blocking in Lua -- a FIFO write with no reader
attached would freeze the compositor -- and a bug there takes down the session,
not just the bar.

## Open questions

- FIFO versus a unix socket per slot. FIFOs need no new package; sockets
  reconnect more cleanly and need `socat`, which is not installed.
- The daemon is a single point of failure: it dies, the whole bar blanks at
  once, where today one button dies alone.
- Debuggability regresses. `windows.py 3` in a terminal currently shows exactly
  what slot 3 emits; after this the slot is just a pipe.
