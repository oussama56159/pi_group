"""Authentication & authorization schemas."""
from __future__ import annotations

import enum
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

__all__ = [
    "Role",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "LoginRequest",
    "LoginResponse",
    "TokenPayload",
    "TokenRefreshRequest",
    "TokenRefreshResponse",
    "APIKeyCreate",
    "APIKeyResponse",
]


class Role(str, enum.Enum):
    SUPER_ADMIN = "super_admin"
    ADMIN = "admin"
    PILOT = "pilot"
    OPERATOR = "operator"
    VIEWER = "viewer"


ROLE_HIERARCHY: dict[Role, int] = {
    Role.SUPER_ADMIN: 5,
    Role.ADMIN: 4,
    Role.PILOT: 3,
    Role.OPERATOR: 2,
    Role.VIEWER: 1,
}


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(min_length=1, max_length=255)
    role: Role = Role.VIEWER
    organization_id: UUID | None = None


class UserUpdate(BaseModel):
    name: str | None = None
    role: Role | None = None
    is_active: bool | None = None
    organization_id: UUID | None = None


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str
    role: Role
    organization_id: UUID | None
    is_active: bool
    created_at: datetime
    last_login: datetime | None

    model_config = {"from_attributes": True}


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: UserResponse


class TokenPayload(BaseModel):
    sub: str  # user_id
    role: Role
    org_id: str | None = None
    exp: int
    iat: int
    jti: str  # unique token id for revocation


class TokenRefreshRequest(BaseModel):
    refresh_token: str


class TokenRefreshResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class APIKeyCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    scopes: list[str] = Field(default_factory=list)
    expires_in_days: int | None = None


class APIKeyResponse(BaseModel):
    id: UUID
    name: str
    prefix: str  # first 8 chars for identification
    scopes: list[str]
    created_at: datetime
    expires_at: datetime | None
    last_used_at: datetime | None
    is_active: bool

    model_config = {"from_attributes": True}

