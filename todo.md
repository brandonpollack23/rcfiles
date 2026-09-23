# rewrite todo: rcfiles on Omarchy

Goal: move this machine to Omarchy 4 (Arch + Hyprland) and restart the rcfiles
from scratch, without losing anything or re-downloading Steam. §§0-5 are the
move itself; §§6-19 are everything to set up once it boots, checked against
**Omarchy 4.0.4 "Quattro"** (Sep 2026): repo `github.com/omacom/omarchy`,
manual at omarchy.org/manual.

In §§6-19, where a feature of my old `.config/hypr` + waybar setup is concerned:

- ✅ Omarchy does it: learn its version and drop mine
- 🟡 partly: needs a setting or a small port
- ❌ no answer: port mine or go without

## 0. Things to know before starting

- **Omarchy 4 installs from its ISO only.** It either wipes a whole disk
  (btrfs + LUKS + Limine) or uses unallocated free space. v4 no longer has a
  supported "install on top of existing Arch" script.
- **Disks today:**
  - `nvme0n1` (Sabrent 1.9T): one ext4 partition holds `/` and `/home`, 1.3T
    used. Steam is ~1T of that (963G of games) and `~/src` is 25G.
  - `sda` (Samsung 870 QVO 1T, NTFS "Emotion_Chip_Sep2020"): not mounted.
  - `sdb` (SanDisk 960G, NTFS "Memory Alpha"): 635G free.
- **Plan: install Omarchy onto `sda` and leave the NVMe alone.** The old install
  stays bootable from the firmware boot menu as a fallback. Omarchy mounts the
  old partition, and Steam uses the games where they already are, so nothing
  gets copied or re-downloaded. Once I'm happy, the NVMe becomes a games/data
  drive (or I reinstall onto it later).
- **Omarchy ships bash, not zsh, and yay, not paru.** It blocks a plain
  `pacman -Syu`; update with `omarchy update`.
- **Omarchy 4's Hyprland config is Lua (Hyprland 0.56), and so is mine.** My
  `conf/*.lua` modules use the same `hl.*` API, so most of them port by copying
  them into `~/.config/hypr/` and `require`-ing them from `hyprland.lua`.
- **Waybar, swaync, swayosd, hyprlock, hypridle, walker and mako are all gone.**
  One Quickshell process (`omarchy-shell`) draws the bar, menus, notifications,
  OSD and lock screen. That means **brpol-waybard, the l1p0-menu popups and the
  swaync config have nowhere to plug in**. Anything they do has to become an
  Omarchy shell plugin (QML, in `~/.config/omarchy/plugins/`) or be dropped.
- **Where settings go:**
  - `~/.config/hypr/{hyprland,bindings,monitors,input,looknfeel,autostart}.lua`
  - `~/.config/omarchy/shell.json` for the bar and idle. It is used instead of
    the defaults, not merged with them.
  - `~/.config/omarchy/themes/`, `~/.config/omarchy/plugins/`
  - `~/.config/omarchy/hooks/<event>.d/`
  - `~/.config/omarchy/extensions/omarchy-menu.jsonc`
  - `~/.config/uwsm/env.d/` for session environment variables
  - `~/.bashrc` for shell aliases and exports (see §18 — I use zsh)
  - Never edit `/usr/share/omarchy`: pacman overwrites it.
  - The full list is at omarchy.org/manual/dotfiles, which also says outright
    that stow is the right way to keep all of this. §1 has the packages.
- **Omarchy rewrites those files on its own.** Update > Config,
  `omarchy reinstall configs` and a full `omarchy reinstall` restore the
  defaults and keep my version as `.bak`. Part of §1 is surviving that.
- **Hyprland plugins (hyprpm):** Omarchy never mentions them. That doesn't mean
  they can't work, but it's untested, so try them in the VM.

## 1. Rework rcfiles (on the current machine)

- [x] Put every config file in stow packages (one dir per program: `zsh/`,
      `nvim/`, `tmux/`, `ghostty/`, `jj/`, `git/`, `hypr/`…), so
      `stow -t ~ <pkg>` links it. Drop the linking in
      `scripts/installer/src/links.ab`.
- [x] reorganize packages to install into categories that will be asked on
      install. eg steam is for gaming, servers wont need it. so there should be
      core, mac only, gaming, etc. if we can we should try to not have the
      brewfile and derive from a single source of truth.
- [ ] Hyprland bankruptcy: `.config/hypr`, waybar, swaync, swayosd, l1p0-menu,
      hyprlock/hypridle stay on this branch for reference only. The new `hypr/`
      stow package holds only the Omarchy override files (`bindings.lua`,
      `looknfeel.lua`, `input.lua`, `monitors.lua`, `autostart.lua`) plus the
      modules ported in §§7-19.
