"""Vehicle & fleet schemas."""
from __future__ import annotations

import enum
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

__all__ = [
    "VehicleType",
    "VehicleStatus",
    "GeoPosition",
    "VehicleCreate",
    "VehicleUpdate",
    "VehicleResponse",
    "VehicleListResponse",
    "FleetCreate",
    "FleetUpdate",
    "FleetResponse",
    "FleetUserAssignRequest",
    "FleetUserAssignmentResponse",
]


class VehicleType(str, enum.Enum):
    QUADCOPTER = "quadcopter"
    HEXACOPTER = "hexacopter"
    OCTOCOPTER = "octocopter"
    FIXED_WING = "fixed_wing"
    VTOL = "vtol"
    ROVER = "rover"
    BOAT = "boat"
    SUBMARINE = "submarine"


class VehicleStatus(str, enum.Enum):
    OFFLINE = "offline"
    IDLE = "idle"
    ARMED = "armed"
    IN_FLIGHT = "in_flight"
    IN_MISSION = "in_mission"
    RETURNING = "returning"
    LANDING = "landing"
    CHARGING = "charging"
    MAINTENANCE = "maintenance"
    ERROR = "error"


class GeoPosition(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    alt: float = Field(default=0.0, description="Altitude in meters MSL")
    relative_alt: float | None = Field(default=None, description="Altitude relative to home")


class VehicleCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    callsign: str = Field(min_length=1, max_length=20)
    type: VehicleType
    fleet_id: UUID | None = None
    firmware: str | None = None
    serial_number: str | None = None
    hardware_id: str | None = None
    home_position: GeoPosition | None = None
    metadata: dict | None = None


class VehicleUpdate(BaseModel):
    name: str | None = None
    callsign: str | None = None
    type: VehicleType | None = None
    fleet_id: UUID | None = None
    firmware: str | None = None
    home_position: GeoPosition | None = None
    metadata: dict | None = None


class VehicleResponse(BaseModel):
    id: UUID
    name: str
    callsign: str
    type: VehicleType
    status: VehicleStatus
    fleet_id: UUID | None
    firmware: str | None
    serial_number: str | None
    hardware_id: str | None
    home_position: GeoPosition | None
    position: GeoPosition | None
    battery: float | None
    gps_fix: int | None
    satellites: int | None
    mode: str | None
    armed: bool
    uptime: int | None
    last_seen: datetime | None
    created_at: datetime
    organization_id: UUID

    model_config = {"from_attributes": True}


class VehicleListResponse(BaseModel):
    items: list[VehicleResponse]
    total: int
    page: int
    page_size: int


class FleetCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None


class FleetUpdate(BaseModel):
    name: str | None = None
    description: str | None = None


class FleetResponse(BaseModel):
    id: UUID
    name: str
    description: str | None
    vehicle_count: int
    online_count: int
    organization_id: UUID
    created_at: datetime

    model_config = {"from_attributes": True}


class FleetUserAssignRequest(BaseModel):
    user_ids: list[UUID] = Field(min_length=1)


class FleetUserAssignmentResponse(BaseModel):
    fleet_id: UUID
    user_id: UUID
    assigned_by: UUID | None
    assigned_at: datetime

    model_config = {"from_attributes": True}

