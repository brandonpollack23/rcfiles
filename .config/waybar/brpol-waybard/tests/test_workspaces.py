from brpol_waybard import workspaces
from builders import client, monitor, snap


def test_every_module_gets_a_state_and_missing_workspaces_are_hidden() -> None:
    states = workspaces.render(snap([]), frozenset())
    assert list(states) == workspaces.MODULES
    assert states["ws1"]["text"] == "1"
    assert states["ws2"] == {"text": "", "class": [], "tooltip": ""}


def test_active_visible_and_neither() -> None:
    state = snap(
        [
            client("0xa", workspace=1),
            client("0xb", workspace=2),
            client("0xc", workspace=3),
        ],
        monitors=[monitor(workspace=1), monitor(focused=False, workspace=2, x=2560)],
    )
    states = workspaces.render(state, frozenset())
    assert states["ws1"]["class"] == ["active"]
    assert states["ws2"]["class"] == ["visible"]
    assert states["ws3"]["class"] == []


def test_empty_workspace() -> None:
    state = workspaces.render(snap([]), frozenset())["ws1"]
    assert state["class"] == ["active", "empty"]
    assert state["tooltip"] == "<b>1</b>\n<i>No windows</i>"


def test_the_button_shows_the_workspace_name_not_its_id() -> None:
    state = snap([], workspaces=[{"id": 1, "name": "Home & <co>", "windows": 0}])
    button = workspaces.render(state, frozenset())["ws1"]
    assert button["text"] == "Home & <co>"
    assert button["tooltip"].startswith("<b>Home &amp; &lt;co&gt;</b>")


def test_urgent_marks_the_workspace_of_an_urgent_window() -> None:
    state = snap([client("0xa", workspace=1), client("0xb", workspace=2)])
    states = workspaces.render(state, {"0xb"})
    assert "urgent" not in states["ws1"]["class"]
    assert states["ws2"]["class"] == ["urgent"]


def test_seen_is_every_window_on_a_workspace_some_monitor_shows() -> None:
    state = snap(
        [
            client("0xa", workspace=1),
            client("0xb", workspace=2),
            client("0xc", workspace=3),
        ],
        monitors=[monitor(workspace=1), monitor(focused=False, workspace=2, x=2560)],
    )
    assert workspaces.seen(state) == {"0xa", "0xb"}


def test_tooltip_lists_recently_focused_windows_first_and_caps_the_list() -> None:
    clients = [
        client(f"0x{i}", title=f"title {i}", focusHistoryID=10 - i) for i in range(7)
    ]
    lines = workspaces.render(snap(clients), frozenset())["ws1"]["tooltip"].split("\n")
    assert lines[1] == "<span alpha='60%'>kitty</span>  title 6"
    assert len(lines) == 1 + workspaces.MAX_WINDOWS + 1
    assert lines[-1] == "<i>… 2 more</i>"


def test_tooltip_cuts_long_titles_and_survives_missing_ones() -> None:
    clients = [
        client("0xa", title="x" * 100, focusHistoryID=0),
        client("0xb", title="", focusHistoryID=1, cls=""),
    ]
    lines = workspaces.render(snap(clients), frozenset())["ws1"]["tooltip"].split("\n")
    assert lines[1].endswith("x" * (workspaces.MAX_TITLE - 1) + "…")
    assert lines[2] == "<span alpha='60%'>?</span>  ?"
