#!/usr/bin/env python3
# Waybar status for the special:Hidden workspace (conf/keymaps.lua in the hypr
# config). Prints one JSON line per change, driven by Hyprland's event socket.
#   class "shown"   Hidden is open on a monitor
#   class "empty"   no windows on Hidden
import json
import os
import socket
import subprocess

NAME = "special:Hidden"
EVENTS = {
    "activespecial",
    "openwindow",
    "closewindow",
    "movewindowv2",
    "createworkspacev2",
    "destroyworkspacev2",
}


def hyprctl(what):
    out = subprocess.run(["hyprctl", what, "-j"], capture_output=True, text=True)
    return json.loads(out.stdout or "[]")


def emit():
    windows = next(
        (w["windows"] for w in hyprctl("workspaces") if w["name"] == NAME), 0
    )
    shown = any(m["specialWorkspace"]["name"] == NAME for m in hyprctl("monitors"))
    classes = (["shown"] if shown else []) + ([] if windows else ["empty"])
    text = f"󰘓  {windows}" if windows else "󰘓"
    plural = "" if windows == 1 else "s"
    print(
        json.dumps(
            {
                "text": text,
                "class": classes,
                "tooltip": f"Hidden: {windows} window{plural}",
            }
        ),
        flush=True,
    )


def main():
    path = os.path.join(
        os.environ["XDG_RUNTIME_DIR"],
        "hypr",
        os.environ["HYPRLAND_INSTANCE_SIGNATURE"],
        ".socket2.sock",
    )
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.connect(path)
    emit()
    for line in sock.makefile():
        if line.split(">>", 1)[0] in EVENTS:
            emit()


if __name__ == "__main__":
    main()
