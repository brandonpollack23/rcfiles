"""status.py: the PIA, weather, night light, recording and phone buttons.

The renderers are pure. Status is driven the way the daemon drives it -- select
on its pipes, then step() -- against stand-ins for the things it talks to:
scripts in place of piactl, curl and gdbus, a socket in place of hyprsunset,
and a PID file in place of hyprcap's.
"""

import contextlib
import json
import os
import select
import socket
import stat
import threading
import time
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest

from brpol_waybard import status
from brpol_waybard.status import Status
from brpol_waybard.types import States, blank

PATIENCE = 2.0  # seconds before a wait gives up and the test fails

REPLY = {
    "weather": [{"icon": "10n", "description": "light rain"}],
    "main": {"temp": 21.4, "feels_like": 19.6},
    "name": "Tokyo",
}


def script(path: Path, body: str) -> str:
    path.write_text("#!/bin/sh\n" + body)
    path.chmod(path.stat().st_mode | stat.S_IXUSR)
    return str(path)


def pump(source: Status, wanted: Callable[[States], bool], what: str) -> States:
    """Run the daemon's loop around `source` until the states it has returned,
    merged, satisfy `wanted`."""
    seen: States = {}
    deadline = time.monotonic() + PATIENCE
    while not wanted(seen):
        assert time.monotonic() < deadline, f"timed out waiting for {what}"
        ready, _, _ = select.select(source.fds(), [], [], 0.01)
        seen |= source.step(ready, time.monotonic())
    return seen


@pytest.fixture
def source() -> Iterator[Status]:
    made = Status()
    yield made
    made.close()


# -- renderers ---------------------------------------------------------------


def test_pia_is_hidden_until_piactl_has_said_something() -> None:
    assert status.render_pia(None, "") == blank()


def test_pia_states() -> None:
    connected = status.render_pia("Connected", "us-seattle")
    assert connected["class"] == ["connected"]
    assert connected["tooltip"] == "PIA: Connected (us-seattle)"
    assert status.render_pia("Disconnected", "auto")["class"] == ["disconnected"]
    # Anything in between is on its way to one of those two.
    assert status.render_pia("Reconnecting", "auto")["class"] == ["busy"]


def test_weather_shows_the_rounded_temperature_and_describes_it() -> None:
    drawn = status.render_weather(REPLY)
    assert drawn["text"] == "󰖖  21°"
    assert drawn["tooltip"] == "Tokyo: light rain, feels like 20°"


def test_weather_icon_falls_back_to_the_code_without_day_or_night() -> None:
    reply = {**REPLY, "weather": [{"icon": "04d", "description": "clouds"}]}
    assert status.render_weather(reply)["text"].startswith("󰖐")


@pytest.mark.parametrize("reply", [{"cod": 401, "message": "Invalid API key"}, [], 7])
def test_weather_hides_on_anything_that_is_not_weather(reply: object) -> None:
    assert status.render_weather(reply) == blank()


def test_nightlight_is_on_below_neutral() -> None:
    assert status.render_nightlight(3500)["class"] == ["on"]
    assert status.render_nightlight(3500)["tooltip"] == "Night light: 3500K"
    assert status.render_nightlight(status.NEUTRAL)["class"] == ["off"]
    assert status.render_nightlight(None) == blank()


# -- pia ---------------------------------------------------------------------


