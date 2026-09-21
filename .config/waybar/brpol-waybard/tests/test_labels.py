from brpol_waybard import labels
from builders import client


def width(text: str) -> int:
    return sum(map(labels.columns, text))


def test_columns_counts_wide_and_combining_characters() -> None:
    assert labels.columns("a") == 1
    assert labels.columns("漢") == 2
    assert labels.columns("́") == 0  # a combining acute accent


def test_shorten_leaves_text_that_fits_alone() -> None:
    assert labels.shorten("x" * 24, 24) == "x" * 24


def test_shorten_cuts_to_the_limit_with_an_ellipsis() -> None:
    assert labels.shorten("x" * 25, 24) == "x" * 23 + "…"


def test_shorten_counts_columns_not_characters() -> None:
    short = labels.shorten("漢字" * 20, 24)
    assert short.endswith("…")
    assert width(short) <= 24
    # 11 wide characters are 22 columns; a 12th would leave no room for "…".
    assert short == "漢字" * 5 + "漢…"


def test_shorten_does_not_leave_a_space_before_the_ellipsis() -> None:
    assert labels.shorten("ab cd", 4) == "ab…"


def test_title_drops_the_application_suffix() -> None:
    assert labels.title(client("0x1", title="Docs - Google Chrome")) == "Docs"
    assert labels.title(client("0x1", title="Inbox — Mozilla Firefox")) == "Inbox"


def test_title_falls_back_to_the_class_then_a_question_mark() -> None:
    assert labels.title(client("0x1", title="", cls="kitty")) == "kitty"
    assert labels.title(client("0x1", title="", cls="")) == "?"
    # A title that is nothing but the suffix is no title either.
    chrome = client("0x1", title=" - Google Chrome", cls="google-chrome")
    assert labels.title(chrome) == "google-chrome"


def test_icon_and_app_name_ignore_case_and_have_defaults() -> None:
    code = client("0x1", cls="Code")
    assert labels.icon(code) == labels.ICONS["code"]
    assert labels.app_name(code) == "VS Code"

    unknown = client("0x1", cls="weird.app")
    assert labels.icon(unknown) == labels.DEFAULT_ICON
    assert labels.app_name(unknown) == "weird.app"
    assert labels.app_name(client("0x1", cls="")) == "?"


def test_tooltip_row_escapes_both_halves() -> None:
    row = labels.tooltip_row("a&b", "<i>title</i>")
    assert "a&amp;b" in row
    assert "&lt;i&gt;title&lt;/i&gt;" in row
