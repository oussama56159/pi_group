# MQTT Device Simulators (Drone + Robot)

This folder contains local simulators for one drone and one robot. They publish
telemetry and status over MQTT and react to control commands so the platform can
be tested without Pixhawk or Raspberry Pi hardware.

## Topics

Drone:
- Telemetry: `drones/drone001/telemetry`
- Status: `drones/drone001/status`
- Control: `drones/drone001/control`

Robot:
- Telemetry: `robots/robot001/telemetry`
- Status: `robots/robot001/status`
- Control: `robots/robot001/control`

## AeroCommand Integration Mode (recommended)

Both simulators can publish directly into the backend's expected MQTT topic schema + payload shape.

When enabled, the simulator publishes:
- Telemetry: `aerocommand/{org_id}/telemetry/{vehicle_id}/raw`
- Heartbeat: `aerocommand/{org_id}/telemetry/{vehicle_id}/heartbeat`

And it listens for commands on:
- Commands: `aerocommand/{org_id}/command/{vehicle_id}/request`

Enable with environment variables:
- `AEROCOMMAND_ENABLED=true`
- `AEROCOMMAND_ORG_ID=<org uuid>`
- `AEROCOMMAND_VEHICLE_ID=<vehicle uuid>` (optional; defaults to `DRONE_CLIENT_ID` / `ROBOT_CLIENT_ID`)

How to get IDs from the running API:

- `org_id`: login, then call `GET /api/v1/auth/me` and read `organization_id`
- `vehicle_id`: call `GET /api/v1/fleet/vehicles` (or create a vehicle in the dashboard and copy its `id`)

## Example Control Payload

```json
{
  "command": "takeoff",
  "params": {"alt": 80}
}
```

## Drone Telemetry Payload (example)

```json
{
  "vehicle_id": "drone001",
  "timestamp": 1738980000.12,
  "position": {"lat": 36.8065, "lng": 10.1815, "alt": 76.2},
  "speed": 6.1,
  "vertical_speed": 0.8,
  "heading": 120.0,
  "attitude": {"roll": 2.3, "pitch": 1.4, "yaw": 120.0},
  "battery": 86.4,
  "signal": 98.5,
  "mode": "AUTO",
  "armed": true,
  "status": "flying",
  "health": "ok"
}
```

## Robot Telemetry Payload (example)

```json
{
  "robot_id": "robot001",
  "timestamp": 1738980000.12,
  "position": {"lat": 36.8068, "lng": 10.1819},
  "speed": 1.2,
  "heading": 45.0,
  "battery": 91.7,
  "signal": 99.1,
  "state": "moving",
  "task": "patrol",
  "health": "ok"
}
```

## Commands Supported

Drone:
- `arm`, `disarm`
- `takeoff`, `land`, `rtl`, `loiter`, `guided`, `auto`
- `start_mission`, `pause_mission`, `resume_mission`
- `emergency_stop`

Robot:
- `move_to` (params: lat, lng, speed)
- `stop`, `pause`, `resume`
- `start_task` (params: task)
- `emergency_stop`, `clear_error`

## Configuration (Environment Variables)

Common:
- `MQTT_HOST` (default: `localhost`)
- `MQTT_PORT` (default: `1883`)
- `MQTT_USERNAME`, `MQTT_PASSWORD`

If you are running the repo's Docker Compose stack with host-port overrides in the repo root `.env`, make sure `MQTT_PORT` matches `EMQX_MQTT_HOST_PORT`.

Drone:
- `DRONE_CLIENT_ID` (default: `drone001`)
- `DRONE_UPDATE_HZ` (default: `5`)
- `DRONE_HOME_LAT`, `DRONE_HOME_LNG`, `DRONE_HOME_ALT`
- `DRONE_TARGET_ALT`
- `DRONE_LOSS_CHANCE`, `DRONE_LOSS_DURATION`

Robot:
- `ROBOT_CLIENT_ID` (default: `robot001`)
- `ROBOT_UPDATE_HZ` (default: `5`)
- `ROBOT_BASE_LAT`, `ROBOT_BASE_LNG`
- `ROBOT_LOSS_CHANCE`, `ROBOT_LOSS_DURATION`

## How To Run

Install dependency:

```bash
pip install paho-mqtt
```

Run drone simulator:

```bash
python testMQTT/drone_simulator.py
```

Run drone simulator in AeroCommand mode:

```bash
set AEROCOMMAND_ENABLED=true
set AEROCOMMAND_ORG_ID=YOUR_ORG_UUID
set AEROCOMMAND_VEHICLE_ID=YOUR_VEHICLE_UUID
python testMQTT/drone_simulator.py
```

Run robot simulator:

```bash
python testMQTT/robot_simulator.py
```

Run robot simulator in AeroCommand mode:

```bash
set AEROCOMMAND_ENABLED=true
set AEROCOMMAND_ORG_ID=YOUR_ORG_UUID
set AEROCOMMAND_VEHICLE_ID=YOUR_VEHICLE_UUID
python testMQTT/robot_simulator.py
```

## Integration Notes

- Default topics are independent of the platform's built-in MQTT topic schema.
- Use AeroCommand mode to publish directly to the backend's telemetry ingestion path.
