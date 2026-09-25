#!/usr/bin/ash
# shellcheck shell=dash
# Root's login shell in the initramfs, so an SSH login (Tailscale SSH runs the
# shell /etc/passwd names) lands here instead of at a prompt: it asks for the
# LUKS passphrase, opens the root volume, and releases the encrypt hook that
# is waiting on the local passphrase prompt, so the boot carries on.
#
# Type "shell" at the passphrase prompt for a plain shell instead.

# cryptdevice=<device>:<name>[:<options>], the same parameter the encrypt hook reads.
read -r cmdline </proc/cmdline
for arg in $cmdline; do
    case $arg in
        cryptdevice=*) cryptdevice=${arg#cryptdevice=} ;;
    esac
done
if [ -z "$cryptdevice" ]; then
    echo "remote-unlock: no cryptdevice= on the kernel command line" >&2
    exec /bin/sh
fi
spec=${cryptdevice%%:*}
name=${cryptdevice#*:}
name=${name%%:*}

# A tag (PARTUUID=..., UUID=...) goes through blkid, falling back to the
# /dev/disk/by-* link udev makes for it.
device=$spec
case $spec in
    *=*)
        device=$(blkid -lt "$spec" -o device)
        if [ -z "$device" ]; then
            tag=$(printf '%s' "${spec%%=*}" | tr '[:upper:]' '[:lower:]')
            device=/dev/disk/by-$tag/${spec#*=}
        fi
        ;;
esac

tries=0
while [ ! -e "/dev/mapper/$name" ]; do
    printf 'Passphrase for %s (or "shell"): ' "$name"
    # shellcheck disable=SC3045 # busybox ash has read -s
    read -rs pass
    echo
    [ "$pass" = shell ] && exec /bin/sh
    # No trailing newline: --key-file=- takes every byte it is given, which is
    # also how the encrypt hook's plymouth prompt hands the passphrase over.
    if printf '%s' "$pass" | cryptsetup open --type luks --key-file=- "$device" "$name"; then
        break
    fi
    tries=$((tries + 1))
    if [ "$tries" -ge 3 ]; then
        echo "remote-unlock: 3 wrong passphrases, giving up" >&2
        exit 1
    fi
done
unset pass

# The encrypt hook sits in `plymouth ask-for-password` until someone types at
# the machine. Killing that client makes it go on to check /dev/mapper/$name,
# which is now there. A login that beat the hook to its prompt waits for it,
# since the hook asks regardless of whether the volume is already open.
i=0
until pid=$(pgrep -f 'plymouth ask-for-password'); do
    i=$((i + 1))
    if [ "$i" -ge 60 ]; then
        echo "remote-unlock: $name is open, but no passphrase prompt showed up to release" >&2
        echo "  (a text-mode prompt, without plymouth, still needs the passphrase at the machine)" >&2
        exit 1
    fi
    sleep 0.5
done
# shellcheck disable=SC2086
kill $pid

echo "Unlocked $name; the boot is continuing and this session will close."
