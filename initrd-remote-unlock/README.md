# Unlock an encrypted Omarchy install over Tailscale SSH

Reboot your Omarchy machine from anywhere, then unlock the disk from any
device on your tailnet:

```console
$ ssh root@<hostname>-initrd
Passphrase for root (or "shell"):
Unlocked root; the boot is continuing and this session will close.
```

The machine joins your tailnet *before* the root filesystem is unlocked, and
the SSH login goes straight to a passphrase prompt. A correct passphrase
unlocks the disk and the boot continues. Unlocking at the keyboard keeps
working exactly as before.

This is written for **Omarchy on Arch** with its defaults: full-disk LUKS,
Limine with unified kernel images (UKIs), plymouth, and a busybox-based
initramfs using the `encrypt` hook. It also assumes a **wired** network
connection: nothing here brings up Wi-Fi before the disk is unlocked.

## Quick setup

A script does steps 1–6 below and skips anything already done. From a clone
of this repo:

```sh
mise run remote-unlock -n   # print what it would do
mise run remote-unlock
```

Without the repo's mise setup, run the compiled copy. It finds the hook files
in the directory it sits in:

```sh
bash initrd-remote-unlock/remote-unlock.sh -n
bash initrd-remote-unlock/remote-unlock.sh
```

Flags: `-n` (dry run), `-f` (rebuild the boot image even when nothing
changed), `--ip <value>` (the `ip=` parameter, default `:::::eth0:dhcp`;
see step 5). The script asks you to log in to Tailscale once, when it
registers the initramfs machine. The admin-console settings in step 2 are up
to you.

