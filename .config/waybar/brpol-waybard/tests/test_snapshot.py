from typing import Any

import pytest

from brpol_waybard import ipc, snapshot
from builders import client, monitor


def test_steam_toasts_are_not_windows() -> None:
    toast = client("0x1", title="notificationtoasts_5_desktop", cls="steam")
    assert snapshot.is_toast(toast)
    assert not snapshot.is_toast(client("0x1", title="Steam", cls="steam"))
    assert not snapshot.is_toast(
        client("0x1", title="notificationtoasts_5", cls="kitty")
    )
    assert not snapshot.is_toast(client("0x1", title=None, cls=None))


@pytest.fixture
def replies(monkeypatch: pytest.MonkeyPatch) -> dict[str, Any]:
    """What Hyprland answers to each `j/` query; tests edit it in place."""
    answers: dict[str, Any] = {
        "activewindow": client("0xa"),
        "monitors": [monitor()],
        "clients": [client("0xa"), client("0xb")],
        "workspaces": [{"id": 1, "name": "1", "windows": 2}],
    }
    monkeypatch.setattr(ipc, "query", lambda what: answers[what])
    monkeypatch.setattr(ipc, "locked_addresses", lambda: frozenset({"0xb"}))
    return answers


def test_take_gathers_the_five_answers(replies: dict[str, Any]) -> None:
    state = snapshot.take()
    assert state.active == "0xa"
    assert [c["address"] for c in state.clients] == ["0xa", "0xb"]
    assert state.locked == {"0xb"}
    assert state.monitors == replies["monitors"]


def test_take_leaves_toasts_out(replies: dict[str, Any]) -> None:
    replies["clients"].append(
        client("0xt", title="notificationtoasts_1_desktop", cls="steam")
    )
    assert [c["address"] for c in snapshot.take().clients] == ["0xa", "0xb"]


@pytest.mark.parametrize("nothing_focused", [{}, []])
def test_nothing_focused_is_none(replies: dict[str, Any], nothing_focused: Any) -> None:
    # `{}` is what Hyprland answers; `[]` is what query() makes of no answer.
    replies["activewindow"] = nothing_focused
    assert snapshot.take().active is None


def test_focused_monitor() -> None:
    elsewhere, here = monitor(focused=False), monitor(focused=True, x=2560)
    state = snapshot.Snapshot([elsewhere, here], [], [], None, frozenset())
    assert state.focused_monitor() == here

    nowhere = snapshot.Snapshot([elsewhere], [], [], None, frozenset())
    assert nowhere.focused_monitor() is None
