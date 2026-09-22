# hyprland todo: what Omarchy has to do before I switch

Everything my current `.config/hypr` + waybar setup does, and whether Omarchy
has an answer. Checked against **Omarchy 4.0.4 "Quattro"** (Sep 2026):
repo `github.com/omacom/omarchy`, manual at learn.omacom.io.

- ✅ Omarchy does it: learn its version and drop mine
- 🟡 partly: needs a setting or a small port
- ❌ no answer: port mine or go without

## Read this first

- **Omarchy 4's Hyprland config is Lua (Hyprland 0.56), and so is mine.** My
  `conf/*.lua` modules use the same `hl.*` API, so most of them port by copying
  them into `~/.config/hypr/` and `require`-ing them from `hyprland.lua`.
- **Waybar, swaync, swayosd, hyprlock, hypridle, walker and mako are all gone.**
  One Quickshell process (`omarchy-shell`) draws the bar, menus,
  notifications, OSD and lock screen. That means **brpol-waybard, the
  l1p0-menu popups and the swaync config have nowhere to plug in**. Anything
  they do has to become an Omarchy shell plugin (QML, in
  `~/.config/omarchy/plugins/`) or be dropped.
- **Where settings go:**
  - `~/.config/hypr/{hyprland,bindings,monitors,input,looknfeel,autostart}.lua`
  - `~/.config/omarchy/shell.json` for the bar and idle. It is used instead of
    the defaults, not merged with them.
  - `~/.config/omarchy/themes/`
  - `~/.config/omarchy/hooks/`
  - `~/.config/omarchy/extensions/omarchy-menu.jsonc`
  - Never edit `/usr/share/omarchy`: pacman overwrites it.
- **Hyprland plugins (hyprpm):** Omarchy never mentions them. That doesn't mean
  they can't work, but it's untested, so try them in the VM.

## 1. Keybindings (do this first, everything else hangs off it)

- [ ] Decide: `omarchy_default_bindings = false` and port my `keymaps.lua`, or
      keep Omarchy's and `hl.unbind` the ones that clash. **Recommended: keep
      Omarchy's defaults and unbind the clashes.** You keep their app, capture
      and panel binds, and `SUPER+K` still lists everything as long as I bind
      with `o.bind(keys, description, cmd)`.
