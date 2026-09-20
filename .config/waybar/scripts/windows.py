#!/usr/bin/env python3
# One taskbar entry for Waybar: `windows.py <slot>` prints the window sitting in
# that slot, and `windows.py overflow` prints the "+N" standing in for the
# windows past the last slot. One custom module per slot, the same way
# workspaces.jsonc does it, so every entry is its own button: waybar has no
# module that lists windows, and a single label could not be clicked per window.
#
# Entries are ordered the way the windows are laid out on screen, left to right,
# with the tabs of a group kept together in tab order. Prints one JSON line per
# change, driven by Hyprland's event socket, plus SIGRTMIN+8 for the group
# changes Hyprland has no event for (conf/wm/taskbar.lua sends it).
#   class "active"    the focused window
#   class "shown"     the tab its group is currently showing
#   class "locked"    in a locked group; the lock icon rides on its first tab
#   class "floating"
#   class "solo" / "gstart" / "gmid" / "gend"   which tab of its group it is,
#                                               which is what spaces groups apart
#
# `windows.py focus <slot>` focuses that slot's window; the buttons come back in
# this way because which window a slot holds changes as windows come and go.
import html
import json
import os
import select
import signal
import socket
import sys

# Slots must match the number of custom/winN modules in windows.jsonc.
SLOTS = 12
ACTIVE_LEN = 34
IDLE_LEN = 34
TOOLTIP_LEN = 90
OVERFLOW_LIST = 8

LOCK_ICON = "󰌾"
DEFAULT_ICON = "󰖯"

ICONS = {
    "com.mitchellh.ghostty": "󰆍",
    "kitty": "󰆍",
    "org.wezfurlong.wezterm": "󰆍",
    "foot": "󰆍",
    "google-chrome": "󰊯",
    "google-chrome-stable": "󰊯",
    "chromium": "󰊯",
    "firefox": "󰈹",
    "code": "󰨞",
    "dev.zed.zed": "󰨞",
    "steam": "󰓓",
    "discord": "󰙯",
    "slack": "󰒱",
    "spotify": "󰓇",
    "thunar": "󰉋",
    "org.pwmt.zathura": "󰈦",
    "obsidian": "󰠮",
    "zenity": "󰋗",
}

# Pretty names for the tooltip, which is the one place the raw class would show.
NAMES = {
    "com.mitchellh.ghostty": "Ghostty",
    "org.wezfurlong.wezterm": "WezTerm",
    "google-chrome": "Google Chrome",
    "google-chrome-stable": "Google Chrome",
    "code": "VS Code",
    "dev.zed.zed": "Zed",
    "org.pwmt.zathura": "Zathura",
}

# Titles that repeat the application name; the icon already says which it is.
SUFFIXES = (
    " - Google Chrome",
    " - Chromium",
    " — Mozilla Firefox",
    " - Mozilla Firefox",
    " - Visual Studio Code",
)

# conf/wm/taskbar.lua sends this after anything that changes a group.
GROUP_SIGNAL = signal.SIGRTMIN + 8

EVENTS = {
    "activewindowv2",
    "openwindow",
    "closewindow",
    "movewindowv2",
    "windowtitlev2",
    "changefloatingmode",
    "fullscreen",
    "workspacev2",
    "focusedmonv2",
    "moveworkspacev2",
    "createworkspacev2",
    "destroyworkspacev2",
    "activespecial",
    "monitoradded",
    "monitorremoved",
}

SOCKET_DIR = os.path.join(
    os.environ["XDG_RUNTIME_DIR"], "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
)


def request(message):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(os.path.join(SOCKET_DIR, ".socket.sock"))
        sock.sendall(message.encode())
        chunks = []
        while chunk := sock.recv(65536):
            chunks.append(chunk)
    return b"".join(chunks).decode()


def hyprctl(what):
    return json.loads(request(f"j/{what}") or "[]")


# Whether a group is locked is not in `hyprctl clients`, so it comes from Lua.
def locked_addresses():
    reply = request('repl return require("conf.wm").lockedAddresses()')
    return {word for word in reply.split() if word.startswith("0x")}


def shorten(text, limit):
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


def label(client):
    title = client["title"] or ""
    for suffix in SUFFIXES:
        if title.endswith(suffix):
            title = title[: -len(suffix)]
            break
    return title.strip() or client["class"] or "?"


def app_name(client):
    name = client["class"] or "?"
    return NAMES.get(name.lower(), name)


