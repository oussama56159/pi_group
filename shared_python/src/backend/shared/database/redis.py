"""Redis async client for caching, pub/sub, and session management."""
from __future__ import annotations

import redis.asyncio as aioredis

from backend.shared.config import get_base_settings

_redis: aioredis.Redis | None = None


# ── Redis Key Patterns ──
class RedisKeys:
    """
    Centralized Redis key patterns.

    Key Architecture:
        aero:session:{user_id}          → JWT session data (hash)
        aero:token:blacklist:{jti}      → Revoked token (string, TTL)
        aero:telemetry:{vehicle_id}     → Latest telemetry snapshot (hash)
        aero:vehicle:status:{vehicle_id}→ Vehicle online status (string, TTL)
        aero:heartbeat:{vehicle_id}     → Last heartbeat timestamp (string, TTL)
        aero:rate_limit:{client_ip}     → Rate limit counter (string, TTL)
        aero:command:{command_id}       → Command status tracking (hash)
        aero:lock:{resource}            → Distributed lock (string, TTL)
        aero:cache:{key}                → General cache (string, TTL)
        aero:ws:connections             → WebSocket connection count (string)
        aero:fleet:{fleet_id}:vehicles  → Set of vehicle IDs in fleet (set)
    """

    @staticmethod
    def session(user_id: str) -> str:
        return f"aero:session:{user_id}"

    @staticmethod
    def token_blacklist(jti: str) -> str:
        return f"aero:token:blacklist:{jti}"

    @staticmethod
    def telemetry(vehicle_id: str) -> str:
        return f"aero:telemetry:{vehicle_id}"

    @staticmethod
    def vehicle_status(vehicle_id: str) -> str:
        return f"aero:vehicle:status:{vehicle_id}"

    @staticmethod
    def heartbeat(vehicle_id: str) -> str:
        return f"aero:heartbeat:{vehicle_id}"

    @staticmethod
    def rate_limit(client_ip: str) -> str:
        return f"aero:rate_limit:{client_ip}"

    @staticmethod
    def command(command_id: str) -> str:
        return f"aero:command:{command_id}"

    @staticmethod
    def lock(resource: str) -> str:
        return f"aero:lock:{resource}"

    @staticmethod
    def fleet_vehicles(fleet_id: str) -> str:
        return f"aero:fleet:{fleet_id}:vehicles"


async def init_redis() -> None:
    global _redis
    settings = get_base_settings()
    _redis = aioredis.from_url(
        settings.redis_url,
        encoding="utf-8",
        decode_responses=True,
        max_connections=50,
    )
    await _redis.ping()


def get_redis() -> aioredis.Redis:
    if _redis is None:
        raise RuntimeError("Redis not initialized. Call init_redis() first.")
    return _redis


async def close_redis() -> None:
    global _redis
    if _redis:
        await _redis.close()
        _redis = None

