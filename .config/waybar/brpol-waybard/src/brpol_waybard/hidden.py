"""Buttons for the hidden (special) workspaces.

  slot None   the default special:Hidden scratchpad
  slot N      the Nth other hidden workspace, 1-based

A slot with no workspace prints empty text, which hides the module. Slots are
the special workspaces other than DEFAULT, ascending by name -- the same rule
conf/workspaces/hidden.lua uses to label them H1, H2, ... in the picker, so a
button and its picker row always mean the same workspace.

  class "hidden"  every button here, for the shared teal styling
  class "shown"   the workspace is open on a monitor
  class "empty"   no windows on it
"""

from collections.abc import Mapping
from typing import Final

from .snapshot import Snapshot
from .types import (
    ButtonState,
    CssClass,
    EventName,
    ModuleName,
    States,
    Workspace,
    blank,
)

# Slots must match the number of custom/hiddenN modules in workspaces.jsonc.
SLOTS: Final = 5
DEFAULT: Final = "Hidden"
PREFIX: Final = "special:"
ICON: Final = "󰘓"

EVENTS: Final[frozenset[EventName]] = frozenset(
    {
        "activespecial",
        "openwindow",
        "closewindow",
        "movewindowv2",
        "createworkspacev2",
        "destroyworkspacev2",
        "renameworkspace",
    }
)

MODULES: Final[list[ModuleName]] = ["hidden"] + [
    f"hidden{slot}" for slot in range(1, SLOTS + 1)
]


def specials(snapshot: Snapshot) -> dict[str, Workspace]:
    """Every special workspace right now, by bare name."""
    return {
        w["name"][len(PREFIX) :]: w
        for w in snapshot.workspaces
        if w["name"].startswith(PREFIX)
    }


def slot_name(open_: Mapping[str, Workspace], slot: int) -> str | None:
    """The workspace a numbered button stands for, or None while it has none."""
    names = sorted(name for name in open_ if name != DEFAULT)
    return names[slot - 1] if 1 <= slot <= len(names) else None


def state(snapshot: Snapshot, slot: int | None) -> ButtonState:
    open_ = specials(snapshot)
    name = DEFAULT if slot is None else slot_name(open_, slot)
    if name is None:
        return blank()

    # The default scratchpad has a button even while its workspace does not
    # exist, which is whenever nothing is on it.
    workspace = open_.get(name)
    windows = workspace["windows"] if workspace else 0
    shown = any(
        m["specialWorkspace"]["name"] == PREFIX + name for m in snapshot.monitors
    )

    # The default scratchpad is labelled by how much is in it, the others by
    # their name.
    if slot is None:
        text = f"{ICON}  {windows}" if windows else ICON
    else:
        text = f"{ICON}  {name}"
    plural = "" if windows == 1 else "s"
    classes: list[CssClass] = ["hidden"]
    if shown:
        classes.append("shown")
    if not windows:
        classes.append("empty")
    return {
        "text": text,
        "class": classes,
        "tooltip": f"{name}: {windows} window{plural}",
    }


def render(snapshot: Snapshot) -> States:
    """Every hidden-workspace module."""
    states: States = {"hidden": state(snapshot, None)}
    for slot in range(1, SLOTS + 1):
        states[f"hidden{slot}"] = state(snapshot, slot)
    return states


def name_at(snapshot: Snapshot, slot: int) -> str | None:
    """The workspace a click on hidden slot N means, or None while it has none."""
    return slot_name(specials(snapshot), slot)
