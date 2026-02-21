import json
import math
import os
import random
import signal
import sys
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, Optional, Tuple

try:
    import paho.mqtt.client as mqtt
except ImportError:  # pragma: no cover
    print("Missing dependency: paho-mqtt. Install with: pip install paho-mqtt")
    sys.exit(1)


@dataclass
class RobotConfig:
    mqtt_host: str = os.getenv("MQTT_HOST", "localhost")
    mqtt_port: int = int(os.getenv("MQTT_PORT", "1883"))
    mqtt_username: Optional[str] = os.getenv("MQTT_USERNAME")
    mqtt_password: Optional[str] = os.getenv("MQTT_PASSWORD")
    client_id: str = os.getenv("ROBOT_CLIENT_ID", "robot001")

    aerocommand_enabled: bool = os.getenv("AEROCOMMAND_ENABLED", "false").strip().lower() in {"1", "true", "yes", "on"}
    aerocommand_org_id: str = os.getenv("AEROCOMMAND_ORG_ID", "").strip()
    aerocommand_vehicle_id: str = os.getenv("AEROCOMMAND_VEHICLE_ID", "").strip()

    telemetry_topic: str = os.getenv("ROBOT_TELEMETRY_TOPIC", "robots/robot001/telemetry")
    status_topic: str = os.getenv("ROBOT_STATUS_TOPIC", "robots/robot001/status")
    control_topic: str = os.getenv("ROBOT_CONTROL_TOPIC", "robots/robot001/control")

    update_hz: float = float(os.getenv("ROBOT_UPDATE_HZ", "5"))
    noise: float = float(os.getenv("ROBOT_NOISE", "0.00002"))
    battery_drain_idle: float = float(os.getenv("ROBOT_BATT_DRAIN_IDLE", "0.001"))
    battery_drain_move: float = float(os.getenv("ROBOT_BATT_DRAIN_MOVE", "0.015"))

    base_lat: float = float(os.getenv("ROBOT_BASE_LAT", "36.8065"))
    base_lng: float = float(os.getenv("ROBOT_BASE_LNG", "10.1815"))

    loss_chance_per_min: float = float(os.getenv("ROBOT_LOSS_CHANCE", "0.01"))
    loss_duration_sec: float = float(os.getenv("ROBOT_LOSS_DURATION", "4"))


