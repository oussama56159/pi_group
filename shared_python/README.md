# aerocommand-shared

Shared Python library used by AeroCommand services and the Raspberry Pi edge agent.

## What’s inside

- `backend.shared.schemas.*` – Pydantic models shared across components
- `backend.shared.mqtt_topics.MQTTTopics` – MQTT topic builder
- `backend.shared.config.BaseServiceSettings` – common env-based configuration
- `backend.shared.mavlink.*` – MAVLink command/message definitions (lightweight)

## Install

From the repo root:

```bash
pip install -e ./shared_python
```

With optional backend helpers:

```bash
pip install -e "./shared_python[backend]"
```

## Note on import paths

This package intentionally publishes modules under the `backend.shared.*` namespace to match the existing backend imports.
This lets the edge agent share the exact same schemas/topics without having to vendor-copy them.
