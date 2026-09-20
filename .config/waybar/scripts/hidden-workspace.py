#!/usr/bin/env python3
# Waybar buttons for the hidden (special) workspaces of the hypr config. Prints
# one JSON line per change, driven by Hyprland's event socket.
#
#   hidden-workspace.py            the default special:Hidden scratchpad
#   hidden-workspace.py <slot>     the <slot>-th other hidden workspace, 1-based
#   hidden-workspace.py toggle <n> show or hide that one, for the button's click
#
# A slot with no workspace prints empty text, which hides the module. Slots are
# the special workspaces other than DEFAULT, ascending by name -- the same rule
# conf/workspaces/hidden.lua uses to label them H1, H2, ... in the picker, so a
# button and its picker row always mean the same workspace.
#
#   class "hidden"  every button here, for the shared teal styling
#   class "shown"   the workspace is open on a monitor
#   class "empty"   no windows on it
import json
import os
import socket
import subprocess
import sys

DEFAULT = "Hidden"
PREFIX = "special:"
EVENTS = {
    "activespecial",
    "openwindow",
    "closewindow",
    "movewindowv2",
    "createworkspacev2",
    "destroyworkspacev2",
    "renameworkspace",
}

SOCKET_DIR = os.path.join(
    os.environ["XDG_RUNTIME_DIR"], "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
)


def hyprctl(what):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(os.path.join(SOCKET_DIR, ".socket.sock"))
        sock.sendall(f"j/{what}".encode())
        chunks = []
        while chunk := sock.recv(65536):
            chunks.append(chunk)
    return json.loads(b"".join(chunks) or b"[]")


def specials():
    """Every special workspace right now, by bare name."""
    return {
        w["name"][len(PREFIX) :]: w
        for w in hyprctl("workspaces")
        if w["name"].startswith(PREFIX)
    }


def slotName(open_, slot):
    """The workspace a numbered button stands for, or None while it has none."""
    names = sorted(name for name in open_ if name != DEFAULT)
    return names[slot - 1] if slot <= len(names) else None


def state(slot):
    open_ = specials()
    name = DEFAULT if slot is None else slotName(open_, slot)
    if name is None:
        return {"text": "", "class": [], "tooltip": ""}

    workspace = open_.get(name)
    windows = workspace["windows"] if workspace else 0
    shown = any(
        m["specialWorkspace"]["name"] == PREFIX + name for m in hyprctl("monitors")
    )

    if slot is None:
        text = f"󰘓  {windows}" if windows else "󰘓"
    else:
        text = f"󰘓  {name}"
    plural = "" if windows == 1 else "s"
    return {
        "text": text,
        "class": ["hidden"]
        + (["shown"] if shown else [])
        + ([] if windows else ["empty"]),
        "tooltip": f"{name}: {windows} window{plural}",
    }


def toggle(slot):
    name = slotName(specials(), slot)
    if name is not None:
        subprocess.run(
            ["hyprctl", "dispatch", f'hl.dsp.workspace.toggle_special("{name}")'],
            capture_output=True,
            check=False,
        )


def main():
    args = sys.argv[1:]
    if args and args[0] == "toggle":
        toggle(int(args[1]))
        return

    slot = int(args[0]) if args else None
    last = None

    def emit():
        nonlocal last
        out = json.dumps(state(slot))
        if out != last:
            print(out, flush=True)
            last = out

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(os.path.join(SOCKET_DIR, ".socket2.sock"))
    emit()
    for line in sock.makefile():
        if line.split(">>", 1)[0] in EVENTS:
            emit()


if __name__ == "__main__":
    main()
