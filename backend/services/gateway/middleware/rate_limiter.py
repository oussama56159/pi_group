"""
Token-bucket rate limiter backed by Redis.
Provides per-IP and per-user rate limiting.
"""
from __future__ import annotations

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

from backend.shared.database.redis import get_redis, RedisKeys

# Default limits
RATE_LIMIT_PER_MINUTE = 120
RATE_LIMIT_BURST = 30

# Lua script for atomic rate limiting (sliding window)
RATE_LIMIT_SCRIPT = """
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local now = tonumber(ARGV[3])

redis.call('ZREMRANGEBYSCORE', key, 0, now - window)
local count = redis.call('ZCARD', key)

if count < limit then
    redis.call('ZADD', key, now, now .. '-' .. math.random(1000000))
    redis.call('EXPIRE', key, window)
    return 0
else
    return 1
end
"""


class RateLimiterMiddleware(BaseHTTPMiddleware):
    """Sliding-window rate limiter using Redis sorted sets."""

    async def dispatch(self, request: Request, call_next):
        # Skip rate limiting for health checks
        if request.url.path.startswith("/health"):
            return await call_next(request)

        try:
            redis = get_redis()
        except RuntimeError:
            # Redis unavailable – allow request through
            return await call_next(request)

        # Determine rate-limit key: authenticated user or IP
        client_id = getattr(request.state, "user_id", None)
        if not client_id:
            client_id = request.client.host if request.client else "unknown"

        key = RedisKeys.rate_limit(client_id)

        import time
        now = int(time.time() * 1000)  # milliseconds
        window = 60_000  # 1-minute window

        try:
            blocked = await redis.eval(
                RATE_LIMIT_SCRIPT,
                1,
                key,
                RATE_LIMIT_PER_MINUTE,
                window,
                now,
            )
        except Exception:
            # Redis error – allow request
            return await call_next(request)

        if blocked:
            return JSONResponse(
                status_code=429,
                content={"detail": "Rate limit exceeded. Try again later."},
                headers={"Retry-After": "60"},
            )

        response = await call_next(request)
        return response

