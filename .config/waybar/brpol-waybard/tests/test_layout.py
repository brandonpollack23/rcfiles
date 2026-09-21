"""layout.arrange(): which window ends up in which slot.

The default monitor's middle is x=1280; see builders.py.
"""

import random
from typing import Any

from brpol_waybard import layout
from brpol_waybard.layout import (
    CENTRE,
    LEFT,
    LEFT_GHOSTS,
    MASTER,
    RIGHT,
    RIGHT_GHOSTS,
    SIDE,
    Entry,
    Layout,
)
from brpol_waybard.types import Address, Client
from builders import client, group, master, monitor, snap


def windows_in(taskbar: Layout, slots: range) -> list[Address | None]:
    """The address in each of `slots`, or None where there is no window."""
    return [taskbar.address_at(slot) for slot in slots]


def side_width(taskbar: Layout, slots: list[int], overflow: bool) -> tuple[int, int]:
    """How wide a run of slots draws, as (tabs, gaps), by the rules in the
    module docstring of layout.py."""
    tabs = gaps = 1 if overflow else 0
    for slot in slots:
        content = taskbar.slots.get(slot)
        if isinstance(content, Entry):
            tabs += 1
            gaps += 1 if content.tab == 0 else 0
        elif content is not None:
            tabs += content in ("tab", "solo")
            gaps += content in ("gap", "solo")
    return tabs, gaps


def test_empty_workspace_draws_nothing() -> None:
    assert layout.arrange(snap([])) == Layout({}, [])


def test_no_focused_monitor_draws_nothing() -> None:
    state = snap([master()], monitors=[monitor(focused=False)])
    assert layout.arrange(state) == Layout({}, [])


def test_master_is_the_tiled_window_across_the_middle() -> None:
    taskbar = layout.arrange(snap([master("0xm")]))
    assert taskbar.address_at(CENTRE[0]) == "0xm"
    # With nothing beside it, each side keeps one placeholder next to it.
    assert taskbar.slots[LEFT[-1]] == "solo"
    assert taskbar.slots[RIGHT[0]] == "solo"


def test_a_floating_window_across_the_middle_is_not_the_master() -> None:
    floating = client("0xf", x=1000, width=600, floating=True)  # middle at 1300
    taskbar = layout.arrange(snap([floating]))
    assert windows_in(taskbar, CENTRE) == [None] * MASTER
    assert taskbar.address_at(RIGHT[0]) == "0xf"


def test_sides_fill_outwards_from_the_master() -> None:
    state = snap(
        [
            master(),
            client("0xl-near", x=400, width=300),
            client("0xl-far", x=0, width=300),
            client("0xr-near", x=1900, width=300),
            client("0xr-far", x=2250, width=300),
        ]
    )
    taskbar = layout.arrange(state)
    assert windows_in(taskbar, LEFT)[-2:] == ["0xl-far", "0xl-near"]
    assert windows_in(taskbar, RIGHT)[:2] == ["0xr-near", "0xr-far"]


def test_in_a_column_the_bottom_window_is_outermost() -> None:
    state = snap(
        [
            master(),
            client("0xl-top", x=0, y=0),
            client("0xl-bottom", x=0, y=700),
            client("0xr-top", x=1900, y=0),
            client("0xr-bottom", x=1900, y=700),
        ]
    )
    taskbar = layout.arrange(state)
    assert windows_in(taskbar, LEFT)[-2:] == ["0xl-bottom", "0xl-top"]
    assert windows_in(taskbar, RIGHT)[:2] == ["0xr-top", "0xr-bottom"]


def test_a_group_is_placed_once_with_its_tabs_in_order() -> None:
    taskbar = layout.arrange(snap(group(["0xa", "0xb", "0xc"], x=700, width=1160)))
    assert windows_in(taskbar, CENTRE)[:4] == ["0xa", "0xb", "0xc", None]
    tabs = [taskbar.slots[slot] for slot in CENTRE[:3]]
    assert [(e.tab, e.size) for e in tabs if isinstance(e, Entry)] == [
        (0, 3),
        (1, 3),
        (2, 3),
    ]


def test_unmapped_windows_and_other_workspaces_are_left_out() -> None:
    state = snap(
        [
            master("0xm"),
            client("0xunmapped", x=1900, mapped=False),
            client("0xelsewhere", x=1900, workspace=2),
        ]
    )
    assert layout.arrange(state).addresses() == {"0xm"}


def test_an_open_special_workspace_takes_over_the_taskbar() -> None:
    state = snap(
        [master("0xnormal"), master("0xspecial", workspace=-98)],
        monitors=[monitor(special="Hidden")],
    )
    assert layout.current_workspace(state) == -98
    assert layout.arrange(state).addresses() == {"0xspecial"}


def test_a_rotated_monitor_is_as_wide_as_it_is_tall() -> None:
    assert layout.middle(snap([], monitors=[monitor()])) == 1280
    assert layout.middle(snap([], monitors=[monitor(transform=1)])) == 720
    assert layout.middle(snap([], monitors=[monitor(scale=2.0, x=100)])) == 740


