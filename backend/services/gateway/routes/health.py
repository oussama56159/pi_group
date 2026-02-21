"""
Health-check endpoints for the API Gateway.
/health       – basic liveness
/health/ready – readiness (checks all downstream services)
/health/live  – Kubernetes liveness probe
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timezone

from fastapi import APIRouter

from backend.shared.database.redis import get_redis
from backend.shared.database.mongo import get_mongo_db

router = APIRouter(prefix="/health")


@router.get("")
async def health():
    """Basic health check."""
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


@router.get("/live")
async def liveness():
    """Kubernetes liveness probe."""
    return {"status": "alive"}


@router.get("/ready")
async def readiness():
    """
    Deep readiness check – validates connectivity to all downstream services.
    Returns 503 if any critical dependency is unhealthy.
    """
    checks = {}

    # Redis check
    try:
        redis = get_redis()
        await asyncio.wait_for(redis.ping(), timeout=2.0)
        checks["redis"] = {"status": "up"}
    except Exception as e:
        checks["redis"] = {"status": "down", "error": str(e)}

    # MongoDB check
    try:
        db = get_mongo_db()
        await asyncio.wait_for(db.command("ping"), timeout=2.0)
        checks["mongodb"] = {"status": "up"}
    except Exception as e:
        checks["mongodb"] = {"status": "down", "error": str(e)}

    all_up = all(c["status"] == "up" for c in checks.values())
    status_code = 200 if all_up else 503

    from fastapi.responses import JSONResponse
    return JSONResponse(
        status_code=status_code,
        content={
            "status": "ready" if all_up else "degraded",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "checks": checks,
        },
    )

