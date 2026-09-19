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
| `hyprlauncher` | app launcher; `--dmenu` picker for `scripts/keybind-search.sh`, `scripts/theme-select.sh`, `scripts/workspace-menu.sh` and `scripts/system.sh` | `SUPER+R`, `SUPER+/`, `SUPER+F5`, `SUPER+W`, `SUPER+M`, `SUPER+SHIFT+R` |
| `google-chrome` (AUR) | browser, autostarted | `hyprland.lua` |
| `waybar` | desktop bar, autostarted; `custom/grouplock` module shows the group lock icon (`conf/wm.lua`) | `hyprland.lua` |
| `swaync` | notification center, autostarted; `swaync-client` toggles it | `hyprland.lua`, `SUPER+N` |
| `hyprlock` | lock screen, styled by `hyprlock.conf` | `SUPER+SHIFT+Escape` |

## Notification center (`~/.config/swaync`)

Buttons in the control center (`SUPER+N`) grid, set in `swaync/config.json`.

| Package | Provides | Used by |
| --- | --- | --- |
| `networkmanager` | `nmcli` | Wi-Fi toggle |
| `bluez-utils` | `bluetoothctl` | Bluetooth toggle |
| `pavucontrol` | audio mixer | Audio button |
| `nm-connection-editor` | network settings | Network button |
| `blueman` | `blueman-manager` | Devices button |

## System menu (`scripts/system.sh`)

`SUPER+SHIFT+R`, and the power subset from the waybar power button. Also uses
`hyprlauncher`, `hyprlock`, `waybar`, `swaync`, `ghostty` and `procps-ng` from
the tables above.

| Package | Provides | Used by |
| --- | --- | --- |
| `systemd` | `systemctl`, `journalctl` | suspend, reboot, shut down, restart audio, failed services, errors since boot |
| `util-linux` | `setsid` | detaching restarted waybar and swaync from the script |
| `coreutils`, `grep` | `cut`, `grep` | mapping the picked label back to its action |
| `pipewire-pulse` | PulseAudio shim user service | restart audio |
| `paru` (AUR) | `paru` | update system, remove unneeded packages |

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
  hyprlauncher hyprlock waybar swaync wireplumber pipewire pipewire-pulse playerctl brightnessctl \
  systemd util-linux grep networkmanager bluez-utils pavucontrol nm-connection-editor blueman
paru -S --needed google-chrome
```
