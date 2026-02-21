# AeroCommand Edge Agent (Raspberry Pi)

This agent runs on a Raspberry Pi (or any Linux host) connected to a Pixhawk/autopilot.
It bridges **MAVLink telemetry** to **cloud MQTT** and listens for **cloud commands**.

## What it does

- Reads MAVLink messages from Pixhawk (`SERIAL`, `UDP`, or `TCP`)
- Publishes telemetry frames to MQTT topic:
  - `aerocommand/{org_id}/telemetry/{vehicle_id}/raw`
- Publishes heartbeat to:
  - `aerocommand/{org_id}/telemetry/{vehicle_id}/heartbeat`
- Subscribes to command requests:
  - `aerocommand/{org_id}/command/{vehicle_id}/request`
- Responds with acknowledgements:
  - `aerocommand/{org_id}/command/{vehicle_id}/ack`

## Install (dev)

From repo root:

```bash
pip install -e ./shared_python
pip install -e ./edge-agent
```

## Run

Set environment variables (example):

```bash
export ORG_ID="demo"
export VEHICLE_ID="vehicle-01"
export MAVLINK_CONNECTION="/dev/ttyAMA0"
export MAVLINK_BAUD="57600"
export MQTT_HOST="localhost"
export MQTT_PORT="1883"
```

Run:

```bash
aerocommand-edge-agent
```

## Notes

- For Raspberry Pi serial access, add your user to `dialout` and ensure UART is enabled.
- Command execution is stubbed in this initial version; it logs requests and sends ACK.
