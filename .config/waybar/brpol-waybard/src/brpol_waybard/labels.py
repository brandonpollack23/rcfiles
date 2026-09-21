"""What a window is called on the bar: its icon, its title, its application.

Everything here is text about a single window. Where that window goes on the
taskbar is layout.py's business, and what its button looks like is windows.py's.
"""

import html
import unicodedata
from typing import Final

from .types import Client

DEFAULT_ICON: Final = "󰖯"

# Keyed by window class, lower-cased.
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


def columns(char: str) -> int:
    """How many columns of a monospaced font `char` takes up."""
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
        if used > limit - 1:  # the last column is the ellipsis's
            break
        kept += char
    return kept.rstrip() + "…"


def icon(client: Client) -> str:
    return ICONS.get((client["class"] or "").lower(), DEFAULT_ICON)


def title(client: Client) -> str:
    """The window's title without the application's name on the end, falling
    back to its class when it has no title."""
    text = client["title"] or ""
    for suffix in SUFFIXES:
        if text.endswith(suffix):
            text = text[: -len(suffix)]
            break
    return text.strip() or client["class"] or "?"


def app_name(client: Client) -> str:
    name = client["class"] or "?"
    return NAMES.get(name.lower(), name)


def tooltip_row(app: str, title: str) -> str:
    """One window in a tooltip's list: the application, dimmed, then the title.
    Both are escaped here, so pass them raw."""
    return f"<span alpha='60%'>{html.escape(app)}</span>  {html.escape(title)}"
