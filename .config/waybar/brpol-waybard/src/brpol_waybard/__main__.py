"""The daemon: one event subscription, one snapshot, 39 buttons.

    brpol-waybard              run it
    brpol-waybard --once NAME  print what button NAME would show, and exit

`--once` is what a button used to be: `windows.py 3` in a terminal showed
exactly what slot 3 emits. A FIFO cannot be read that way without stealing the
line from waybar, so the inspection lives here instead.
"""

import json
import select
import signal
import sys
import time

from . import control, fifos, hidden, snapshot, windows, workspaces

# Any of these means something a button draws may have moved.
EVENTS = windows.EVENTS | workspaces.EVENTS | hidden.EVENTS

MODULES = windows.MODULES + workspaces.MODULES + hidden.MODULES

# Hyprland reports a window opening as several events in a row. Waiting this
# long collapses them into one snapshot, and is short enough to stay invisible.
DEBOUNCE = 0.016


class Daemon:
    def __init__(self):
        # Urgency has no "no longer urgent" event: a window raises it, and it
        # stays raised until its workspace is looked at. So unlike everything
        # else here, this is state the snapshot cannot rebuild.
        self.urgent = set()
        self.bar = fifos.Bar(MODULES)
        self.events = None

    def render(self):
        state = snapshot.take()
        self.bar.publish(windows.render(state))
        self.bar.publish(workspaces.render(state, self.urgent))
        self.bar.publish(hidden.render(state))

    def run(self):
        self.events = ipc_events()
        self.render()

        buffer = ""
        deadline = None
        while True:
            timeout = (
                None if deadline is None else max(0.0, deadline - time.monotonic())
            )
            ready, _, _ = select.select(
                [self.events, self.bar.control.fd], [], [], timeout
            )

            if not ready:
                deadline = None
                self.render()
                continue

            dirty = False

            if self.bar.control.fd in ready:
                for command in self.bar.commands():
                    dirty |= control.apply(command, self.bar, snapshot.take)

            if self.events in ready:
                data = self.events.recv(65536)
                if not data:
                    return  # Hyprland went away; so do we.
                buffer += data.decode(errors="replace")
                complete, _, buffer = buffer.rpartition("\n")
                for line in complete.split("\n"):
                    name, _, payload = line.partition(">>")
                    if name == "urgent":
                        self.urgent.add("0x" + payload)
                    if name in EVENTS:
                        dirty = True

            if dirty and deadline is None:
                deadline = time.monotonic() + DEBOUNCE

    def close(self):
        self.bar.close()


def ipc_events():
    from . import ipc

    return ipc.events()


def once(name):
    if name not in MODULES:
        sys.exit(f"no such module: {name}\nknown: {' '.join(MODULES)}")
    state = snapshot.take()
    states = windows.render(state)
    states.update(workspaces.render(state, set()))
    states.update(hidden.render(state))
    print(json.dumps(states[name]))


def main():
    arguments = sys.argv[1:]
    if arguments and arguments[0] == "--once":
        if len(arguments) != 2:
            sys.exit("usage: brpol-waybard --once <module>")
        once(arguments[1])
        return

    if arguments:
        sys.exit(
            f"usage: brpol-waybard [--once <module>]\nmodules: {' '.join(MODULES)}"
        )

    daemon = Daemon()
    # Leaving FIFOs behind would block the next `cat` on a pipe nobody writes.
    for received in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(received, lambda *_: sys.exit(0))
    try:
        daemon.run()
    finally:
        daemon.close()


if __name__ == "__main__":
    main()
