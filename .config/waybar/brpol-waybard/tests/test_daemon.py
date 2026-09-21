"""The whole daemon, end to end: a fake Hyprland on one side, and on the other
the FIFOs read the way waybar's `cat` would.

Everything here is real -- sockets, pipes, the select loop, the debounce and
the fade timers -- so these wait on the clock, in tens of milliseconds.
"""

import contextlib
import json
import os
import threading
import time
from collections.abc import Callable, Iterator

import pytest

from brpol_waybard import fifos
from brpol_waybard.__main__ import MODULES, Daemon
from brpol_waybard.layout import CENTRE, RIGHT
from brpol_waybard.types import ButtonState, ModuleName
from builders import client, master, monitor
from fake_hyprland import FakeHyprland

PATIENCE = 2.0  # seconds before a wait gives up and the test fails


def wait_until(condition: Callable[[], bool], what: str) -> None:
    deadline = time.monotonic() + PATIENCE
    while not condition():
        assert time.monotonic() < deadline, f"timed out waiting for {what}"
        time.sleep(0.005)


class Reader:
    """One button's `cat`: holds the pipe open and takes each line written."""

    def __init__(self, name: ModuleName) -> None:
        self.name = name
        self.fd = os.open(
            os.path.join(fifos.DIRECTORY, name), os.O_RDONLY | os.O_NONBLOCK
        )
        self.pending = ""
        self.unread: list[ButtonState] = []

    def lines(self) -> list[ButtonState]:
        """Every line written that has not been handed out yet, oldest first."""
        with contextlib.suppress(BlockingIOError):
            self.pending += os.read(self.fd, 1 << 20).decode()
        complete, _, self.pending = self.pending.rpartition("\n")
        self.unread += [json.loads(line) for line in complete.split("\n") if line]
        taken, self.unread = self.unread, []
        return taken

    def wait_for(self, wanted: Callable[[ButtonState], bool], what: str) -> ButtonState:
        """The next line that satisfies `wanted`. Lines before it are dropped;
        lines after it stay unread, for the next call."""
        found: list[ButtonState] = []

        def arrived() -> bool:
            lines = self.lines()
            for index, state in enumerate(lines):
                if wanted(state):
                    found.append(state)
                    self.unread = lines[index + 1 :]
                    return True
            return False

        wait_until(arrived, f"{self.name}: {what}")
        return found[0]

    def close(self) -> None:
        os.close(self.fd)


@pytest.fixture
def hyprland() -> Iterator[FakeHyprland]:
    fake = FakeHyprland()
    fake.clients = [master("0xm", title="vim")]
    fake.active = "0xm"
    yield fake
    fake.stop()


@pytest.fixture
def running(hyprland: FakeHyprland) -> Iterator[Daemon]:
    """A daemon that has drawn the bar once and is waiting for events."""
    daemon = Daemon()
    thread = threading.Thread(target=daemon.run, daemon=True)
    thread.start()
    wait_until(lambda: hyprland.renders() == 1, "the first render")
    yield daemon
    hyprland.hang_up()
    thread.join(PATIENCE)
    assert not thread.is_alive(), "run() did not return once Hyprland hung up"
    daemon.close()


@pytest.fixture
def read(running: Daemon) -> Iterator[Callable[[ModuleName], Reader]]:
    readers: list[Reader] = []

    def attach(name: ModuleName) -> Reader:
        readers.append(Reader(name))
        return readers[-1]

    yield attach
    for reader in readers:
        reader.close()


def test_startup_draws_every_button(
    running: Daemon, read: Callable[[ModuleName], Reader]
) -> None:
    assert sorted(os.listdir(fifos.DIRECTORY)) == sorted([*MODULES, fifos.CONTROL])

    window = read(f"win{CENTRE[0]}").wait_for(lambda s: True, "its first line")
    assert window["text"].endswith("vim")
    assert window["class"] == ["master", "active", "solo"]

    workspace = read("ws1").wait_for(lambda s: True, "its first line")
    assert workspace["class"] == ["active"]

    # Even a hidden button is sent its blank line, or `cat` would show nothing
    # new when a window leaves the slot.
    assert read(f"win{CENTRE[1]}").wait_for(lambda s: True, "a line")["text"] == ""


def test_status_buttons_start_hidden(read: Callable[[ModuleName], Reader]) -> None:
    # No piactl, weather key or hyprsunset here (conftest.py), so each is sent
    # the blank line that clears whatever it showed before a restart.
    for name in ("pia", "weather", "nightlight"):
        assert read(name).wait_for(lambda s: True, "its first line")["text"] == ""


def test_one_snapshot_is_five_requests(hyprland: FakeHyprland, running: Daemon) -> None:
    assert len(hyprland.requests) == 5


