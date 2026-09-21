"""The per-window taskbar: one entry per window on the focused monitor.

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

  class "active"    the focused window
  class "shown"     the tab its group is currently showing
  class "grouped"   in a group, even a group of one; the group icon rides on
                    its first tab, and a locked group shows a lock instead
  class "locked"    in a locked group
  class "floating"
  class "solo" / "gstart" / "gmid" / "gend"   which tab of its group it is,
                                              which is what spaces groups apart
  class "master"    the window or group pinned to the middle
  class "fresh"     just opened: drawn transparent, then faded in
  class "ghost"     invisible padding: a tab ("ghost"), a gap ("ghost gap"),
                    or both ("ghost solo")
  class "first" / "last"   the two ends of the taskbar, ghosts included, whose
                           outer gap spaces them from nothing and is dropped
"""

import html
import unicodedata
from typing import Final, Literal, NamedTuple

from .snapshot import Snapshot
from .types import Address, ButtonState, Client, CssClass, EventName, ModuleName, States

# How many tabs each side and the master can show before the rest go to
# custom/winmore, and how many ghosts a side can need to balance the other --
# one per tab or gap it is short, counting the overflow button as a tab.
SIDE: Final = 6
# Units each side keeps even when it has fewer windows, held by invisible
# placeholders in the slots the next windows will take. Opening one of those
# windows then changes a single button, from placeholder to window, at the
# same width. Anything more is several buttons that waybar may draw a frame
# apart, and the master twitches in between.
RESERVE: Final = 1
MASTER: Final = 6
GHOSTS: Final = SIDE + 1

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

# Title budgets are in columns of the bar's monospaced font. With the icons in
# front, the longest label is 29 columns, which is what min-width in style.css
# is sized to; a wider label would break the equal widths the ghosts rely on.
ACTIVE_LEN: Final = 24
IDLE_LEN: Final = 24
TOOLTIP_LEN: Final = 90
OVERFLOW_LIST: Final = 8

LOCK_ICON: Final = "󰌾"
GROUP_ICON: Final = "󰆏"
DEFAULT_ICON: Final = "󰖯"

ICONS: Final[dict[str, str]] = {
    "com.mitchellh.ghostty": "󰆍",
    "kitty": "󰆍",
    "org.wezfurlong.wezterm": "󰆍",
    "foot": "󰆍",
    "google-chrome": "󰊯",
    "google-chrome-stable": "󰊯",
    "chromium": "󰊯",
    "firefox": "󰈹",
    "code": "󰨞",
    "dev.zed.zed": "󰨞",
    "steam": "󰓓",
    "discord": "󰙯",
    "slack": "󰒱",
    "spotify": "󰓇",
    "thunar": "󰉋",
    "org.pwmt.zathura": "󰈦",
    "obsidian": "󰠮",
    "zenity": "󰋗",
}

# Pretty names for the tooltip, which is the one place the raw class would show.
NAMES: Final[dict[str, str]] = {
    "com.mitchellh.ghostty": "Ghostty",
    "org.wezfurlong.wezterm": "WezTerm",
    "google-chrome": "Google Chrome",
    "google-chrome-stable": "Google Chrome",
    "code": "VS Code",
    "dev.zed.zed": "Zed",
    "org.pwmt.zathura": "Zathura",
}

# Titles that repeat the application name; the icon already says which it is.
SUFFIXES: Final[tuple[str, ...]] = (
    " - Google Chrome",
    " - Chromium",
    " — Mozilla Firefox",
    " - Mozilla Firefox",
    " - Visual Studio Code",
)

EVENTS: Final[frozenset[EventName]] = frozenset(
    {
        "activewindowv2",
        "openwindow",
        "closewindow",
        "movewindowv2",
        "windowtitlev2",
        "changefloatingmode",
        "fullscreen",
        "workspacev2",
        "focusedmonv2",
        "moveworkspacev2",
        "createworkspacev2",
        "destroyworkspacev2",
        "activespecial",
        "monitoradded",
        "monitorremoved",
    }
)

