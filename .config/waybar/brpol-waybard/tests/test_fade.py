"""Fader.step(): the timeline in fade.py's docstring, one render at a time."""

from brpol_waybard.fade import FADE_DELAY, FOCUS_DELAY, Fader
from brpol_waybard.snapshot import Snapshot
from brpol_waybard.types import Address
from builders import snap


def step(
    fader: Fader,
    buttons: set[Address],
    active: Address | None,
    now: float,
    workspace: int = 1,
) -> tuple[Address | None, frozenset[Address]]:
    """One render. Returns where the focus is drawn, and what is fresh."""
    state: Snapshot = snap([], active=active)
    drawn, fresh = fader.step(state, frozenset(buttons), workspace, now)
    return drawn.active, fresh


def settled(buttons: set[Address], active: Address | None) -> Fader:
    """A fader that has already drawn `buttons`, with nothing pending."""
    fader = Fader()
    step(fader, buttons, active, now=0.0)
    step(fader, buttons, active, now=1.0)
    assert fader.next_render() is None
    return fader


def test_the_first_render_fades_nothing_in() -> None:
    fader = Fader()
    assert step(fader, {"0xa", "0xb"}, "0xa", now=0.0) == ("0xa", frozenset())
    assert fader.next_render() is None


def test_a_new_window_is_fresh_for_one_render_and_asks_for_the_next() -> None:
    fader = settled({"0xa"}, active="0xa")

    assert step(fader, {"0xa", "0xb"}, "0xa", now=10.0) == ("0xa", frozenset({"0xb"}))
    assert fader.next_render() == 10.0 + FADE_DELAY

    assert step(fader, {"0xa", "0xb"}, "0xa", now=10.0 + FADE_DELAY) == (
        "0xa",
        frozenset(),
    )
    assert fader.next_render() is None


def test_any_earlier_render_counts_as_the_second_draw() -> None:
    fader = settled({"0xa"}, active="0xa")
    step(fader, {"0xa", "0xb"}, "0xa", now=10.0)
    step(fader, {"0xa", "0xb"}, "0xa", now=10.001)  # a debounced render got in first
    assert fader.next_render() is None


def test_switching_workspace_fades_nothing_in() -> None:
    fader = settled({"0xa"}, active="0xa")
    assert step(fader, {"0xb", "0xc"}, "0xb", now=10.0, workspace=2) == (
        "0xb",
        frozenset(),
    )
    assert fader.next_render() is None


def test_a_window_that_opens_focused_leaves_the_focus_drawn_where_it_was() -> None:
    fader = settled({"0xa"}, active="0xa")

    # It opens: drawn fresh, focus still on 0xa.
    assert step(fader, {"0xa", "0xb"}, "0xb", now=10.0) == ("0xa", frozenset({"0xb"}))
    assert fader.next_render() == 10.0 + FADE_DELAY

    # The second draw: fading in, focus still held; the hold is what is left.
    assert step(fader, {"0xa", "0xb"}, "0xb", now=10.0 + FADE_DELAY) == (
        "0xa",
        frozenset(),
    )
    assert fader.next_render() == 10.0 + FOCUS_DELAY

    # The hold runs out: focus is drawn where it really is.
    assert step(fader, {"0xa", "0xb"}, "0xb", now=10.0 + FOCUS_DELAY) == (
        "0xb",
        frozenset(),
    )
    assert fader.next_render() is None


def test_focus_moving_elsewhere_ends_the_hold_at_once() -> None:
    fader = settled({"0xa", "0xc"}, active="0xa")
    step(fader, {"0xa", "0xb", "0xc"}, "0xb", now=10.0)
    assert step(fader, {"0xa", "0xb", "0xc"}, "0xc", now=10.01) == ("0xc", frozenset())
    assert fader.next_render() is None


def test_a_second_newcomer_inherits_the_held_focus() -> None:
    fader = settled({"0xa"}, active="0xa")
    step(fader, {"0xa", "0xb"}, "0xb", now=10.0)
    # 0xc opens focused while 0xb's hold is on: focus stays drawn on 0xa, not
    # on 0xb, which never got to show it.
    assert step(fader, {"0xa", "0xb", "0xc"}, "0xc", now=10.05) == (
        "0xa",
        frozenset({"0xc"}),
    )
    assert fader.next_render() == 10.05 + FADE_DELAY


def test_a_new_window_that_is_not_focused_holds_nothing() -> None:
    fader = settled({"0xa"}, active="0xa")
    step(fader, {"0xa", "0xb"}, "0xa", now=10.0)
    assert fader.hold is None


def test_opening_the_first_window_holds_the_focus_on_nothing() -> None:
    fader = settled(set(), active=None)
    assert step(fader, {"0xa"}, "0xa", now=10.0) == (None, frozenset({"0xa"}))
    assert step(fader, {"0xa"}, "0xa", now=10.0 + FOCUS_DELAY) == ("0xa", frozenset())
