"""Which window goes in which taskbar slot.

The window (or group) tiled across the middle of the monitor -- the master, on
a centred master layout -- is pinned to the middle of the bar, and the windows
beside it on screen are listed beside it on the bar. Nothing that is already
drawn moves when a window opens: the new one fades in where it lands.

Two things make that hold. First, every slot has a fixed role -- ghosts, left,
master, right, ghosts, left to right -- and each side fills outwards from the
master, so a window opening at the edge of a side takes the next empty slot
instead of pushing every button along by one. Within a column the bottom window
is the outermost, and the master layout opens new windows at the bottom.

Second, waybar centres the taskbar as a whole, so the master only stays put if
both sides are the same width. Every tab is the same width (style.css), so the
sides differ only by whole tabs and whole gaps between tiles, and the short
side is padded out to match with invisible ghosts of exactly those sizes. The
wide gap on either side of the master is the master's own, the same on both
sides, so it needs no balancing.

Vocabulary used throughout:

  entry   one window, and which tab of its group it is
  unit    a group's entries in tab order, or a lone window's single entry;
          units are what get placed, since a group's tabs stay together
  slot    one custom/winN module, numbered from 1, left to right
  ghost   invisible padding in a slot, there only for its width
"""

from typing import Final, Literal, NamedTuple

from .snapshot import Snapshot
from .types import Address, Client, ModuleName

# How many tabs each side and the master can show before the rest go to
# custom/winmore, and how many ghosts a side can need to balance the other --
# one per tab or gap it is short, counting the overflow button as a tab.
SIDE: Final = 6
MASTER: Final = 6
GHOSTS: Final = SIDE + 1

# Units each side keeps even when it has fewer windows, held by invisible
# placeholders in the slots the next windows will take. Opening one of those
# windows then changes a single button, from placeholder to window, at the
# same width. Anything more is several buttons that waybar may draw a frame
# apart, and the master twitches in between.
RESERVE: Final = 1

# The slots, left to right. Their total must match the number of custom/winN
# modules in windows.jsonc; custom/winmore sits between RIGHT and RIGHT_GHOSTS.
LEFT_GHOSTS: Final = range(1, GHOSTS + 1)
LEFT: Final = range(LEFT_GHOSTS.stop, LEFT_GHOSTS.stop + SIDE)
CENTRE: Final = range(LEFT.stop, LEFT.stop + MASTER)
RIGHT: Final = range(CENTRE.stop, CENTRE.stop + SIDE)
RIGHT_GHOSTS: Final = range(RIGHT.stop, RIGHT.stop + GHOSTS)
SLOTS: Final = RIGHT_GHOSTS.stop - 1

# Every module in the order the bar draws them.
ORDER: Final[list[ModuleName]] = (
    [f"win{slot}" for slot in range(1, RIGHT.stop)]
    + ["winmore"]
    + [f"win{slot}" for slot in RIGHT_GHOSTS]
)


class Entry(NamedTuple):
    """One taskbar slot's window, and where it sits in its group."""

    client: Client
    tab: int  # 0-based index within its group
    size: int  # how many tabs the group has; 1 for a lone window


type Unit = list[Entry]
"""What is placed as a whole: a group's tabs in tab order, or one lone window."""

type Ghost = Literal["tab", "gap", "solo"]
"""Invisible padding: one tab's width, one gap's, or a tab with its gaps."""

type Slot = Entry | Ghost


class Layout(NamedTuple):
    """What every slot draws, and the windows that found no slot."""

    slots: dict[int, Slot]
    overflow: list[Entry]

    def addresses(self) -> frozenset[Address]:
        """Every window with a button of its own."""
        return frozenset(
            content.client["address"]
            for content in self.slots.values()
            if isinstance(content, Entry)
        )

    def address_at(self, slot: int) -> Address | None:
        """The window in slot N, or None for an empty slot or a ghost."""
        content = self.slots.get(slot)
        return content.client["address"] if isinstance(content, Entry) else None


def current_workspace(snapshot: Snapshot) -> int | None:
    """The workspace the taskbar is showing: the focused monitor's, or the
    special workspace covering it while one is open."""
    monitor = snapshot.focused_monitor()
    if monitor is None:
        return None
    special = monitor["specialWorkspace"]
    return special["id"] if special["name"] else monitor["activeWorkspace"]["id"]


def middle(snapshot: Snapshot) -> float:
    """Where the middle of the focused monitor falls, in the layout coordinates
    windows report their position in."""
    monitor = snapshot.focused_monitor()
    if monitor is None:
        return 0.0
    rotated = monitor["transform"] % 2 == 1
    width = monitor["height"] if rotated else monitor["width"]
    return monitor["x"] + width / monitor["scale"] / 2


def units(snapshot: Snapshot) -> list[Unit]:
    """Every window on the taskbar's workspace, one unit per group or lone
    window. Group members all report the same position, so a group is placed
    once, where it sits."""
    showing = current_workspace(snapshot)
    if showing is None:
        return []

    clients = [
        c for c in snapshot.clients if c["workspace"]["id"] == showing and c["mapped"]
    ]
    by_address: dict[Address, Client] = {c["address"]: c for c in clients}

    # Every member of a group lists the whole group, so the group comes up once
    # per member. Its first tab's address is what marks it as already placed.
    result: list[Unit] = []
    placed: set[Address] = set()
    for client in clients:
        members = [by_address[a] for a in client["grouped"] if a in by_address]
        members = members or [client]
        if members[0]["address"] in placed:
            continue
        placed.add(members[0]["address"])
        result.append(
            [Entry(member, tab, len(members)) for tab, member in enumerate(members)]
        )
    return result