MODULES: Final[list[ModuleName]] = [f"win{slot}" for slot in range(1, SLOTS + 1)] + [
    "winmore"
]


class Entry(NamedTuple):
    """One taskbar slot's window, and where it sits in its group."""

    client: Client
    tab: int
    size: int


type Ghost = Literal["tab", "gap", "solo"]
"""Invisible padding: one tab's width, one gap's, or a tab with its gaps."""

type Slot = Entry | Ghost


class Layout(NamedTuple):
    """What every slot draws, and the windows that found no slot."""

    slots: dict[int, Slot]
    overflow: list[Entry]


def columns(char: str) -> int:
    if unicodedata.combining(char):
        return 0
    return 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1


def shorten(text: str, limit: int) -> str:
    """`text` cut to `limit` columns, which wide characters take two of."""
    if sum(map(columns, text)) <= limit:
        return text
    kept, used = "", 0
    for char in text:
        used += columns(char)
        if used > limit - 1:
            break
        kept += char
    return kept.rstrip() + "…"


def label(client: Client) -> str:
    title = client["title"] or ""
    for suffix in SUFFIXES:
        if title.endswith(suffix):
            title = title[: -len(suffix)]
            break
    return title.strip() or client["class"] or "?"


def app_name(client: Client) -> str:
    name = client["class"] or "?"
    return NAMES.get(name.lower(), name)


# The workspace the taskbar is showing: the focused monitor's, or the special
# workspace covering it while one is open.
def workspace(snapshot: Snapshot) -> int | None:
    monitor = next((m for m in snapshot.monitors if m["focused"]), None)
    if monitor is None:
        return None
    special = monitor["specialWorkspace"]
    return special["id"] if special["name"] else monitor["activeWorkspace"]["id"]


# Every window on the focused monitor, one list per group (or lone window),
# with the tabs in tab order. Group members all report the same position, so a
# group is placed once, where it sits.
def units(snapshot: Snapshot) -> list[list[Entry]]:
    showing = workspace(snapshot)
    if showing is None:
        return []

    clients = [
        c for c in snapshot.clients if c["workspace"]["id"] == showing and c["mapped"]
    ]
    by_address: dict[Address, Client] = {c["address"]: c for c in clients}

    result: list[list[Entry]] = []
    placed: set[Address] = set()
    for client in clients:
        members = [by_address[a] for a in client["grouped"] if a in by_address]
        members = members or [client]
        if members[0]["address"] in placed:
            continue
        placed.add(members[0]["address"])
        result.append(
            [Entry(member, index, len(members)) for index, member in enumerate(members)]
        )
    return result


# Where the middle of the focused monitor falls, in the layout coordinates
# windows report their position in.
def middle(snapshot: Snapshot) -> float:
    monitor = next((m for m in snapshot.monitors if m["focused"]), None)
    if monitor is None:
        return 0.0
    width = monitor["height"] if monitor["transform"] % 2 else monitor["width"]
    return monitor["x"] + width / monitor["scale"] / 2


# Units taken innermost first while their tabs fit in `room`; the rest overflow.
def fill(
    inside_out: list[list[Entry]], room: int
) -> tuple[list[list[Entry]], list[Entry]]:
    kept: list[list[Entry]] = []
    spilled: list[Entry] = []
    for unit in inside_out:
        if len(unit) <= room:
            kept.append(unit)
            room -= len(unit)
        else:
            spilled.extend(unit)
    return kept, spilled


def flat(units: list[list[Entry]]) -> list[Entry]:
    return [entry for unit in units for entry in unit]


# The ghosts that make up a side that is `tabs` tabs and `gaps` gaps short,
# pairing them into solo ghosts where it can.
def ghosts(tabs: int, gaps: int) -> list[Ghost]:
    pairs = min(tabs, gaps)
    solo: list[Ghost] = ["solo"]
    tab: list[Ghost] = ["tab"]
    gap: list[Ghost] = ["gap"]
    return solo * pairs + tab * (tabs - pairs) + gap * (gaps - pairs)


