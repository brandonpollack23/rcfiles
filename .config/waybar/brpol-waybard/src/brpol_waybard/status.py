"""The status buttons that are not about windows: PIA, weather, night light,
and the screen recording indicator.

Nothing here comes from Hyprland's event socket, so none of it goes through a
snapshot. Each button has a source of its own, and all four fit the daemon's
one select loop without a thread:

    pia         `piactl monitor connectionstate`, a line per change; its pipe
                is watched like the event socket
    weather     OpenWeatherMap, fetched by a `curl` whose pipe is watched the
                same way, so a slow network never holds up the taskbar
    nightlight  hyprsunset's socket, which has no events: asked on a timer,
                and again straight after a toggle (`ctl.sh nightlight`)
    recording   the PID file hyprcap keeps while it records, checked every
                second: hidden unless it names a live process, and counting
                up from the file's age while it does

The popups these buttons open live in ~/.config/l1p0-menu, and so does the
config read here: launch.sh there writes the weather key and city into it.
The recording button opens the capture panel, ~/.config/hypr/scripts/capture.py,
which leads with a stop button while a recording runs.
"""

import contextlib
import json
import os
import select
import shutil
import socket
import subprocess
import time
from collections.abc import Collection
from typing import Any, Final

from .ipc import SOCKET_DIR
from .types import ButtonState, CssClass, ModuleName, States, blank

MODULES: Final[list[ModuleName]] = ["pia", "weather", "nightlight", "recording"]

PIACTL: Final = shutil.which("piactl")
CURL: Final = shutil.which("curl")
CONFIG: Final = os.path.join(
    os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config"),
    "l1p0-menu",
    "config.json",
)
SUNSET_SOCKET: Final = os.path.join(SOCKET_DIR, ".hyprsunset.sock")
REC_PID: Final = os.path.join(
    os.environ.get("XDG_RUNTIME_DIR") or "/run", "hyprcap_rec.pid"
)
WEATHER_URL: Final = "https://api.openweathermap.org/data/2.5/weather"

WEATHER_EVERY: Final = 900.0  # seconds
# After a fetch that failed, and while launch.sh has not written a key yet.
WEATHER_RETRY: Final = 60.0
NIGHTLIGHT_EVERY: Final = 30.0
RECORDING_EVERY: Final = 1.0
# `piactl monitor` exits with PIA's daemon; look for it again this often.
PIA_RETRY: Final = 5.0

# What l1p0-menus' own night light switch counts as off, and turns it on to
# when its config names no preset.
NEUTRAL: Final = 6000
NIGHT_PRESET: Final = 3500

# OpenWeatherMap icon codes: exact first, then without the day/night letter.
WEATHER_ICONS: Final = {
    "01d": "󰖙",
    "01n": "󰖔",
    "02d": "󰖕",
    "02n": "󰼱",
    "03": "󰖐",
    "04": "󰖐",
    "09": "󰖗",
    "10": "󰖖",
    "11": "󰖓",
    "13": "󰖘",
    "50": "󰖑",
}


# Every other state piactl reports (Connecting, Reconnecting, ...) is "busy".
PIA_LOOKS: Final[dict[str, tuple[str, CssClass]]] = {
    "Connected": ("󰦝", "connected"),
    "Disconnected": ("󰦞", "disconnected"),
}


def render_pia(state: str | None, region: str) -> ButtonState:
    """`state` as piactl prints it; None while there is no piactl to ask."""
    if state is None:
        return blank()
    icon, css = PIA_LOOKS.get(state, ("󰦜", "busy"))
    return {"text": icon, "class": [css], "tooltip": f"PIA: {state} ({region})"}


def render_weather(reply: Any) -> ButtonState:
    """`reply` is OpenWeatherMap's current-weather JSON, or whatever came back
    instead of it: anything without the fields hides the button."""
    try:
        now = reply["weather"][0]
        code = str(now["icon"])
        icon = WEATHER_ICONS.get(code) or WEATHER_ICONS.get(code[:2], "󰖐")
        return {
            "text": f"{icon}  {round(reply['main']['temp'])}°",
            "class": [],
            "tooltip": f"{reply['name']}: {now['description']}, "
            f"feels like {round(reply['main']['feels_like'])}°",
        }
    except (KeyError, IndexError, TypeError):
        return blank()


