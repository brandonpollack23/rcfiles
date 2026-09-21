# brpol-waybard

The daemon behind every scripted waybar button. `README.md` has the why, the
file layout, and how one render flows; read it first.

## Run the checks after every change

Any change under `src/` or `tests/` is not done until all three pass:

    uv run pytest
    uv run mypy
    uv run ruff check src tests && uv run ruff format --check src tests

They take a few seconds and never touch the live session: the tests run against
a fake Hyprland on scratch sockets (`tests/fake_hyprland.py`), so there is no
reason to skip them, and they work from a shell with no Hyprland at all.

Changes elsewhere that the daemon depends on need the tests too, plus a look at
the live bar, because the tests fake that side:

- `lockedAddresses` / `focusAddress` in `~/.config/hypr/conf/wm/taskbar.lua`,
  which `ipc.py` calls through the Lua REPL as `require("conf.wm")`
- the `custom/winN`, `custom/wsN`, `custom/hiddenN` modules in `../windows.jsonc`
  and `../workspaces.jsonc`, whose counts must equal `layout.SLOTS`,
  `workspaces.SLOTS` and `hidden.SLOTS`
- the classes in `../style.css`, which must stay in step with `CssClass` in
  `types.py`, and its `transition`, which must match `FADE` in `fade.py`

## Tests change with the code

- New behaviour gets a test, and a bug gets a test that fails before the fix.
  The README's test table says which file each kind belongs in.
- Build snapshots with `tests/builders.py` rather than by hand, so a test
  states only the fields it is about.
- If a change makes an existing test fail, decide which of the two is wrong
  before touching either. Do not loosen an assertion just to get back to green.
- `test_daemon.py` runs on real timers. Wait with `wait_until` / `Reader.wait_for`;
  do not add bare `time.sleep` calls to make a race go away.

## Trying it live

The running daemon keeps the old code until it is restarted:
`~/.config/hypr/scripts/system.sh restart-taskbar-daemon`. To look at a button
without restarting anything, `scripts/launch.sh --once win14` prints what that
button would be given right now. Both act on the user's real session; see
`~/.config/hypr/AGENTS.md` for the rules on live testing.