# Every window on the focused monitor, in layout order, as (client, tab index,
# group size). Group members all report the same position, so a group is placed
# once, where it sits, and its tabs follow in tab order.
def entries():
    monitor = next((m for m in hyprctl("monitors") if m["focused"]), None)
    if monitor is None:
        return []

    # A special workspace covers the monitor for as long as it is open.
    special = monitor["specialWorkspace"]
    workspace = special["id"] if special["name"] else monitor["activeWorkspace"]["id"]

    clients = [
        c
        for c in hyprctl("clients")
        if c["workspace"]["id"] == workspace and c["mapped"]
    ]
    by_address = {c["address"]: c for c in clients}

    result, placed = [], set()
    for client in sorted(clients, key=lambda c: (c["at"][0], c["at"][1])):
        members = [by_address[a] for a in client["grouped"] if a in by_address]
        members = members or [client]
        if members[0]["address"] in placed:
            continue
        placed.add(members[0]["address"])
        for index, member in enumerate(members):
            result.append((member, index, len(members)))
    return result


def blank():
    return {"text": "", "class": [], "tooltip": ""}


def overflow_state(items):
    hidden = items[SLOTS:]
    if not hidden:
        return blank()

    lines = [f"<b>{len(hidden)} more window(s)</b>"]
    for client, _, _ in hidden[:OVERFLOW_LIST]:
        app = html.escape(app_name(client))
        title = html.escape(shorten(label(client), TOOLTIP_LEN))
        lines.append(f"<span alpha='60%'>{app}</span>  {title}")
    if len(hidden) > OVERFLOW_LIST:
        lines.append(f"<i>… {len(hidden) - OVERFLOW_LIST} more</i>")

    return {
        "text": f"+{len(hidden)}",
        "class": ["overflow"],
        "tooltip": "\n".join(lines),
    }


def window_state(items, slot, active, locked):
    if slot > min(len(items), SLOTS):
        return blank()
    client, index, size = items[slot - 1]

    classes = []
    if client["address"] == active:
        classes.append("active")
    elif client["visible"]:
        classes.append("shown")
    if client["floating"]:
        classes.append("floating")
    if size == 1:
        classes.append("solo")
    elif index == 0:
        classes.append("gstart")
    elif index == size - 1:
        classes.append("gend")
    else:
        classes.append("gmid")

    is_locked = client["address"] in locked
    if is_locked:
        classes.append("locked")

    icon = ICONS.get((client["class"] or "").lower(), DEFAULT_ICON)
    budget = ACTIVE_LEN if "active" in classes else IDLE_LEN
    text = f"{icon}  {html.escape(shorten(label(client), budget))}"
    # The lock belongs to the group, so it rides on the group's first tab. That
    # is what makes it visible on a group that is not the focused one.
    if is_locked and index == 0:
        text = f"{LOCK_ICON} {text}"

    lines = [f"<b>{html.escape(shorten(label(client), TOOLTIP_LEN))}</b>"]
    lines.append(f"<span alpha='60%'>{html.escape(app_name(client))}</span>")
    if size > 1:
        group = f"Group: tab {index + 1} of {size}"
        lines.append(f"{group} · locked" if is_locked else group)
    elif is_locked:
        lines.append("Locked group of one")

    return {"text": text, "class": classes, "tooltip": "\n".join(lines)}


def state(slot):
    items = entries()
    if slot == "overflow":
        return overflow_state(items)
    window = hyprctl("activewindow")
    active = window.get("address") if isinstance(window, dict) else None
    return window_state(items, slot, active, locked_addresses())


def focus(slot):
    items = entries()
    if slot <= min(len(items), SLOTS):
        address = items[slot - 1][0]["address"]
        request(f'repl require("conf.wm").focusAddress("{address}")')


def watch(slot):
    # The signal handler only has to break the wait; set_wakeup_fd is what the
    # loop actually sees, since a realtime signal would otherwise be ignored
    # only after the default action has killed the process.
    reader, writer = os.pipe()
    os.set_blocking(writer, False)
    signal.signal(GROUP_SIGNAL, lambda *_: None)
    signal.set_wakeup_fd(writer)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(os.path.join(SOCKET_DIR, ".socket2.sock"))

    last = None

    def emit():
        nonlocal last
        out = json.dumps(state(slot))
        if out != last:
            print(out, flush=True)
            last = out

    emit()
    buffer = ""
    while True:
        ready, _, _ = select.select([sock, reader], [], [])
        if reader in ready:
            os.read(reader, 4096)
            emit()
        if sock in ready:
            data = sock.recv(65536)
            if not data:
                return
            buffer += data.decode(errors="replace")
            complete, _, buffer = buffer.rpartition("\n")
            if any(line.partition(">>")[0] in EVENTS for line in complete.split("\n")):
                emit()


def main():
    if sys.argv[1] == "focus":
        focus(int(sys.argv[2]))
        return
    watch("overflow" if sys.argv[1] == "overflow" else int(sys.argv[1]))


if __name__ == "__main__":
    main()
