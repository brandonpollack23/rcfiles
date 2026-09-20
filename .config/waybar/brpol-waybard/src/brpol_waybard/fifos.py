"""One FIFO per waybar button, plus the control FIFO commands arrive on.

Waybar wants one process per button and reads its stdout until the bar exits.
That process is now `cat` on one of these, so the button costs a pipe rather
than an interpreter.

Every FIFO is opened O_RDWR: on Linux that means `open()` never blocks waiting
for a peer and a write never raises EPIPE once waybar's `cat` dies, which is
what lets the daemon start before or after waybar and survive either one
restarting. The cost is that nothing drains the pipe while no `cat` is
attached, so writes are non-blocking and a full buffer is drained and retried
once before the update is dropped.
"""

import contextlib
import errno
import json
import os
from collections.abc import Iterable
from typing import Final

from .types import ButtonState, ModuleName, States

DIRECTORY: Final = "waybar"
CONTROL: Final = "control"


def runtime_dir() -> str:
    from .ipc import SOCKET_DIR

    return os.path.join(SOCKET_DIR, DIRECTORY)


class Fifo:
    """One button's pipe, holding the last line it was given."""

    path: str
    last: str | None
    fd: int

    def __init__(self, path: str) -> None:
        self.path = path
        self.last = None
        if not os.path.exists(path):
            os.mkfifo(path, 0o600)
        self.fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)

    def write(self, state: ButtonState) -> bool:
        """Emit `state` unless it is what this button already shows."""
        line = json.dumps(state) + "\n"
        if line == self.last:
            return False
        self.last = line
        self._push(line.encode())
        return True

    def prime(self) -> None:
        """Re-send the last line, for a `cat` that has only just attached.

        A pipe is not a file: whoever reads a line takes it, so a button whose
        reader waybar restarted has nothing to draw until the next event.
        scripts/ctl.sh asks for this as the button comes up.
        """
        if self.last is not None:
            self._push(self.last.encode())

    def _push(self, data: bytes) -> None:
        try:
            os.write(self.fd, data)
        except BlockingIOError:
            # No `cat` attached and the 64 KB buffer filled with updates nobody
            # read. Drop the backlog -- only the newest line matters -- and let
            # the next reader start from this one.
            try:
                os.read(self.fd, 1 << 20)
                os.write(self.fd, data)
            except OSError:
                pass
        except OSError as error:
            if error.errno != errno.EPIPE:
                raise

    def close(self) -> None:
        os.close(self.fd)
        with contextlib.suppress(FileNotFoundError):
            os.unlink(self.path)


class Bar:
    """Every button's FIFO, created once and fed by name."""

    fifos: dict[ModuleName, Fifo]
    control: Fifo

    def __init__(self, names: Iterable[ModuleName]) -> None:
        directory = runtime_dir()
        os.makedirs(directory, 0o700, exist_ok=True)
        # Deliberately not unlinking first: a restart should keep feeding the
        # `cat`s that are already attached to these pipes.
        self.fifos = {name: Fifo(os.path.join(directory, name)) for name in names}
        self.control = Fifo(os.path.join(directory, CONTROL))

    def publish(self, states: States) -> None:
        for name, state in states.items():
            self.fifos[name].write(state)

    def prime(self, name: ModuleName | None = None) -> None:
        for fifo_name, fifo in self.fifos.items():
            if name in (None, fifo_name):
                fifo.prime()

    def commands(self) -> list[str]:
        """Whole lines written to the control FIFO since the last call."""
        try:
            data = os.read(self.control.fd, 65536)
        except BlockingIOError:
            return []
        return [line for line in data.decode(errors="replace").split("\n") if line]

    def close(self) -> None:
        for fifo in self.fifos.values():
            fifo.close()
        self.control.close()
