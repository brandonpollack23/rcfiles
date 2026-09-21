from brpol_waybard import hidden
from brpol_waybard.types import Workspace
from builders import monitor, snap


def special(name: str, windows: int) -> Workspace:
    return {"id": -98, "name": f"special:{name}", "windows": windows}


def test_the_default_scratchpad_has_a_button_even_before_it_exists() -> None:
    state = hidden.render(snap([]))["hidden"]
    assert state == {
        "text": hidden.ICON,
        "class": ["hidden", "empty"],
        "tooltip": "Hidden: 0 windows",
    }


def test_the_default_scratchpad_shows_its_window_count() -> None:
    state = hidden.render(snap([], workspaces=[special("Hidden", 1)]))["hidden"]
    assert state["text"] == f"{hidden.ICON}  1"
    assert state["class"] == ["hidden"]
    assert state["tooltip"] == "Hidden: 1 window"


def test_numbered_slots_are_the_other_specials_by_name() -> None:
    state = snap(
        [], workspaces=[special("zed", 2), special("Hidden", 1), special("chat", 3)]
    )
    states = hidden.render(state)
    assert list(states) == hidden.MODULES
    assert states["hidden1"]["text"] == f"{hidden.ICON}  chat"
    assert states["hidden2"]["text"] == f"{hidden.ICON}  zed"
    assert states["hidden2"]["tooltip"] == "zed: 2 windows"
    assert states["hidden3"]["text"] == ""


def test_shown_while_open_on_any_monitor() -> None:
    state = snap(
        [],
        monitors=[monitor(), monitor(focused=False, special="chat", x=2560)],
        workspaces=[special("chat", 1)],
    )
    states = hidden.render(state)
    assert states["hidden1"]["class"] == ["hidden", "shown"]
    assert "shown" not in states["hidden"]["class"]


def test_name_at_means_the_same_workspace_as_the_button() -> None:
    state = snap(
        [], workspaces=[special("zed", 2), special("Hidden", 1), special("chat", 3)]
    )
    assert hidden.name_at(state, 1) == "chat"
    assert hidden.name_at(state, 2) == "zed"


def test_name_at_is_none_for_a_slot_with_no_workspace() -> None:
    state = snap([], workspaces=[special("chat", 3)])
    assert hidden.name_at(state, 2) is None


def test_name_at_does_not_wrap_round_for_slot_zero_or_below() -> None:
    # `names[slot - 1]` with slot 0 is the last workspace, not none of them.
    state = snap([], workspaces=[special("chat", 3)])
    assert hidden.name_at(state, 0) is None
    assert hidden.name_at(state, -1) is None