- [ ] Installer that installs every package I always want (AUR included):
  - [ ] Add an "Omarchy" platform next to Arch/Manjaro/Debian. It uses `yay`
        (or `omarchy pkg add` / `omarchy pkg drop`), skips everything Omarchy
        already ships, and runs the Omarchy menu installers where they exist
        (Steam, dev envs, Ghostty, Chrome).
  - [ ] Go through `pacman -Qqe` / `pacman -Qqm` on this machine (387 + 71
        packages) and move the ones I still want into `packages.toml`.
  - [ ] Decide what to drop from `packages.toml`'s `core`, which Omarchy
        already ships: fzf, zoxide, ripgrep, eza, fd, bat, tldr, yt-dlp,
        lazygit, lazydocker, btop, fastfetch, neovim, docker + compose, gh,
        mise, tmux. `deps` skips what's installed, so this is about not
        fighting them rather than about install time.
- [ ] Make sure the Mac still works (packages.toml, stow on macOS,
      `mise run deps -n` there).
- [ ] zsh: redo in `dotfiles/zsh/.zshrc` whatever Omarchy's bash sets up for
      me. The list of what that is, and what collides, is in §18.

### Stow packages for the Omarchy files

The manual's dotfiles page says which files under `~/.config` are *mine* rather
than Omarchy's. Each of these wants to be a stow package here, so the whole
desktop comes back with `mise run stow`. Most can only be filled in once I've
configured them in the VM (§3), but the layout can be decided now.

- [ ] **`dotfiles/hypr/`** → `~/.config/hypr/`
  - `hyprland.lua` (the one that `require`s the rest), `bindings.lua`,
    `monitors.lua`, `input.lua`, `looknfeel.lua`, `autostart.lua`
  - plus whatever `conf/*.lua` modules survive §§7-10.
- [ ] **`dotfiles/omarchy/`** → `~/.config/omarchy/`
  - `shell.json` (bar, widgets, screensaver, idle; replaces the defaults
    wholesale rather than merging)
  - `extensions/omarchy-menu.jsonc` (my menu entries, §12)
  - `hooks/<event>.d/*` (executables Omarchy runs on system events)
  - `themes/<name>/` for the palettes I port (§15), and `themed/*.tpl` for
    templating my own app configs from the active theme
  - `branding/screensaver.txt` and `branding/about.txt` (`omarchy ascii` /
    `omarchy transcode ascii` generate them)
  - `plugins/<id>/` if I write a QML shell plugin (§11): `manifest.json` plus
    its QML files
  - **not** `backgrounds/<theme>/`: images, and the Bing wallpaper writes there
    (§15). Keep it out of the repo.
  - **not** `~/.local/state/omarchy/`: runtime state (toggles, workspace
    layouts), not config.
- [ ] **Other single files that are mine:** `~/.config/hypr/hyprsunset.conf`
      (night light profile, §11) and `~/.config/voxtype/config.toml`
      (dictation, §18) — both only once I've actually set them up.
- [ ] **`dotfiles/uwsm/`** → `~/.config/uwsm/env.d/`: session environment
      variables, which is where `OMARCHY_SCREENSHOT_DIR` and
      `OMARCHY_SCREENRECORD_DIR` belong (create the directories first; takes a
      relogin).
- [ ] **`~/.XCompose`**: the manual lists it as mine (emoji/text autocomplete).
      Its own small package, since it isn't Omarchy-specific — but it must
      keep Omarchy's `include` line, see the table below.
- [ ] **`~/.config/starship.toml`** is already the `starship` package, and
      Omarchy uses starship too, so nothing to do beyond stowing over theirs.
- [ ] **`~/.bashrc`** is Omarchy's shell customization point. Going to zsh, so
      either leave it alone or keep a two-line one that hands over to zsh.
- [ ] Update `README.md`'s package list once these exist.

### Where Omarchy and stow collide

Checked by stowing the packages (with the new ones stubbed out) into a fake
`$HOME` shaped like a fresh Omarchy install. Two different failure modes, and
they want opposite fixes:

- **A file Omarchy wrote is in the way.** Stow refuses and names it;
  `mise run stow` then offers replace / adopt / skip. Loud and safe.
- **A directory of mine is linked whole.** Stow links the *highest* directory
  it can, so if `~/.config/foo` doesn't exist yet it becomes one symlink into
  the repo — and everything Omarchy writes there afterwards lands in my repo,
  silently. `ensure_shared_dirs()` in `scripts/lib/stow.ab` exists to
  pre-create those parents as real directories; every path both sides write to
  needs to be in it.

