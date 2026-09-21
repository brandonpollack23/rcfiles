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
import socket
import sys
import time
from collections.abc import Set
from typing import Final, NoReturn

from . import control, fifos, hidden, ipc, layout, snapshot, windows, workspaces
from .fade import Fader
from .layout import Layout
from .snapshot import Snapshot
from .types import Address, EventName, ModuleName, States

# Any of these means something a button draws may have moved.
EVENTS: Final[frozenset[EventName]] = windows.EVENTS | workspaces.EVENTS | hidden.EVENTS

MODULES: Final[list[ModuleName]] = windows.MODULES + workspaces.MODULES + hidden.MODULES

# Hyprland reports a window opening as several events in a row. Waiting this
# long collapses them into one snapshot, and is short enough to stay invisible.
DEBOUNCE: Final = 0.016


def render_all(
    state: Snapshot,
    taskbar: Layout,
    fresh: frozenset[Address] = frozenset(),
    urgent: Set[Address] = frozenset(),
) -> States:
    """Every button on the bar, by module name."""
    return {
        **windows.render(state, taskbar, fresh),
        **workspaces.render(state, urgent),
        **hidden.render(state),
    }


class Daemon:
    events: socket.socket
    # Event-socket bytes received so far that do not yet end in a newline.
    partial: str
    bar: fifos.Bar
    fader: Fader
    # Urgency has no "no longer urgent" event: a window raises it, and it
    # stays raised until its workspace is looked at. So unlike everything
    # else here, this is state the snapshot cannot rebuild.
    urgent: set[Address]
    # When the render that events have asked for is due, if one is.
    debounce: float | None

    def __init__(self) -> None:
        self.events = ipc.events()
        self.partial = ""
        self.bar = fifos.Bar(MODULES)
        self.fader = Fader()
        self.urgent = set()
        self.debounce = None

    def render(self) -> None:
        state = snapshot.take()
        taskbar = layout.arrange(state)

        # Let the fader see what is about to be drawn. It answers with which
        # windows to draw transparent, and may move the focus back for a moment.
        state, fresh = self.fader.step(
            state,
            taskbar.addresses(),
            layout.current_workspace(state),
            time.monotonic(),
        )

        # A window stops being urgent once its workspace is on a monitor.
        self.urgent -= workspaces.seen(state)

        self.bar.publish(render_all(state, taskbar, fresh, self.urgent))

    def run(self) -> None:
        self.render()

        while True:
            # Sleep until there is something to read or a render falls due:
            # the debounced one, or one the fader wants. There is no telling
            # them apart afterwards and no need to, since each is a full
            # render and a full render settles all of them.
            due = [
                t for t in (self.debounce, self.fader.next_render()) if t is not None
            ]
            timeout = max(0.0, min(due) - time.monotonic()) if due else None
            watch: list[socket.socket | int] = [self.events, self.bar.control.fd]
            ready, _, _ = select.select(watch, [], [], timeout)

            if not ready:
                self.debounce = None
                self.render()
                continue

            # Find out whether anything that came in changes the bar. Nothing
            # is drawn here: it only starts the debounce, unless one is running.
            dirty = False
            if self.bar.control.fd in ready:
                for command in self.bar.commands():
                    dirty |= control.apply(command, self.bar)
            if self.events in ready:
                lines = self.read_events()
                if lines is None:
                    return  # Hyprland went away; so do we.
                dirty |= self.note_events(lines)

            if dirty and self.debounce is None:
                self.debounce = time.monotonic() + DEBOUNCE

    def read_events(self) -> list[str] | None:
        """The whole lines now available on the event socket, or None once
        Hyprland has closed it."""
        data = self.events.recv(65536)
        if not data:
            return None
        received = self.partial + data.decode(errors="replace")
        complete, _, self.partial = received.rpartition("\n")
        return complete.split("\n")

    def note_events(self, lines: list[str]) -> bool:
        """Take in a batch of `name>>data` lines. Returns True when any of them
        means the bar should be recomputed."""
        dirty = False
        for line in lines:
            name, _, payload = line.partition(">>")
            if name == "urgent":
                self.urgent.add("0x" + payload)
            if name in EVENTS:
                dirty = True
        return dirty

    def close(self) -> None:
        self.events.close()
        self.bar.close()


def once(name: ModuleName) -> None:
    if name not in MODULES:
        sys.exit(f"no such module: {name}\nknown: {' '.join(MODULES)}")
    state = snapshot.take()
    print(json.dumps(render_all(state, layout.arrange(state))[name]))


def main() -> None:
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

    def stop(*_: object) -> NoReturn:
        sys.exit(0)

    # Leaving FIFOs behind would block the next `cat` on a pipe nobody writes.
    for received in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
        signal.signal(received, stop)
    try:
        daemon.run()
    finally:
        daemon.close()


if __name__ == "__main__":
    main()
