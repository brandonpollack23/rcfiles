# Dependencies

Everything this Hyprland config needs beyond Hyprland itself. Package names are
Arch/AUR. Keep this in sync with the config (see `AGENTS.md`).

## Required

| Package | Provides | Used by |
| --- | --- | --- |
| `hyprland` (>= 0.56, Lua config) | compositor, `hyprctl`, Lua stubs in `/usr/share/hypr/stubs` | everything; `hyprctl eval` is the callback for the close-others dialog (`conf/wm.lua`); stubs are referenced by `.luarc.json` |
| `zenity` | `zenity` | close-others confirmation dialog (`conf/wm.lua`) |

## Programs (`conf/programs.lua`)

Swappable: change the entry in `conf/programs.lua` and update this table.

| Package | Role | Bind |
| --- | --- | --- |
| `ghostty` | terminal | `SUPER+T` |
| `nautilus` | file manager | `SUPER+E` |
| `hyprlauncher` | app launcher; `--dmenu` picker for `scripts/keybind-search.sh` | `SUPER+R`, `SUPER+/` |
| `google-chrome` (AUR) | browser, autostarted | `hyprland.lua` |

## Media / hardware keys (`conf/keymaps.lua`)

| Package | Provides | Used by |
| --- | --- | --- |
| `wireplumber` (with `pipewire`) | `wpctl` | volume and mic mute keys |
| `playerctl` | `playerctl` | play/pause/next/prev keys |
| `brightnessctl` | `brightnessctl` | brightness keys |

## Referenced only in commented-out config

Not needed today; install if you uncomment the matching lines.

- `waybar`, `hyprpaper`, `network-manager-applet` (`nm-applet`): autostart in `hyprland.lua`
- `hyprshutdown`: exit bind in `conf/keymaps.lua`
- `hyprpm` (ships with `hyprland`): plugin permission in `hyprland.lua`

## Install

```sh
sudo pacman -S --needed hyprland zenity ghostty nautilus hyprlauncher \
  wireplumber pipewire playerctl brightnessctl
paru -S --needed google-chrome
```
