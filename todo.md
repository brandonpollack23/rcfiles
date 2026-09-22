# rewrite todo

Goal: move this machine to Omarchy 4 (Arch + Hyprland) and restart the rcfiles
from scratch, without losing anything or re-downloading Steam. The desktop
features to carry over are in `hyprland_todo.md`.

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
- **Omarchy ships bash, not zsh, and yay, not paru.** Its Hyprland config is Lua
  on 0.56, the same as mine. It blocks a plain `pacman -Syu`; update with
  `omarchy update`.

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
      modules ported from `hyprland_todo.md`.
- [ ] Installer that installs every package I always want (AUR included):
  - [ ] Add an "Omarchy" platform next to Arch/Manjaro/Debian. It uses `yay`,
        skips everything Omarchy already ships, and runs the Omarchy menu
        installers where they exist (Steam, dev envs, Ghostty, Chrome).
  - [ ] Go through `pacman -Qqe` / `pacman -Qqm` on this machine (387 + 71
        packages) and move the ones I still want into `packages.toml`.
- [ ] Make sure the Mac still works (packages.toml, stow on macOS,
      `mise run deps -n` there).
- [ ] zsh on Omarchy: `chsh` to zsh. Check what Omarchy's bash sets up
      (`/usr/share/omarchy/default/bash/*`: PATH, mise, starship, zoxide,
      aliases) and redo anything I want in `scripts/zshrc`.

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
- [ ] Set scale 1 in `~/.config/hypr/monitors.lua` (Omarchy assumes HiDPI).
- [ ] Use it plain for a day to learn their keys (`SUPER+K`) before changing
      anything.
- [ ] Clone rcfiles, run the new installer and stow the configs. Stow will trip
      over the files Omarchy already created in `~/.config/hypr` and
      `~/.config/nvim`: delete them first, or `stow --adopt` and then
      `git diff`.
- [ ] Work through `hyprland_todo.md` in order: bindings, then layouts, then the
      rest. Commit as I go.
- [ ] Test the hyprpm plugins (Hyprspace fork, hyprfocus) and hypr-persist.
- [ ] Destroy the VM and install fresh from rcfiles once more, to prove it works
      from zero.

## 4. Install on the real machine

- [ ] Check what's on `sda` ("Emotion_Chip"). Move anything worth keeping to
      Memory Alpha, since the install wipes it.
- [ ] Turn Secure Boot off in firmware (Omarchy requires it off).
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

## 6. Settle in, then retire the old install

- [ ] Use it for a couple of weeks and keep `hyprland_todo.md` up to date.
- [ ] When nothing has needed the old install for a while: back up anything
      left, reformat the NVMe (btrfs or ext4) as a games/data drive, and move
      `SteamLibrary` onto it the same way.
- [ ] Merge the rewrite branch, and update `README.md` and `CLAUDE.md` for the
      stow + Omarchy layout.
