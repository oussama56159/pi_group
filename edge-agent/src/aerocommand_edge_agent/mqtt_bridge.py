from __future__ import annotations

import asyncio
from datetime import datetime, timezone

import orjson
from aiomqtt import Client

from backend.shared.mqtt_topics import MQTTTopics
from backend.shared.schemas.command import CommandAck, CommandStatus

from .telemetry_state import TelemetryState


class MqttBridge:
    def __init__(
        self,
        *,
        org_id: str,
        vehicle_id: str,
        host: str,
        port: int,
        username: str | None,
        password: str | None,
        client_id: str,
        keepalive: int,
        qos: int,
    ) -> None:
        self.org_id = org_id
        self.vehicle_id = vehicle_id
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.client_id = client_id
        self.keepalive = keepalive
        self.qos = qos

        self.telemetry_topic = MQTTTopics.telemetry_raw(org_id, vehicle_id)
        self.heartbeat_topic = MQTTTopics.heartbeat(org_id, vehicle_id)
        self.command_request_topic = MQTTTopics.command_request(org_id, vehicle_id)
        self.command_ack_topic = MQTTTopics.command_ack(org_id, vehicle_id)

    async def run(
        self,
        *,
        telemetry_state: TelemetryState,
        telemetry_interval_s: float,
        heartbeat_interval_s: float,
        on_command_request: callable | None = None,
    ) -> None:
        async with Client(
            hostname=self.host,
            port=self.port,
            username=self.username,
            password=self.password,
            identifier=self.client_id,
            keepalive=self.keepalive,
        ) as client:
            await client.subscribe(self.command_request_topic, qos=self.qos)

            async def publish_telemetry() -> None:
                while True:
                    frame = telemetry_state.to_frame()
                    payload = orjson.dumps(frame.model_dump(mode="json"))
                    await client.publish(self.telemetry_topic, payload, qos=self.qos)
                    await asyncio.sleep(telemetry_interval_s)

            async def publish_heartbeat() -> None:
                while True:
                    payload = orjson.dumps(
                        {
                            "vehicle_id": self.vehicle_id,
                            "ts": datetime.now(tz=timezone.utc).isoformat(),
                            "seq": telemetry_state.seq,
                        }
                    )
                    await client.publish(self.heartbeat_topic, payload, qos=self.qos)
                    await asyncio.sleep(heartbeat_interval_s)

            async def handle_commands() -> None:
                async for message in client.messages:
                    if message.topic.value != self.command_request_topic:
                        continue

                    # Initial stub: ACK immediately. A full implementation would translate
                    # the request into MAVLink COMMAND_LONG/MISSION* messages.
                    ack = CommandAck(
                        command_id="unknown",
                        vehicle_id=self.vehicle_id,
                        status=CommandStatus.ACKNOWLEDGED,
                        result_code=0,
                        message="Received by edge agent",
                        timestamp=datetime.now(tz=timezone.utc),
                    )
                    await client.publish(self.command_ack_topic, orjson.dumps(ack.model_dump(mode="json")), qos=self.qos)

                    if on_command_request is not None:
                        try:
                            await on_command_request(message)
                        except Exception:
                            # swallow errors so we keep the bridge alive
                            pass

            await asyncio.gather(publish_telemetry(), publish_heartbeat(), handle_commands())
