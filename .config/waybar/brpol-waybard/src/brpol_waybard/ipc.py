"""Hyprland IPC: the request socket, the event socket, and the Lua REPL.

Talks to `.socket.sock` directly rather than shelling out to `hyprctl`, which
is what the module scripts did before, for the same reason: one snapshot costs
several round trips and a process each would dominate them.
"""

import json
import os
import socket
import subprocess

SOCKET_DIR = os.path.join(
    os.environ["XDG_RUNTIME_DIR"], "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
)

REQUEST_SOCKET = os.path.join(SOCKET_DIR, ".socket.sock")
EVENT_SOCKET = os.path.join(SOCKET_DIR, ".socket2.sock")


def request(message):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(REQUEST_SOCKET)
        sock.sendall(message.encode())
        chunks = []
        while chunk := sock.recv(65536):
            chunks.append(chunk)
    return b"".join(chunks).decode()


def query(what):
    return json.loads(request(f"j/{what}") or "[]")


# Whether a group is locked is not in `hyprctl clients`, so it comes from Lua.
# The 0x filter is what tolerates any REPL banner in the reply.
def locked_addresses():
    reply = request('repl return require("conf.wm").lockedAddresses()')
    return {word for word in reply.split() if word.startswith("0x")}


# A taskbar click knows an address, and only Lua can act on a window that is not
# the focused one.
def focus_address(address):
    request(f'repl require("conf.wm").focusAddress("{address}")')


# Through the binary, not the socket: this is the one call the scripts made that
# way, and a click is rare enough that the process does not matter.
def toggle_special(name):
    subprocess.run(
        ["hyprctl", "dispatch", f'hl.dsp.workspace.toggle_special("{name}")'],
        capture_output=True,
        check=False,
    )


def events():
    """A connected event socket. Readable lines are `name>>data`."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(EVENT_SOCKET)
    return sock
