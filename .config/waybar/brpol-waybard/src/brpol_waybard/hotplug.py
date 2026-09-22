"""A sound and a notification when a device connects or disconnects.

Not a button, but it is the same kind of thing as status.py: a source that
joins the daemon's one select loop, here a socket and a timer.

    usb, charger  udev's events, read from the netlink socket udevd multicasts
                  them on: what libudev and `udevadm monitor --udev` read, so
                  no child process and nothing to parse but KEY=value pairs
    monitor       Hyprland's monitor events, which ~/.config/hypr/conf/hotplug.lua
                  passes on with `ctl.sh announce added|removed monitor <name>`

Sounds are the XDG theme's device-added / device-removed, played by name, and
not while the session is locked: ~/.config/hypr/conf/lock.lua sends
`ctl.sh locked` and `ctl.sh unlocked`. The bubbles still come, so what was
plugged in behind the lock screen is there to read afterwards.
"""

import contextlib
import os
import shutil
import socket
import struct
import subprocess
from collections.abc import Collection
from typing import Final, Literal

Action = Literal["added", "removed"]

CANBERRA: Final = shutil.which("canberra-gtk-play")
NOTIFY_SEND: Final = shutil.which("notify-send")
POWER_SUPPLIES: Final = "/sys/class/power_supply"

# From <linux/netlink.h>; the socket module does not have it.
NETLINK_KOBJECT_UEVENT: Final = 15
# The multicast group udevd sends processed events to. Group 1 is the kernel's
# own, which comes before the rules have run and so has no names in it.
UDEV_GROUP: Final = 2
# How udevd's datagrams start: this, then the magic in network byte order,
# then native-endian sizes. monitor_netlink_header in systemd's
# src/libsystemd/sd-device/device-monitor.c.
PREFIX: Final = b"libudev\0"
MAGIC: Final = 0xFEEDCAFE

# A dock or a composite device arrives as several events; they share one
# bubble once none has come for this long.
BURST: Final = 0.5

ACTIONS: Final[dict[str, Action]] = {"added": "added", "removed": "removed"}

USB_SUMMARIES: Final[dict[Action, str]] = {
    "added": "USB connected",
    "removed": "USB disconnected",
}

# What `ctl.sh announce <action> <kind> <name>` may name: icon and summary.
KINDS: Final[dict[str, tuple[str, dict[Action, str]]]] = {
    "monitor": (
        "video-display",
        {"added": "Monitor connected", "removed": "Monitor disconnected"},
    ),
}


def open_monitor() -> socket.socket | None:
    """The udev event socket; None where there is no netlink to listen on.

    Anyone may listen, but only CAP_NET_ADMIN may send to the group, so what
    arrives needs no check of who sent it."""
    try:
        monitor = socket.socket(
            socket.AF_NETLINK,
            socket.SOCK_RAW | socket.SOCK_NONBLOCK | socket.SOCK_CLOEXEC,
            NETLINK_KOBJECT_UEVENT,
        )
        monitor.bind((0, UDEV_GROUP))
    except OSError:
        return None
    return monitor


def parse(datagram: bytes) -> dict[str, str]:
    """One event's properties; {} for anything that is not udevd's format."""
    if len(datagram) < 20 or not datagram.startswith(PREFIX):
        return {}
    (magic,) = struct.unpack_from(">I", datagram, 8)
    _, offset = struct.unpack_from("=II", datagram, 12)
    if magic != MAGIC:
        return {}
    properties = {}
    for pair in datagram[offset:].split(b"\0"):
        key, equals, value = pair.decode(errors="replace").partition("=")
        if equals:
            properties[key] = value
    return properties


def usb_name(properties: dict[str, str]) -> str:
    """ID_USB_MODEL is the device's own product string ("Logitech_BRIO"), but
    some devices only report a hex id there, so fall back to the hwdb names,
    then the vendor/product ids."""
    model = properties.get("ID_USB_MODEL", "").replace("_", " ")
    if model and not all(c in "0123456789abcdefABCDEF" for c in model):
        return model
    if "ID_MODEL_FROM_DATABASE" in properties:
        vendor = properties.get("ID_VENDOR_FROM_DATABASE", "")
        return f"{vendor} {properties['ID_MODEL_FROM_DATABASE']}".strip()
    return f"USB device {properties.get('PRODUCT', '')}".strip()


