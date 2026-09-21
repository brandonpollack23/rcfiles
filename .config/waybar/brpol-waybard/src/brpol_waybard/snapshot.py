"""Everything the 39 buttons need, fetched once.

Before this, each of the 39 scripts asked Hyprland for its own copy of the same
answer on every event -- about 129 round trips for one window opening, plus 12
identical `lockedAddresses()` calls into Lua. One snapshot is five.
"""

import re
from dataclasses import dataclass
from typing import Final

from . import ipc
from .types import Address, Client, Monitor, Workspace

# Toasts some apps draw as real windows rather than through swaync. They are not
# windows anyone switches to, so no button lists them. Steam's are matched the
# same way in hypr/conf/rules.lua.
TOASTS: Final[list[tuple[re.Pattern[str], re.Pattern[str]]]] = [
    (re.compile(r"^steam$"), re.compile(r"^notificationtoasts_")),
]


def is_toast(client: Client) -> bool:
    cls, title = client["class"] or "", client["title"] or ""
    return any(c.search(cls) and t.search(title) for c, t in TOASTS)


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
        clients=[c for c in clients if not is_toast(c)],
        workspaces=workspaces,
        active=window.get("address") if isinstance(window, dict) else None,
        locked=ipc.locked_addresses(),
    )