def test_a_window_opening_fades_in_and_then_takes_the_focus(
    hyprland: FakeHyprland, read: Callable[[ModuleName], Reader]
) -> None:
    newcomer = read(f"win{RIGHT[0]}")
    old_focus = read(f"win{CENTRE[0]}")
    newcomer.lines(), old_focus.lines()  # discard the startup render

    hyprland.clients = [*hyprland.clients, client("0xnew", x=1900, title="new")]
    hyprland.active = "0xnew"
    hyprland.emit("openwindow>>new,1,kitty,new\nactivewindowv2>>new\n")

    # First transparent, without the focus colours...
    first = newcomer.wait_for(lambda s: s["text"].endswith("new"), "the new window")
    assert first["class"] == ["fresh", "shown", "solo", "last"]
    # ...then opaque, which is what fades; the focus is still where it was...
    second = newcomer.wait_for(lambda s: "fresh" not in s["class"], "the second draw")
    assert "active" not in second["class"]
    assert all("active" in s["class"] for s in old_focus.lines())
    # ...and once it has faded in, the two swap.
    newcomer.wait_for(lambda s: "active" in s["class"], "the focus to follow")
    old_focus.wait_for(lambda s: "active" not in s["class"], "the old focus to let go")


def test_a_burst_of_events_is_one_render(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    hyprland.emit("windowtitlev2>>m\n" * 20)
    wait_until(lambda: hyprland.renders() == 2, "the debounced render")
    time.sleep(0.1)
    assert hyprland.renders() == 2


def test_a_steady_stream_of_events_does_not_put_rendering_off(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    # The debounce runs from the first event, not the latest: a title that
    # changes every few milliseconds must not starve the bar.
    for _ in range(40):
        hyprland.emit("windowtitlev2>>m\n")
        time.sleep(0.005)
    assert hyprland.renders() >= 4


def test_events_nothing_draws_are_ignored(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    hyprland.emit("submap>>resize\nactivelayout>>kbd,us\n")
    time.sleep(0.1)
    assert hyprland.renders() == 1


def test_an_event_split_across_two_reads_is_still_one_event(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    hyprland.emit("windowtit")
    time.sleep(0.05)
    assert hyprland.renders() == 1
    hyprland.emit("lev2>>m\n")
    wait_until(lambda: hyprland.renders() == 2, "the render")


def test_urgency_lasts_until_the_workspace_is_looked_at(
    hyprland: FakeHyprland, read: Callable[[ModuleName], Reader]
) -> None:
    hyprland.clients = [*hyprland.clients, client("0xb", workspace=2)]
    hyprland.workspaces = [*hyprland.workspaces, {"id": 2, "name": "2", "windows": 1}]
    button = read("ws2")

    hyprland.emit("urgent>>b\n")  # the event carries the address without its 0x
    button.wait_for(lambda s: "urgent" in s["class"], "urgent")

    # Any number of renders later it still is: nothing reports it ending.
    hyprland.emit("windowtitlev2>>m\n")
    wait_until(lambda: hyprland.renders() >= 3, "another render")
    assert all("urgent" in s["class"] for s in button.lines())

    hyprland.monitors = [monitor(workspace=2)]
    hyprland.emit("workspacev2>>2,2\n")
    seen = button.wait_for(lambda s: "active" in s["class"], "the switch")
    assert "urgent" not in seen["class"]

    hyprland.monitors = [monitor(workspace=1)]
    hyprland.emit("workspacev2>>1,1\n")
    back = button.wait_for(lambda s: "active" not in s["class"], "the switch back")
    assert "urgent" not in back["class"]


def control(line: str) -> None:
    with open(os.path.join(fifos.DIRECTORY, fifos.CONTROL), "w") as fifo:
        fifo.write(line + "\n")


def test_ctl_refresh_redraws_without_an_event(
    hyprland: FakeHyprland, read: Callable[[ModuleName], Reader]
) -> None:
    button = read(f"win{CENTRE[0]}")
    hyprland.locked = ["0xm"]
    control("refresh")
    button.wait_for(lambda s: "locked" in s["class"], "the lock")


def test_ctl_prime_resends_a_line_that_was_already_read(
    running: Daemon, read: Callable[[ModuleName], Reader]
) -> None:
    button = read("ws1")
    first = button.wait_for(lambda s: True, "its first line")
    assert button.lines() == []  # a pipe is not a file: the line is gone

    control("prime ws1")
    assert button.wait_for(lambda s: True, "the line again") == first


def test_ctl_focus_asks_lua_for_the_window_in_that_slot(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    control(f"focus {CENTRE[0]}")
    wait_until(
        lambda: any('focusAddress("0xm")' in r for r in hyprland.requests),
        "the focus request",
    )


def test_a_malformed_command_does_not_stop_the_daemon(
    hyprland: FakeHyprland, running: Daemon
) -> None:
    control("bogus\nfocus notanumber\n\xff\xfe")
    control("refresh")
    wait_until(lambda: hyprland.renders() == 2, "the render after the nonsense")


def test_closing_removes_the_pipes(hyprland: FakeHyprland) -> None:
    daemon = Daemon()
    assert os.listdir(fifos.DIRECTORY)
    daemon.close()
    assert os.listdir(fifos.DIRECTORY) == []
