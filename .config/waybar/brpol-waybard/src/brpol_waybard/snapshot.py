"""Everything the 39 buttons need, fetched once.

Before this, each of the 39 scripts asked Hyprland for its own copy of the same
answer on every event -- about 129 round trips for one window opening, plus 12
identical `lockedAddresses()` calls into Lua. One snapshot is five.
"""

from dataclasses import dataclass

from . import ipc


@dataclass(frozen=True)
class Snapshot:
    monitors: list
    clients: list
    workspaces: list
    active: str | None
    locked: frozenset


def take():
    window = ipc.query("activewindow")
    return Snapshot(
        monitors=ipc.query("monitors"),
        clients=ipc.query("clients"),
        workspaces=ipc.query("workspaces"),
        active=window.get("address") if isinstance(window, dict) else None,
        locked=frozenset(ipc.locked_addresses()),
    )
