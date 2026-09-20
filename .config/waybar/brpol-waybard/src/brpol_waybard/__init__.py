"""The daemon behind every scripted waybar button in this config.

Waybar needs one process per button, so the bar still has 39 of them -- but they
are `cat` on a FIFO rather than 39 Python interpreters, each holding its own
subscription to Hyprland's event socket and each recomputing the whole layout to
keep one slice of it. This package is the one process that does the work.
"""