def layout(snapshot: Snapshot) -> Layout:
    centre = middle(snapshot)
    master: list[list[Entry]] = []
    left: list[list[Entry]] = []
    right: list[list[Entry]] = []
    for unit in units(snapshot):
        client = unit[0].client
        x, width = client["at"][0], client["size"][0]
        if not client["floating"] and x <= centre < x + width:
            master.append(unit)
        elif x + width / 2 < centre:
            left.append(unit)
        else:
            right.append(unit)

    # Innermost first on both sides: nearest column first, and in a column the
    # top window first, so the bottom one -- the newest -- is at the edge.
    def at(unit: list[Entry]) -> tuple[int, int]:
        return unit[0].client["at"][0], unit[0].client["at"][1]

    master.sort(key=lambda u: at(u)[1])
    left.sort(key=lambda u: (-at(u)[0], at(u)[1]))
    right.sort(key=at)

    kept, spilled = fill(master, MASTER)
    centred = flat(kept)
    if len(master) == 1 and spilled:  # one group too big: show what fits
        centred, spilled = spilled[:MASTER], spilled[MASTER:]
    kept_left, spilled_left = fill(left, SIDE)
    kept_right, spilled_right = fill(right, SIDE)
    overflow = spilled + spilled_left + spilled_right

    # Each side fills outwards from the master: the left side is drawn
    # outermost first, so it is packed against the master's end of its slots.
    lefts = flat(kept_left[::-1])
    rights = flat(kept_right)
    slots: dict[int, Slot] = {}
    for slot, entry in zip(LEFT[len(LEFT) - len(lefts) :], lefts, strict=True):
        slots[slot] = entry
    for slot, entry in zip(CENTRE, centred, strict=False):
        slots[slot] = entry
    for slot, entry in zip(RIGHT, rights, strict=False):
        slots[slot] = entry

    # Placeholders, in the next slots out from each side's windows. An empty
    # workspace keeps none: there is no master yet to hold still.
    anything = bool(lefts or centred or rights)
    reserve_l = max(0, RESERVE - len(kept_left)) if anything else 0
    reserve_r = max(0, RESERVE - len(kept_right)) if anything else 0
    for i in range(reserve_l):
        slots[LEFT[len(LEFT) - len(lefts) - 1 - i]] = "solo"
    for i in range(reserve_r):
        slots[RIGHT[len(rights) + i]] = "solo"

    # A side is as wide as its tabs plus a pair of gaps per group, placeholders
    # included; the overflow button, at the end of the right side, is one more
    # of each.
    def span(entries: list[Entry], reserved: int) -> tuple[int, int]:
        groups = sum(1 for e in entries if e.tab == 0)
        return len(entries) + reserved, groups + reserved

    tabs_l, gaps_l = span(lefts, reserve_l)
    tabs_r, gaps_r = span(rights, reserve_r)
    if overflow:
        tabs_r, gaps_r = tabs_r + 1, gaps_r + 1
    left_pad = ghosts(max(0, tabs_r - tabs_l), max(0, gaps_r - gaps_l))
    right_pad = ghosts(max(0, tabs_l - tabs_r), max(0, gaps_l - gaps_r))
    for slot, ghost in zip(reversed(LEFT_GHOSTS), left_pad, strict=False):
        slots[slot] = ghost
    for slot, ghost in zip(RIGHT_GHOSTS, right_pad, strict=False):
        slots[slot] = ghost
    return Layout(slots, overflow)


def blank() -> ButtonState:
    return {"text": "", "class": [], "tooltip": ""}


def ghost_state(ghost: Ghost) -> ButtonState:
    classes: list[CssClass] = ["ghost"]
    if ghost != "tab":
        classes.append(ghost)
    # A zero-width space: waybar hides a button with no text at all.
    return {"text": "\u200b", "class": classes, "tooltip": ""}