class RobotSimulator:
    def __init__(self, config: RobotConfig) -> None:
        self.cfg = config
        self.client = mqtt.Client(client_id=self.cfg.client_id)
        if self.cfg.mqtt_username:
            self.client.username_pw_set(self.cfg.mqtt_username, self.cfg.mqtt_password)

        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message

        self.running = True
        self.connected = False

        self.state = "idle"  # idle, moving, stopped, error
        self.task = None

        self.lat = self.cfg.base_lat
        self.lng = self.cfg.base_lng
        self.heading = 0.0
        self.speed = 0.0
        self.target: Optional[Tuple[float, float]] = None

        self.battery = 100.0
        self.signal_strength = 100.0
        self.health = "ok"

        self._seq = 0

        self._loss_until = 0.0

    def _on_connect(self, client, userdata, flags, rc):
        self.connected = True
        if self.cfg.aerocommand_enabled:
            client.subscribe(self._command_topic())
        else:
            client.subscribe(self.cfg.control_topic)

    def _on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode("utf-8")) if msg.payload else {}
        except Exception:
            payload = {}

        command = (payload.get("command") or payload.get("action") or "").lower()
        params = payload.get("params") or {}

        if command in ("move_to", "goto"):
            lat = float(params.get("lat", self.lat))
            lng = float(params.get("lng", self.lng))
            self.target = (lat, lng)
            self.state = "moving"
            self.speed = max(self.speed, float(params.get("speed", 1.5)))
        elif command in ("stop", "pause"):
            self.state = "stopped"
            self.speed = 0.0
        elif command == "resume":
            if self.target:
                self.state = "moving"
                self.speed = max(self.speed, 1.0)
        elif command == "start_task":
            self.task = params.get("task", "patrol")
            self.state = "moving"
        elif command == "emergency_stop":
            self.state = "error"
            self.speed = 0.0
        elif command == "clear_error":
            self.state = "idle"

    def _simulate_link(self, now: float) -> None:
        if now < self._loss_until:
            self.connected = False
            self.signal_strength = max(0.0, self.signal_strength - 2.0)
            return

        self.connected = True
        self.signal_strength = min(100.0, self.signal_strength + 0.5)

        if random.random() < (self.cfg.loss_chance_per_min / 60.0):
            self._loss_until = now + self.cfg.loss_duration_sec

    def _update_motion(self, dt: float) -> None:
        if self.state in ("stopped", "error"):
            self.speed = 0.0
            return

        if self.state == "moving":
            if self.target:
                self._navigate_to(self.target[0], self.target[1], dt)
                if self._distance_to(self.target[0], self.target[1]) < 2:
                    self.state = "idle"
                    self.target = None
                    self.speed = 0.0
            else:
                self._wander(dt)

    def _wander(self, dt: float) -> None:
        self.speed = max(self.speed, 1.0)
        self.heading = (self.heading + 6.0 * dt) % 360
        self._move_forward(dt)

    def _move_forward(self, dt: float) -> None:
        heading_rad = math.radians(self.heading)
        meters = self.speed * dt
        lat_scale = 111_111.0
        lon_scale = 111_111.0 * math.cos(math.radians(self.lat))
        dlat = (meters * math.cos(heading_rad)) / lat_scale
        dlon = (meters * math.sin(heading_rad)) / lon_scale
        self.lat += dlat + random.uniform(-self.cfg.noise, self.cfg.noise)
        self.lng += dlon + random.uniform(-self.cfg.noise, self.cfg.noise)

    def _navigate_to(self, target_lat: float, target_lng: float, dt: float) -> None:
        dy = (target_lat - self.lat) * 111_111.0
        dx = (target_lng - self.lng) * 111_111.0 * math.cos(math.radians(self.lat))
        self.heading = (math.degrees(math.atan2(dx, dy)) + 360) % 360
        self.speed = max(self.speed, 1.5)
        self._move_forward(dt)

    def _distance_to(self, target_lat: float, target_lng: float) -> float:
        dy = (target_lat - self.lat) * 111_111.0
        dx = (target_lng - self.lng) * 111_111.0 * math.cos(math.radians(self.lat))
        return math.hypot(dx, dy)

    def _update_battery(self, dt: float) -> None:
        drain = self.cfg.battery_drain_move if self.speed > 0.1 else self.cfg.battery_drain_idle
        self.battery = max(0.0, self.battery - drain * dt)
        if self.battery < 20.0:
            self.health = "low_battery"
        else:
            self.health = "ok"

    def _telemetry_payload(self) -> Dict[str, Any]:
        return {
            "robot_id": self.cfg.client_id,
            "timestamp": time.time(),
            "position": {"lat": self.lat, "lng": self.lng},
            "speed": self.speed,
            "heading": self.heading,
            "battery": round(self.battery, 2),
            "signal": round(self.signal_strength, 1),
            "state": self.state,
            "task": self.task,
            "health": self.health,
        }

    def _heartbeat_payload(self) -> Dict[str, Any]:
        return {
            "vehicle_id": self._vehicle_id(),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "connected": self.connected,
        }

    def _vehicle_id(self) -> str:
        return self.cfg.aerocommand_vehicle_id or self.cfg.client_id

    def _raw_telemetry_topic(self) -> str:
        return f"aerocommand/{self.cfg.aerocommand_org_id}/telemetry/{self._vehicle_id()}/raw"

    def _heartbeat_topic(self) -> str:
        return f"aerocommand/{self.cfg.aerocommand_org_id}/telemetry/{self._vehicle_id()}/heartbeat"

    def _command_topic(self) -> str:
        return f"aerocommand/{self.cfg.aerocommand_org_id}/command/{self._vehicle_id()}/request"

    def _aerocommand_frame(self) -> Dict[str, Any]:
        self._seq += 1
        now = datetime.now(timezone.utc)

        voltage = 11.0 + (self.battery / 100.0) * 2.0
        current = 0.1 if self.state != "moving" else 2.0 + self.speed * 1.5
        throttle = 0.0 if self.state != "moving" else min(100.0, 25.0 + self.speed * 20.0)

        return {
            "vehicle_id": self._vehicle_id(),
            "timestamp": now.isoformat(),
            "seq": self._seq,
            "attitude": {
                "roll": 0.0,
                "pitch": 0.0,
                "yaw": float(self.heading),
            },
            "gps": {
                "lat": float(self.lat),
                "lng": float(self.lng),
                "alt": 0.0,
                "relative_alt": None,
                "fix_type": 3,
                "satellites_visible": max(0, int(10 + random.uniform(-2, 2))),
                "hdop": 1.0,
                "vdop": 1.4,
            },
            "battery": {
                "voltage": round(voltage, 2),
                "current": round(current, 2),
                "remaining": round(self.battery, 2),
                "temperature": None,
                "cell_voltages": None,
                "capacity_consumed": None,
            },
            "system": {
                "mode": self.state.upper(),
                "armed": self.state == "moving",
                "system_status": 4,
                "autopilot": "ardupilot",
                "vehicle_type": 10,
                "cpu_load": None,
                "errors_count": 0,
            },
            "airspeed": 0.0,
            "groundspeed": float(self.speed),
            "heading": float(self.heading % 360.0),
            "climb_rate": 0.0,
            "throttle": float(throttle),
            "rc": None,
            "wind_speed": None,
            "wind_direction": None,
        }

    def _status_payload(self) -> Dict[str, Any]:
        return {
            "robot_id": self.cfg.client_id,
            "timestamp": time.time(),
            "connected": self.connected,
            "state": self.state,
            "health": self.health,
        }

    def start(self) -> None:
        if self.cfg.aerocommand_enabled and not self.cfg.aerocommand_org_id:
            raise SystemExit("AEROCOMMAND_ENABLED=true requires AEROCOMMAND_ORG_ID (a UUID string)")

        self.client.connect(self.cfg.mqtt_host, self.cfg.mqtt_port, keepalive=30)
        self.client.loop_start()

        def _handle_sig(*_args):
            self.running = False

        signal.signal(signal.SIGINT, _handle_sig)
        signal.signal(signal.SIGTERM, _handle_sig)

        interval = 1.0 / max(1.0, self.cfg.update_hz)
        last = time.time()

        while self.running:
            now = time.time()
            dt = max(0.001, now - last)
            last = now

            self._simulate_link(now)
            if self.connected:
                self._update_motion(dt)
                self._update_battery(dt)

                if self.cfg.aerocommand_enabled:
                    self.client.publish(self._raw_telemetry_topic(), json.dumps(self._aerocommand_frame()))
                    self.client.publish(self._heartbeat_topic(), json.dumps(self._heartbeat_payload()))
                else:
                    self.client.publish(self.cfg.telemetry_topic, json.dumps(self._telemetry_payload()))
                    self.client.publish(self.cfg.status_topic, json.dumps(self._status_payload()))

            time.sleep(interval)

        self.client.loop_stop()
        self.client.disconnect()


if __name__ == "__main__":
    sim = RobotSimulator(RobotConfig())
    sim.start()
