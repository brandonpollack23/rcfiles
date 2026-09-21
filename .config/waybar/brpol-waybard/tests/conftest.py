"""Shared test setup.

ipc.py works out where Hyprland's sockets are as it is imported, so the two
variables it reads have to be in place before any test imports the package.
They point at a scratch directory: nothing here talks to a real Hyprland, and
the tests run the same inside a session or out of one. test_daemon.py puts a
fake Hyprland at the same paths.
"""

import os
import shutil
import tempfile

# Kept short: a unix socket path has to fit in 108 bytes.
RUNTIME_DIR = tempfile.mkdtemp(prefix="waybard-")
os.environ["XDG_RUNTIME_DIR"] = RUNTIME_DIR
os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = "test"
os.makedirs(os.path.join(RUNTIME_DIR, "hypr", "test"))


def pytest_sessionfinish() -> None:
    shutil.rmtree(RUNTIME_DIR, ignore_errors=True)
