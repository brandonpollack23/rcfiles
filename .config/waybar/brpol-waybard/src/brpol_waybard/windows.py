"""The per-window taskbar: one entry per window on the focused monitor.

Entries are ordered the way the windows are laid out on screen, left to right,
with the tabs of a group kept together in tab order.

  class "active"    the focused window
  class "shown"     the tab its group is currently showing
  class "locked"    in a locked group; the lock icon rides on its first tab
  class "floating"
  class "solo" / "gstart" / "gmid" / "gend"   which tab of its group it is,
                                              which is what spaces groups apart
"""

import html
from typing import Final, NamedTuple

from .snapshot import Snapshot
from .types import Address, ButtonState, Client, CssClass, EventName, ModuleName, States

# Slots must match the number of custom/winN modules in windows.jsonc.
SLOTS: Final = 12
ACTIVE_LEN: Final = 34
IDLE_LEN: Final = 34
TOOLTIP_LEN: Final = 90
OVERFLOW_LIST: Final = 8

LOCK_ICON: Final = "󰌾"
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


def shorten(text: str, limit: int) -> str:
    return text if len(text) <= limit else text[: limit - 1].rstrip() + "…"


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


# Every window on the focused monitor, in layout order, as (client, tab index,
# group size). Group members all report the same position, so a group is placed
# once, where it sits, and its tabs follow in tab order.
def entries(snapshot: Snapshot) -> list[Entry]:
    monitor = next((m for m in snapshot.monitors if m["focused"]), None)
    if monitor is None:
        return []

    # A special workspace covers the monitor for as long as it is open.
    special = monitor["specialWorkspace"]
    workspace = special["id"] if special["name"] else monitor["activeWorkspace"]["id"]

    clients = [
        c for c in snapshot.clients if c["workspace"]["id"] == workspace and c["mapped"]
    ]
    by_address: dict[Address, Client] = {c["address"]: c for c in clients}

    result: list[Entry] = []
    placed: set[Address] = set()
    for client in sorted(clients, key=lambda c: (c["at"][0], c["at"][1])):
        members = [by_address[a] for a in client["grouped"] if a in by_address]
        members = members or [client]
        if members[0]["address"] in placed:
            continue
        placed.add(members[0]["address"])
        for index, member in enumerate(members):
            result.append(Entry(member, index, len(members)))
    return result


def blank() -> ButtonState:
    return {"text": "", "class": [], "tooltip": ""}


def overflow_state(items: list[Entry]) -> ButtonState:
    hidden = items[SLOTS:]
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
    items: list[Entry],
    slot: int,
    active: Address | None,
    locked: frozenset[Address],
) -> ButtonState:
    if slot > min(len(items), SLOTS):
        return blank()
    client, index, size = items[slot - 1]

    classes: list[CssClass] = []
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

    is_locked = client["address"] in locked
    if is_locked:
        classes.append("locked")

    icon = ICONS.get((client["class"] or "").lower(), DEFAULT_ICON)
    budget = ACTIVE_LEN if "active" in classes else IDLE_LEN
    text = f"{icon}  {html.escape(shorten(label(client), budget))}"
    # The lock belongs to the group, so it rides on the group's first tab. That
    # is what makes it visible on a group that is not the focused one.
    if is_locked and index == 0:
        text = f"{LOCK_ICON} {text}"

    lines = [f"<b>{html.escape(shorten(label(client), TOOLTIP_LEN))}</b>"]
    lines.append(f"<span alpha='60%'>{html.escape(app_name(client))}</span>")
    if size > 1:
        group = f"Group: tab {index + 1} of {size}"
        lines.append(f"{group} · locked" if is_locked else group)
    elif is_locked:
        lines.append("Locked group of one")

    return {"text": text, "class": classes, "tooltip": "\n".join(lines)}


def render(snapshot: Snapshot) -> States:
    """Every window module, from one layout pass."""
    items = entries(snapshot)
    states: States = {
        f"win{slot}": window_state(items, slot, snapshot.active, snapshot.locked)
        for slot in range(1, SLOTS + 1)
    }
    states["winmore"] = overflow_state(items)
    return states


def address_at(snapshot: Snapshot, slot: int) -> Address | None:
    """The window a click on slot N means, or None while that slot is empty."""
    items = entries(snapshot)
    if slot > min(len(items), SLOTS):
        return None
    return items[slot - 1].client["address"]
