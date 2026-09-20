# Dependencies

Everything this Hyprland config needs beyond Hyprland itself. Package names are
Arch/AUR. Keep this in sync with the config (see `AGENTS.md`).

## Required

| Package | Provides | Used by |
| --- | --- | --- |
| `hyprland` (>= 0.56, Lua config) | compositor, `hyprctl`, Lua stubs in `/usr/share/hypr/stubs` | everything; `hyprctl eval` is the callback for the close-others dialog (`conf/wm/close.lua`) and the workspace prompts (`scripts/workspace-menu.sh`); stubs are referenced by `.luarc.json` |
| `zenity` | `zenity` | close-others confirmation dialog (`conf/wm/dialog.lua`); workspace name and placement prompts (`scripts/workspace-menu.sh`), floated by a rule in `conf/rules.lua` |
| `coreutils` | `ls`, `mkdir` | listing `conf/themes/` and creating `$XDG_STATE_HOME/hypr` (`conf/theme/`) |
| `procps-ng` | `pkill`, `pidof` | signals waybar to refresh the group lock indicator (`conf/wm/group.lua`); single-instance check for the lock bind (`conf/keymaps.lua`) |
| `python` | `python3` | the waybar workspace buttons: one per workspace id (`~/.config/waybar/scripts/workspace.py`) and one per hidden workspace (`~/.config/waybar/scripts/hidden-workspace.py`) |

## Programs (`conf/programs.lua`)

Swappable: change the entry in `conf/programs.lua` and update this table.

