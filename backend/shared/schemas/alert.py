"""Alert & notification schemas."""
from __future__ import annotations

import enum
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

__all__ = [
    "AlertSeverity",
    "AlertCategory",
    "AlertCreate",
    "AlertResponse",
    "AlertRule",
    "GeofenceZone",
    "NotificationChannel",
]


class AlertSeverity(str, enum.Enum):
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"
    EMERGENCY = "emergency"


class AlertCategory(str, enum.Enum):
    BATTERY = "battery"
    GEOFENCE = "geofence"
    CONNECTION = "connection"
    SYSTEM = "system"
    MISSION = "mission"
    SENSOR = "sensor"
    WEATHER = "weather"
    CUSTOM = "custom"


class AlertCreate(BaseModel):
    vehicle_id: UUID | None = None
    severity: AlertSeverity
    category: AlertCategory
    title: str = Field(max_length=255)
    message: str
    metadata: dict | None = None


class AlertResponse(BaseModel):
    id: UUID
    vehicle_id: UUID | None
    severity: AlertSeverity
    category: AlertCategory
    title: str
    message: str
    metadata: dict | None
    acknowledged: bool = False
    acknowledged_by: UUID | None = None
    acknowledged_at: datetime | None = None
    resolved: bool = False
    resolved_at: datetime | None = None
    created_at: datetime
    organization_id: UUID

    model_config = {"from_attributes": True}


class NotificationChannel(str, enum.Enum):
    EMAIL = "email"
    PUSH = "push"
    SMS = "sms"
    WEBHOOK = "webhook"
    SLACK = "slack"


class AlertRule(BaseModel):
    """Configurable alert rule for automated monitoring."""
    id: UUID | None = None
    name: str
    description: str | None = None
    enabled: bool = True
    category: AlertCategory
    severity: AlertSeverity
    condition: dict = Field(
        description="Rule condition, e.g. {'field': 'battery.remaining', 'operator': 'lt', 'value': 20}"
    )
    cooldown_seconds: int = Field(default=300, description="Min seconds between repeated alerts")
    vehicle_ids: list[UUID] | None = Field(default=None, description="None = all vehicles")
    fleet_ids: list[UUID] | None = None
    notification_channels: list[NotificationChannel] = Field(default_factory=lambda: [NotificationChannel.PUSH])
    recipients: list[UUID] | None = Field(default=None, description="User IDs; None = org admins")


class GeofenceZone(BaseModel):
    """Geofence zone definition."""
    id: UUID | None = None
    name: str
    type: str = Field(default="polygon", pattern="^(polygon|circle)$")
    # For polygon: list of [lat, lng] pairs; for circle: center + radius
    coordinates: list[list[float]] = Field(description="Polygon vertices [[lat,lng], ...] or [[center_lat, center_lng]]")
    radius: float | None = Field(default=None, description="Radius in meters (circle type only)")
    max_altitude: float | None = Field(default=None, description="Max altitude in meters")
    min_altitude: float | None = None
    action: str = Field(default="alert", pattern="^(alert|rtl|land|loiter)$")
    enabled: bool = True
    organization_id: UUID | None = None

