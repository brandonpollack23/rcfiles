"""Hyprland IPC: the request socket, the event socket, and the Lua REPL.

Talks to `.socket.sock` directly rather than shelling out to `hyprctl`, which
is what the module scripts did before, for the same reason: one snapshot costs
several round trips and a process each would dominate them.
"""

import json
import os
import socket
import subprocess
from typing import Any, Final

from .types import Address

SOCKET_DIR: Final = os.path.join(
    os.environ["XDG_RUNTIME_DIR"], "hypr", os.environ["HYPRLAND_INSTANCE_SIGNATURE"]
)

REQUEST_SOCKET: Final = os.path.join(SOCKET_DIR, ".socket.sock")
EVENT_SOCKET: Final = os.path.join(SOCKET_DIR, ".socket2.sock")


def request(message: str) -> str:
    """One round trip on the request socket. Hyprland closes the connection
    after replying, which is what ends the read."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(REQUEST_SOCKET)
        sock.sendall(message.encode())
        chunks: list[bytes] = []
        while chunk := sock.recv(65536):
            chunks.append(chunk)
    return b"".join(chunks).decode()


def query(what: str) -> Any:
    """Decode a `j/` reply.

    This is the trust boundary, and the Any is deliberate: JSON decoding cannot
    know the shape, so snapshot.py names it instead. Hyprland is the only
    writer, nothing validates the reply at runtime, and a field added there
    without one added to types.py is the one class of mistake types will not
    catch here.
    """
    return json.loads(request(f"j/{what}") or "[]")


def locked_addresses() -> frozenset[Address]:
    """Every window in a locked group. Whether a group is locked is not in
    `hyprctl clients`, so it comes from Lua. The 0x filter is what tolerates
    any REPL banner in the reply."""
    reply = request('repl return require("conf.wm").lockedAddresses()')
    return frozenset(word for word in reply.split() if word.startswith("0x"))


def focus_address(address: Address) -> None:
    """Focus a window by address. A taskbar click knows an address, and only
    Lua can act on a window that is not the focused one."""
    request(f'repl require("conf.wm").focusAddress("{address}")')


def toggle_special(name: str) -> None:
    """Show or hide a special workspace. Through the binary, not the socket:
    this is the one call the scripts made that way, and a click is rare enough
    that the process does not matter."""
    subprocess.run(
        ["hyprctl", "dispatch", f'hl.dsp.workspace.toggle_special("{name}")'],
        capture_output=True,
        check=False,
    )


def events() -> socket.socket:
    """A connected event socket. Readable lines are `name>>data`."""
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(EVENT_SOCKET)
    return sock
