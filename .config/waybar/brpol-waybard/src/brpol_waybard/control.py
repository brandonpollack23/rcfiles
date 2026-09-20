"""What a line on the control FIFO means.

scripts/ctl.sh is the only writer. It replaces both the SIGRTMIN+8 the taskbar
used to be poked with and the short-lived Python process every click used to
spawn:

    refresh        recompute; for the group changes Hyprland has no event for
    prime [name]   re-send what a button already shows, for a reader that has
                   only just attached; every button when no name is given
    focus <n>      focus the window in taskbar slot n
    toggle <n>     show or hide hidden-workspace slot n
"""

from collections.abc import Callable

from . import hidden, ipc, windows
from .fifos import Bar
from .snapshot import Snapshot


def apply(command: str, bar: Bar, snapshot_of: Callable[[], Snapshot]) -> bool:
    """Run one command. Returns True when the bar should be recomputed.

    `snapshot_of` is called only by the commands that need one, so a refresh
    does not pay for a snapshot it is about to take anyway.
    """
    verb, _, argument = command.strip().partition(" ")

    if verb == "refresh":
        return True

    if verb == "prime":
        bar.prime(argument or None)
        return False

    if verb in ("focus", "toggle"):
        try:
            slot = int(argument)
        except ValueError:
            return False
        if verb == "focus":
            address = windows.address_at(snapshot_of(), slot)
            if address is not None:
                ipc.focus_address(address)
        else:
            name = hidden.name_at(snapshot_of(), slot)
            if name is not None:
                ipc.toggle_special(name)
        # Both act through Hyprland, which reports back on the event socket.
        return False

    return False
