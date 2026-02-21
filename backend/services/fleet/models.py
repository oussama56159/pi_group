"""SQLAlchemy ORM models for vehicles and fleets."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Enum, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.shared.database.postgres import PostgresBase
from backend.shared.schemas.vehicle import VehicleStatus, VehicleType


class Fleet(PostgresBase):
    __tablename__ = "fleets"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    vehicles: Mapped[list["Vehicle"]] = relationship(back_populates="fleet")


class Vehicle(PostgresBase):
    __tablename__ = "vehicles"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    callsign: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    type: Mapped[VehicleType] = mapped_column(Enum(VehicleType, name="vehicle_type"), nullable=False)
    status: Mapped[VehicleStatus] = mapped_column(
        Enum(VehicleStatus, name="vehicle_status"), nullable=False, default=VehicleStatus.OFFLINE
    )
    fleet_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), ForeignKey("fleets.id"), nullable=True)
    organization_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), nullable=False, index=True)

    # Hardware info
    firmware: Mapped[str | None] = mapped_column(String(100), nullable=True)
    serial_number: Mapped[str | None] = mapped_column(String(100), unique=True, nullable=True)
    hardware_id: Mapped[str | None] = mapped_column(String(100), nullable=True)

    # Position
    home_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    home_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    home_alt: Mapped[float | None] = mapped_column(Float, nullable=True)
    current_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    current_lng: Mapped[float | None] = mapped_column(Float, nullable=True)
    current_alt: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Live state
    battery: Mapped[float | None] = mapped_column(Float, nullable=True)
    gps_fix: Mapped[int | None] = mapped_column(Integer, nullable=True)
    satellites: Mapped[int | None] = mapped_column(Integer, nullable=True)
    mode: Mapped[str | None] = mapped_column(String(50), nullable=True)
    armed: Mapped[bool] = mapped_column(Boolean, default=False)
    uptime: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # Metadata
    metadata_json: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    last_seen: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc)
    )

    fleet: Mapped[Fleet | None] = relationship(back_populates="vehicles")


class FleetUserAssignment(PostgresBase):
    __tablename__ = "fleet_user_assignments"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    fleet_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("fleets.id"), nullable=False, index=True)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True)
    assigned_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    fleet: Mapped[Fleet] = relationship()

