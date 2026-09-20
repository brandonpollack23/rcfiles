"""Everything the 39 buttons need, fetched once.

Before this, each of the 39 scripts asked Hyprland for its own copy of the same
answer on every event -- about 129 round trips for one window opening, plus 12
identical `lockedAddresses()` calls into Lua. One snapshot is five.
"""

from dataclasses import dataclass

from . import ipc
from .types import Address, Client, Monitor, Workspace


@dataclass(frozen=True, slots=True)
class Snapshot:
    monitors: list[Monitor]
    clients: list[Client]
    workspaces: list[Workspace]
    active: Address | None
    locked: frozenset[Address]


def take() -> Snapshot:
    # `activewindow` answers an object, or `{}` with nothing focused; the
    # empty-reply fallback in query() turns a silent socket into a list.
    window: Client | list[object] = ipc.query("activewindow")
    monitors: list[Monitor] = ipc.query("monitors")
    clients: list[Client] = ipc.query("clients")
    workspaces: list[Workspace] = ipc.query("workspaces")
    return Snapshot(
        monitors=monitors,
        clients=clients,
        workspaces=workspaces,
        active=window.get("address") if isinstance(window, dict) else None,
        locked=ipc.locked_addresses(),
    )
