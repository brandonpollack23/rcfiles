#!/usr/bin/env python3
# One workspace button for Waybar: `workspace.py <id>`. Prints one JSON line per
# change, driven by Hyprland's event socket. Hovering lists the workspace's
# windows (at most MAX_WINDOWS). Prints empty text while the workspace does not
# exist, which hides the module.
#   class "active"   focused workspace
#   class "visible"  shown on another monitor
#   class "urgent"   a window on it wants attention
#   class "empty"    no windows
import html
import json
import os
import socket
import sys

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


def shorten(text):
    return text if len(text) <= MAX_TITLE else text[: MAX_TITLE - 1] + "…"


def state(ws_id, urgent):
    workspace = next((w for w in hyprctl("workspaces") if w["id"] == ws_id), None)
    if workspace is None:
        return {"text": "", "class": [], "tooltip": ""}

    monitors = hyprctl("monitors")
    shown = {m["activeWorkspace"]["id"]: m["focused"] for m in monitors}
    clients = sorted(
        (c for c in hyprctl("clients") if c["workspace"]["id"] == ws_id),
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


def main():
    ws_id = int(sys.argv[1])
    urgent = set()
    last = None

    def emit():
        nonlocal last
        out = json.dumps(state(ws_id, urgent))
        if out != last:
            print(out, flush=True)
            last = out

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(os.path.join(SOCKET_DIR, ".socket2.sock"))
    emit()
    for line in sock.makefile():
        event, _, data = line.rstrip("\n").partition(">>")
        if event == "urgent":
            urgent.add("0x" + data)
        if event in EVENTS:
            emit()


if __name__ == "__main__":
    main()