def test_a_full_side_spills_into_the_overflow() -> None:
    right = [client(f"0xr{i}", x=1900, y=i * 100) for i in range(SIDE + 2)]
    taskbar = layout.arrange(snap([master(), *right]))
    assert windows_in(taskbar, RIGHT) == [f"0xr{i}" for i in range(SIDE)]
    overflowed = [entry.client["address"] for entry in taskbar.overflow]
    assert overflowed == [f"0xr{SIDE}", f"0xr{SIDE + 1}"]


def test_a_group_is_never_split_but_a_smaller_unit_further_out_still_fits() -> None:
    state = snap(
        [
            master(),
            *group([f"0xa{i}" for i in range(4)], x=1900),
            *group([f"0xb{i}" for i in range(4)], x=2100),  # 4 + 4 > SIDE
            client("0xlone", x=2300),
        ]
    )
    taskbar = layout.arrange(state)
    assert windows_in(taskbar, RIGHT) == [
        "0xa0",
        "0xa1",
        "0xa2",
        "0xa3",
        "0xlone",
        None,
    ]
    assert [e.client["address"] for e in taskbar.overflow] == [
        "0xb0",
        "0xb1",
        "0xb2",
        "0xb3",
    ]


def test_a_master_group_too_big_shows_what_fits() -> None:
    tabs = [f"0x{i}" for i in range(MASTER + 2)]
    taskbar = layout.arrange(snap(group(tabs, x=700, width=1160)))
    assert windows_in(taskbar, CENTRE) == tabs[:MASTER]
    assert [e.client["address"] for e in taskbar.overflow] == tabs[MASTER:]


def test_the_short_side_is_padded_with_ghosts_next_to_the_other_sides_width() -> None:
    right = [client(f"0xr{i}", x=1900, y=i * 100) for i in range(3)]
    taskbar = layout.arrange(snap([master(), *right]))
    # Left has its placeholder (1 tab, 1 gap) against 3 tabs and 3 gaps, so it
    # is two solo ghosts short, packed against the left side's slots.
    assert [taskbar.slots.get(s) for s in LEFT_GHOSTS][-3:] == [None, "solo", "solo"]
    assert all(s not in taskbar.slots for s in RIGHT_GHOSTS)


def test_opening_the_first_window_on_a_side_changes_a_single_slot() -> None:
    before = layout.arrange(snap([master()]))
    after = layout.arrange(snap([master(), client("0xnew", x=1900)]))
    changed = {
        slot
        for slot in before.slots.keys() | after.slots.keys()
        if before.slots.get(slot) != after.slots.get(slot)
    }
    assert changed == {RIGHT[0]}


def test_a_window_opening_at_the_outer_edge_moves_no_window() -> None:
    windows = [
        master(),
        client("0xl", x=0),
        client("0xr-top", x=1900, y=0),
    ]
    before = layout.arrange(snap(windows))
    after = layout.arrange(snap([*windows, client("0xr-bottom", x=1900, y=700)]))
    for slot, content in before.slots.items():
        if isinstance(content, Entry):
            assert after.address_at(slot) == content.client["address"]


def test_address_at_is_none_for_ghosts_empty_slots_and_nonsense() -> None:
    taskbar = layout.arrange(snap([master("0xm")]))
    assert taskbar.address_at(CENTRE[0]) == "0xm"
    assert taskbar.address_at(RIGHT[0]) is None  # the placeholder
    assert taskbar.address_at(CENTRE[1]) is None
    assert taskbar.address_at(0) is None
    assert taskbar.address_at(999) is None


def random_clients(rng: random.Random) -> list[Client]:
    """A workspace's worth of lone windows and groups, anywhere on the monitor."""
    clients: list[Client] = []
    for unit in range(rng.randrange(0, 12)):
        place: dict[str, Any] = {
            "x": rng.choice([0, 300, 700, 1280, 1900, 2250]),
            "y": rng.choice([0, 480, 960]),
            "width": rng.choice([300, 600, 1160, 2560]),
            "floating": rng.random() < 0.15,
        }
        tabs = [f"0x{unit}-{tab}" for tab in range(rng.choice([1, 1, 1, 2, 3, 7]))]
        if len(tabs) > 1 or rng.random() < 0.1:
            clients += group(tabs, **place)
        else:
            clients.append(client(tabs[0], **place))
    return clients


def test_whatever_is_open_both_sides_draw_the_same_width() -> None:
    """The point of the ghosts, and the thing that keeps the master centred."""
    for seed in range(300):
        clients = random_clients(random.Random(seed))
        taskbar = layout.arrange(snap(clients))

        left = side_width(taskbar, [*LEFT_GHOSTS, *LEFT], overflow=False)
        right = side_width(
            taskbar, [*RIGHT, *RIGHT_GHOSTS], overflow=bool(taskbar.overflow)
        )
        assert left == right, f"seed {seed}"


def test_whatever_is_open_every_window_is_drawn_or_overflowed_exactly_once() -> None:
    for seed in range(300):
        clients = random_clients(random.Random(seed))
        taskbar = layout.arrange(snap(clients))

        drawn = [
            c.client["address"] for c in taskbar.slots.values() if isinstance(c, Entry)
        ]
        spilled = [entry.client["address"] for entry in taskbar.overflow]
        assert sorted(drawn + spilled) == sorted(c["address"] for c in clients), seed
        assert all(1 <= slot <= layout.SLOTS for slot in taskbar.slots), seed
