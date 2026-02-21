from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone

from backend.shared.schemas.telemetry import (
    AttitudeData,
    BatteryData,
    GPSData,
    SystemStatus,
    TelemetryFrame,
)


@dataclass
class TelemetryState:
    vehicle_id: str
    seq: int = 0

    attitude: AttitudeData = field(default_factory=lambda: AttitudeData(roll=0, pitch=0, yaw=0))
    gps: GPSData = field(
        default_factory=lambda: GPSData(lat=0, lng=0, alt=0, relative_alt=0, fix_type=0, satellites_visible=0)
    )
    battery: BatteryData = field(default_factory=lambda: BatteryData(voltage=0, current=0, remaining=0))
    system: SystemStatus = field(
        default_factory=lambda: SystemStatus(mode="UNKNOWN", armed=False, system_status=0, autopilot="unknown", vehicle_type=0)
    )

    heading: float = 0.0
    groundspeed: float = 0.0
    airspeed: float = 0.0
    climb_rate: float = 0.0
    throttle: float = 0.0

    def to_frame(self) -> TelemetryFrame:
        self.seq += 1
        return TelemetryFrame(
            vehicle_id=self.vehicle_id,
            timestamp=datetime.now(tz=timezone.utc),
            seq=self.seq,
            attitude=self.attitude,
            gps=self.gps,
            battery=self.battery,
            system=self.system,
            airspeed=self.airspeed,
            groundspeed=self.groundspeed,
            heading=self.heading % 360,
            climb_rate=self.climb_rate,
            throttle=max(0, min(100, self.throttle)),
            rc=None,
            wind_speed=None,
            wind_direction=None,
        )
