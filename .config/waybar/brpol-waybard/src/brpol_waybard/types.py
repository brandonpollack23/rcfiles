"""The shapes Hyprland's `j/` replies come back in, and the one the bar reads.

Only the fields the 39 buttons actually touch are declared; Hyprland sends a
good deal more, and anything not listed here is deliberately not depended on.

`class` is a keyword, so the two payloads that carry one -- a window and a
button -- are written in the functional TypedDict form rather than as a class.
"""

from typing import Literal, TypedDict

type Address = str
"""A window handle the way Hyprland prints it: `0x` followed by hex."""

type ModuleName = str
"""A waybar module name: `win3`, `winmore`, `ws7`, `hidden`, `hidden1`."""

type EventName = Literal[
    "activespecial",
    "activewindowv2",
    "changefloatingmode",
    "closewindow",
    "createworkspacev2",
    "destroyworkspacev2",
    "focusedmonv2",
    "fullscreen",
    "monitoradded",
    "monitorremoved",
    "movewindowv2",
    "moveworkspacev2",
    "openwindow",
    "renameworkspace",
    "urgent",
    "windowtitlev2",
    "workspacev2",
]
"""Every line name on `.socket2.sock` this daemon acts on.

Naming them makes a typo in one of the three EVENTS sets a type error rather
than a button that quietly stops updating.
"""

type CssClass = Literal[
    # windows.py
    "active",
    "shown",
    "floating",
    "solo",
    "gstart",
    "gmid",
    "gend",
    "grouped",
    "locked",
    "overflow",
    "master",
    "fresh",
    "ghost",
    "gap",
    "first",
    "last",
    # workspaces.py
    "visible",
    "urgent",
    "empty",
    # hidden.py
    "hidden",
]
"""Every class the bar's CSS styles. Same reasoning as EventName: style.css and
these renderers have to agree, and nothing else checks that they do.
"""

type Verb = Literal["refresh", "prime", "focus", "toggle"]
"""What scripts/ctl.sh may write to the control FIFO."""


class WorkspaceRef(TypedDict):
    """How a workspace is named from inside a client or a monitor."""

    id: int
    name: str


class Monitor(TypedDict):
    focused: bool
    x: int
    width: int  # physical pixels, before scale and transform
    height: int
    scale: float
    transform: int  # odd values are rotated a quarter turn
    activeWorkspace: WorkspaceRef
    specialWorkspace: WorkspaceRef  # `name` is "" while none is open


class Workspace(TypedDict):
    id: int
    name: str
    windows: int


Client = TypedDict(
    "Client",
    {
        "address": Address,
        "class": str,
        "title": str,
        "workspace": WorkspaceRef,
        "at": list[int],  # [x, y]; the taskbar's left-to-right order
        "size": list[int],  # [width, height], in layout coordinates like `at`
        "mapped": bool,
        "visible": bool,
        "floating": bool,
        "grouped": list[Address],  # every tab of its group, in tab order
        "focusHistoryID": int,
    },
)

ButtonState = TypedDict(
    "ButtonState",
    {
        "text": str,
        "class": list[CssClass],
        "tooltip": str,
    },
)
"""One line of waybar JSON: what a single button draws."""

type States = dict[ModuleName, ButtonState]
"""Every button a renderer produced, by module name."""
