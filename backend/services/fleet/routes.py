"""Fleet & Vehicle REST API routes."""
from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from backend.shared.database.postgres import get_postgres_session
from backend.shared.schemas.auth import Role
from backend.shared.schemas.vehicle import (
    FleetCreate,
    FleetResponse,
    FleetUserAssignRequest,
    FleetUserAssignmentResponse,
    FleetUpdate,
    VehicleCreate,
    VehicleListResponse,
    VehicleResponse,
    VehicleStatus,
    VehicleUpdate,
)

from backend.services.auth.dependencies import CurrentUser, OrgId, RequireRole
from .service import (
    create_fleet,
    create_vehicle,
    delete_fleet,
    delete_vehicle,
    get_vehicle,
    list_fleets,
    list_fleet_users,
    list_user_fleets,
    list_vehicles,
    assign_users_to_fleet,
    remove_user_from_fleet,
    update_fleet,
    update_vehicle,
)

router = APIRouter()


# ── Vehicles ──

@router.get("/vehicles", response_model=VehicleListResponse)
async def api_list_vehicles(
    org_id: OrgId,
    user: CurrentUser,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    fleet_id: UUID | None = None,
    status: VehicleStatus | None = None,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_vehicles(db, org_id, page, page_size, fleet_id, status, user=user)


@router.post("/vehicles", response_model=VehicleResponse, status_code=201,
             dependencies=[Depends(RequireRole(Role.OPERATOR))])
async def api_create_vehicle(
    data: VehicleCreate,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await create_vehicle(db, org_id, data)


@router.get("/vehicles/{vehicle_id}", response_model=VehicleResponse)
async def api_get_vehicle(
    vehicle_id: UUID,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await get_vehicle(db, org_id, vehicle_id, user=user)


@router.patch("/vehicles/{vehicle_id}", response_model=VehicleResponse,
              dependencies=[Depends(RequireRole(Role.OPERATOR))])
async def api_update_vehicle(
    vehicle_id: UUID,
    data: VehicleUpdate,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await update_vehicle(db, org_id, vehicle_id, data, user=user)


@router.delete("/vehicles/{vehicle_id}", status_code=204,
               dependencies=[Depends(RequireRole(Role.ADMIN))])
async def api_delete_vehicle(
    vehicle_id: UUID,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    await delete_vehicle(db, org_id, vehicle_id, user=user)


# ── Fleets ──

@router.get("/fleets", response_model=list[FleetResponse])
async def api_list_fleets(
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_fleets(db, org_id, user=user)


@router.post("/fleets", response_model=FleetResponse, status_code=201,
             dependencies=[Depends(RequireRole(Role.ADMIN))])
async def api_create_fleet(
    data: FleetCreate,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await create_fleet(db, org_id, data)


@router.put("/fleets/{fleet_id}", response_model=FleetResponse,
            dependencies=[Depends(RequireRole(Role.ADMIN))])
async def api_update_fleet(
    fleet_id: UUID,
    data: FleetUpdate,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await update_fleet(db, org_id, fleet_id, data)


@router.delete("/fleets/{fleet_id}", status_code=204,
               dependencies=[Depends(RequireRole(Role.ADMIN))])
async def api_delete_fleet(
    fleet_id: UUID,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    await delete_fleet(db, org_id, fleet_id)


@router.get(
    "/fleets/{fleet_id}/users",
    response_model=list[FleetUserAssignmentResponse],
    dependencies=[Depends(RequireRole(Role.ADMIN))],
)
async def api_list_fleet_users(
    fleet_id: UUID,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_fleet_users(db, org_id, fleet_id)


@router.post(
    "/fleets/{fleet_id}/users",
    response_model=list[FleetUserAssignmentResponse],
    dependencies=[Depends(RequireRole(Role.ADMIN))],
)
async def api_assign_fleet_users(
    fleet_id: UUID,
    data: FleetUserAssignRequest,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await assign_users_to_fleet(db, org_id, fleet_id, data.user_ids, assigned_by=user.get("user_id"))


@router.delete(
    "/fleets/{fleet_id}/users/{user_id}",
    status_code=204,
    dependencies=[Depends(RequireRole(Role.ADMIN))],
)
async def api_remove_fleet_user(
    fleet_id: UUID,
    user_id: UUID,
    org_id: OrgId,
    db: AsyncSession = Depends(get_postgres_session),
):
    await remove_user_from_fleet(db, org_id, fleet_id, user_id)


@router.get(
    "/users/{user_id}/fleets",
    response_model=list[FleetResponse],
    dependencies=[Depends(RequireRole(Role.ADMIN))],
)
async def api_list_user_fleets(
    user_id: UUID,
    org_id: OrgId,
    user: CurrentUser,
    db: AsyncSession = Depends(get_postgres_session),
):
    return await list_user_fleets(db, org_id, user_id)

