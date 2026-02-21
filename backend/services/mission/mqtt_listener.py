"""MQTT listener for mission status/progress updates."""
from __future__ import annotations

import logging
from uuid import UUID

from backend.shared.database.postgres import get_postgres_session
from backend.shared.mqtt_runtime import get_mqtt
from backend.shared.schemas.mission import MissionStatus, MissionStatusUpdateRequest

from .service import update_mission_status

logger = logging.getLogger(__name__)


async def start_mission_status_listener() -> None:
    """Subscribe to mission status/progress topics and persist updates."""
    mqtt = await get_mqtt()

    async def _handle(topic: str, payload: dict) -> None:
        # Expected: aerocommand/{org_id}/mission/{vehicle_id}/status|progress
        parts = topic.split("/")
        if len(parts) < 5:
            return

        org_id, domain, vehicle_id, sub = parts[1], parts[2], parts[3], parts[4]
        if domain != "mission" or sub not in {"status", "progress"}:
            return

        mission_id = payload.get("mission_id")
        if not mission_id:
            return

        raw_status = payload.get("status") or payload.get("state")
        if not raw_status:
            return

        try:
            status = MissionStatus(raw_status)
        except Exception:
            logger.warning("Unknown mission status: %s", raw_status)
            return

        try:
            req = MissionStatusUpdateRequest(
                vehicle_id=UUID(vehicle_id),
                mission_id=UUID(mission_id),
                status=status,
                progress=payload.get("progress"),
                current_waypoint=payload.get("current_waypoint"),
            )
        except Exception as exc:
            logger.warning("Invalid mission status payload: %s", exc)
            return

        try:
            async for db in get_postgres_session():
                await update_mission_status(db, UUID(org_id), req)
                break
        except Exception as exc:
            logger.error("Mission status update failed: %s", exc)

    await mqtt.subscribe("aerocommand/+/mission/+/status", _handle)
    await mqtt.subscribe("aerocommand/+/mission/+/progress", _handle)