def mains_online() -> dict[str, str]:
    """Each mains supply's `online`, to tell a flip from any other change."""
    online = {}
    with contextlib.suppress(OSError):
        for name in os.listdir(POWER_SUPPLIES):
            with contextlib.suppress(OSError):
                with open(os.path.join(POWER_SUPPLIES, name, "type")) as file:
                    if file.read().strip() != "Mains":
                        continue
                with open(os.path.join(POWER_SUPPLIES, name, "online")) as file:
                    online[name] = file.read().strip()
    return online


class Hotplug:
    monitor: socket.socket | None
    ac: dict[str, str]
    # USB devices seen since the last bubble, and when that burst is over.
    pending: dict[Action, list[str]]
    due: float | None
    # Sounds and bubbles still running, to be reaped.
    children: list[subprocess.Popen[bytes]]
    # No sound while the session is locked.
    silent: bool

    def __init__(self) -> None:
        self.monitor = open_monitor()
        self.ac = mains_online()
        self.pending = {"added": [], "removed": []}
        self.due = None
        self.children = []
        self.silent = False

    def fds(self) -> list[socket.socket]:
        return [self.monitor] if self.monitor is not None else []

    def next_due(self) -> float | None:
        return self.due

    def step(self, ready: Collection[object], now: float) -> None:
        self.children = [child for child in self.children if child.poll() is None]

        if self.monitor is not None and self.monitor in ready:
            while True:
                try:
                    datagram = self.monitor.recv(65536)
                except BlockingIOError:
                    break
                except OSError:
                    break  # ENOBUFS: events were dropped, the socket is fine
                self.event(parse(datagram), now)

        if self.due is not None and now >= self.due:
            self.due = None
            for action, summary in USB_SUMMARIES.items():
                if self.pending[action]:
                    names = "\n".join(self.pending[action])
                    self.notify(action, "drive-removable-media-usb", summary, names)
                    self.pending[action] = []

    def event(self, properties: dict[str, str], now: float) -> None:
        match properties.get("SUBSYSTEM"), properties.get("ACTION"):
            case "usb", "add" | "remove" as action:
                if properties.get("DEVTYPE") != "usb_device":
                    return
                # Hubs, root hubs included, are plumbing, not something plugged in.
                if properties.get("ID_USB_INTERFACES", "").startswith(":09"):
                    return
                which = ACTIONS["added" if action == "add" else "removed"]
                self.pending[which].append(usb_name(properties))
                self.due = now + BURST

            case "power_supply", "change":
                if properties.get("POWER_SUPPLY_TYPE") != "Mains":
                    return
                name = properties.get("POWER_SUPPLY_NAME", "")
                online = properties.get("POWER_SUPPLY_ONLINE", "")
                # change events also come for unrelated updates; only a flip counts.
                if online == self.ac.get(name):
                    return
                self.ac[name] = online
                if online == "1":
                    self.notify("added", "ac-adapter", "Charger connected")
                else:
                    self.notify("removed", "ac-adapter", "Charger disconnected")

    def announce(self, argument: str) -> None:
        """`<added|removed> <kind> <name>`, from the control FIFO."""
        action, _, rest = argument.partition(" ")
        kind, _, name = rest.partition(" ")
        which = ACTIONS.get(action)
        if which is not None and kind in KINDS:
            icon, summaries = KINDS[kind]
            self.notify(which, icon, summaries[which], name)

    def silence(self, on: bool) -> None:
        self.silent = on

    def notify(self, action: Action, icon: str, summary: str, body: str = "") -> None:
        commands = []
        if CANBERRA is not None and not self.silent:
            commands.append([CANBERRA, "-i", f"device-{action}", "-d", "hotplug"])
        if NOTIFY_SEND is not None:
            commands.append(
                [NOTIFY_SEND, "-a", "Devices", "-e", "-t", "3000", "-i", icon]
                + ["--", summary, body]
            )
        for argv in commands:
            with contextlib.suppress(OSError):
                self.children.append(
                    subprocess.Popen(
                        argv,
                        stdin=subprocess.DEVNULL,
                        stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL,
                    )
                )

    def close(self) -> None:
        if self.monitor is not None:
            self.monitor.close()
