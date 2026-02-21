"""Lightweight MAVLink definitions used by the edge agent.

This is intentionally minimal (no pymavlink dependency) and focuses on constants
we map to/from MQTT command payloads.

If you need the full MAVLink dialects, use `pymavlink` on the edge agent.
"""

from __future__ import annotations

import enum


class MAVCmd(int, enum.Enum):
    COMPONENT_ARM_DISARM = 400
    NAV_TAKEOFF = 22
    NAV_LAND = 21
    NAV_RETURN_TO_LAUNCH = 20
    NAV_LOITER_UNLIM = 17
    DO_SET_MODE = 176
    PREFLIGHT_REBOOT_SHUTDOWN = 246
    DO_REPOSITION = 192


class MAVResult(int, enum.Enum):
    ACCEPTED = 0
    TEMPORARILY_REJECTED = 1
    DENIED = 2
    UNSUPPORTED = 3
    FAILED = 4
    IN_PROGRESS = 5