def fill(inside_out: list[Unit], room: int) -> tuple[list[Unit], list[Entry]]:
    """Units taken innermost first while their tabs fit in `room`; the rest
    overflow. A unit is never split, so a small one further out can still fit
    after a big one did not."""
    kept: list[Unit] = []
    spilled: list[Entry] = []
    for unit in inside_out:
        if len(unit) <= room:
            kept.append(unit)
            room -= len(unit)
        else:
            spilled.extend(unit)
    return kept, spilled


def flat(units: list[Unit]) -> list[Entry]:
    return [entry for unit in units for entry in unit]


def width(entries: list[Entry], reserved: int) -> tuple[int, int]:
    """How wide a side is, as (tabs, gaps): a side is as wide as its tabs plus
    a pair of gaps per unit, and each placeholder is a unit of one tab."""
    units_ = sum(1 for entry in entries if entry.tab == 0)
    return len(entries) + reserved, units_ + reserved


def ghosts(tabs: int, gaps: int) -> list[Ghost]:
    """The ghosts that make up a side that is `tabs` tabs and `gaps` gaps
    short, pairing them into solo ghosts where it can."""
    pairs = min(tabs, gaps)
    solo: list[Ghost] = ["solo"]
    tab: list[Ghost] = ["tab"]
    gap: list[Ghost] = ["gap"]
    return solo * pairs + tab * (tabs - pairs) + gap * (gaps - pairs)


def arrange(snapshot: Snapshot) -> Layout:
    """The whole taskbar for one snapshot: the one entry point of this module."""
    # Sort every unit into the master area or one of the sides, by where it is
    # on screen: the master is whatever tiled unit lies across the monitor's
    # middle, and anything else goes to the side its own middle is on.
    centre = middle(snapshot)
    master: list[Unit] = []
    left: list[Unit] = []
    right: list[Unit] = []
    for unit in units(snapshot):
        client = unit[0].client
        x, client_width = client["at"][0], client["size"][0]
        if not client["floating"] and x <= centre < x + client_width:
            master.append(unit)
        elif x + client_width / 2 < centre:
            left.append(unit)
        else:
            right.append(unit)

    # Order each area innermost first: nearest column first, and in a column the
    # top window first, so the bottom one -- the newest -- is at the edge.
    def x_of(unit: Unit) -> int:
        return unit[0].client["at"][0]

    def y_of(unit: Unit) -> int:
        return unit[0].client["at"][1]

    master.sort(key=y_of)
    left.sort(key=lambda unit: (-x_of(unit), y_of(unit)))
    right.sort(key=lambda unit: (x_of(unit), y_of(unit)))

    # Keep what fits in each area; everything else goes behind custom/winmore.
    kept_master, spilled_master = fill(master, MASTER)
    centred = flat(kept_master)
    if len(master) == 1 and spilled_master:  # one group too big: show what fits
        centred, spilled_master = spilled_master[:MASTER], spilled_master[MASTER:]
    kept_left, spilled_left = fill(left, SIDE)
    kept_right, spilled_right = fill(right, SIDE)
    overflow = spilled_master + spilled_left + spilled_right

    # Give the kept windows their slots. Each side fills outwards from the
    # master, so the right side starts at its first slot, and the left side --
    # drawn outermost first -- ends at its last one.
    lefts = flat(kept_left[::-1])
    rights = flat(kept_right)
    slots: dict[int, Slot] = {}
    slots.update(zip(LEFT[len(LEFT) - len(lefts) :], lefts, strict=True))
    slots.update(zip(CENTRE, centred, strict=False))
    slots.update(zip(RIGHT, rights, strict=False))

    # Placeholders, in the next slots out from each side's windows. An empty
    # workspace keeps none: there is no master yet to hold still.
    reserve_left = reserve_right = 0
    if lefts or centred or rights:
        reserve_left = max(0, min(RESERVE - len(kept_left), SIDE - len(lefts)))
        reserve_right = max(0, min(RESERVE - len(kept_right), SIDE - len(rights)))
    for i in range(reserve_left):
        slots[LEFT[len(LEFT) - len(lefts) - 1 - i]] = "solo"
    for i in range(reserve_right):
        slots[RIGHT[len(rights) + i]] = "solo"

    # Balance the sides: whichever is narrower is padded, from the master
    # outwards, with ghosts for exactly the tabs and gaps it is short. The
    # overflow button sits at the end of the right side, and is one more of each.
    tabs_left, gaps_left = width(lefts, reserve_left)
    tabs_right, gaps_right = width(rights, reserve_right)
    if overflow:
        tabs_right, gaps_right = tabs_right + 1, gaps_right + 1
    left_pad = ghosts(max(0, tabs_right - tabs_left), max(0, gaps_right - gaps_left))
    right_pad = ghosts(max(0, tabs_left - tabs_right), max(0, gaps_left - gaps_right))
    slots.update(zip(reversed(LEFT_GHOSTS), left_pad, strict=False))
    slots.update(zip(RIGHT_GHOSTS, right_pad, strict=False))

    return Layout(slots, overflow)
