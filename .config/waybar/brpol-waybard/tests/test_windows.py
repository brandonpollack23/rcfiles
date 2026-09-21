"""windows.render(): what each taskbar button draws."""

from brpol_waybard import layout, windows
from brpol_waybard.layout import CENTRE, LEFT, RIGHT, SLOTS
from brpol_waybard.snapshot import Snapshot
from brpol_waybard.types import Address, States
from builders import client, group, master, snap


def render(state: Snapshot, fresh: frozenset[Address] = frozenset()) -> States:
    return windows.render(state, layout.arrange(state), fresh)


def test_every_module_gets_a_state_every_time() -> None:
    assert set(render(snap([]))) == set(windows.MODULES)
    assert len(windows.MODULES) == SLOTS + 1


def test_an_empty_taskbar_hides_every_button() -> None:
    assert all(state["text"] == "" for state in render(snap([])).values())


def test_a_lone_master_window() -> None:
    state = render(snap([master("0xm", title="vim")], active="0xm"))[f"win{CENTRE[0]}"]
    assert state["class"] == ["master", "active", "solo"]
    assert state["text"] == "󰆍  vim"
    assert state["tooltip"] == "<b>vim</b>\n<span alpha='60%'>kitty</span>"


def test_visible_but_unfocused_is_shown_and_hidden_tabs_are_neither() -> None:
    tabs = group(["0xa", "0xb"], x=700, width=1160)
    tabs[1]["visible"] = False
    states = render(snap(tabs))
    assert "shown" in states[f"win{CENTRE[0]}"]["class"]
    assert "shown" not in states[f"win{CENTRE[1]}"]["class"]
    assert "active" not in states[f"win{CENTRE[1]}"]["class"]


def test_group_tabs_say_where_in_the_group_they_are() -> None:
    states = render(snap(group(["0xa", "0xb", "0xc"], x=700, width=1160)))
    position = [
        next(
            c
            for c in states[f"win{slot}"]["class"]
            if c.startswith("g") and c != "grouped"
        )
        for slot in CENTRE[:3]
    ]
    assert position == ["gstart", "gmid", "gend"]
    assert "Group: tab 2 of 3" in states[f"win{CENTRE[1]}"]["tooltip"]


def test_the_group_icon_rides_on_the_first_tab_only() -> None:
    states = render(snap(group(["0xa", "0xb"], x=700, width=1160)))
    assert states[f"win{CENTRE[0]}"]["text"].startswith(windows.GROUP_ICON)
    assert not states[f"win{CENTRE[1]}"]["text"].startswith(windows.GROUP_ICON)


def test_a_locked_group_shows_a_lock_instead() -> None:
    tabs = group(["0xa", "0xb"], x=700, width=1160)
    states = render(snap(tabs, locked=frozenset({"0xa", "0xb"})))
    first, second = states[f"win{CENTRE[0]}"], states[f"win{CENTRE[1]}"]
    assert first["text"].startswith(windows.LOCK_ICON)
    assert "locked" in first["class"] and "locked" in second["class"]
    assert first["tooltip"].endswith("Group: tab 1 of 2 · locked")


def test_a_group_of_one_is_still_a_group() -> None:
    states = render(snap(group(["0xa"], x=700, width=1160)))
    state = states[f"win{CENTRE[0]}"]
    assert state["class"] == ["master", "shown", "solo", "grouped"]
    assert state["text"].startswith(windows.GROUP_ICON)
    assert state["tooltip"].endswith("Group of one")


def test_floating_and_fresh() -> None:
    state = snap([master(), client("0xf", x=1900, floating=True)])
    button = render(state, fresh=frozenset({"0xf"}))[f"win{RIGHT[0]}"]
    assert button["class"][:1] == ["fresh"]
    assert "floating" in button["class"]


def test_long_titles_are_cut_and_markup_is_escaped() -> None:
    state = render(snap([master(title="<b>" + "x" * 100)]))[f"win{CENTRE[0]}"]
    assert state["text"] == "󰆍  &lt;b&gt;" + "x" * (windows.TITLE_LEN - 4) + "…"
    assert "<b>&lt;b&gt;xxx" in state["tooltip"]


def test_placeholders_and_ghosts_are_invisible_but_not_hidden() -> None:
    states = render(snap([master(), client("0xr0", x=1900), client("0xr1", x=2250)]))
    placeholder = states[f"win{LEFT[-1]}"]
    assert placeholder == {"text": "​", "class": ["ghost", "solo"], "tooltip": ""}
    # Waybar hides a button with no text; a ghost has to keep its width.
    assert windows.ghost_state("tab") == {
        "text": "​",
        "class": ["ghost"],
        "tooltip": "",
    }
    assert windows.ghost_state("gap")["class"] == ["ghost", "gap"]


def test_the_two_ends_of_what_is_drawn_are_marked() -> None:
    states = render(snap([master(), client("0xr0", x=1900), client("0xr1", x=2250)]))
    marked = {
        name: [c for c in state["class"] if c in ("first", "last")]
        for name, state in states.items()
        if "first" in state["class"] or "last" in state["class"]
    }
    # Left: one placeholder plus one ghost to match the right's two windows.
    assert marked == {f"win{LEFT[0] - 1}": ["first"], f"win{RIGHT[1]}": ["last"]}


def test_a_single_button_is_both_ends() -> None:
    state = snap([client("0xf", x=1000, width=600, floating=True)])
    drawn = {n: s for n, s in render(state).items() if s["text"]}
    # The floating window on the right, and its balancing placeholder on the left.
    assert [s["class"][-1] for s in drawn.values()] == ["first", "last"]


def test_overflow_button_counts_and_lists_what_has_no_slot() -> None:
    right = [client(f"0xr{i}", x=1900, y=i * 50, title=f"t{i}") for i in range(16)]
    more = render(snap([master(), *right]))["winmore"]
    assert more["text"] == "+10"
    assert more["class"] == ["overflow", "last"]
    lines = more["tooltip"].split("\n")
    assert lines[0] == "<b>10 more window(s)</b>"
    assert len(lines) == 1 + windows.OVERFLOW_LIST + 1
    assert lines[-1] == "<i>… 2 more</i>"


def test_no_overflow_hides_the_button() -> None:
    assert render(snap([master()]))["winmore"]["text"] == ""
