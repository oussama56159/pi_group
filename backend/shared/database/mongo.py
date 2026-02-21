"""MongoDB async client using Motor for telemetry time-series data."""
from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from backend.shared.config import get_base_settings

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def init_mongo() -> None:
    """Initialize Motor client and create indexes."""
    global _client, _db
    settings = get_base_settings()
    _client = AsyncIOMotorClient(
        settings.mongo_dsn,
        maxPoolSize=50,
        minPoolSize=10,
        serverSelectionTimeoutMS=5000,
    )
    _db = _client[settings.MONGO_DB]

    # ── Create indexes for telemetry collections ──
    telemetry = _db["telemetry"]
    await telemetry.create_index([("vehicle_id", 1), ("timestamp", -1)])
    await telemetry.create_index([("timestamp", 1)], expireAfterSeconds=30 * 24 * 3600)  # 30-day TTL

    # Flight logs collection
    flight_logs = _db["flight_logs"]
    await flight_logs.create_index([("vehicle_id", 1), ("started_at", -1)])
    await flight_logs.create_index([("organization_id", 1), ("started_at", -1)])

    # Audit log collection
    audit_log = _db["audit_log"]
    await audit_log.create_index([("user_id", 1), ("timestamp", -1)])
    await audit_log.create_index([("timestamp", 1)], expireAfterSeconds=90 * 24 * 3600)  # 90-day TTL


def get_mongo_db() -> AsyncIOMotorDatabase:
    """FastAPI dependency – returns the Motor database handle."""
    if _db is None:
        raise RuntimeError("MongoDB not initialized. Call init_mongo() first.")
    return _db


async def close_mongo() -> None:
    global _client, _db
    if _client:
        _client.close()
        _client = None
        _db = None

