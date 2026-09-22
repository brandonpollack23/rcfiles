"""hotplug.py: udev's datagrams, and what Hotplug makes of them.

A datagram socketpair stands in for the netlink socket, fed datagrams built
the way udevd builds them, and a script stands in for notify-send.
"""

import socket
import stat
import struct
import subprocess
import time
from collections.abc import Callable
from pathlib import Path

import pytest

from brpol_waybard import hotplug
from brpol_waybard.hotplug import BURST, Hotplug

PATIENCE = 2.0  # seconds before a wait gives up and the test fails

Bubble = tuple[str, str, str, str]  # action, icon, summary, body


def datagram(**properties: str) -> bytes:
    """One event as udevd sends it: the 40-byte header, then the properties."""
    body = b"".join(f"{k}={v}".encode() + b"\0" for k, v in properties.items())
    header = hotplug.PREFIX + struct.pack(">I", hotplug.MAGIC)
    header += struct.pack("=IIIIIII", 40, 40, len(body), 0, 0, 0, 0)
    return header + body


def usb(action: str, **properties: str) -> bytes:
    return datagram(ACTION=action, SUBSYSTEM="usb", DEVTYPE="usb_device", **properties)


def mains(online: str, **properties: str) -> bytes:
    return datagram(
        ACTION="change",
        SUBSYSTEM="power_supply",
        POWER_SUPPLY_NAME="AC",
        POWER_SUPPLY_TYPE="Mains",
        POWER_SUPPLY_ONLINE=online,
        **properties,
    )


class Udev:
    """A Hotplug listening to the test instead of to udevd, with its bubbles
    collected rather than shown."""

    def __init__(self, monkeypatch: pytest.MonkeyPatch) -> None:
        self.sender, receiver = socket.socketpair(socket.AF_UNIX, socket.SOCK_DGRAM)
        receiver.setblocking(False)
        monkeypatch.setattr(hotplug, "open_monitor", lambda: receiver)
        self.bubbles: list[Bubble] = []
        monkeypatch.setattr(
            Hotplug, "notify", lambda _, *bubble: self.bubbles.append((*bubble, "")[:4])
        )
        self.hotplug = Hotplug()

    def send(self, *datagrams: bytes, now: float = 0.0) -> None:
        for each in datagrams:
            self.sender.send(each)
        self.hotplug.step(self.hotplug.fds(), now)

    def close(self) -> None:
        self.sender.close()
        self.hotplug.close()


@pytest.fixture
def udev(monkeypatch: pytest.MonkeyPatch) -> Callable[[], Udev]:
    return lambda: Udev(monkeypatch)


def test_parse_reads_the_properties_after_the_header() -> None:
    assert hotplug.parse(usb("add", ID_USB_MODEL="Logitech_BRIO")) == {
        "ACTION": "add",
        "SUBSYSTEM": "usb",
        "DEVTYPE": "usb_device",
        "ID_USB_MODEL": "Logitech_BRIO",
    }


@pytest.mark.parametrize(
    "junk",
    [
        b"",
        b"add@/devices/pci0000:00\0ACTION=add\0",  # the kernel's own format
        hotplug.PREFIX + struct.pack(">I", 0xDEADBEEF) + bytes(28) + b"ACTION=add\0",
    ],
)
def test_parse_ignores_what_udevd_did_not_send(junk: bytes) -> None:
    assert hotplug.parse(junk) == {}


def test_a_usb_device_is_named_by_its_own_product_string() -> None:
    assert hotplug.usb_name({"ID_USB_MODEL": "Logitech_BRIO"}) == "Logitech BRIO"


def test_a_hex_product_string_falls_back_to_the_hwdb_names() -> None:
    properties = {
        "ID_USB_MODEL": "0a2b",
        "ID_VENDOR_FROM_DATABASE": "Intel Corp.",
        "ID_MODEL_FROM_DATABASE": "Bluetooth adapter",
    }
    assert hotplug.usb_name(properties) == "Intel Corp. Bluetooth adapter"


def test_a_device_nothing_names_is_known_by_its_ids() -> None:
    assert hotplug.usb_name({"PRODUCT": "46d/85e/317"}) == "USB device 46d/85e/317"


