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

# Slots must match the number of custom/wsN modules in workspaces.jsonc.
SLOTS = 20
MAX_WINDOWS = 5
MAX_TITLE = 60

EVENTS = {
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

MODULES = [f"ws{slot}" for slot in range(1, SLOTS + 1)]


def shorten(text):
    return text if len(text) <= MAX_TITLE else text[: MAX_TITLE - 1] + "…"


def state(snapshot, ws_id, urgent):
    workspace = next((w for w in snapshot.workspaces if w["id"] == ws_id), None)
    if workspace is None:
        return {"text": "", "class": [], "tooltip": ""}

    shown = {m["activeWorkspace"]["id"]: m["focused"] for m in snapshot.monitors}
    clients = sorted(
        (c for c in snapshot.clients if c["workspace"]["id"] == ws_id),
        key=lambda c: c["focusHistoryID"],
    )

    classes = []
    if ws_id in shown:
        classes.append("active" if shown[ws_id] else "visible")
        urgent.difference_update(c["address"] for c in clients)
    if any(c["address"] in urgent for c in clients):
        classes.append("urgent")
    if not clients:
        classes.append("empty")

    lines = [f"<b>{html.escape(workspace['name'])}</b>"]
    for c in clients[:MAX_WINDOWS]:
        app = html.escape(c["class"] or "?")
        title = html.escape(shorten(c["title"] or c["class"] or "?"))
        lines.append(f"<span alpha='60%'>{app}</span>  {title}")
    if len(clients) > MAX_WINDOWS:
        lines.append(f"<i>… {len(clients) - MAX_WINDOWS} more</i>")
    if not clients:
        lines.append("<i>No windows</i>")

    return {"text": workspace["name"], "class": classes, "tooltip": "\n".join(lines)}


def render(snapshot, urgent):
    """Every workspace module. `urgent` is mutated: see the note in daemon.py."""
    return {f"ws{slot}": state(snapshot, slot, urgent) for slot in range(1, SLOTS + 1)}