def render_nightlight(temperature: int | None) -> ButtonState:
    """None when hyprsunset is not running."""
    if temperature is None:
        return blank()
    if temperature < NEUTRAL:
        return {
            "text": "󰖔",
            "class": ["on"],
            "tooltip": f"Night light: {temperature}K",
        }
    return {"text": "󰖙", "class": ["off"], "tooltip": "Night light: off"}


def render_recording(elapsed: float | None) -> ButtonState:
    """Seconds since the recording started; None when nothing is recording."""
    if elapsed is None:
        return blank()
    minutes, seconds = divmod(max(0, int(elapsed)), 60)
    hours, minutes = divmod(minutes, 60)
    clock = f"{hours}:{minutes:02}:{seconds:02}" if hours else f"{minutes}:{seconds:02}"
    return {
        "text": f"󰑋 {clock}",
        "class": ["recording"],
        "tooltip": "Recording: click to stop it, right-click to stop at once",
    }


def recording_elapsed() -> float | None:
    """How long hyprcap has been recording, from when it wrote its PID file;
    None when there is no file, or its process is gone."""
    try:
        with open(REC_PID) as file:
            os.kill(int(file.read().strip()), 0)
        return time.time() - os.stat(REC_PID).st_mtime
    except (OSError, ValueError):
        return None


def config() -> Any:
    """l1p0-menus' config, or {} while launch.sh has not written one."""
    try:
        with open(CONFIG) as file:
            return json.load(file)
    except (OSError, ValueError):
        return {}


def sunset(message: str) -> str | None:
    """One request to hyprsunset, the way `hyprctl hyprsunset` makes it."""
    try:
        with socket.socket(socket.AF_UNIX) as client:
            client.settimeout(0.2)
            client.connect(SUNSET_SOCKET)
            client.sendall(message.encode())
            return client.recv(4096).decode(errors="replace").strip()
    except OSError:
        return None


def temperature() -> int | None:
    reply = sunset("temperature")
    return int(reply) if reply is not None and reply.isdecimal() else None


