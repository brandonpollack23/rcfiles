"""Fading a new window's button in, and holding the focus colours meanwhile.

A button cannot be animated from here: all the daemon can do is change a
button's classes, and style.css's `transition` animates the difference. So a
window that opens is drawn twice -- first with class "fresh", which is
transparent, and a moment later without it -- and GTK fades between the two.

If the new window also took the focus, the focus colours would jump to a button
that is still invisible. Instead the focus stays drawn on the window that had
it until the newcomer has faded in, and then the two cross-fade.

    t = 0            window opens      newcomer drawn "fresh"; focus held back
    t = FADE_DELAY                     newcomer drawn plainly, and fades in
    t = FOCUS_DELAY                    hold ends; focus drawn on the newcomer

This is the only state in the daemon that depends on what was drawn before,
which is why it lives apart from the renderers: they are pure functions of a
snapshot, and this decides what snapshot they are shown.
"""

import dataclasses
from typing import Final, NamedTuple

from .snapshot import Snapshot
from .types import Address

# A window that has just opened is first drawn transparent and redrawn opaque
# this much later, which style.css's opacity transition turns into a fade. Long
# enough that GTK has drawn a frame in between; a change inside one frame is
# not animated.
FADE_DELAY: Final = 0.025

# How long the fade takes: the `transition` on `#windows label` in style.css,
# for opacity and the focus colours alike. Keep the two in step.
FADE: Final = 0.125

# A window that opens focused does not take the focus colours until it has
# faded in; the old focus keeps them until then, and the two cross-fade.
FOCUS_DELAY: Final = FADE_DELAY + FADE


class Hold(NamedTuple):
    """The focus being drawn somewhere other than where it is."""

    focus: Address | None  # where it is drawn instead: where it was before
    newcomer: Address | None  # the window that opened focused
    until: float


class Fader:
    # The windows with a button after the last render, and the workspace they
    # were on: a window new to a workspace fades in, a workspace switched to
    # is simply drawn.
    buttons: frozenset[Address]
    workspace: int | None
    # Where the last render drew the focus. A hold keeps it there.
    drawn_focus: Address | None
    hold: Hold | None
    # When the "fresh" windows are due their second, opaque draw.
    redraw_at: float | None

    def __init__(self) -> None:
        self.buttons = frozenset()
        self.workspace = None
        self.drawn_focus = None
        self.hold = None
        self.redraw_at = None

    def step(
        self,
        state: Snapshot,
        buttons: frozenset[Address],
        workspace: int | None,
        now: float,
    ) -> tuple[Snapshot, frozenset[Address]]:
        """Called once per render with what is about to be drawn: the windows
        that have a button, and the workspace they are on.

        Returns the snapshot to draw, which is `state` with the focus moved
        back while a hold is on, and the windows to draw as "fresh".
        """
        # Whatever was fresh last time has a button by now, so any render at
        # all is its second draw, and the one that was scheduled is moot.
        self.redraw_at = None

        # A window is fresh if it has a button now and had none last time --
        # unless the workspace changed, where every window would qualify.
        fresh = buttons - self.buttons if workspace == self.workspace else frozenset()
        self.buttons, self.workspace = buttons, workspace

        # Fresh windows need their second draw, and one that opened focused
        # starts a hold. A hold already on is replaced: `drawn_focus` is where
        # that one was drawing the focus, so it carries over.
        if fresh:
            self.redraw_at = now + FADE_DELAY
            if state.active in fresh:
                self.hold = Hold(self.drawn_focus, state.active, now + FOCUS_DELAY)

        # The hold running out, or focus moving anywhere else, ends it.
        if self.hold is not None and (
            now >= self.hold.until or state.active != self.hold.newcomer
        ):
            self.hold = None

        if self.hold is not None:
            state = dataclasses.replace(state, active=self.hold.focus)
        self.drawn_focus = state.active
        return state, fresh

    def next_render(self) -> float | None:
        """When this next needs a render to happen, if it does."""
        due = [self.redraw_at, self.hold.until if self.hold else None]
        return min((t for t in due if t is not None), default=None)
