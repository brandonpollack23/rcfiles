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
- commented-out lines: list them under "Referenced only in commented-out
  config", and move them to the right table when they are uncommented

Record the package name (not just the binary), what it provides, and where it is
used. Resolve the package with `pacman -Qo $(which <binary>)`, and add it to the
install command at the bottom.

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
- To test binds and submaps, inject real keycodes with `ydotool key <code>:1 <code>:0`
  (needs `ydotoold`; 28 = Enter, 1 = Escape). Do not use `wtype`: its private
  keymap makes Hyprland's binds read every key as Escape. `wtype` is fine for
  sending keys to a client.
- Live tests act on the user's real session and focus; use throwaway windows on
  a hidden special workspace where possible.
- From a shell without `HYPRLAND_INSTANCE_SIGNATURE`, take it from
  `hyprctl instances`.