def test_a_burst_of_usb_devices_is_one_bubble_once_it_is_over(
    udev: Callable[[], Udev],
) -> None:
    dock = udev()
    dock.send(usb("add", ID_USB_MODEL="Keyboard"), now=10.0)
    dock.send(usb("add", ID_USB_MODEL="Mouse"), now=10.3)
    assert dock.bubbles == []
    assert dock.hotplug.next_due() == 10.3 + BURST

    dock.hotplug.step([], 10.3 + BURST)
    assert dock.bubbles == [
        ("added", "drive-removable-media-usb", "USB connected", "Keyboard\nMouse")
    ]
    assert dock.hotplug.next_due() is None
    dock.close()


def test_removals_get_a_bubble_of_their_own(udev: Callable[[], Udev]) -> None:
    dock = udev()
    dock.send(usb("add", ID_USB_MODEL="Mouse"), usb("remove", ID_USB_MODEL="Disk"))
    dock.hotplug.step([], BURST)
    assert [(action, body) for action, _, _, body in dock.bubbles] == [
        ("added", "Mouse"),
        ("removed", "Disk"),
    ]
    dock.close()


def test_hubs_interfaces_and_other_subsystems_are_not_devices(
    udev: Callable[[], Udev],
) -> None:
    quiet = udev()
    quiet.send(
        usb("add", ID_USB_MODEL="Hub", ID_USB_INTERFACES=":090000:"),
        datagram(ACTION="add", SUBSYSTEM="usb", DEVTYPE="usb_interface"),
        datagram(ACTION="add", SUBSYSTEM="block", DEVTYPE="disk"),
        usb("bind", ID_USB_MODEL="Mouse"),
        b"not udevd's",
    )
    assert quiet.hotplug.next_due() is None
    quiet.close()


def test_the_charger_is_announced_when_it_flips_and_only_then(
    udev: Callable[[], Udev], monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    (tmp_path / "AC").mkdir()
    (tmp_path / "AC" / "type").write_text("Mains\n")
    (tmp_path / "AC" / "online").write_text("1\n")
    (tmp_path / "BAT0").mkdir()
    (tmp_path / "BAT0" / "type").write_text("Battery\n")
    monkeypatch.setattr(hotplug, "POWER_SUPPLIES", str(tmp_path))

    laptop = udev()
    laptop.send(mains("1"))  # as it already was: some other change
    assert laptop.bubbles == []
    laptop.send(mains("0"), mains("0"), mains("1"))
    assert [(action, summary) for action, _, summary, _ in laptop.bubbles] == [
        ("removed", "Charger disconnected"),
        ("added", "Charger connected"),
    ]
    laptop.close()


def test_announce_is_a_monitor_by_name(udev: Callable[[], Udev]) -> None:
    desk = udev()
    desk.hotplug.announce("removed monitor Dell Inc. U2720Q")
    assert desk.bubbles == [
        ("removed", "video-display", "Monitor disconnected", "Dell Inc. U2720Q")
    ]
    desk.close()


@pytest.mark.parametrize("argument", ["", "added", "exploded monitor X", "added cat X"])
def test_a_malformed_announce_is_ignored(
    udev: Callable[[], Udev], argument: str
) -> None:
    desk = udev()
    desk.hotplug.announce(argument)
    assert desk.bubbles == []
    desk.close()


def test_locked_keeps_the_bubble_and_drops_the_sound(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    ran: list[list[str]] = []
    monkeypatch.setattr(hotplug, "CANBERRA", "canberra")
    monkeypatch.setattr(hotplug, "NOTIFY_SEND", "notify")
    monkeypatch.setattr(subprocess, "Popen", lambda argv, **_: ran.append(argv))
    source = Hotplug()
    source.silence(True)
    source.notify("added", "ac-adapter", "Charger connected")
    assert [argv[0] for argv in ran] == ["notify"]
    source.silence(False)
    source.notify("added", "ac-adapter", "Charger connected")
    assert [argv[0] for argv in ran] == ["notify", "canberra", "notify"]


def test_notify_runs_notify_send_and_reaps_it(
    monkeypatch: pytest.MonkeyPatch, tmp_path: Path
) -> None:
    log = tmp_path / "log"
    stand_in = tmp_path / "notify-send"
    stand_in.write_text(f'#!/bin/sh\nprintf "%s|" "$@" >{log}\n')
    stand_in.chmod(stand_in.stat().st_mode | stat.S_IXUSR)
    monkeypatch.setattr(hotplug, "NOTIFY_SEND", str(stand_in))

    source = Hotplug()
    source.notify("added", "ac-adapter", "Charger connected")
    deadline = time.monotonic() + PATIENCE
    while source.children and time.monotonic() < deadline:
        source.step([], 0.0)
    assert source.children == []
    assert log.read_text().endswith("-i|ac-adapter|--|Charger connected||")
    source.close()
