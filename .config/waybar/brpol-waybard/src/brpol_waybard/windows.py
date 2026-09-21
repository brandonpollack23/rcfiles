"""The per-window taskbar: one button per window on the focused monitor.

layout.py decides which window goes in which slot; this turns each slot into
the JSON its button draws. labels.py supplies the icons and titles.

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
  class "overflow"  custom/winmore, while there are windows without a slot
  class "first" / "last"   the two ends of the taskbar, ghosts included, whose
                           outer gap spaces them from nothing and is dropped
"""

import html
from typing import Final

from . import labels
from .layout import CENTRE, ORDER, SLOTS, Entry, Ghost, Layout
from .snapshot import Snapshot
from .types import Address, ButtonState, CssClass, EventName, ModuleName, States, blank

# Title budgets are in columns of the bar's monospaced font. With the icons in
# front, the longest label is 29 columns, which is what min-width in style.css
# is sized to; a wider label would break the equal widths the ghosts rely on.
TITLE_LEN: Final = 24
TOOLTIP_LEN: Final = 90
OVERFLOW_LIST: Final = 8

LOCK_ICON: Final = "󰌾"
GROUP_ICON: Final = "󰆏"

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


def ghost_state(ghost: Ghost) -> ButtonState:
    classes: list[CssClass] = ["ghost"]
    if ghost != "tab":
        classes.append(ghost)
    # A zero-width space: waybar hides a button with no text at all.
    return {"text": "​", "class": classes, "tooltip": ""}


def overflow_state(hidden: list[Entry]) -> ButtonState:
    """custom/winmore: a count, with the windows it stands for in the tooltip."""
    if not hidden:
        return blank()

    lines = [f"<b>{len(hidden)} more window(s)</b>"]
    for entry in hidden[:OVERFLOW_LIST]:
        title = labels.shorten(labels.title(entry.client), TOOLTIP_LEN)
        lines.append(labels.tooltip_row(labels.app_name(entry.client), title))
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
    client, tab, size = entry
    address = client["address"]
    # Hyprland lists a group of one in its own `grouped`, so that is the test.
    is_grouped = bool(client["grouped"])
    is_locked = address in locked

    # The classes, in the order style.css was written against.
    classes: list[CssClass] = []
    if master:
        classes.append("master")
    if address in fresh:
        classes.append("fresh")
    if address == active:
        classes.append("active")
    elif client["visible"]:
        classes.append("shown")
    if client["floating"]:
        classes.append("floating")
    if size == 1:
        classes.append("solo")
    elif tab == 0:
        classes.append("gstart")
    elif tab == size - 1:
        classes.append("gend")
    else:
        classes.append("gmid")
    if is_grouped:
        classes.append("grouped")
    if is_locked:
        classes.append("locked")

    # The label: icon and title. The group marker belongs to the group, so it
    # rides on the group's first tab. That is what makes it visible on a group
    # that is not the focused one. Locking replaces it: a locked group is
    # still a group.
    title = html.escape(labels.shorten(labels.title(client), TITLE_LEN))
    text = f"{labels.icon(client)}  {title}"
    if tab == 0 and (is_locked or is_grouped):
        text = f"{LOCK_ICON if is_locked else GROUP_ICON} {text}"

    # The tooltip: the fuller title, the application, and the group if any.
    long_title = html.escape(labels.shorten(labels.title(client), TOOLTIP_LEN))
    lines = [
        f"<b>{long_title}</b>",
        f"<span alpha='60%'>{html.escape(labels.app_name(client))}</span>",
    ]
    if size > 1:
        group = f"Group: tab {tab + 1} of {size}"
        lines.append(f"{group} · locked" if is_locked else group)
    elif is_locked:
        lines.append("Locked group of one")
    elif is_grouped:
        lines.append("Group of one")

    return {"text": text, "class": classes, "tooltip": "\n".join(lines)}


def render(
    snapshot: Snapshot, layout: Layout, fresh: frozenset[Address] = frozenset()
) -> States:
    """Every window module. Windows in `fresh` are drawn transparent, for a
    later render without them to fade in."""
    states: States = {}
    for slot in range(1, SLOTS + 1):
        content = layout.slots.get(slot)
        if content is None:
            states[f"win{slot}"] = blank()
        elif isinstance(content, Entry):
            states[f"win{slot}"] = window_state(
                content, snapshot.active, snapshot.locked, fresh, slot in CENTRE
            )
        else:
            states[f"win{slot}"] = ghost_state(content)
    states["winmore"] = overflow_state(layout.overflow)

    # Both ends lose the same outer gap, so the sides stay balanced.
    drawn = [name for name in ORDER if states[name]["text"]]
    if drawn:
        states[drawn[0]]["class"].append("first")
        states[drawn[-1]]["class"].append("last")
    return states