def overflow_state(hidden: list[Entry]) -> ButtonState:
    if not hidden:
        return blank()

    lines = [f"<b>{len(hidden)} more window(s)</b>"]
    for entry in hidden[:OVERFLOW_LIST]:
        app = html.escape(app_name(entry.client))
        title = html.escape(shorten(label(entry.client), TOOLTIP_LEN))
        lines.append(f"<span alpha='60%'>{app}</span>  {title}")
    if len(hidden) > OVERFLOW_LIST:
        lines.append(f"<i>… {len(hidden) - OVERFLOW_LIST} more</i>")

    return {
        "text": f"+{len(hidden)}",
        "class": ["overflow"],
        "tooltip": "\n".join(lines),
    }


def window_state(
    entry: Entry,
    active: Address | None,
    locked: frozenset[Address],
    fresh: frozenset[Address],
    master: bool,
) -> ButtonState:
    client, index, size = entry

    classes: list[CssClass] = []
    if master:
        classes.append("master")
    if client["address"] in fresh:
        classes.append("fresh")
    if client["address"] == active:
        classes.append("active")
    elif client["visible"]:
        classes.append("shown")
    if client["floating"]:
        classes.append("floating")
    if size == 1:
        classes.append("solo")
    elif index == 0:
        classes.append("gstart")
    elif index == size - 1:
        classes.append("gend")
    else:
        classes.append("gmid")

    # Hyprland lists a group of one in its own `grouped`, so that is the test.
    is_grouped = bool(client["grouped"])
    if is_grouped:
        classes.append("grouped")
    is_locked = client["address"] in locked
    if is_locked:
        classes.append("locked")

    icon = ICONS.get((client["class"] or "").lower(), DEFAULT_ICON)
    budget = ACTIVE_LEN if "active" in classes else IDLE_LEN
    text = f"{icon}  {html.escape(shorten(label(client), budget))}"
    # The group marker belongs to the group, so it rides on the group's first
    # tab. That is what makes it visible on a group that is not the focused one.
    # Locking replaces it: a locked group is still a group.
    if index == 0 and (is_locked or is_grouped):
        text = f"{LOCK_ICON if is_locked else GROUP_ICON} {text}"

    lines = [f"<b>{html.escape(shorten(label(client), TOOLTIP_LEN))}</b>"]
    lines.append(f"<span alpha='60%'>{html.escape(app_name(client))}</span>")
    if size > 1:
        group = f"Group: tab {index + 1} of {size}"
        lines.append(f"{group} · locked" if is_locked else group)
    elif is_locked:
        lines.append("Locked group of one")
    elif is_grouped:
        lines.append("Group of one")

    return {"text": text, "class": classes, "tooltip": "\n".join(lines)}


def render(snapshot: Snapshot, fresh: frozenset[Address] = frozenset()) -> States:
    """Every window module, from one layout pass. Windows in `fresh` are drawn
    transparent, for a later render without them to fade in."""
    slots, overflow = layout(snapshot)
    states: States = {}
    for slot in range(1, SLOTS + 1):
        content = slots.get(slot)
        if content is None:
            states[f"win{slot}"] = blank()
        elif isinstance(content, Entry):
            states[f"win{slot}"] = window_state(
                content, snapshot.active, snapshot.locked, fresh, slot in CENTRE
            )
        else:
            states[f"win{slot}"] = ghost_state(content)
    states["winmore"] = overflow_state(overflow)

    # Both ends lose the same outer gap, so the sides stay balanced.
    drawn = [name for name in ORDER if states[name]["text"]]
    if drawn:
        states[drawn[0]]["class"].append("first")
        states[drawn[-1]]["class"].append("last")
    return states


def shown(snapshot: Snapshot) -> frozenset[Address]:
    """Every window with a button of its own."""
    return frozenset(
        c.client["address"]
        for c in layout(snapshot).slots.values()
        if isinstance(c, Entry)
    )


def address_at(snapshot: Snapshot, slot: int) -> Address | None:
    """The window a click on slot N means, or None for an empty slot or a ghost."""
    content = layout(snapshot).slots.get(slot)
    return content.client["address"] if isinstance(content, Entry) else None