def test_pia_follows_the_monitor(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    go = tmp_path / "go"
    piactl = script(
        tmp_path / "piactl",
        'test "$1" = get && { echo us-seattle; exit; }\n'
        "echo Disconnected\n"
        f'until test -e "{go}"; do sleep 0.01; done\n'
        "echo Connected\n"
        "exec sleep 30\n",
    )
    monkeypatch.setattr(status, "PIACTL", piactl)
    source.pia_due = 0.0

    first = pump(source, lambda seen: "pia" in seen, "the first state")
    assert first["pia"]["class"] == ["disconnected"]
    assert first["pia"]["tooltip"] == "PIA: Disconnected (us-seattle)"

    go.touch()
    pump(
        source,
        lambda seen: "pia" in seen and seen["pia"]["class"] == ["connected"],
        "the change",
    )


def test_pia_hides_and_looks_again_when_the_monitor_exits(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(
        status, "PIACTL", script(tmp_path / "piactl", "echo Connected\n")
    )
    source.pia_due = 0.0

    seen = pump(source, lambda seen: source.pia is None and "pia" in seen, "its exit")
    assert seen["pia"] == blank()
    assert source.pia_due is not None
    assert source.pia_due > time.monotonic()


def test_without_piactl_there_is_no_pia_button(source: Status) -> None:
    assert source.pia_due is None
    assert "pia" not in source.step([], time.monotonic())
    assert source.fds() == []


# -- weather -----------------------------------------------------------------


def configure(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, settings: object
) -> None:
    path = tmp_path / "config.json"
    path.write_text(json.dumps(settings))
    monkeypatch.setattr(status, "CONFIG", str(path))


def test_weather_is_fetched_with_the_key_kept_off_the_command_line(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    configure(
        tmp_path,
        monkeypatch,
        {"weather-clock": {"api_key": "s3cret", "city": "Tokyo,JP"}},
    )
    curl = script(
        tmp_path / "curl",
        f'echo "$@" >"{tmp_path}/argv"\n'
        f'cat >"{tmp_path}/stdin"\n'
        f"cat <<'EOF'\n{json.dumps(REPLY)}\nEOF\n",
    )
    monkeypatch.setattr(status, "CURL", curl)

    before = time.monotonic()
    seen = pump(source, lambda seen: "weather" in seen, "the fetch")

    assert seen["weather"]["text"] == "󰖖  21°"
    assert "s3cret" not in (tmp_path / "argv").read_text()
    sent = (tmp_path / "stdin").read_text()
    assert 'data-urlencode = "appid=s3cret"' in sent
    assert 'data-urlencode = "q=Tokyo,JP"' in sent
    assert source.fetch is None
    assert source.weather_due >= before + status.WEATHER_EVERY


def test_a_failed_fetch_hides_the_button_and_is_retried_sooner(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    configure(tmp_path, monkeypatch, {"weather-clock": {"api_key": "k", "city": "c"}})
    monkeypatch.setattr(status, "CURL", script(tmp_path / "curl", "exit 22\n"))

    seen = pump(source, lambda seen: "weather" in seen, "the fetch")

    assert seen["weather"] == blank()
    assert source.weather_due < time.monotonic() + status.WEATHER_EVERY


def test_no_key_means_no_fetch(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    configure(tmp_path, monkeypatch, {"weather-clock": {"city": "Tokyo,JP"}})
    monkeypatch.setattr(status, "CURL", script(tmp_path / "curl", "exit 1\n"))

    now = time.monotonic()
    assert "weather" not in source.step([], now)
    assert source.fetch is None
    assert source.weather_due == now + status.WEATHER_RETRY


# -- night light -------------------------------------------------------------


class FakeSunset:
    """hyprsunset's socket: `temperature` reads, `temperature <n>` sets."""

    def __init__(self, temperature: int) -> None:
        self.temperature = temperature
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(status.SUNSET_SOCKET)
        self.server.listen()
        threading.Thread(target=self.serve, daemon=True).start()

    def serve(self) -> None:
        while True:
            try:
                client, _ = self.server.accept()
            except OSError:
                return
            with client:
                _, _, value = client.recv(4096).decode().partition(" ")
                if value:
                    self.temperature = int(value)
                client.sendall(str(self.temperature).encode())

    def close(self) -> None:
        self.server.close()
        with contextlib.suppress(FileNotFoundError):
            os.unlink(status.SUNSET_SOCKET)


@pytest.fixture
def sunset() -> Iterator[FakeSunset]:
    fake = FakeSunset(status.NEUTRAL)
    yield fake
    fake.close()


def test_nightlight_is_hidden_without_hyprsunset(source: Status) -> None:
    assert source.step([], time.monotonic())["nightlight"] == blank()


def test_nightlight_is_asked_on_a_timer(source: Status, sunset: FakeSunset) -> None:
    now = time.monotonic()
    assert source.step([], now)["nightlight"]["class"] == ["off"]
    assert "nightlight" not in source.step([], now + 1)

    sunset.temperature = 2500  # changed from the popup's slider
    later = source.step([], now + status.NIGHTLIGHT_EVERY)
    assert later["nightlight"]["class"] == ["on"]


def test_toggle_goes_to_the_configured_preset_and_back(
    source: Status, sunset: FakeSunset, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    configure(tmp_path, monkeypatch, {"brightness": {"night_preset": "2700"}})

    assert source.toggle_nightlight()["nightlight"]["tooltip"] == "Night light: 2700K"
    assert sunset.temperature == 2700

    assert source.toggle_nightlight()["nightlight"]["class"] == ["off"]
    assert sunset.temperature == status.NEUTRAL


def test_toggle_without_hyprsunset_changes_nothing(source: Status) -> None:
    assert source.toggle_nightlight() == {}


# -- recording ---------------------------------------------------------------


def test_recording_counts_minutes_and_seconds_then_hours() -> None:
    assert status.render_recording(65.9)["text"] == "󰑋 1:05"
    assert status.render_recording(3725)["text"] == "󰑋 1:02:05"
    assert status.render_recording(65)["class"] == ["recording"]
    assert status.render_recording(None) == blank()


@pytest.fixture
def pid_file(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    path = tmp_path / "hyprcap_rec.pid"
    monkeypatch.setattr(status, "REC_PID", str(path))
    return path


def test_recording_is_hidden_without_a_pid_file(source: Status, pid_file: Path) -> None:
    assert source.step([], time.monotonic())["recording"] == blank()


def test_recording_shows_while_its_process_lives_and_times_from_the_file(
    source: Status, pid_file: Path
) -> None:
    pid_file.write_text(f"{os.getpid()}\n")
    started = time.time() - 90
    os.utime(pid_file, (started, started))
    assert source.step([], time.monotonic())["recording"]["text"] == "󰑋 1:30"


def test_recording_left_behind_by_a_dead_process_is_hidden(
    source: Status, pid_file: Path
) -> None:
    # hyprcap removes the file when the recorder exits; one left by a crash
    # names a process that is gone.
    pid_file.write_text("999999999\n")
    assert source.step([], time.monotonic())["recording"] == blank()


def test_recording_is_checked_every_second(source: Status, pid_file: Path) -> None:
    now = time.monotonic()
    assert source.step([], now)["recording"] == blank()
    assert "recording" not in source.step([], now + status.RECORDING_EVERY / 2)

    pid_file.write_text(f"{os.getpid()}\n")
    later = source.step([], now + status.RECORDING_EVERY)
    assert later["recording"]["class"] == ["recording"]


# -- kdeconnect --------------------------------------------------------------


def test_kdeconnect_states() -> None:
    phone = status.Phone("p1", "Pixel", True, 83, False)
    assert status.render_kdeconnect(phone) == {
        "text": "󰄜 83%",
        "class": ["connected"],
        "tooltip": "Pixel: 83%",
    }
    charging = status.render_kdeconnect(status.Phone("p1", "Pixel", True, 83, True))
    assert charging["class"] == ["charging"]
    assert charging["tooltip"] == "Pixel: 83%, charging"
    away = status.render_kdeconnect(status.Phone("p1", "Pixel", False, None, False))
    assert away["class"] == ["disconnected"]
    assert away["tooltip"] == "Pixel: not connected"
    assert status.render_kdeconnect(None)["class"] == ["unpaired"]


def test_kdeconnect_without_a_shared_battery_shows_just_the_phone() -> None:
    drawn = status.render_kdeconnect(status.Phone("p1", "Pixel", True, None, False))
    assert drawn == {"text": "󰄜", "class": ["connected"], "tooltip": "Pixel"}


class FakeKdeconnect:
    """gdbus against a kdeconnectd with one paired phone, which is reachable
    while `reachable` exists. `gdbus monitor` prints a signal once `signal`
    exists; `sendPing` writes the object path it was called on to `pinged`."""

    def __init__(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        self.reachable = tmp_path / "reachable"
        self.signal = tmp_path / "signal"
        self.pinged = tmp_path / "pinged"
        gdbus = script(
            tmp_path / "gdbus",
            'if test "$1" = monitor; then\n'
            "  echo 'The name org.kde.kdeconnect is owned by :1.42'\n"
            f'  until test -e "{self.signal}"; do sleep 0.01; done\n'
            "  echo '/modules/kdeconnect/devices/p1: org.kde.kdeconnect.device"
            ".reachableChanged ()'\n"
            "  exec sleep 30\n"
            "fi\n"
            "path=$6 method=$8\nshift 8\n"
            'case "$method" in\n'
            "*.devices)\n"
            f'  if test "$1" = false || test -e "{self.reachable}"; then\n'
            "    echo \"(['p1'],)\"\n"
            "  else echo '([],)'; fi ;;\n"
            "*.Get)\n"
            '  case "$2" in\n'
            "  name) echo '(<\"Bob'\"'\"'s Pixel\">,)' ;;\n"
            f'  isReachable) test -e "{self.reachable}" && echo "(<true>,)" '
            '|| echo "(<false>,)" ;;\n'
            "  charge) echo '(<83>,)' ;;\n"
            "  isCharging) echo '(<true>,)' ;;\n"
            "  esac ;;\n"
            f'*.sendPing) echo "$path" >"{self.pinged}"; echo "()" ;;\n'
            "*) exit 1 ;;\n"
            "esac\n",
        )
        monkeypatch.setattr(status, "GDBUS", gdbus)
        monkeypatch.setattr(status, "KDECONNECT_CLI", "/usr/bin/kdeconnect-cli")


@pytest.fixture
def kdeconnect(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> FakeKdeconnect:
    return FakeKdeconnect(tmp_path, monkeypatch)


def test_kdeconnect_is_asked_again_on_each_signal(
    kdeconnect: FakeKdeconnect, source: Status
) -> None:
    source.kdeconnect_due = 0.0
    first = pump(source, lambda seen: "kdeconnect" in seen, "the first state")
    assert first["kdeconnect"]["class"] == ["disconnected"]
    assert first["kdeconnect"]["tooltip"] == "Bob's Pixel: not connected"

    kdeconnect.reachable.touch()
    kdeconnect.signal.touch()
    seen = pump(
        source,
        lambda seen: seen.get("kdeconnect", blank())["class"] == ["charging"],
        "the phone to connect",
    )
    assert seen["kdeconnect"]["text"] == "󰄜 83%"


def test_kdeconnect_hides_and_looks_again_when_the_monitor_exits(
    source: Status, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(status, "GDBUS", script(tmp_path / "gdbus", "exit 1\n"))
    monkeypatch.setattr(status, "KDECONNECT_CLI", "/usr/bin/kdeconnect-cli")
    source.kdeconnect_due = 0.0

    seen = pump(
        source,
        lambda seen: source.kdeconnect is None and seen.get("kdeconnect") == blank(),
        "its exit",
    )
    # Nothing answered the call either: the same as nothing paired.
    assert source.kdeconnect_due is not None
    assert source.kdeconnect_due > time.monotonic()
    assert "kdeconnect" in seen


def test_without_kdeconnect_there_is_no_phone_button(source: Status) -> None:
    assert source.kdeconnect_due is None
    assert "kdeconnect" not in source.step([], time.monotonic())
    assert status.once("kdeconnect") == blank()


def test_ping_reaches_a_connected_phone_only(kdeconnect: FakeKdeconnect) -> None:
    Status.ping_phone()
    assert not kdeconnect.pinged.exists()

    kdeconnect.reachable.touch()
    Status.ping_phone()
    assert kdeconnect.pinged.read_text().strip() == (
        "/modules/kdeconnect/devices/p1/ping"
    )
