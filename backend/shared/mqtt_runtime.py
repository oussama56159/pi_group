"""Singleton MQTT service instance for publishing/subscribing across services."""
from __future__ import annotations

import asyncio
from typing import Optional

from backend.shared.mqtt_client import MQTTService

_mqtt: Optional[MQTTService] = None


async def get_mqtt() -> MQTTService:
    global _mqtt
    if _mqtt is None:
        _mqtt = MQTTService(client_id="gateway")
        await _mqtt.start()
    return _mqtt


async def close_mqtt() -> None:
    """Stop the singleton MQTT service (if started)."""
    global _mqtt
    if _mqtt is None:
        return

    mqtt = _mqtt
    _mqtt = None
    try:
        await mqtt.stop()
    except asyncio.CancelledError:
        raise
    except Exception:
        # Best-effort cleanup; shutdown should continue even if MQTT stop fails.
        pass
