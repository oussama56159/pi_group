"""
Auth REST API routes.
"""
from __future__ import annotations

from pydantic import BaseModel, Field
from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession

from backend.shared.config import get_base_settings
from backend.shared.email import EmailSendError, send_email_smtp
from backend.shared.database.postgres import get_postgres_session
from backend.shared.schemas.auth import (
    LoginRequest,
    LoginResponse,
    OrganizationCreate,
    OrganizationResponse,
    OrganizationUpdate,
    TokenRefreshRequest,
    TokenRefreshResponse,
    UserCreate,
    UserUpdate,
    UserResponse,
)

from .dependencies import CurrentUser, RequireRole
from backend.shared.schemas.auth import Role
from .service import (
    create_organization_by_owner,
    create_user_by_admin,
    deactivate_organization_by_owner,
    deactivate_user_by_admin,
    get_organization_for_actor,
    get_user_for_actor,
    list_organizations_for_actor,
    list_users_for_actor,
    login_user,
    logout_user,
    refresh_tokens,
    update_organization_by_owner,
    update_user_by_admin,
    update_user_password_by_admin,
)

router = APIRouter()


class _PasswordUpdateRequest(BaseModel):
    password: str = Field(min_length=8, max_length=128)


class _PasswordRecoveryRequest(BaseModel):
    email: str = Field(min_length=3, max_length=320)
    message: str = Field(min_length=10, max_length=4000)


@router.post("/password-recovery-request")
async def password_recovery_request(payload: _PasswordRecoveryRequest, request: Request):
    """Send a password reset request email to Dev/Admin support.

    This endpoint is intentionally public and does not confirm whether a user exists.
    """
    from pydantic import EmailStr, TypeAdapter
    from fastapi import HTTPException

    # Validate email format using Pydantic's EmailStr
    try:
        email_adapter = TypeAdapter(EmailStr)
        normalized_email = str(email_adapter.validate_python(payload.email.strip())).strip()
    except Exception:
        raise HTTPException(status_code=422, detail="Enter a valid email address")

    settings = get_base_settings()
    if not settings.SMTP_HOST:
        raise HTTPException(status_code=503, detail="Email sending is not configured on the server")

    client_ip = request.client.host if request.client else "unknown"
    user_agent = request.headers.get("user-agent", "")

    subject = "Password reset request - AeroCommand"
    body = "\n".join(
        [
            payload.message.strip(),
            "",
            "---",
            f"Requested email: {normalized_email}",
            f"Client IP: {client_ip}",
            f"User-Agent: {user_agent}",
        ]
    )

    try:
        await send_email_smtp(
            settings,
            to_email=settings.SUPPORT_EMAIL,
            subject=subject,
            body=body,
            reply_to=normalized_email,
        )
    except EmailSendError as e:
        raise HTTPException(status_code=502, detail=f"Failed to send email: {e}")

    return {"detail": "Request sent"}


@router.post("/register", response_model=UserResponse, status_code=201,
             dependencies=[Depends(RequireRole(Role.SUPER_ADMIN))])
async def register(
    data: UserCreate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Create a new user account (super-admin only)."""
    return await create_user_by_admin(db, user, data)


@router.post("/login", response_model=LoginResponse)
async def login(
    data: LoginRequest,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Authenticate and receive access + refresh tokens."""
    return await login_user(db, data)


@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh(
    data: TokenRefreshRequest,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Exchange a refresh token for a new token pair."""
    return await refresh_tokens(db, data.refresh_token)


@router.post("/logout", status_code=204)
async def logout(user: CurrentUser):
    """Revoke current token and clear session."""
    await logout_user(user["user_id"], user.get("token_jti"))


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Get the current user's profile."""
    from uuid import UUID
    from sqlalchemy import select
    from .models import User

    result = await db.execute(select(User).where(User.id == UUID(user["user_id"])))
    db_user = result.scalar_one_or_none()
    if not db_user:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(db_user)


@router.get("/users", response_model=list[UserResponse], dependencies=[Depends(RequireRole(Role.ADMIN))])
async def list_users(
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_users_for_actor(db, user)


@router.get("/users/{user_id}", response_model=UserResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def get_user(
    user_id: str,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await get_user_for_actor(db, user, user_id)


@router.post("/users", response_model=UserResponse, status_code=201,
             dependencies=[Depends(RequireRole(Role.ADMIN))])
async def create_user(
    data: UserCreate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Create users from admin/owner context."""
    return await create_user_by_admin(db, user, data)


@router.post("/organizations", response_model=OrganizationResponse, status_code=201,
             dependencies=[Depends(RequireRole(Role.SUPER_ADMIN))])
async def create_organization(
    data: OrganizationCreate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Create organization (owner/super-admin only)."""
    return await create_organization_by_owner(db, user, data)


@router.get("/organizations", response_model=list[OrganizationResponse], dependencies=[Depends(RequireRole(Role.ADMIN))])
async def list_organizations(
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_organizations_for_actor(db, user)


@router.get("/organizations/{org_id}", response_model=OrganizationResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def get_organization(
    org_id: str,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await get_organization_for_actor(db, user, org_id)


@router.put("/organizations/{org_id}", response_model=OrganizationResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def update_organization(
    org_id: str,
    data: OrganizationUpdate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await update_organization_by_owner(db, user, org_id, data)


@router.delete("/organizations/{org_id}", response_model=OrganizationResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def deactivate_organization(
    org_id: str,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await deactivate_organization_by_owner(db, user, org_id)


@router.put("/users/{user_id}", response_model=UserResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def update_user(
    user_id: str,
    data: UserUpdate,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await update_user_by_admin(db, user, user_id, data)


@router.put("/users/{user_id}/password", response_model=UserResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def update_user_password(
    user_id: str,
    data: _PasswordUpdateRequest,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    """Reset a user's password (admin/super-admin)."""
    return await update_user_password_by_admin(db, user, user_id, data.password)


@router.delete("/users/{user_id}", response_model=UserResponse, dependencies=[Depends(RequireRole(Role.ADMIN))])
async def deactivate_user(
    user_id: str,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await deactivate_user_by_admin(db, user, user_id)

