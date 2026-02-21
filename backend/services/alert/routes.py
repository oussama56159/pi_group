"""Alert REST API routes."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from backend.shared.database.postgres import get_postgres_session
from backend.shared.schemas.alert import AlertCategory, AlertResponse, AlertSeverity

from backend.services.auth.dependencies import CurrentUser, OrgId
from .service import acknowledge_alert, list_alerts, resolve_alert

router = APIRouter()


@router.get("", response_model=list[AlertResponse])
async def api_list_alerts(
    org_id: OrgId,
    severity: AlertSeverity | None = None,
    category: AlertCategory | None = None,
    acknowledged: bool | None = None,
    limit: int = Query(100, ge=1, le=500),
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_alerts(db, org_id, severity, category, acknowledged, limit)


@router.post("/{alert_id}/acknowledge", response_model=AlertResponse)
async def api_acknowledge_alert(
    alert_id: UUID,
    user: CurrentUser,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await acknowledge_alert(db, org_id, alert_id, UUID(user["user_id"]))


@router.post("/{alert_id}/resolve", response_model=AlertResponse)
async def api_resolve_alert(
    alert_id: UUID,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await resolve_alert(db, org_id, alert_id)

