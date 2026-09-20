# Hyprland config

Lua-based Hyprland config. `hyprland.lua` is the entry point; modules live in
`conf/` and are loaded with `require("conf.<name>")`. API stubs are in
`/usr/share/hypr/stubs/hl.meta.lua`.

## Keep `DEPENDENCIES.md` up to date

Any change that adds, removes, or swaps an external program must update
`DEPENDENCIES.md` in the same change. That covers:

- anything passed to `hl.exec_cmd` / `hl.dsp.exec_cmd`, including every binary
  inside a shell one-liner
- entries in `conf/programs.lua`
- plugins, cursor/icon themes, fonts, and env vars that assume a package
- disabled snippets in `TODO.md`: list them under "Referenced only in
  `TODO.md`", and move them to the right table when they go back into the config

Record the package name (not just the binary), what it provides, and where it is
used. Resolve the package with `pacman -Qo $(which <binary>)`, and add it to the
install command at the bottom.

## System commands go in `scripts/system.sh`

Anything the user might need to run by hand, such as restarting a daemon, a
session or power action, or a maintenance task, goes in the `SUPER+SHIFT+R`
menu in `scripts/system.sh`: add an `action|label` line to `ALL` (or `POWER`
for session and power actions) and a matching `case` branch. Use `in_terminal`
for commands whose output the user needs to read or that prompt. When you add a
new daemon or program to the config, add its restart or reload here too.

## Disabled config and TODOs

Don't leave commented-out config or TODO comments in the Lua files. Put planned
work and disabled snippets in `TODO.md`.

When you implement something, check that file if you should update it and remove
something you've done.

## Gotchas

- Never block in Lua on a GUI program (`io.popen`, `os.execute`): the compositor
  cannot draw the window it is waiting on. Spawn it with `hl.exec_cmd` and call
  back in with `hyprctl eval '<lua>'`.
- A command passed to exec must not start with `[`: Hyprland parses a leading
  bracket as inline window rules (`[float] cmd`). Use `test` instead of `[ ]`.

- `hyprland-dialog` (hyprland-guiutils) has no keyboard handling and cannot
  position its buttons, so confirmations use `zenity --question`, where Enter
  and Escape work natively. Pass `--no-markup` when the text includes window
  titles.

## Testing

- `luac -p conf/*.lua hyprland.lua` for syntax.
- `hyprctl reload config-only && hyprctl configerrors` to load and check.
- `hyprctl repl '<lua>'` evaluates in the live config state, e.g.
  `hyprctl repl 'return pcall(require("conf.wm").closeOtherWindows)'`.
- To test binds and submaps, inject real keycodes with
  `ydotool key <code>:1 <code>:0` (needs `ydotoold`; 28 = Enter, 1 = Escape). Do
  not use `wtype`: its private keymap makes Hyprland's binds read every key as
  Escape. `wtype` is fine for sending keys to a client.
- Live tests act on the user's real session and focus; use throwaway windows on
  a hidden special workspace where possible. Make your own named one for it
  (`special:agenttest`, e.g. `hl.exec_cmd("ghostty", { workspace = "special:agenttest silent" })`)
  rather than borrowing `special:Hidden`, which is the user's scratchpad. Close
  every window you opened when you are done, and check nothing of yours is left
  behind, including dialogs. Leaving test windows around is a bug in the test.
- From a shell without `HYPRLAND_INSTANCE_SIGNATURE`, take it from
  `hyprctl instances`.
