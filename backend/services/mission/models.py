"""SQLAlchemy ORM models for missions and waypoints."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.shared.database.postgres import PostgresBase
from backend.shared.schemas.mission import MissionStatus, WaypointCommand


class Mission(PostgresBase):
    __tablename__ = "missions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    type: Mapped[str] = mapped_column(String(50), nullable=False, default="waypoint")
    status: Mapped[MissionStatus] = mapped_column(
        Enum(MissionStatus, name="mission_status"), nullable=False, default=MissionStatus.DRAFT
    )
    vehicle_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True, index=True)
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)

    # Progress tracking
    progress: Mapped[float] = mapped_column(Float, default=0)
    current_waypoint: Mapped[int] = mapped_column(Integer, default=0)
    total_distance: Mapped[float | None] = mapped_column(Float, nullable=True)
    estimated_duration: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Mission settings (speed, alt defaults, camera, etc.)
    settings: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    # Timestamps
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    waypoints: Mapped[list["Waypoint"]] = relationship(
        back_populates="mission", cascade="all, delete-orphan", order_by="Waypoint.seq"
    )
    assignments: Mapped[list["MissionAssignment"]] = relationship(
        back_populates="mission", cascade="all, delete-orphan"
    )


class Waypoint(PostgresBase):
    __tablename__ = "waypoints"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mission_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("missions.id"), nullable=False)
    seq: Mapped[int] = mapped_column(Integer, nullable=False)
    lat: Mapped[float] = mapped_column(Float, nullable=False)
    lng: Mapped[float] = mapped_column(Float, nullable=False)
    alt: Mapped[float] = mapped_column(Float, nullable=False)
    command: Mapped[WaypointCommand] = mapped_column(
        Enum(WaypointCommand, name="waypoint_command"), nullable=False, default=WaypointCommand.NAV_WAYPOINT
    )
    frame: Mapped[int] = mapped_column(Integer, default=3)
    param1: Mapped[float] = mapped_column(Float, default=0)
    param2: Mapped[float] = mapped_column(Float, default=0)
    param3: Mapped[float] = mapped_column(Float, default=0)
    param4: Mapped[float] = mapped_column(Float, default=0)

    mission: Mapped[Mission] = relationship(back_populates="waypoints")


class MissionAssignment(PostgresBase):
    __tablename__ = "mission_assignments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    mission_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("missions.id"), nullable=False, index=True)
    vehicle_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("vehicles.id"), nullable=False, index=True)
    status: Mapped[MissionStatus] = mapped_column(
        Enum(MissionStatus, name="mission_assignment_status"),
        nullable=False,
        default=MissionStatus.READY,
    )
    progress: Mapped[float] = mapped_column(Float, default=0)
    current_waypoint: Mapped[int] = mapped_column(Integer, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    assigned_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    mission: Mapped[Mission] = relationship(back_populates="assignments")

