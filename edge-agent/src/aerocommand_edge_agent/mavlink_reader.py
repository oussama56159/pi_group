from __future__ import annotations

import time
from dataclasses import dataclass

from pymavlink import mavutil


@dataclass
class MavlinkMessage:
    name: str
    data: dict
    timestamp: float


class MavlinkReader:
    def __init__(self, connection: str, baud: int, source_system: int = 255) -> None:
        self.connection = connection
        self.baud = baud
        self.source_system = source_system
        self._master: mavutil.mavfile | None = None

    def connect(self) -> None:
        self._master = mavutil.mavlink_connection(
            self.connection,
            baud=self.baud,
            source_system=self.source_system,
            autoreconnect=True,
        )

        # Wait for heartbeat so we know the link is alive.
        self._master.wait_heartbeat(timeout=30)

    def recv(self, timeout: float = 1.0) -> MavlinkMessage | None:
        if self._master is None:
            raise RuntimeError("MavlinkReader not connected")

        msg = self._master.recv_match(blocking=True, timeout=timeout)
        if msg is None:
            return None

        try:
            data = msg.to_dict()
        except Exception:
            data = {}

        return MavlinkMessage(name=msg.get_type(), data=data, timestamp=time.time())
