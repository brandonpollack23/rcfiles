"""The daemon: one event subscription, one snapshot, 39 buttons.

    brpol-waybard              run it
    brpol-waybard --once NAME  print what button NAME would show, and exit

`--once` is what a button used to be: `windows.py 3` in a terminal showed
exactly what slot 3 emits. A FIFO cannot be read that way without stealing the
line from waybar, so the inspection lives here instead.
"""

import dataclasses
import json
import select
import signal
import socket
import sys
import time
from typing import Final, NoReturn

from . import control, fifos, hidden, snapshot, windows, workspaces
from .types import Address, EventName, ModuleName, States

# Any of these means something a button draws may have moved.
EVENTS: Final[frozenset[EventName]] = windows.EVENTS | workspaces.EVENTS | hidden.EVENTS

MODULES: Final[list[ModuleName]] = windows.MODULES + workspaces.MODULES + hidden.MODULES

# Hyprland reports a window opening as several events in a row. Waiting this
# long collapses them into one snapshot, and is short enough to stay invisible.
DEBOUNCE: Final = 0.016

# A window that has just opened is first drawn transparent and redrawn opaque
# this much later, which style.css's opacity transition turns into a fade. Long
# enough that GTK has drawn a frame in between; a change inside one frame is
# not animated.
FADE_DELAY: Final = 0.025

# How long the fade takes: the `transition` on `#windows label` in style.css,
# for opacity and the focus colours alike. Keep the two in step.
FADE: Final = 0.125

# A window that opens focused does not take the focus colours until it has
# faded in; the old focus keeps them until then, and the two cross-fade.
FOCUS_DELAY: Final = FADE_DELAY + FADE


class Daemon:
    # Urgency has no "no longer urgent" event: a window raises it, and it
    # stays raised until its workspace is looked at. So unlike everything
    # else here, this is state the snapshot cannot rebuild.
    urgent: set[Address]
    bar: fifos.Bar
    events: socket.socket | None
    # The windows with a button after the last render, and the workspace they
    # were on: a window new to a workspace fades in, a workspace switched to
    # is simply drawn.
    shown: frozenset[Address]
    workspace: int | None
    fade: float | None
    # While a window that opened focused fades in, the focus is drawn where it
    # was: on `held`, until `hold`, for as long as `holding_for` stays focused.
    drawn: Address | None
    held: Address | None
    holding_for: Address | None
    hold: float | None

    def __init__(self) -> None:
        self.urgent = set()
        self.bar = fifos.Bar(MODULES)
        self.events = None
        self.shown = frozenset()
        self.workspace = None
        self.fade = None
        self.drawn = None
        self.held = self.holding_for = None
        self.hold = None

    def render(self) -> None:
        state = snapshot.take()
        now = time.monotonic()
        shown = windows.shown(state)
        workspace = windows.workspace(state)
        fresh = shown - self.shown if workspace == self.workspace else frozenset()
        self.shown, self.workspace = shown, workspace
        if fresh:
            self.fade = now + FADE_DELAY
            if state.active in fresh:
                self.held, self.holding_for = self.drawn, state.active
                self.hold = now + FOCUS_DELAY

        # Focus moving anywhere else, or the hold running out, ends it.
        if self.hold is not None and (
            now >= self.hold or state.active != self.holding_for
        ):
            self.held = self.holding_for = self.hold = None
        if self.hold is not None:
            state = dataclasses.replace(state, active=self.held)
        self.drawn = state.active

        self.bar.publish(windows.render(state, fresh))
        self.bar.publish(workspaces.render(state, self.urgent))
        self.bar.publish(hidden.render(state))

    def run(self) -> None:
        # Bound locally as well so the type stays narrowed for select().
        events = self.events = ipc_events()
        self.render()

        buffer = ""
        deadline: float | None = None
        while True:
            # Whichever comes first: a debounced render, a fade to start, or
            # the focus to follow it. Each is a full render: the windows that
            # were fresh are in `shown` by now, and render() ends a hold that
            # has run out.
            due = [d for d in (deadline, self.fade, self.hold) if d is not None]
            timeout = max(0.0, min(due) - time.monotonic()) if due else None
            watch: list[socket.socket | int] = [events, self.bar.control.fd]
            ready, _, _ = select.select(watch, [], [], timeout)

            if not ready:
                deadline = self.fade = None
                self.render()
                continue

            dirty = False

            if self.bar.control.fd in ready:
                for command in self.bar.commands():
                    dirty |= control.apply(command, self.bar, snapshot.take)

            if events in ready:
                data = events.recv(65536)
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

    def close(self) -> None:
        self.bar.close()


def ipc_events() -> socket.socket:
    from . import ipc

    return ipc.events()


def once(name: ModuleName) -> None:
    if name not in MODULES:
        sys.exit(f"no such module: {name}\nknown: {' '.join(MODULES)}")
    state = snapshot.take()
    states: States = windows.render(state)
    states.update(workspaces.render(state, set()))
    states.update(hidden.render(state))
    print(json.dumps(states[name]))


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
