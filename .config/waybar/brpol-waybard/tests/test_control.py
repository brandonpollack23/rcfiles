"""control.apply(): what each line on the control FIFO does."""

import pytest

from brpol_waybard import control, ipc, snapshot
from brpol_waybard.layout import CENTRE, RIGHT
from brpol_waybard.types import ModuleName, States, Workspace
from builders import master, snap


class FakeBar:
    primed: list[ModuleName | None]
    published: list[States]

    def __init__(self) -> None:
        self.primed = []
        self.published = []

    def prime(self, name: ModuleName | None = None) -> None:
        self.primed.append(name)

    def publish(self, states: States) -> None:
        self.published.append(states)


class FakeStatus:
    pings: int

    def __init__(self) -> None:
        self.pings = 0

    def toggle_nightlight(self) -> States:
        return {"nightlight": {"text": "󰖔", "class": ["on"], "tooltip": ""}}

    def ping_phone(self) -> None:
        self.pings += 1


class Calls:
    """What apply() asked of Hyprland, and how many snapshots it took."""

    focused: list[str]
    toggled: list[str]
    snapshots: int

    def __init__(self) -> None:
        self.focused, self.toggled, self.snapshots = [], [], 0


@pytest.fixture
def calls(monkeypatch: pytest.MonkeyPatch) -> Calls:
    made = Calls()
    chat: Workspace = {"id": -97, "name": "special:chat", "windows": 1}
    state = snap([master("0xm")], workspaces=[chat])

    def take() -> snapshot.Snapshot:
        made.snapshots += 1
        return state

    monkeypatch.setattr(snapshot, "take", take)
    monkeypatch.setattr(ipc, "focus_address", made.focused.append)
    monkeypatch.setattr(ipc, "toggle_special", made.toggled.append)
    return made


def apply(
    command: str, bar: FakeBar | None = None, status: FakeStatus | None = None
) -> bool:
    return control.apply(command, bar or FakeBar(), status or FakeStatus())  # type: ignore[arg-type]


def test_refresh_asks_for_a_render_without_taking_a_snapshot(calls: Calls) -> None:
    assert apply("refresh") is True
    assert calls.snapshots == 0


def test_prime_one_button_or_all_of_them(calls: Calls) -> None:
    bar = FakeBar()
    assert apply("prime win3\n", bar) is False
    assert apply("prime", bar) is False
    assert bar.primed == ["win3", None]


def test_focus_focuses_the_window_in_that_slot(calls: Calls) -> None:
    assert apply(f"focus {CENTRE[0]}") is False  # Hyprland's event redraws it
    assert calls.focused == ["0xm"]


def test_focus_on_a_placeholder_or_an_empty_slot_does_nothing(calls: Calls) -> None:
    apply(f"focus {RIGHT[0]}")
    apply(f"focus {CENTRE[1]}")
    assert calls.focused == []


def test_toggle_toggles_the_special_workspace_in_that_slot(calls: Calls) -> None:
    assert apply("toggle 1") is False
    apply("toggle 2")
    assert calls.toggled == ["chat"]


@pytest.mark.parametrize(
    "command", ["", "bogus", "focus", "focus x", "focus -1", "toggle", "toggle 1.5"]
)
def test_malformed_commands_are_ignored(calls: Calls, command: str) -> None:
    assert apply(command) is False
    assert (calls.focused, calls.toggled) == ([], [])


def test_nightlight_toggles_and_redraws_its_own_button(calls: Calls) -> None:
    bar = FakeBar()
    # hyprsunset has no event to wait for, and nothing else on the bar moved.
    assert apply("nightlight", bar) is False
    assert bar.published == [FakeStatus().toggle_nightlight()]
    assert calls.snapshots == 0


def test_ping_phone_pings_and_redraws_nothing(calls: Calls) -> None:
    bar, status = FakeBar(), FakeStatus()
    assert apply("ping-phone", bar, status) is False
    assert status.pings == 1
    assert bar.published == []
    assert calls.snapshots == 0
