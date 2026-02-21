"""Startup auth seeding helpers."""
from __future__ import annotations

import os
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from backend.shared.schemas.auth import Role
from .models import Organization, User
from .security import hash_password

DEFAULT_OWNER_EMAIL = "owner@makerskills.com"
DEFAULT_OWNER_PASSWORD = "change_me_owner_password"
DEFAULT_OWNER_NAME = "MakerSkills Owner"
DEFAULT_ORG_NAME = "AeroCommand HQ"
DEFAULT_ORG_SLUG = "aerocommand"


def _get_env(name: str, default: str) -> str:
    value = os.getenv(name)
    return value.strip() if value and value.strip() else default


async def ensure_dev_admin(db: AsyncSession) -> None:
    """Backwards-compatible alias for owner seeding."""
    await ensure_owner_account(db)


async def ensure_auth_runtime_schema(db: AsyncSession) -> None:
    """Apply lightweight schema updates for dev environments with existing DB volumes."""
    await db.execute(text("ALTER TABLE users ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ"))
    await db.execute(text("ALTER TABLE organizations ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ"))


def _get_bool_env(name: str, default: bool) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


async def ensure_owner_account(db: AsyncSession) -> None:
    """Create a single owner account (and optionally seed first org)."""
    if not _get_bool_env("SEED_OWNER_ENABLED", True):
        return

    owner_email = _get_env("OWNER_EMAIL", DEFAULT_OWNER_EMAIL).lower()
    owner_password = _get_env("OWNER_PASSWORD", DEFAULT_OWNER_PASSWORD)
    owner_name = _get_env("OWNER_NAME", DEFAULT_OWNER_NAME)
    owner_create_org = _get_bool_env("OWNER_CREATE_ORG", False)
    org_name = _get_env("OWNER_ORG_NAME", DEFAULT_ORG_NAME)
    org_slug = _get_env("OWNER_ORG_SLUG", DEFAULT_ORG_SLUG)

    existing_user = (await db.execute(select(User).where(User.email == owner_email))).scalar_one_or_none()
    if existing_user:
        changed = False
        if existing_user.role != Role.SUPER_ADMIN:
            existing_user.role = Role.SUPER_ADMIN
            changed = True
        if not existing_user.is_active:
            existing_user.is_active = True
            changed = True
        if not existing_user.is_verified:
            existing_user.is_verified = True
            changed = True

        # Important: by default we do NOT mutate an existing user's password.
        # Opt-in reset for dev environments with persistent volumes.
        if _get_bool_env("SEED_OWNER_UPDATE_PASSWORD", False) or _get_bool_env("OWNER_UPDATE_PASSWORD", False):
            existing_user.hashed_password = hash_password(owner_password)
            changed = True

        if owner_create_org and existing_user.organization_id is None:
            org = (await db.execute(select(Organization).where(Organization.slug == org_slug))).scalar_one_or_none()
            if not org:
                org = Organization(
                    name=org_name,
                    slug=org_slug,
                    is_active=True,
                    created_at=datetime.now(timezone.utc),
                )
                db.add(org)
                await db.flush()
            existing_user.organization_id = org.id
            changed = True
        if changed:
            await db.flush()
        return

    org = None
    if owner_create_org:
        org = (await db.execute(select(Organization).where(Organization.slug == org_slug))).scalar_one_or_none()
        if not org:
            org = Organization(
                name=org_name,
                slug=org_slug,
                is_active=True,
                created_at=datetime.now(timezone.utc),
            )
            db.add(org)
            await db.flush()

    user = User(
        email=owner_email,
        hashed_password=hash_password(owner_password),
        name=owner_name,
        role=Role.SUPER_ADMIN,
        organization_id=org.id if org else None,
        is_active=True,
        is_verified=True,
        created_at=datetime.now(timezone.utc),
    )
    db.add(user)
    await db.flush()
