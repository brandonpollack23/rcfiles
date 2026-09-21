"""One button per workspace id.

Ids are compacted to 1..N in conf/workspaces/order.lua, so a slot is a
workspace id. Hovering lists the workspace's windows. A workspace that does not
exist prints empty text, which hides the module.

  class "active"   focused workspace
  class "visible"  shown on another monitor
  class "urgent"   a window on it wants attention
  class "empty"    no windows
"""

import html
from collections.abc import Set
from typing import Final

from . import labels
from .snapshot import Snapshot
from .types import (
    Address,
    ButtonState,
    CssClass,
    EventName,
    ModuleName,
    States,
    blank,
)

# Slots must match the number of custom/wsN modules in workspaces.jsonc.
SLOTS: Final = 20
MAX_WINDOWS: Final = 5
MAX_TITLE: Final = 60

EVENTS: Final[frozenset[EventName]] = frozenset(
    {
        "workspacev2",
        "focusedmonv2",
        "moveworkspacev2",
        "createworkspacev2",
        "destroyworkspacev2",
        "renameworkspace",
        "openwindow",
        "closewindow",
        "movewindowv2",
        "windowtitlev2",
        "urgent",
        "monitoradded",
        "monitorremoved",
    }
)

MODULES: Final[list[ModuleName]] = [f"ws{slot}" for slot in range(1, SLOTS + 1)]


def seen(snapshot: Snapshot) -> set[Address]:
    """Every window on a workspace some monitor is showing, which is what ends
    its urgency: see the note on Daemon.urgent in __main__.py."""
    showing = {m["activeWorkspace"]["id"] for m in snapshot.monitors}
    return {c["address"] for c in snapshot.clients if c["workspace"]["id"] in showing}


def state(snapshot: Snapshot, ws_id: int, urgent: Set[Address]) -> ButtonState:
    workspace = next((w for w in snapshot.workspaces if w["id"] == ws_id), None)
    if workspace is None:
        return blank()

    # Which monitor, if any, is showing this workspace, and its windows with
    # the most recently focused first.
    focused_by_shown: dict[int, bool] = {
        m["activeWorkspace"]["id"]: m["focused"] for m in snapshot.monitors
    }
    clients = sorted(
        (c for c in snapshot.clients if c["workspace"]["id"] == ws_id),
        key=lambda c: c["focusHistoryID"],
    )

    classes: list[CssClass] = []
    if ws_id in focused_by_shown:
        classes.append("active" if focused_by_shown[ws_id] else "visible")
    if any(c["address"] in urgent for c in clients):
        classes.append("urgent")
    if not clients:
        classes.append("empty")

    # The tooltip: the workspace's name, then its first few windows.
    lines = [f"<b>{html.escape(workspace['name'])}</b>"]
    for c in clients[:MAX_WINDOWS]:
        title = labels.shorten(c["title"] or c["class"] or "?", MAX_TITLE)
        lines.append(labels.tooltip_row(c["class"] or "?", title))
    if len(clients) > MAX_WINDOWS:
        lines.append(f"<i>… {len(clients) - MAX_WINDOWS} more</i>")
    if not clients:
        lines.append("<i>No windows</i>")

    return {"text": workspace["name"], "class": classes, "tooltip": "\n".join(lines)}


def render(snapshot: Snapshot, urgent: Set[Address]) -> States:
    """Every workspace module. `urgent` is the windows still asking for
    attention."""
    return {f"ws{slot}": state(snapshot, slot, urgent) for slot in range(1, SLOTS + 1)}
