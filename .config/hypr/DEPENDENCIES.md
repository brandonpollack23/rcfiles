# Dependencies

Everything this Hyprland config needs beyond Hyprland itself. Package names are
Arch/AUR. Keep this in sync with the config (see `AGENTS.md`).

## Required

| Package | Provides | Used by |
| --- | --- | --- |
| `hyprland` (>= 0.56, Lua config) | compositor, `hyprctl`, Lua stubs in `/usr/share/hypr/stubs` | everything; `hyprctl eval` is the callback for the close-others dialog (`conf/wm.lua`) and the workspace prompts (`scripts/workspace-menu.sh`); stubs are referenced by `.luarc.json` |
| `zenity` | `zenity` | close-others confirmation dialog (`conf/wm.lua`); workspace name and placement prompts (`scripts/workspace-menu.sh`), floated by a rule in `conf/rules.lua` |
| `coreutils` | `ls`, `mkdir` | listing `conf/themes/` and creating `$XDG_STATE_HOME/hypr` (`conf/theme.lua`) |
| `procps-ng` | `pkill`, `pidof` | signals waybar to refresh the group lock indicator (`conf/wm.lua`); single-instance check for the lock bind (`conf/keymaps.lua`) |

## Programs (`conf/programs.lua`)

Swappable: change the entry in `conf/programs.lua` and update this table.

| Package | Role | Bind |
| --- | --- | --- |
| `ghostty` | terminal | `SUPER+T` |
| `nautilus` | file manager | `SUPER+E` |
| `hyprlauncher` | app launcher; `--dmenu` picker for `scripts/keybind-search.sh`, `scripts/theme-select.sh` and `scripts/workspace-menu.sh` | `SUPER+R`, `SUPER+/`, `SUPER+F5`, `SUPER+W`, `SUPER+M` |
| `google-chrome` (AUR) | browser, autostarted | `hyprland.lua` |
| `waybar` | desktop bar, autostarted; `custom/grouplock` module shows the group lock icon (`conf/wm.lua`) | `hyprland.lua` |
| `swaync` | notification center, autostarted | `hyprland.lua` |
| `hyprlock` | lock screen, styled by `hyprlock.conf` | `SUPER+SHIFT+Escape` |

## Media / hardware keys (`conf/keymaps.lua`)

| Package | Provides | Used by |
| --- | --- | --- |
| `wireplumber` (with `pipewire`) | `wpctl` | volume and mic mute keys |
| `playerctl` | `playerctl` | play/pause/next/prev keys |
| `brightnessctl` | `brightnessctl` | brightness keys |

## Referenced only in `TODO.md`

Not needed today; install if you paste the matching snippet from `TODO.md` back
into the config.

- `hyprpaper`, `network-manager-applet` (`nm-applet`): autostart in `hyprland.lua`
- `hyprshutdown`: exit bind in `conf/keymaps.lua`
- `grim`, `xdg-desktop-portal-hyprland`, `hyprpm` (ships with `hyprland`): permissions in `hyprland.lua`

## Install

```sh
sudo pacman -S --needed hyprland zenity coreutils procps-ng ghostty nautilus \
  hyprlauncher hyprlock waybar swaync wireplumber pipewire playerctl brightnessctl
paru -S --needed google-chrome
```