- [ ] Clashes to resolve (mine → Omarchy's use of the key):
  - `SUPER+h/j/k/l` focus → Omarchy: `SUPER+J` togglesplit, `SUPER+K`
    keybind cheatsheet, `SUPER+L` dwindle/scrolling toggle
  - `SUPER+V` float → Omarchy: paste (`SUPER+T` is float)
  - `SUPER+T` terminal → Omarchy: `SUPER+Return` (my `SUPER+Return` is
    swapwithmaster)
  - `SUPER+S` my hidden-workspace toggle → Omarchy: scratchpad (same idea)
  - `SUPER+TAB` next tab in group → Omarchy: next workspace
  - `SUPER+/` keybind search → Omarchy: display scale
  - `SUPER+R` launcher → Omarchy: `SUPER+Space`
  - `SUPER+SHIFT+R` system menu → Omarchy: `SUPER+Escape`
  - `SUPER+E` file manager → Omarchy: `SUPER+SHIFT+F`
  - `SUPER+N` notification center → Omarchy: `SUPER+SHIFT+ALT+,` (history)
  - `SUPER+SHIFT+Escape` lock → Omarchy: `SUPER+CTRL+L`
  - `SUPER+Q` close: check what Omarchy binds for close
  - `SUPER+W`, `SUPER+M`, `SUPER+O`, `SUPER+I`, `SUPER+D`, `SUPER+G`:
    check each against `omarchy menu keybindings --print`

## 2. Layouts

- [ ] 🟡 **Master as the default layout.** Omarchy defaults to dwindle and no
      binding uses master. Set `general.layout = "master"` in `looknfeel.lua`.
- [ ] 🟡 **Master binds** (swapwithmaster, focusmaster, addmaster,
      removemaster, orientation cycle): not bound in Omarchy. Port them from
      `keymaps.lua`.
- [ ] 🟡 **Per-workspace layouts kept by name** (`conf/layouts.lua`,
      `conf/workspaces/layout.lua`: "focus" center-master 0.6 vs
      "work/reference" with a 25% reference column, `SUPER+ALT+O`). Omarchy
      keeps a dwindle/scrolling choice per workspace in
      `~/.local/state/omarchy/workspace-layouts/`. Either port mine or extend
      theirs to cover my presets.
- [ ] ❌ **Center-master side columns stay put** when a window closes
      (`conf/wm/columns.lua`): port it.
- [ ] 🟡 **Special/hidden workspaces use dwindle**: a one-line `hl.workspace_rule`.
- [ ] ✅ **Scrolling layout** is built in (`SUPER+L`). Worth trying before
      porting all my master work.
- [ ] ✅ **Pseudo (`SUPER+P`), float, and mouse drag/resize** are built in.
- [ ] 🟡 **Look:** gaps 0, border 3, rounding 4, blur and shadow go in
      `looknfeel.lua`.

## 3. Windows and groups

- [ ] ✅ **Group toggle, next/prev tab, move into group by direction, ungroup**
      are built in (different keys: `SUPER+ALT+arrows`, `SUPER+ALT+G`).
- [ ] ❌ **Group lock** (new windows don't join), `SUPER+SHIFT+G`: port
      `conf/wm/group.lua`.
- [ ] ❌ **Reorder tabs submap** (`SUPER+CTRL+G`, h/l): port it.
- [ ] 🟡 **Group-with-direction submap** (`SUPER+ALT+G` h/j/k/l): Omarchy does
      this with `SUPER+ALT+arrows` and no submap. Probably just use theirs.
- [ ] ❌ **Undo/redo of group changes** (`conf/wm/history.lua`): port it.
- [ ] ❌ **Close every other window with a confirmation**
      (`conf/wm/close.lua`, zenity): port it. It needs `zenity`.
- [ ] ❌ **hyprfocus focus animation** (hyprpm plugin): try hyprpm in the VM.
- [ ] 🟡 **Window rules:**
  - suppress maximize, the XWayland drag fix, float zenity: diff against
    Omarchy's `default/hypr/windows.lua`, keep what's missing
  - the Steam toast offset was for a bottom bar, so probably not needed

## 4. Workspaces

- [ ] ✅ **Workspaces 1-10, next/prev existing, scroll to switch** are built in.
- [ ] ✅ **Move a workspace to another monitor** is built in
      (`SUPER+SHIFT+ALT+arrows`).
- [ ] ❌ **Named workspaces** (`conf/workspaces/`, `scripts/workspace-menu.sh`):
      a picker to create, rename and move a window to one, with placement
      order and gap-free ids. Port it. It used hyprlauncher `--dmenu`, so swap
      in Omarchy's menu (check whether `omarchy menu` has a dmenu mode) or use
      `fzf` in a floating terminal.
- [ ] ❌ **Reorder workspaces** left/right (`SUPER+CTRL+SHIFT+arrows`): port
      it, it comes with the above.
- [ ] 🟡 **Hidden workspaces:** Omarchy has one scratchpad (`SUPER+S`,
      `SUPER+ALT+S`). My named hidden workspaces H1, H2… and "move to
      hidden" are ❌.
- [ ] ❌ **Workspace overview** (Hyprspace fork, `SUPER+SHIFT+W`): Omarchy has
      none and doesn't use hyprpm. Try hyprpm with my fork in the VM, or go
      without.
- [ ] ❌ **Workspace names survive a session restore**
      (`conf/workspaces/persist.lua`): only matters if session restore comes
      along (§8).

## 5. Bar (the biggest gap)

- [ ] ❌ **Per-window taskbar** with group tabs and a lock icon, click to focus
      (brpol-waybard). Omarchy has no window list, only
      `omarchy.active-window` (the focused title). Decide: write an Omarchy
      shell plugin (QML), look at omarchyplugins.com, or live without it.
- [ ] 🟡 **Workspace buttons with names and hidden-workspace buttons:**
      Omarchy's bar shows numbers 1-5 plus any others in use. Names and hidden
      buttons need a plugin.
- [ ] ✅ **Weather** is built in (no OpenWeatherMap key, so the sops secret
      for it can go).
- [ ] ✅ **Audio, network, Bluetooth, calendar, display/brightness and power
      panels** are built in (`SUPER+CTRL+A/W/B/D/P`) and replace l1p0-menus.
- [ ] ✅ **Tailscale widget** is built in (optional).
- [ ] 🟡 **Night light button:** hyprsunset with a toggle (`SUPER+CTRL+N`,
      fixed 4000K/6500K); no bar widget.
- [ ] 🟡 **Recording indicator:** Omarchy records with gpu-screen-recorder.
      Check whether the bar shows a timer or stop button.
- [ ] ❌ **PIA VPN widget:** a plugin, or use Tailscale plus the PIA app's own
      tray icon.
- [ ] ❌ **KDE Connect phone widget:** a plugin, or drop it (install
      `kdeconnect` either way; it has a tray icon).
- [ ] ❌ **Bing logo button and popup:** see §9.
- [ ] 🟡 **Submap indicator:** only needed if my submaps come along.

## 6. Launcher, menus, notifications, OSD

- [ ] ✅ **App launcher** is built in: `SUPER+Space`.
- [ ] ✅ **Keybind search** is built in: `SUPER+K`.
- [ ] ✅ **Emoji picker** is built in: `SUPER+CTRL+E`, which replaces rofimoji
      and the ydotool paste hack.
- [ ] ✅ **Clipboard history** is new for me: `SUPER+CTRL+V`.
- [ ] 🟡 **System menu** (`scripts/system.sh`): Omarchy has System (power),
      Update (system, config, restart audio/wifi/bt/hyprsunset/shell) and
      Setup menus. Add what's missing through
      `~/.config/omarchy/extensions/omarchy-menu.jsonc`:
  - edit secrets (sops)
  - failed units
  - journal errors
  - fcitx5 config
  - restart KDE Connect
- [ ] 🟡 **Notifications:** dismiss, dismiss all, DND and history are built in.
      There is no swaync-style control center, and my vim keys for it are moot.
- [ ] ✅ **Volume/brightness OSD and media keys** are built in, plus DDC
      brightness on external monitors.
- [ ] ❌ **Sound and notification on USB, charger or monitor plug/unplug**
      (brpol-waybard `hotplug.py`, `conf/hotplug.lua`): port it as a small
      standalone user service, if I still want it.

## 7. Lock, idle, power

- [ ] 🟡 **Lock screen:** Omarchy's own (`SUPER+CTRL+L`). My hyprlock extras
      are probably ❌: themed colours, weather, the NVIDIA "restart after
      driver update" hint, the greeting and uptime footer. Check what their
      LockView shows.
- [ ] 🟡 **Idle:** mine dims at 9.5 min, locks at 10, screens off at 10.5, and
      turns screens off 60 s into any lock. Omarchy has screensaver and lock
      timings in `shell.json` `idle`. Check whether dim and DPMS-off exist.
- [ ] ✅ **Lock before sleep**: check it on real hardware.
- [ ] ✅ **Fingerprint** (not needed on the desktop).
- [ ] 🟡 **Keyboard focus comes back after unlock** (`conf/wm/focus.lua` works
      around a Hyprland bug): see whether it still happens under Omarchy's lock.
- [ ] ✅ **Stay-awake toggle** is new: `SUPER+CTRL+I`.

## 8. Session restore

- [ ] ❌ **Restore last session's windows at login** (hypr-persist + my
      named-workspace shim): Omarchy has none. Try the `hypr-persist` AUR
      package on Omarchy, or drop it and lean on tmux/Herdr sessions.

## 9. Theme and wallpaper

- [ ] ✅ **Theme picker** (`SUPER+CTRL+SHIFT+Space`, 22 themes). Unlike mine,
      it also themes the terminal, nvim, btop and Chromium.
- [ ] 🟡 **My ~40 palettes** (`conf/themes/*.lua`): convert the ones I
      actually use to `~/.config/omarchy/themes/<name>/colors.toml`.
- [ ] 🟡 **Next/previous theme** (`SUPER+F6`): not in Omarchy. It's a
      small bind on `omarchy theme set`.
- [ ] 🟡 **GTK colour file** for my GTK scripts (`conf/gtk_colors.lua`): use
      a `~/.config/omarchy/themed/*.tpl` template if any GTK script survives.
- [ ] ❌ **Daily Bing wallpaper** with title, description and a "what's this"
      popup: Omarchy has per-theme backgrounds and no timed rotation. Port
      `bing-wallpaper.sh` + the systemd timer, and have it drop the image
      where Omarchy's background picker looks
      (`~/.config/omarchy/backgrounds/<theme>/`), then select it. The popup
      would need a plugin; maybe settle for a notification.

## 10. Capture

- [ ] ✅ **Screenshots** of a region, window or screen, with freeze and
      clipboard, are built in: `Print`, capture menu `SUPER+CTRL+C`.
- [ ] ✅ **Screen recording** is built in: `ALT+Print`.
- [ ] ✅ **Color picker and OCR** are new: `SUPER+Print`, `SUPER+CTRL+Print`.
- [ ] 🟡 **My capture panel** (`scripts/capture.py`): probably drop it in
      favour of Omarchy's menu.

## 11. Input, monitors, apps

- [ ] 🟡 **Keyboard:** Omarchy makes Caps Lock the Compose key and both-Shifts
      the Caps Lock. Decide whether to keep that. Repeat 40/250 is set.
- [ ] 🟡 **3-finger horizontal swipe for workspaces:** off in Omarchy.
      Uncomment `hl.gesture` in `input.lua`.
- [ ] ✅ **fcitx5 IME** runs by default. Add Mozc and check its config tool.
- [ ] 🟡 **Monitors:** Omarchy assumes HiDPI (`GDK_SCALE=2`). Set scale 1
      where it's wrong (and in the VM).
- [ ] ❌ **Save and switch monitor arrangements** (`TODO.md`'s hyprmoncfg):
      nothing built in; the manual points to the `hyprmon` TUI.
- [ ] 🟡 **Terminal:** Foot is the default. Install Ghostty from Install >
      Terminal and set it in Setup > Defaults.
- [ ] 🟡 **Browser:** Chromium is the default. Install Chrome and run
      `omarchy default browser`.
- [ ] ✅ **Nautilus.**
- [ ] ✅ **Nvim:** Omarchy ships LazyVim, and my `.config/nvim` is LazyVim too.
      Keep mine, just stow over it.
- [ ] 🟡 **tmux:** Omarchy ships a tmux config (prefix `Ctrl+Space`). Mine
      wins once stowed.
- [ ] ✅ **Herdr** is shipped, and I already have `.config/herdr`.
- [ ] 🟡 **Webapps:** remove the preinstalled ones I don't want (Remove >
      Preinstalls) and `omarchy_preinstalled_bindings = false` if their binds
      get in the way.

## 12. Leftovers from `.config/hypr/TODO.md`

- [ ] Bind to create a new hidden workspace directly (if hidden workspaces
      get ported).
- [ ] TeamSpeak: window rule for the right side and the comms workspace.
- [ ] Pause background games to free the GPU (wl freeze).
- [ ] Monitor arrangement profiles (see §11).
- [ ] `enforce_permissions` snippet: only if still wanted.