| target | verdict |
| --- | --- |
| `~/.claude/skills` | **No conflict, nothing to do.** Omarchy symlinks its skill in, but my `claude` package only holds `settings.shared.json` and `agents/`, and `.claude` is already in `ensure_shared_dirs()`, so stow links those two *individually* and Omarchy's `skills/` sits beside them. It would only break if I added `dotfiles/claude/.claude/skills/` — then stow links `skills` whole and Omarchy writes into the repo. Don't, or add `.claude/skills` to `ensure_shared_dirs()` first. |
| `~/.local/bin` | **No conflict.** Already in `ensure_shared_dirs()`, so Omarchy's lazy agent stubs (`claude`, `codex`, …) sit next to my linked `hacker-news.sh`. |
| `~/.bashrc`, `~/.config/btop`, `~/.config/herdr` | **No conflict:** Omarchy owns them and I don't package them. Only becomes one if I ever add a package for them. |
| `~/.config/hypr/*.lua` | **Expected conflict, adopt it.** Omarchy writes all six files, so stow stops on each. Answer `[a]dopt` so Omarchy's defaults become the repo's baseline, then `jj diff` and edit down to my overrides. |
| `~/.config/omarchy/shell.json` | Same: **adopt**, since I want their default bar as the starting point (and it is used instead of the defaults, not merged). |
| `~/.config/starship.toml` | **Expected conflict, replace.** Omarchy ships its own; mine is the one I want. `[r]eplace` puts theirs in `~/.local/state/rcfiles/backup/<stamp>/`. |
| `~/.config/nvim` | **Probably no conflict.** Omarchy's repo has no `config/nvim`, so nothing is copied into `~/.config/nvim` at install — `omarchy-nvim` is its own package. Check on the VM whether the directory exists before stowing: if it doesn't, mine is linked whole and that's fine; if it does, `[r]eplace`. Mine is LazyVim too, so nothing is lost either way. |
| `~/.config/omarchy/` subdirs | **Silent-leak risk → fix `ensure_shared_dirs()`.** Omarchy writes `themes/`, `plugins/` and `backgrounds/` in here (the active-theme pointer is `~/.local/state/omarchy/current`, so that one is out of the way). With the parents pre-created, only the things I fully own get directory links (`themes/<mine>`, `plugins/<mine>`, `hooks/<event>.d`) and Omarchy's are siblings — which is what I want. |
| `~/.config/uwsm/env.d` | Same treatment: pre-create it, so my env file is a file link. |
| `~/.config/git/config` | **No conflict, and theirs is inert.** Omarchy ships aliases (`co`/`br`/`ci`/`st`) and `pull.rebase`, `push.autoSetupRemote`, `diff.algorithm=histogram`, `rerere.enabled` there — but git **ignores `$XDG_CONFIG_HOME/git/config` entirely when `~/.gitconfig` exists** (tested), and mine is stowed. So none of it applies. If I want `rerere` and the histogram diff, copy them into my `.gitconfig`. |
| `~/.gitconfig` | **Expected conflict, replace.** `install/user/git.sh` runs `git config --global user.name/email` during install, so the file is there before I stow. Afterwards any `git config --global` writes *through* the symlink into the repo — that's the existing design, and `~/.gitconfig.local` is the escape hatch for machine-specific bits. |
| `~/.XCompose` | **Expected conflict, and don't just replace.** `install/user/xcompose.sh` writes it with `include "/usr/share/omarchy/default/xcompose"` plus `<Multi_key><space>n/e` macros for my name and email. That include *is* Omarchy's emoji compose access, so **my version has to keep it** or `SUPER+CTRL+E`-adjacent compose stops working. Adopt theirs first, then add my own lines under it. |
| `~/.config/ghostty/config` | **Expected conflict, replace — then add one line.** See §6; this is the one that fails silently. |

- [ ] Add these to `ensure_shared_dirs()`: `.config/hypr`, `.config/omarchy`,
      `.config/omarchy/themes`, `.config/omarchy/plugins`,
      `.config/omarchy/hooks`, `.config/omarchy/extensions`,
      `.config/omarchy/branding`, `.config/omarchy/themed`,
      `.config/uwsm/env.d`. Verified: with them, every one of those becomes a
      file link instead of a whole-directory link.
- [ ] Check on the real thing whether Omarchy pre-creates each
      `hooks/<event>.d/` (the manual says each ships a `.sample`). If it does,
      nothing more to do; if not, add the event dirs too, or my `hooks/` link
      swallows their samples.
- [ ] ⚠️ **Omarchy rewrites the files it owns.** `omarchy update`,
      Update > Config and `omarchy reinstall configs` restore the defaults and
      leave my version as `.bak`. Find out in the VM what that does to a stow
      symlink — replaces it (my repo file survives, the link is gone) or writes
      through it (my repo file is overwritten, which `jj diff` would at least
      show me). Either way the fix is a `post-update` hook (§18) that runs
      `mise run stow`; the difference decides whether I also need to commit
      before updating.

## 2. Back up what isn't in git (on the current machine)

Nothing on the NVMe gets touched by the plan, but back these up anyway (to
Memory Alpha, and the keys also to a password manager):

- [ ] Keys: `~/.ssh`, `~/.gnupg`, `~/.config/sops/age/keys.txt` (without it
      `secrets.sops.env` can't be decrypted; the master password also works
      through `sops-bootstrap`).
