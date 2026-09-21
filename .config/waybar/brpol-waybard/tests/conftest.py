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

import pytest

# Kept short: a unix socket path has to fit in 108 bytes.
RUNTIME_DIR = tempfile.mkdtemp(prefix="waybard-")
os.environ["XDG_RUNTIME_DIR"] = RUNTIME_DIR
os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = "test"
os.makedirs(os.path.join(RUNTIME_DIR, "hypr", "test"))


def pytest_sessionfinish() -> None:
    shutil.rmtree(RUNTIME_DIR, ignore_errors=True)


@pytest.fixture(autouse=True)
def no_real_status_sources(monkeypatch: pytest.MonkeyPatch) -> None:
    """status.py finds piactl, curl, gdbus, KDE Connect, l1p0-menus' config and
    hyprcap's PID file on the machine it runs on. A test that wants one puts a
    stand-in there itself."""
    from brpol_waybard import status

    monkeypatch.setattr(status, "PIACTL", None)
    monkeypatch.setattr(status, "CURL", None)
    monkeypatch.setattr(status, "GDBUS", None)
    monkeypatch.setattr(status, "KDECONNECT_CLI", None)
    monkeypatch.setattr(status, "CONFIG", os.path.join(RUNTIME_DIR, "no-config.json"))
    monkeypatch.setattr(
        status, "REC_PID", os.path.join(RUNTIME_DIR, "no-recording.pid")
    )
