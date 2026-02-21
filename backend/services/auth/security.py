"""
Security utilities – password hashing, JWT creation, token validation.
"""
from __future__ import annotations

import secrets
import uuid
from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext

from backend.shared.config import get_base_settings
from backend.shared.schemas.auth import Role, TokenPayload

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(
    user_id: str,
    role: Role,
    org_id: str | None = None,
) -> tuple[str, str, int]:
    """
    Create a JWT access token.
    Returns: (token, jti, expires_in_seconds)
    """
    settings = get_base_settings()
    jti = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    expires_delta = timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    expire = now + expires_delta

    payload = TokenPayload(
        sub=user_id,
        role=role,
        org_id=org_id,
        exp=int(expire.timestamp()),
        iat=int(now.timestamp()),
        jti=jti,
    )

    token = jwt.encode(
        payload.model_dump(),
        settings.JWT_SECRET_KEY,
        algorithm=settings.JWT_ALGORITHM,
    )
    return token, jti, int(expires_delta.total_seconds())


def create_refresh_token(user_id: str) -> tuple[str, str]:
    """
    Create a JWT refresh token.
    Returns: (token, jti)
    """
    settings = get_base_settings()
    jti = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    expire = now + timedelta(days=settings.JWT_REFRESH_TOKEN_EXPIRE_DAYS)

    payload = {
        "sub": user_id,
        "exp": int(expire.timestamp()),
        "iat": int(now.timestamp()),
        "jti": jti,
        "type": "refresh",
    }

    token = jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return token, jti


def decode_token(token: str) -> dict:
    """Decode and validate a JWT token."""
    settings = get_base_settings()
    return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])


def generate_api_key() -> tuple[str, str, str]:
    """
    Generate an API key.
    Returns: (full_key, prefix, hashed_key)
    """
    raw_key = secrets.token_urlsafe(48)
    prefix = raw_key[:8]
    hashed = pwd_context.hash(raw_key)
    return raw_key, prefix, hashed