- [ ] Push every repo in `~/src`: find anything with uncommitted, unpushed or
      jj-only work before it lives only on an old disk.
- [ ] `~/.claude` (settings, memory), `~/Documents`, `~/Videos`, `~/Pictures`,
      `~/Android`, game saves outside Steam Cloud (`steamapps/compatdata` 8.4G,
      `~/.local/share/Larian Studios`, lutris, bottles).
- [ ] Note the services I run so I can re-enable them:
  - user: syncthing, timewsync timer, livebook, ydotool
  - system: docker, ollama, tailscaled, piavpn, sshd, nix-daemon (Determinate
    Nix), waydroid, the Google Drive mount unit
- [ ] Copy `/etc/fstab` and the `mnt-google_drive-*.mount` unit for reference.
- [ ] Look through libvirt VMs, docker volumes and ollama models, and keep the
      ones worth keeping.

## 3. Try Omarchy in a VM

- [ ] Get the Omarchy 4 ISO (omarchy.org).
- [ ] Create a virt-manager/QEMU VM: UEFI (OVMF, no Secure Boot), q35, host CPU,
      8G+ RAM, 60G disk, Virtio video **with 3D acceleration** (Spice, OpenGL
      on). Hyprland crashes at login without GL. Fallback:
      `hl.env("LIBGL_ALWAYS_SOFTWARE", "1")` in `hyprland.lua`.
- [ ] Set the scale to 1 in `~/.config/hypr/monitors.lua` (§17; Omarchy assumes
      HiDPI).
- [ ] Use it plain for a day to learn their keys (`SUPER+K`) before changing
      anything.
- [ ] Clone rcfiles, run the new installer and stow the configs. Stow will stop
      on the files Omarchy already wrote — §1's table says which, and whether
      to adopt or replace each. Confirm the real conflict list matches it.
- [ ] Work through §§6-19 in order: terminal and shell, then bindings, then
      layouts, then the rest. Commit as I go.
- [ ] Test the hyprpm plugins (Hyprspace fork, hyprfocus) and hypr-persist.
- [ ] Destroy the VM and install fresh from rcfiles once more, to prove it works
      from zero.

## 4. Install on the real machine

- [ ] Check what's on `sda` ("Emotion_Chip"). Move anything worth keeping to
      Memory Alpha, since the install wipes it.
- [ ] Turn Secure Boot off in firmware (Omarchy requires it off). Note: the
      disk-encryption password can't be typed on a Bluetooth keyboard at boot.
- [ ] Boot the ISO and do a full-disk install onto **sda: the 931.5G Samsung 870
      QVO, not the 1.9T Sabrent.** Check size and model twice. Unplug the NVMe
      if that's easy.
