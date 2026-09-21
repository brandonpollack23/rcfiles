"""What a line on the control FIFO means.

scripts/ctl.sh is the only writer. It replaces both the SIGRTMIN+8 the taskbar
used to be poked with and the short-lived Python process every click used to
spawn:

    refresh        recompute; for the group changes Hyprland has no event for
    prime [name]   re-send what a button already shows, for a reader that has
                   only just attached; every button when no name is given
    focus <n>      focus the window in taskbar slot n
    toggle <n>     show or hide hidden-workspace slot n
    nightlight     night light on or off
    ping-phone     make the KDE Connect phone ring
"""

from . import hidden, ipc, layout, snapshot
from .fifos import Bar
from .status import Status


def apply(command: str, bar: Bar, status: Status) -> bool:
    """Run one command. Returns True when the bar should be recomputed.

    Anything malformed is ignored: a click is not worth a traceback.
    """
    verb, _, argument = command.strip().partition(" ")

    match verb:
        case "refresh":
            return True

        case "prime":
            bar.prime(argument or None)

        # A click names a slot, and what is in that slot is only known from a
        # snapshot. Both act through Hyprland, which reports the change back on
        # the event socket, so neither asks for a recompute itself.
        case "focus" if argument.isdecimal():
            taskbar = layout.arrange(snapshot.take())
            address = taskbar.address_at(int(argument))
            if address is not None:
                ipc.focus_address(address)

        case "toggle" if argument.isdecimal():
            name = hidden.name_at(snapshot.take(), int(argument))
            if name is not None:
                ipc.toggle_special(name)

        # hyprsunset reports nothing back, so the button is redrawn from here.
        case "nightlight":
            bar.publish(status.toggle_nightlight())

        case "ping-phone":
            status.ping_phone()

    return False
