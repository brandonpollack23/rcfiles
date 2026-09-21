"""The pipes themselves, read the way waybar's `cat` reads them."""

import json
import os
from collections.abc import Iterator
from pathlib import Path

import pytest

from brpol_waybard import fifos
from brpol_waybard.fifos import Bar, Fifo
from brpol_waybard.types import ButtonState


def button(text: str) -> ButtonState:
    return {"text": text, "class": [], "tooltip": ""}


def drain(path: str) -> list[ButtonState]:
    """Everything in the pipe right now, as a reader would get it."""
    fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
    try:
        data = os.read(fd, 1 << 20).decode()
    except BlockingIOError:
        return []
    finally:
        os.close(fd)
    return [json.loads(line) for line in data.split("\n") if line]


@pytest.fixture
def fifo(tmp_path: Path) -> Iterator[Fifo]:
    made = Fifo(str(tmp_path / "button"))
    yield made
    made.close()


def test_a_state_is_written_as_one_json_line(fifo: Fifo) -> None:
    assert fifo.write(button("a")) is True
    assert drain(fifo.path) == [button("a")]


def test_writing_does_not_wait_for_a_reader(fifo: Fifo) -> None:
    # The whole reason for O_RDWR: this would block forever, or raise, on a
    # pipe opened write-only with no `cat` on the other end.
    fifo.write(button("nobody is listening"))


def test_an_unchanged_state_is_not_written_again(fifo: Fifo) -> None:
    fifo.write(button("a"))
    assert fifo.write(button("a")) is False
    assert fifo.write(button("b")) is True
    assert drain(fifo.path) == [button("a"), button("b")]


def test_prime_resends_the_last_line_and_only_if_there_is_one(fifo: Fifo) -> None:
    fifo.prime()
    assert drain(fifo.path) == []

    fifo.write(button("a"))
    drain(fifo.path)
    fifo.prime()
    assert drain(fifo.path) == [button("a")]


def test_a_full_pipe_drops_its_backlog_for_the_newest_line(fifo: Fifo) -> None:
    # Far more than the 64 KB a pipe holds, with no reader attached.
    for index in range(300):
        fifo.write(button(f"{index} " + "x" * 1000))
    assert drain(fifo.path)[-1]["text"].startswith("299 ")


def test_an_existing_pipe_is_reused_so_attached_readers_survive(tmp_path: Path) -> None:
    path = str(tmp_path / "button")
    first = Fifo(path)
    reader = os.open(path, os.O_RDONLY | os.O_NONBLOCK)  # a `cat` left attached
    os.close(first.fd)  # the daemon dies without cleaning up

    second = Fifo(path)
    second.write(button("after restart"))
    assert json.loads(os.read(reader, 65536)) == button("after restart")
    os.close(reader)
    second.close()


def test_close_removes_the_pipe(tmp_path: Path) -> None:
    made = Fifo(str(tmp_path / "button"))
    made.close()
    assert not os.path.exists(made.path)


@pytest.fixture
def bar(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Iterator[Bar]:
    monkeypatch.setattr(fifos, "DIRECTORY", str(tmp_path / "waybar"))
    made = Bar(["win1", "ws1"])
    yield made
    made.close()


def test_bar_makes_a_private_directory_with_a_pipe_per_button(bar: Bar) -> None:
    assert sorted(os.listdir(fifos.DIRECTORY)) == ["control", "win1", "ws1"]
    assert os.stat(fifos.DIRECTORY).st_mode & 0o777 == 0o700


def test_publish_feeds_each_button_by_name(bar: Bar) -> None:
    bar.publish({"win1": button("w"), "ws1": button("1")})
    assert drain(bar.fifos["win1"].path) == [button("w")]
    assert drain(bar.fifos["ws1"].path) == [button("1")]


def test_prime_one_button_or_every_button(bar: Bar) -> None:
    bar.publish({"win1": button("w"), "ws1": button("1")})
    drain(bar.fifos["win1"].path), drain(bar.fifos["ws1"].path)

    bar.prime("ws1")
    assert drain(bar.fifos["win1"].path) == []
    assert drain(bar.fifos["ws1"].path) == [button("1")]

    bar.prime()
    assert drain(bar.fifos["win1"].path) == [button("w")]
    assert drain(bar.fifos["ws1"].path) == [button("1")]


def test_commands_are_the_whole_lines_on_the_control_pipe(bar: Bar) -> None:
    assert bar.commands() == []
    with open(bar.control.path, "w") as control:
        control.write("refresh\n\nfocus 3\n")
    assert bar.commands() == ["refresh", "focus 3"]
    assert bar.commands() == []
