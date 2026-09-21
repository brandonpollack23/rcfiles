"""A stand-in for Hyprland's two sockets, at the paths ipc.py looks for them.

Answers the `j/` queries and the lockedAddresses() REPL call from whatever is
in its fields at the time, keeps every request it was sent, and lets a test
write lines to the event socket. Runs on a thread of its own.
"""

import contextlib
import json
import os
import select
import socket
import threading

from brpol_waybard import ipc
from brpol_waybard.types import Address, Client, Monitor, Workspace
from builders import monitor


class FakeHyprland:
    monitors: list[Monitor]
    clients: list[Client]
    workspaces: list[Workspace]
    active: Address | None
    locked: list[Address]
    requests: list[str]

    def __init__(self) -> None:
        self.monitors = [monitor()]
        self.clients = []
        self.workspaces = [{"id": 1, "name": "1", "windows": 0}]
        self.active = None
        self.locked = []
        self.requests = []

        self._subscribers: list[socket.socket] = []
        self._request_listener = self._listen(ipc.REQUEST_SOCKET)
        self._event_listener = self._listen(ipc.EVENT_SOCKET)
        self._stopping = threading.Event()
        self._thread = threading.Thread(target=self._serve, daemon=True)
        self._thread.start()

    @staticmethod
    def _listen(path: str) -> socket.socket:
        with contextlib.suppress(FileNotFoundError):
            os.unlink(path)
        listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        listener.bind(path)
        listener.listen()
        return listener

    def _serve(self) -> None:
        listeners = [self._request_listener, self._event_listener]
        while not self._stopping.is_set():
            ready, _, _ = select.select(listeners, [], [], 0.05)
            for listener in ready:
                connection, _ = listener.accept()
                if listener is self._event_listener:
                    self._subscribers.append(connection)
                else:
                    with connection:
                        message = connection.recv(65536).decode()
                        self.requests.append(message)
                        connection.sendall(self._reply(message).encode())

    def _reply(self, message: str) -> str:
        match message:
            case "j/monitors":
                return json.dumps(self.monitors)
            case "j/clients":
                return json.dumps(self.clients)
            case "j/workspaces":
                return json.dumps(self.workspaces)
            case "j/activewindow":
                focused = [c for c in self.clients if c["address"] == self.active]
                return json.dumps(focused[0] if focused else {})
            case _ if "lockedAddresses" in message:
                return " ".join(self.locked)
            case _:
                return "ok"

    def renders(self) -> int:
        """How many snapshots have been taken: each asks for the clients once."""
        return self.requests.count("j/clients")

    def emit(self, text: str) -> None:
        """Write to the event socket exactly as given, newline or not."""
        for subscriber in self._subscribers:
            subscriber.sendall(text.encode())

    def hang_up(self) -> None:
        """Close the event socket, as Hyprland exiting would."""
        for subscriber in self._subscribers:
            subscriber.close()
        self._subscribers.clear()

    def stop(self) -> None:
        self._stopping.set()
        self._thread.join()
        self.hang_up()
        for listener in (self._request_listener, self._event_listener):
            listener.close()