class Pipe:
    """A child process whose stdout is read from the select loop."""

    process: subprocess.Popen[bytes]
    fd: int
    data: bytes

    def __init__(self, argv: list[str], stdin: str | None = None) -> None:
        self.process = subprocess.Popen(
            argv,
            stdin=subprocess.PIPE if stdin is not None else subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        if stdin is not None and self.process.stdin is not None:
            self.process.stdin.write(stdin.encode())
            self.process.stdin.close()
        assert self.process.stdout is not None
        self.fd = self.process.stdout.fileno()
        os.set_blocking(self.fd, False)
        self.data = b""

    def read(self) -> bool:
        """Take what is there. False once the child has closed its end."""
        try:
            received = os.read(self.fd, 65536)
        except BlockingIOError:
            return True
        self.data += received
        return bool(received)

    def lines(self) -> list[str]:
        """The whole lines read so far, which are then forgotten."""
        complete, _, self.data = self.data.rpartition(b"\n")
        return [line for line in complete.decode(errors="replace").split("\n") if line]

    def close(self) -> None:
        with contextlib.suppress(OSError):
            self.process.kill()
        self.process.wait()
        if self.process.stdout is not None:
            self.process.stdout.close()


class Status:
    pia: Pipe | None
    pia_state: str | None
    pia_due: float | None
    fetch: Pipe | None
    weather: ButtonState
    weather_due: float
    nightlight_due: float
    recording_due: float

    def __init__(self) -> None:
        self.pia = None
        self.pia_state = None
        # No piactl, no button: never due.
        self.pia_due = 0.0 if PIACTL else None
        self.fetch = None
        self.weather = blank()
        self.weather_due = 0.0
        self.nightlight_due = 0.0
        self.recording_due = 0.0

    def fds(self) -> list[int]:
        return [pipe.fd for pipe in (self.pia, self.fetch) if pipe is not None]

    def next_due(self) -> float:
        """When step() next has something to do without a pipe being ready."""
        due = [self.nightlight_due, self.recording_due]
        if self.pia is None and self.pia_due is not None:
            due.append(self.pia_due)
        if self.fetch is None:
            due.append(self.weather_due)
        return min(due)

    def step(self, ready: Collection[object], now: float) -> States:
        """Read the pipes in `ready` and do what has fallen due. Returns the
        buttons that may have changed; publishing skips the ones that did not."""
        states: States = {}

        if self.pia is None and self.pia_due is not None and now >= self.pia_due:
            assert PIACTL is not None
            self.pia = Pipe([PIACTL, "monitor", "connectionstate"])
        if self.pia is not None and self.pia.fd in ready:
            alive = self.pia.read()
            for line in self.pia.lines():
                self.pia_state = line.strip()
            if not alive:
                self.pia.close()
                self.pia, self.pia_state, self.pia_due = None, None, now + PIA_RETRY
            states["pia"] = render_pia(self.pia_state, self.region())

        if self.fetch is None and now >= self.weather_due:
            self.start_fetch(now)
        if self.fetch is not None and self.fetch.fd in ready and not self.fetch.read():
            self.weather = self.fetched(self.fetch.data)
            self.fetch.close()
            self.fetch = None
            retry = self.weather == blank()
            self.weather_due = now + (WEATHER_RETRY if retry else WEATHER_EVERY)
            states["weather"] = self.weather

        if now >= self.nightlight_due:
            self.nightlight_due = now + NIGHTLIGHT_EVERY
            states["nightlight"] = render_nightlight(temperature())

        if now >= self.recording_due:
            self.recording_due = now + RECORDING_EVERY
            states["recording"] = render_recording(recording_elapsed())

        return states

    def region(self) -> str:
        if PIACTL is None or self.pia_state is None:
            return ""
        try:
            asked = subprocess.run(
                [PIACTL, "get", "region"], capture_output=True, text=True, timeout=1
            )
        except (OSError, subprocess.TimeoutExpired):
            return ""
        return asked.stdout.strip()

    def start_fetch(self, now: float) -> None:
        weather = config().get("weather-clock", {})
        key, city = weather.get("api_key"), weather.get("city")
        if not (CURL and key and city):
            self.weather_due = now + WEATHER_RETRY
            return
        # The key goes in on stdin, as curl config, to stay out of `ps`.
        self.fetch = Pipe(
            [CURL, "-fsS", "-m", "5", "-G", WEATHER_URL, "-K", "-"],
            stdin=f'data-urlencode = "q={city}"\n'
            f'data-urlencode = "appid={key}"\n'
            'data = "units=metric"\n',
        )

    @staticmethod
    def fetched(data: bytes) -> ButtonState:
        try:
            return render_weather(json.loads(data))
        except ValueError:
            return blank()

    def toggle_nightlight(self) -> States:
        """Night preset <-> neutral, and the button as it is afterwards."""
        current = temperature()
        if current is None:
            return {}
        preset = config().get("brightness", {}).get("night_preset", NIGHT_PRESET)
        sunset(f"temperature {NEUTRAL if current < NEUTRAL else preset}")
        return {"nightlight": render_nightlight(temperature())}

    def close(self) -> None:
        for pipe in (self.pia, self.fetch):
            if pipe is not None:
                pipe.close()


def once(name: ModuleName) -> ButtonState:
    """What button `name` would show right now, for `--once`: the same sources,
    asked and waited for rather than followed."""
    source = Status()
    try:
        if name == "nightlight":
            return render_nightlight(temperature())
        if name == "recording":
            return render_recording(recording_elapsed())
        if name == "pia":
            if PIACTL is None:
                return blank()
            asked = subprocess.run(
                [PIACTL, "get", "connectionstate"], capture_output=True, text=True
            )
            source.pia_state = asked.stdout.strip() or None
            return render_pia(source.pia_state, source.region())
        source.start_fetch(0.0)
        if source.fetch is None:
            return blank()
        while source.fetch.read():
            select.select([source.fetch.fd], [], [])
        return source.fetched(source.fetch.data)
    finally:
        source.close()