The script is `scripts/remote-unlock.ab` ([Amber](https://amber-lang.com));
`remote-unlock.sh` is compiled from it, and `mise run lint` checks the two
match.

---

## How booting works here, and what we change

On an Omarchy install with an encrypted disk, a boot goes roughly like this:

1. **UEFI firmware** starts **Limine**, the bootloader, from the unencrypted
   EFI partition (`/boot`).
2. Limine loads a **UKI** (unified kernel image), such as
   `/boot/EFI/Linux/omarchy_linux-omarchy.efi`. It's one signed file that
   holds three things:
   - the **kernel**,
   - the **initramfs**: a small, temporary root filesystem the kernel unpacks
     into RAM,
   - the **kernel command line** (`cryptdevice=…`, `root=…`, `quiet splash`,
     and so on).
3. The kernel runs `/init` from the initramfs. That's a busybox shell script,
   and it runs a series of **hooks** in order. Each hook is a small script
   that does one job: `udev` loads drivers, `plymouth` shows the splash
   screen, `encrypt` asks for the LUKS passphrase and opens the disk as
   `/dev/mapper/root`, and so on.
4. Once the disk is open, `/init` mounts the real root filesystem, and the
   hooks clean up after themselves. Then `/init` hands control to the real
   system (`switch_root`), where systemd takes over and you get your normal
   login.

Everything before step 4 happens with the real disk still locked, so anything
needed to reach the machine remotely has to be *inside the initramfs*.

**mkinitcpio** builds the initramfs. It reads the `HOOKS=(…)` list from
`/etc/mkinitcpio.conf` and then from the drop-in files in
`/etc/mkinitcpio.conf.d/`, sourced in alphabetical order, so a later file can
change what an earlier one set. For each hook in the list it runs that hook's
*build* script, which copies binaries and config files into the image. The
same hook's *runtime* script then runs at boot, in list order.

**`limine-update`** (from Omarchy's `limine-mkinitcpio-hook`) is how Omarchy
rebuilds all of this. It runs mkinitcpio, reads the kernel command line from
`/etc/default/limine`, bundles the kernel, initramfs and command line into the
UKI, and updates Limine's menu. On Omarchy, `mkinitcpio -P` does nothing,
because there are no presets in `/etc/mkinitcpio.d/`. Use `limine-update`.

What we add to the initramfs, in the order it runs, just before `encrypt`
prompts:

| Hook | From | What it does at boot |
|---|---|---|
| `netconf` | `mkinitcpio-extras` | Gets an IP address over DHCP, driven by the `ip=` kernel parameter |
| `remote-unlock` | this directory | Sets root's login shell in the initramfs to an unlock script |
| `tailscale` | `mkinitcpio-tailscale` | Starts `tailscaled` in the background, logged in as a separate machine with Tailscale SSH on |
| `encrypt` | stock | Waits on the passphrase prompt as usual |

When you SSH in, Tailscale SSH starts root's login shell. Here that's the
unlock script, which:
1. reads `cryptdevice=` from the kernel command line,
2. asks for your passphrase and opens the disk with `cryptsetup`,
3. stops the plymouth password prompt that `encrypt` is waiting on. `encrypt`
   then sees that `/dev/mapper/root` already exists and the boot carries on.

---

## 1. Install the packages

```sh
yay -S mkinitcpio-tailscale mkinitcpio-extras
```

- **`mkinitcpio-tailscale`** (AUR) provides the `tailscale` hook and
  `setup-initcpio-tailscale`. Source:
  <https://github.com/dangra/mkinitcpio-tailscale>
- **`mkinitcpio-extras`** provides the `netconf` hook. Stock mkinitcpio has
  nothing that brings up a network interface.

## 2. Register the initramfs as its own Tailscale machine

```sh
sudo setup-initcpio-tailscale
```

This runs a separate, temporary `tailscaled` and logs it in as a **new
machine** called `<hostname>-initrd`. It doesn't touch your system's normal
Tailscale machine. It saves that machine's key, its settings and SSH host
keys in `/etc/initcpio/tailscale/`. The `tailscale` hook copies those into
every image it builds.

> **Ignore the "next steps" it prints about `/etc/mkinitcpio.conf`.** On
> Omarchy, `/etc/mkinitcpio.conf.d/omarchy_hooks.conf` *replaces* `HOOKS=`
> outright, so a hook you add to `/etc/mkinitcpio.conf` is silently dropped.
> Also, Omarchy uses the busybox `encrypt` hook, not `sd-encrypt`, so there's
> no `sd-encrypt` to insert before, and `sd-network` won't work. Steps 4
> and 5 do the Omarchy equivalent.

Then, in the [Tailscale admin console](https://login.tailscale.com/admin/machines):
- **Disable key expiry** for `<hostname>-initrd`. Otherwise that machine's
  key eventually expires, and remote unlock silently stops working.
- Make sure your tailnet's **SSH policy** lets you log in as `root` on that
  machine. The default policy allows `root` in "check" mode, which means you
  re-authenticate in a browser.

Optional: in `/etc/initcpio/tailscale/default.env`, set `CLI="yes"` to put
the `tailscale` command in the image, so you can run `tailscale status` from
the debug shell. It makes the image noticeably bigger, so turn it off again
once everything works.

## 3. Install the `remote-unlock` hook

From this directory:

```sh
sudo install -Dm644 remote-unlock.install /etc/initcpio/install/remote-unlock
sudo install -Dm755 remote-unlock.login   /etc/initcpio/remote-unlock/login
```

mkinitcpio looks for hooks in `/etc/initcpio/` before `/usr/lib/initcpio/`,
so a hook you install yourself goes there.

- **`remote-unlock.install`** is the *build* script. It copies the unlock
  script into the image as `/usr/bin/remote-unlock` and writes the image's
  `/etc/passwd` with that as root's shell. This hook has to come before
  `tailscale`: the `tailscale` hook only writes its own `/etc/passwd`, with
  `/bin/sh` as root's shell, when the image has none yet.
- **`remote-unlock.login`** is the unlock script. Type `shell` at its
  passphrase prompt for a plain shell instead, for debugging.

No `login` or `su` is in the initramfs, so Tailscale SSH starts the shell
from `/etc/passwd` directly. That's why setting root's shell there is enough.

## 4. Add the hooks with a drop-in

```sh
sudo install -Dm644 zz_tailscale.conf /etc/mkinitcpio.conf.d/zz_tailscale.conf
```

`zz_tailscale.conf` starts from the `HOOKS=` list Omarchy's drop-ins have
already built and inserts `netconf remote-unlock tailscale` right before
`encrypt`. The `zz_` prefix makes it load after Omarchy's own files. Don't
edit `omarchy_hooks.conf` itself, because Omarchy updates can overwrite it.

## 5. Add the network to the kernel command line

Append to `/etc/default/limine`:

```sh
KERNEL_CMDLINE[default]+=" ip=:::::eth0:dhcp netconf_timeout=15"
```

- `netconf` does nothing without `ip=`. This one says "DHCP on `eth0`".
- **`eth0`, not the usual `enp…` name:** the busybox initramfs has
  no udev rule to rename network interfaces, so a machine with one wired port
  sees it as `eth0` at this stage. If your machine has more than one, use
  plain `ip=dhcp`, which tries them all.
- `netconf` runs before the passphrase prompt, so it delays it until DHCP
  finishes. `netconf_timeout=15` caps that at 15 seconds when there's no
  cable, instead of the default 120.

On the running system, nothing else picks up `ip=` on a default Omarchy
install. The kernel ignores it (`CONFIG_IP_PNP` is off), and NetworkManager
doesn't read it. Your normal network is unaffected.

## 6. Rebuild and check

```sh
sudo limine-update
sudo setup-initcpio-tailscale --check
```

In the `limine-update` output, the build hooks should include
`… block netconf remote-unlock tailscale encrypt filesystems …`.

`--check` should pass everything except `WARN: no built image to inspect`,
which you can ignore. It looks for a separate `/boot/initramfs-*.img`, but on
Omarchy the initramfs lives inside the UKI. To check it yourself, pull the
initramfs and command line out of the UKI:

```sh
sudo objcopy -O binary --only-section=.initrd /boot/EFI/Linux/omarchy_linux-omarchy.efi /tmp/initrd.img
lsinitcpio /tmp/initrd.img | grep -E 'tailscaled$|remote-unlock|hooks/(netconf|tailscale)|etc/passwd'
sudo objcopy -O binary --only-section=.cmdline /boot/EFI/Linux/omarchy_linux-omarchy.efi /dev/stdout; echo
```

## 7. Use it

Reboot. When the passphrase prompt appears, wait 10–20 seconds for DHCP and
Tailscale to come up, then from any device on your tailnet:

```sh
ssh root@<hostname>-initrd
```

Enter your passphrase. The session prints a success message and closes, and
the machine finishes booting.

**Do your first test while you're at the machine.** If anything goes wrong,
type the passphrase on the keyboard as usual.

---

## What stays the same

- **Unlocking at the keyboard:** the `encrypt` hook and plymouth prompt are
  unchanged. The only difference is that the prompt can appear a few seconds
  later while DHCP runs, or up to `netconf_timeout` seconds later with no
  network.
- **The local emergency shell** in the initramfs starts `/bin/sh` directly,
  not root's shell from `/etc/passwd`.
- **The installed system:** the modified `/etc/passwd` exists only inside
  the initramfs. Before handing over to the real system, `netconf` takes the
  interface down again and `tailscale` stops its daemon. Your normal
  networking and your normal Tailscale machine come up as usual.
- **Hibernation:** `resume` still runs after `encrypt`.

## Limitations

- **Wired only.** `netconf` doesn't bring up Wi-Fi.
- **Needs plymouth running.** If plymouth fails and the boot falls back to a
  text-mode LUKS prompt, the script still opens the disk but can't release
  that prompt. It tells you the passphrase has to be typed at the machine.
- **The unlock script handles `cryptdevice=<device>:<name>` with no extra
  options**, which is what Omarchy writes. If you've added options like
  `:allow-discards`, add the matching `cryptsetup` flag to the script.
- **Root's shell in the initramfs is now the unlock script.** Type `shell`
  at the prompt for a plain shell.

## Troubleshooting

- **`<hostname>-initrd` never shows up in `tailscale status`:** the network
  likely didn't come up. Check the interface name: boot normally, then run
  `journalctl -b -k | grep -iE 'eth0|renamed'`. Or switch to `ip=dhcp`.
- **Anything else:** after a failed attempt, unlock locally and look at the
  previous boot with
  `journalctl -b -1 | grep -iE 'tailscale|remote-unlock|plymouth'`.
  Or SSH in, type `shell`, and look around from inside the initramfs.

## Undo

```sh
sudo rm /etc/mkinitcpio.conf.d/zz_tailscale.conf
# and remove the ip=… line from /etc/default/limine
sudo limine-update
```

Optionally also remove `/etc/initcpio/install/remote-unlock`,
`/etc/initcpio/remote-unlock/`, and the two packages. Then delete the
`<hostname>-initrd` machine in the Tailscale admin console.