| Package | Role | Bind |
| --- | --- | --- |
| `ghostty` | terminal | `SUPER+T` |
| `nautilus` | file manager | `SUPER+E` |
| `hyprlauncher` | app launcher; `--dmenu` picker for `scripts/keybind-search.sh`, `scripts/theme-select.sh`, `scripts/workspace-menu.sh` and `scripts/system.sh` | `SUPER+R`, `SUPER+/`, `SUPER+F5`, `SUPER+W`, `SUPER+M`, `SUPER+SHIFT+S`, `SUPER+SHIFT+R` |
| `google-chrome` (AUR) | browser, autostarted | `hyprland.lua` |
| `waybar` | desktop bar, autostarted; `custom/grouplock` module shows the group lock icon (`conf/wm/group.lua`) | `hyprland.lua` |
| `swaync` | notification center, autostarted; `swaync-client` toggles it | `hyprland.lua`, `SUPER+N` |
| `hyprlock` | lock screen, styled by `hyprlock.conf` | `SUPER+SHIFT+Escape` |
| `hypridle` | idle daemon, autostarted; dims, locks and turns screens off per `hypridle.conf` | `hyprland.lua` |
| `hypr-persist` (AUR) | session save/restore daemon, autostarted; restores the last session's windows (adopting ones already open) per `hypr-persist.toml` | `hyprland.lua` |
| `awww` | wallpaper daemon (`awww-daemon`), autostarted; `awww img` sets the Bing wallpaper | `hyprland.lua`, `scripts/bing-wallpaper.sh` |
| `rofimoji` | emoji picker; runs through `hyprlauncher --dmenu` (`--selector hyprlauncher`), copies with `wl-clipboard` and pastes with `ydotool` (`--typer ydotool`, since the autodetected `wtype` breaks Hyprland's binds) | `SUPER+SHIFT+semicolon` |

## Bing wallpaper (`scripts/bing-wallpaper.sh`)

`hyprland.lua` runs `bing-wallpaper.sh start` at startup, which imports the
Wayland environment into the systemd user manager and starts
`bing-wallpaper.timer` (not enabled) and `bing-wallpaper.service`. The timer
runs at the frequency saved in `$XDG_STATE_HOME/hypr/bing-wallpaper-frequency`
(default `daily`; set it from the system menu or with
`bing-wallpaper.sh frequency <spec>`), applied as a runtime drop-in. The
units live in `.config/systemd/user/` in rcfiles and are symlinked by
`install.sh`. The service skips its run when the Hyprland instance it was
started from is gone. Images and metadata are cached in
`$XDG_CACHE_HOME/bing-wallpaper` for 30 days. The system menu lists the current
image as "Bing Wallpaper: <title>" and opens Bing's page about it.

| Package | Provides | Used by |
| --- | --- | --- |
| `awww` | `awww` | shows the image, waits for the daemon with `awww query` |
| `systemd` | `systemctl`, `systemd-analyze`, user service and timer | scheduled `update`, `start`, `refresh`, validating `frequency` |
| `curl` | `curl` | Bing's image API and the UHD image |
| `jq` | `jq` | reading the image metadata (title, link) |
| `xdg-utils` | `xdg-open` | opening the Bing page in the default browser |
| `coreutils`, `findutils` | `readlink`, `ln`, `basename`, `find` | tracking the current image, deleting old ones |

## Lock screen and idle (`hyprlock.conf`, `hypridle.conf`)

`conf/lockscreen.lua` writes the theme colours for `hyprlock.conf` to
`$XDG_STATE_HOME/hypr/hyprlock.conf` (uses `coreutils` `mkdir`). The dynamic
labels come from `scripts/lock-info.sh`.

| Package | Provides | Used by |
| --- | --- | --- |
| `ttf-jetbrains-mono-nerd` | JetBrainsMono Nerd Font, incl. icons | every `hyprlock.conf` label and the input field |
| `noto-fonts-emoji` | colour emoji | weather condition icon from wttr.in |
| `curl` | `curl` | weather (`lock-info.sh weather`, cached in `~/.cache/hyprlock`) |
| `kmod` | `modinfo` | restart hint after an NVIDIA driver update (`lock-info.sh reboot`) |
| `procps-ng` | `uptime`, `pidof` | footer (`lock-info.sh footer`); single-instance lock in `hypridle.conf` |
| `coreutils` | `stat`, `date` | weather cache age, clock date, greeting |
| `systemd` | `loginctl` | `hypridle.conf` locks before sleep via `lock-session` |
| `brightnessctl` | `brightnessctl` | dim before locking (`hypridle.conf`); no-op on desktop monitors |
| `fprintd` (only with a reader) | fingerprint D-Bus service, `fprintd-enroll` | parallel fingerprint unlock (`hyprlock.conf` `auth`); installed by `install.sh` when a reader is found; enroll from the system menu |

## Notification center (`~/.config/swaync`)

Buttons in the control center (`SUPER+N`) grid, set in `swaync/config.json`.

| Package | Provides | Used by |
| --- | --- | --- |
| `networkmanager` | `nmcli` | Wi-Fi toggle |
| `bluez-utils` | `bluetoothctl` | Bluetooth toggle |
| `pavucontrol` | audio mixer | Audio button |
| `nm-connection-editor` | network settings | Network button |
| `blueman` | `blueman-manager` | Devices button |

Vim keys while the control center is open (`conf/notifications.lua`), listed in
the panel's top label.

| Package | Provides | Used by |
| --- | --- | --- |
| `ydotool` | `ydotool`, `ydotoold` (enable `ydotool.service` user unit; needs `/dev/uinput` access) | sends arrow/Enter/Delete keys to the panel from the `notifications` submap; pastes the emoji picked by `rofimoji` |

## System menu (`scripts/system.sh`)

`SUPER+SHIFT+R`, and the power subset from the waybar power button. Also uses
`hyprlauncher`, `hyprlock`, `waybar`, `swaync`, `ghostty` and `procps-ng` from
the tables above.

| Package | Provides | Used by |
| --- | --- | --- |
| `systemd` | `systemctl`, `journalctl` | suspend, reboot, shut down, restart audio, failed services, errors since boot |
| `util-linux` | `setsid` | detaching restarted waybar, swaync and hypridle from the script |
| `fprintd` | `fprintd-enroll`, `fprintd-verify` | enroll fingerprint |
| `coreutils`, `grep` | `cut`, `grep` | mapping the picked label back to its action |
| `pipewire-pulse` | PulseAudio shim user service | restart audio |
| `paru` (AUR) | `paru` | update system, remove unneeded packages |
| `awww` | `awww-daemon` | restart wallpaper daemon |
| `hypr-persist` (AUR) | `hypr-persist` | restart session daemon, save session now |

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
sudo pacman -S --needed hyprland zenity coreutils procps-ng python ghostty nautilus \
  hyprlauncher hyprlock hypridle waybar swaync wireplumber pipewire pipewire-pulse playerctl brightnessctl \
  systemd util-linux grep networkmanager bluez-utils pavucontrol nm-connection-editor blueman ydotool \
  ttf-jetbrains-mono-nerd noto-fonts-emoji curl kmod awww jq xdg-utils findutils rofimoji wl-clipboard
sudo pacman -S --needed fprintd  # only with a fingerprint reader
paru -S --needed google-chrome hypr-persist
```
