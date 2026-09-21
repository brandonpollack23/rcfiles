"""Hand-made Hyprland replies, so a test states only the fields it is about.

The default monitor is 2560 wide at x=0, so its middle is x=1280: a tiled window
lying across 1280 is the master, and anything else is left or right of it.
"""

from typing import Any

from brpol_waybard.snapshot import Snapshot
from brpol_waybard.types import Address, Client, Monitor, Workspace

HIDDEN_ID = -98  # any negative id will do for a special workspace


def monitor(
    focused: bool = True,
    workspace: int = 1,
    special: str = "",
    x: int = 0,
    **fields: Any,
) -> Monitor:
    """`special` is the bare name of the special workspace open on it, if any."""
    made: Monitor = {
        "focused": focused,
        "x": x,
        "width": 2560,
        "height": 1440,
        "scale": 1.0,
        "transform": 0,
        "activeWorkspace": {"id": workspace, "name": str(workspace)},
        "specialWorkspace": {
            "id": HIDDEN_ID if special else 0,
            "name": f"special:{special}" if special else "",
        },
    }
    made.update(fields)  # type: ignore[typeddict-item]
    return made


def client(
    address: Address,
    x: int = 0,
    y: int = 0,
    width: int = 600,
    workspace: int = 1,
    cls: str | None = "kitty",
    **fields: Any,
) -> Client:
    made: Client = {
        "address": address,
        # None is for tests of a window that reports no class at all.
        "class": cls,  # type: ignore[typeddict-item]
        "title": address,
        "workspace": {"id": workspace, "name": str(workspace)},
        "at": [x, y],
        "size": [width, 400],
        "mapped": True,
        "visible": True,
        "floating": False,
        "grouped": [],
        "focusHistoryID": 0,
    }
    made.update(fields)  # type: ignore[typeddict-item]
    return made


def group(addresses: list[Address], **fields: Any) -> list[Client]:
    """One group: every tab lists the whole group and sits in the same place."""
    return [client(a, grouped=list(addresses), **fields) for a in addresses]


def master(address: Address = "0xm", **fields: Any) -> Client:
    """A tiled window across the middle of the default monitor."""
    return client(address, x=700, width=1160, **fields)


def snap(
    clients: list[Client],
    monitors: list[Monitor] | None = None,
    workspaces: list[Workspace] | None = None,
    active: Address | None = None,
    locked: frozenset[Address] = frozenset(),
) -> Snapshot:
    """A snapshot. The workspace list is worked out from the clients and the
    monitors unless one is given, the way Hyprland would report it."""
    monitors = [monitor()] if monitors is None else monitors
    if workspaces is None:
        names: dict[int, str] = {}
        for m in monitors:
            names[m["activeWorkspace"]["id"]] = m["activeWorkspace"]["name"]
        for c in clients:
            names[c["workspace"]["id"]] = c["workspace"]["name"]
        workspaces = [
            {
                "id": ws_id,
                "name": name,
                "windows": sum(1 for c in clients if c["workspace"]["id"] == ws_id),
            }
            for ws_id, name in sorted(names.items())
        ]
    return Snapshot(monitors, clients, workspaces, active, locked)