- [ ] Check that the old Arch install still boots from the firmware boot menu
      (and `limine-scan` if I want it in Limine's menu).
- [ ] NVIDIA (RTX 4080): the installer should pick `nvidia-open-dkms`. Check
      Hyprland, a game and suspend/resume.
- [ ] Clone rcfiles, run the installer, stow.

## 5. Bring the data across (no re-downloads)

- [ ] Mount the old NVMe partition read-write with an fstab line:
      `UUID=f99f8c9a-c34c-4f80-8d75-7864b8c4860b /mnt/old ext4 defaults,nofail 0 2`.
      My user should get uid 1000 again, so the file ownership matches.
- [ ] Add Memory Alpha to fstab too (see the old fstab line).
- [ ] Steam, keeping the games on the NVMe:
  1. Install Steam (Install > Gaming > Steam) and log in.
  2. Steam > Settings > Storage > add a library at `/mnt/old/SteamLibrary`
     (Steam creates `steamapps/` in it).
  3. Close Steam. Move the games into it (same filesystem, so this is instant):
     `mv /mnt/old/home/brpol/.local/share/Steam/steamapps/{common,workshop,compatdata,appmanifest_*.acf} /mnt/old/SteamLibrary/steamapps/`
     Skip `shadercache`; it rebuilds.
  4. Start Steam. The games should show as installed; if one wants to download,
     "Verify integrity" and it only fetches the differences. Try it with one
     small game first.
  - This breaks Steam on the old install. That's fine at this point; moving the
    files back undoes it.
- [ ] `~/src`: `rsync -a /mnt/old/home/brpol/src/ ~/src/` (25G, local and fast).
      Recreate the mise, uv and pnpm caches rather than copying them.
- [ ] Re-enable the services from §2, restore the keys, and log in to Chrome,
      Tailscale, PIA and syncthing.

## 6. First hour: shell, terminal, defaults

Before touching Hyprland at all, get the terminal and shell I actually type in.

- [ ] **Ghostty as the default terminal.** Omarchy ships foot. Install Ghostty
      (Install > Terminal > Ghostty, or `packages.toml`'s `desktop` group) and
      make it the default in Setup > Defaults > Terminal, so `SUPER+Return` and
      every "open in terminal" action use it. (`omarchy default browser` and
      `omarchy default agent` exist, so try `omarchy default terminal ghostty`
      first; the manual only documents the menu.) Then stow the `ghostty`
      package and check `~/.config/ghostty/config` wins.
- [ ] ⚠️ **Add the theme hook to my ghostty config**, or the theme picker
      silently skips the terminal. Omarchy's own ghostty config themes itself
      with one line and nothing else:
      `config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"`
      (the `?` makes it optional). Mine has no such line, and it hard-codes
      `theme = Dark Modern`, so `omarchy theme set` would change everything
      *but* my terminal. Put that line in
      `dotfiles/ghostty/.config/ghostty/config` and drop the `theme =` line —
      or keep `theme =` and accept that ghostty stays on my colours. Worth
      diffing the rest of their config too: they set
      `shell-integration-features = no-cursor,ssh-env` where I set
      `ssh-terminfo`, plus `async-backend = epoll` as a Hyprland speed fix.
- [ ] **Drop the foot config** from the manual's list: I don't use it, so no
      `foot/` stow package. Leave Omarchy's `~/.config/foot/foot.ini` alone in
      case something falls back to it.
- [ ] **zsh:** `chsh -s /usr/bin/zsh`, then work through §18's shell list for
      what Omarchy's bash was doing for me.
- [ ] **tmux splits.** ⚠️ Omarchy ships its own tmux config with prefix
      `Ctrl+Space`; the Hotkeys page points at `~/.config/tmux/tmux.conf`,
      which tmux sources *after* my `~/.tmux.conf`, so theirs would win on
      everything we both set. First `tmux display -p '#{config_files}'` to see
      what actually loads, then either empty theirs or move my package to that
      path. Then check: `tmux show -g prefix` says `C-a`, and
      `tmux list-keys | grep split` has `|` → `split-window -h` and `-` →
      `split-window -v`, both with `-c "#{pane_current_path}"`. `SUPER+ALT+K`
      shows Omarchy's tmux cheatsheet, which will be wrong for my binds.
- [ ] **tmux plugins:** `mise run plugins` (tpm) and `prefix + I` once, so
      resurrect/continuum/dracula are there before I start living in it.
- [ ] **Browser:** install Chrome and `omarchy default browser`.
- [ ] **Font:** default is JetBrainsMono Nerd Font; my Consolas Nerd Font comes
      from `mise run fonts`. Pick it in Style > Font if I want it everywhere
      (there's no config file for this, it's menu-only).

## 7. Keybindings (do this before the rest of Hyprland)

- [ ] Decide: `omarchy_default_bindings = false` and port my `keymaps.lua`, or
      keep Omarchy's and `hl.unbind` the ones that clash. **Recommended: keep
      Omarchy's defaults and unbind the clashes.** You keep their app, capture
      and panel binds, and `SUPER+K` still lists everything as long as I bind
      with `o.bind(keys, description, cmd)`. The documented shape is
      `hl.unbind("SUPER + SHIFT + O")` followed by my own `o.bind(...)`, both
      in `bindings.lua`.
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

## 8. Layouts

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

## 9. Windows and groups

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

## 10. Workspaces

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
      along (§14).

## 11. Bar (the biggest gap)

- [ ] ❌ **Per-window taskbar** with group tabs and a lock icon, click to focus
      (brpol-waybard). Omarchy has no window list, only
      `omarchy.active-window` (the focused title). Decide: write an Omarchy
      shell plugin (QML, §18), look at omarchyplugins.com, or live without it.
- [ ] 🟡 **Workspace buttons with names and hidden-workspace buttons:**
      Omarchy's bar shows numbers 1-5 plus any others in use. Names and hidden
      buttons need a plugin.
- [ ] ✅ **Weather** is built in (no OpenWeatherMap key, so the sops secret
      for it can go).
- [ ] ✅ **Audio, network, Bluetooth, calendar, display/brightness and power
      panels** are built in (`SUPER+CTRL+A/W/B/D/P`) and replace l1p0-menus.
- [ ] ✅ **Tailscale widget** is built in (optional).
- [ ] 🟡 **Night light button:** hyprsunset with a toggle (`SUPER+CTRL+N`);
      no bar widget, but schedules go in `~/.config/hypr/hyprsunset.conf`
      (`profile { time = 20:00, temperature = 4000 }`) with
      `o.launch_on_start("hyprsunset")` in `autostart.lua`.
- [ ] 🟡 **Recording indicator:** Omarchy records with gpu-screen-recorder.
      Check whether the bar shows a timer or stop button.
- [ ] ❌ **PIA VPN widget:** a plugin, or use Tailscale plus the PIA app's own
      tray icon.
- [ ] ❌ **KDE Connect phone widget:** a plugin, or drop it (install
      `kdeconnect` either way; it has a tray icon).
- [ ] ❌ **Bing logo button and popup:** see §15.
- [ ] 🟡 **Submap indicator:** only needed if my submaps come along.

## 12. Launcher, menus, notifications, OSD

- [ ] ✅ **App launcher** is built in: `SUPER+Space`.
- [ ] ✅ **Keybind search** is built in: `SUPER+K`.
- [ ] ✅ **Emoji picker** is built in: `SUPER+CTRL+E`, which replaces rofimoji
      and the ydotool paste hack.
- [ ] ✅ **Clipboard history** is new for me: `SUPER+CTRL+V`. Copy/cut/paste
      are system-wide on `SUPER+C/X/V`, terminal included.
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
      standalone user service, or as an Omarchy hook (§18), if I still want it.

## 13. Lock, idle, power

- [ ] 🟡 **Lock screen:** Omarchy's own (`SUPER+CTRL+L`). My hyprlock extras
      are probably ❌: themed colours, weather, the NVIDIA "restart after
      driver update" hint, the greeting and uptime footer. Check what their
      LockView shows.
- [ ] 🟡 **Idle:** mine dims at 9.5 min, locks at 10, screens off at 10.5, and
      turns screens off 60 s into any lock. Omarchy has only
      `"idle": { "screensaver": 150, "lock": 300 }` in `shell.json` (seconds).
      Check whether dim and DPMS-off exist at all, or if `omarchy toggle idle`
      plus a hook is the closest I get. Toggle state lives in
      `~/.local/state/omarchy/toggles/` — state, not config.
- [ ] ✅ **Lock before sleep**: check it on real hardware.
- [ ] ✅ **Fingerprint / FIDO2** (Setup > Security): not needed on the desktop.
- [ ] 🟡 **Keyboard focus comes back after unlock** (`conf/wm/focus.lua` works
      around a Hyprland bug): see whether it still happens under Omarchy's lock.
- [ ] ✅ **Stay-awake toggle** is new: `SUPER+CTRL+I`.
- [ ] 🟡 **Power profiles:** `omarchy powerprofiles set autodetect performance`
      on the desktop; skip hibernation (`omarchy hibernation setup` wants a
      RAM-sized `/swap` subvolume).

## 14. Session restore

- [ ] ❌ **Restore last session's windows at login** (hypr-persist + my
      named-workspace shim): Omarchy has none. Try the `hypr-persist` AUR
      package on Omarchy, or drop it and lean on tmux/Herdr sessions.

## 15. Theme and wallpaper

- [ ] ✅ **Theme picker** (`SUPER+CTRL+SHIFT+Space`, 22 themes). Unlike mine,
      it also themes the terminal, nvim, btop and Chromium (Obsidian needs the
      `Omarchy` theme picked by hand).
- [ ] ⚠️ **How that reaches an app matters for every config I stow.** Omarchy
      points `~/.local/state/omarchy/current/theme` at the active theme dir and
      each app's *own* config includes the file it needs from there
      (`ghostty.conf`, `btop.theme`, …). So a stowed config only follows the
      theme if I put that include in it — ghostty is the one that bites (§6),
      and the same applies to anything else I package later.
- [ ] 🟡 **My ~40 palettes** (`conf/themes/*.lua`): convert the ones I
      actually use to `~/.config/omarchy/themes/<name>/colors.toml`. Copy a
      stock theme from `/usr/share/omarchy/themes/` as the skeleton — a theme
      dir also holds `shell.toml`, `hyprland.lua`, `ghostty.conf`,
      `btop.theme`, `chromium.theme`, `icons.theme`, `unlock.png` and friends,
      most of them generated from `colors.toml`. `light.mode` (empty file) or
      `mode = "light"` marks a light theme. `omarchy theme install <git-url>`
      installs one from a repo, so my themes could live in their own repo.
- [ ] 🟡 **Next/previous theme** (`SUPER+F6`): not in Omarchy. It's a
      small bind on `omarchy theme set`.
- [ ] 🟡 **GTK colour file** for my GTK scripts (`conf/gtk_colors.lua`): use
      a `~/.config/omarchy/themed/*.tpl` template if any GTK script survives.
- [ ] ❌ **Daily Bing wallpaper** with title, description and a "what's this"
      popup: Omarchy has per-theme backgrounds (`SUPER+CTRL+Space` cycles them)
      and no timed rotation. Port `bing-wallpaper.sh` + the systemd timer, and
      have it drop the image where Omarchy's background picker looks
      (`~/.config/omarchy/backgrounds/<theme>/`), then select it. The popup
      would need a plugin; maybe settle for a notification.

## 16. Capture

- [ ] ✅ **Screenshots** of a region, window or screen, with freeze and
      clipboard, are built in: `Print`, capture menu `SUPER+CTRL+C`.
- [ ] ✅ **Screen recording** is built in: `ALT+Print`.
- [ ] ✅ **Color picker and OCR** are new: `SUPER+Print`, `SUPER+CTRL+Print`.
- [ ] 🟡 **My capture panel** (`scripts/capture.py`): probably drop it in
      favour of Omarchy's menu.
- [ ] 🟡 **Where files land** is env vars, not config: see §18.

## 17. Input, monitors, apps

- [ ] 🟡 **Keyboard:** Omarchy makes Caps Lock the Compose key and both-Shifts
      the Caps Lock (`kb_options = "compose:caps,shift:both_capslock_cancel"`).
      Decide whether to keep that. Repeat 40/250 is set.
- [ ] 🟡 **3-finger horizontal swipe for workspaces:** off in Omarchy.
      Uncomment `hl.gesture` in `input.lua`.
- [ ] ✅ **fcitx5 IME** runs by default. Add Mozc (`omarchy pkg add
      fcitx5-mozc`) and check its config tool.
- [ ] 🟡 **Monitors:** `monitors.lua` starts with
      `local omarchy_gdk_scale = 2` and `local omarchy_monitor_scale = 1.6`;
      both go to `1` for my 1440p/1080p screens (and in the VM). Per-output
      settings are `hl.monitor({ output = "DP-2", ... })`, and
      `omarchy display text size 14` changes text size without rescaling.
      `SUPER+/` and `SUPER+ALT+/` step the scale live.
- [ ] ❌ **Save and switch monitor arrangements** (`TODO.md`'s hyprmoncfg):
      nothing built in — the manual has no profile feature, just `hl.monitor`
      entries and ad-hoc extend/mirror from Trigger > Hardware. The `hyprmon`
      TUI is still the fallback.
- [ ] 🟡 **Terminal, browser and tmux:** see §6. tmux does *not* just work
      once stowed.
- [ ] ✅ **Nautilus.**
- [ ] ✅ **Nvim:** Omarchy ships LazyVim, and my `.config/nvim` is LazyVim too.
      Keep mine, just stow over it.
- [ ] ✅ **Herdr** is shipped, and I already have `.config/herdr`. Omarchy
      gives it the same `Ctrl+Space` prefix as its tmux, so the same conflict
      may apply (`SUPER+CTRL+K` is its cheatsheet).
- [ ] 🟡 **Webapps:** remove the preinstalled ones I don't want (Remove >
      Preinstalls) and `omarchy_preinstalled_bindings = false` if their binds
      get in the way. Adding one is menu-only (Install > Web App); their binds
      live in `bindings.lua`.

## 18. Rest of the manual: one-time setup and things I didn't know about

A sweep of omarchy.org/manual for everything the sections above don't cover.

### Shell (the big one, since I'm leaving bash)

- [ ] ⚠️ **zsh is nowhere in the manual.** Every ergonomic Omarchy ships lives
      in `~/.bashrc` ("add aliases, functions and exports there; it is not
      overwritten on updates"). Going to zsh throws all of it away, so read
      `/usr/share/omarchy/default/bash/*` once and port what I want into
      `dotfiles/zsh/.zshrc` (§1):
  - `mup` = `omarchy update`, `d` = docker, `a`/`c`/`cx`/`cy` = agent CLIs
  - `ga [branch]` / `gd` — git worktree create/remove. **These collide with my
    `ga`/`gd` git aliases**; pick one meaning.
  - `ls` → eza, `cd` → zoxide, `ff` → fzf (I already do these my way)
  - an `ssh` wrapper that cleans up the terminal and reconnects dropped
    sessions — worth stealing
  - `tdl`/`tds`/`tdlm`/`tsl` tmux dev layouts (and `hdl`/`hds`/… for Herdr)
- [ ] **Docker is sudo-only on purpose** (my user isn't in the `docker` group).
      `omarchy-setup-security-sudoless-docker` if I want the old behaviour.

### AI and `~/.claude`

- [ ] ✅ **Omarchy symlinks its own skill into `~/.claude/skills`** (and
      `~/.codex/skills`, `~/.agents/skills`, …). Checked: this does *not*
      collide with my `claude` package — §1's table says why, and what would
      break it later.
- [ ] Agent CLIs are lazy mise stubs in `~/.local/bin` (`claude`, `codex`,
      `opencode`, `agy`, `copilot`, …), installed on first run. So drop any of
      those I install myself, and mind that `~/.local/bin` is also a stow
      target. `omarchy default agent <name>`, `omarchy agent prompt "<task>"`.
- [ ] Crash capture hands coredumps to the agent (`omarchy agent crash <pid>`);
      `omarchy toggle crash-capture` / `omarchy crash mute <program>` to stop it.

### Bar, plugins and menus (follow-up to §11)

- [ ] `shell.json` layout is `{ "version": 1, "bar": { "position", "transparent",
      "centerAnchor", "layout": { "left": [], "center": [], "right": [] } },
      "idle": { "screensaver": 150, "lock": 300 } }` (idle in seconds; widget
      settings sit directly on the widget object). Once I own the file,
      **future Omarchy widgets are not merged in** — re-diff it after big
      updates. `omarchy bar set/move/position/defaults` edits it from the CLI.
- [ ] A waybar module becomes a **QML plugin** in `~/.config/omarchy/plugins/<id>/`:
      `manifest.json` (`schemaVersion`, `id`, `name`, `version`, `kinds`,
      `entryPoints`, `barWidget`) plus QML. Kinds: `bar-widget`, `panel`,
      `overlay`, `menu`, `service`, `bar`. `omarchy plugin clone <id> --edit`
      forks a first-party widget — the way to start brpol-waybard's replacement.
      Also `omarchy plugin add <git-url> --enable`, `list`, `validate <path>`.
- [ ] `omarchy menu summon <path>` / `toggle` / `close` script the menu, so my
      old menu scripts can drive Omarchy's UI instead of drawing their own.

### Hooks instead of systemd units

- [ ] `~/.config/omarchy/hooks/<event>.d/` runs every executable on an event:
      `post-boot`, `post-update`, `pre-refresh-pacman`, `theme-set` ($1=theme),
      `font-set` ($1=font), `battery-low` ($1=percentage). `omarchy hook install
      post-boot ~/my-hook`. Candidates: re-stow after an update (§1), the Bing
      wallpaper on `theme-set` (§15), hotplug sounds (§12).
- [ ] `o.launch_on_start("...")` in `autostart.lua` replaces some of my systemd
      user units — go through `dotfiles/systemd/` and decide which move.

### Capture, dictation, reminders

- [ ] Env vars go in `~/.config/uwsm/env.d/<file>` (§1):
      `OMARCHY_SCREENSHOT_DIR`, `OMARCHY_SCREENSHOT_EDITOR`,
      `OMARCHY_SCREENRECORD_DIR`, `OMARCHY_YTDLP_DIR`. Create the directories
      first; needs a relogin.
- [ ] **Dictation** is new: Install > AI > Dictation, then `voxtype setup model`
      (~150MB). Hold `F9` or `SUPER+CTRL+X`; config in
      `~/.config/voxtype/config.toml`.
- [ ] **Reminders** are new: `omarchy reminder 7 'Tea ready'`, `SUPER+CTRL+R`.
- [ ] **Notices** (`SUPER+CTRL+ALT+T/W/B`) replace glanceable bar modules. Set
      the weather once: `omarchy weather location --set Tokyo 35.68,139.69`.

### System

- [ ] **Firewall is on and denies inbound** except 53317 (LocalSend). Open what
      I need: Setup > Security > SSHD for sshd; Docker is locked down through
      ufw-docker, which will bite when I expose a container port.
- [ ] **`omarchy update` only.** `pacman -Syu`/`yay -Syu` are blocked. Channels
      (stable/RC/edge/dev) via `omarchy-channel-set`; stable runs a month behind
      Arch. `omarchy reinstall` resets *all* user config to defaults — the
      nuclear option, and a reason to keep §1's packages stowed and committed.
- [ ] **Snapshots cover `/` only**, not `/home`, so `omarchy-snapshot` is no
      substitute for this repo or for §2's backups.
- [ ] Diagnostics when something breaks: `omarchy debug`, `omarchy-debug`,
      `omarchy commands --all --json` for the real CLI inventory (the manual's
      list is truncated).

### Small stuff

- [ ] `omarchy-restart-xcompose` after editing `~/.XCompose`.
- [ ] Chromium-family browsers get Omarchy extensions (Copy URL `ALT+SHIFT+L`,
      Download Video `ALT+SHIFT+D`); Firefox/Zen get neither theming nor those.
- [ ] Branding: `~/.config/omarchy/branding/screensaver.txt` and `about.txt`,
      generated with `omarchy ascii "..."` or
      `omarchy transcode ascii ~/logo.svg ... --width 100`. Boot splash with
      `omarchy plymouth set '<bg>' '<fg>' logo.png`.
- [ ] Gaming: only Moonlight is preinstalled; Steam et al. come from
      Install > Gaming (§5). RetroArch wants `~/Games/bios` and `~/Games/roms`.
- [ ] Windows VM, if I ever want it: `~/Windows` (shared) and `~/.windows`
      (disk) — keep both out of the repo.

## 19. Leftovers from `.config/hypr/TODO.md`

- [ ] Bind to create a new hidden workspace directly (if hidden workspaces
      get ported).
- [ ] TeamSpeak: window rule for the right side and the comms workspace.
- [ ] Pause background games to free the GPU (wl freeze).
- [ ] Monitor arrangement profiles (see §17).
- [ ] `enforce_permissions` snippet: only if still wanted.

## 20. Settle in, then retire the old install

- [ ] Use it for a couple of weeks and keep §§6-19 up to date.
- [ ] When nothing has needed the old install for a while: back up anything
      left, reformat the NVMe (btrfs or ext4) as a games/data drive, and move
      `SteamLibrary` onto it the same way.
- [ ] Merge the rewrite branch, and update `README.md` and `AGENTS.md` for the
      stow + Omarchy layout.
