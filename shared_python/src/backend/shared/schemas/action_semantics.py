"""Action semantics (industrial-grade action description metadata).

Mirrors backend/shared/schemas/action_semantics.py.
"""

from __future__ import annotations

import enum
from datetime import datetime

from pydantic import BaseModel, Field

from .auth import Role

__all__ = [
    "ActionCategory",
    "ActionRiskLevel",
    "ActionSafetyImpact",
    "ActionVisualPriority",
    "ActionReversibility",
    "ActionEffectLevel",
    "ActionConfirmation",
    "ActionCondition",
    "ActionLogging",
    "ActionMetadata",
    "ActionRegistryResponse",
    "ActionAuditOutcome",
    "ActionAuditEvent",
]


class ActionCategory(str, enum.Enum):
    NAVIGATION = "navigation"
    CONTROL = "control"
    MISSION = "mission"
    TELEMETRY = "telemetry"
    COMMUNICATION = "communication"
    SAFETY = "safety"
    EMERGENCY = "emergency"
    ADMIN = "admin"
    USER = "user"
    FLEET = "fleet"
    SYSTEM = "system"
    ANALYTICS = "analytics"
    ALERT = "alert"
    CONFIGURATION = "configuration"


class ActionRiskLevel(str, enum.Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ActionSafetyImpact(str, enum.Enum):
    NONE = "none"
    ADVISORY = "advisory"
    OPERATIONAL = "operational"
    FLIGHT_SAFETY = "flight_safety"
    LIFE_SAFETY = "life_safety"


class ActionVisualPriority(str, enum.Enum):
    LOW = "low"
    NORMAL = "normal"
    HIGH = "high"
    URGENT = "urgent"


class ActionReversibility(str, enum.Enum):
    REVERSIBLE = "reversible"
    PARTIALLY_REVERSIBLE = "partially_reversible"
    IRREVERSIBLE = "irreversible"


class ActionEffectLevel(str, enum.Enum):
    NONE = "none"
    LOCAL = "local"
    VEHICLE = "vehicle"
    MISSION = "mission"
    FLEET = "fleet"
    SYSTEM = "system"


class ActionConfirmation(BaseModel):
    required: bool = False
    style: str = Field(default="standard", description="standard|danger|typed")
    prompt: str | None = None
    typed_phrase: str | None = None


class ActionCondition(BaseModel):
    description: str
    key: str | None = Field(default=None, description="Optional machine-readable key")


class ActionLogging(BaseModel):
    required: bool = True
    level: str = Field(default="info", description="debug|info|warning|error")
    audit_trail: bool = True
    include_payload: bool = False


class ActionMetadata(BaseModel):
    action_id: str = Field(min_length=3, description="Stable ID, e.g. control.arm")
    name: str
    description: str
    purpose: str
    functional_impact: str
    technical_impact: str
    safety_impact: str
    risk_level: ActionRiskLevel
    safety_class: ActionSafetyImpact
    visual_priority: ActionVisualPriority = ActionVisualPriority.NORMAL
    preconditions: list[ActionCondition] = Field(default_factory=list)
    postconditions: list[ActionCondition] = Field(default_factory=list)
    failure_scenarios: list[str] = Field(default_factory=list)
    emergency_behavior: str | None = None
    dependencies: list[str] = Field(default_factory=list)
    permissions_required: list[Role] = Field(default_factory=list)
    reversible: ActionReversibility = ActionReversibility.REVERSIBLE
    confirmation: ActionConfirmation = Field(default_factory=ActionConfirmation)
    logging: ActionLogging = Field(default_factory=ActionLogging)
    realtime_effect: ActionEffectLevel = ActionEffectLevel.NONE
    mission_effect: ActionEffectLevel = ActionEffectLevel.NONE
    fleet_effect: ActionEffectLevel = ActionEffectLevel.NONE
    operator_responsibility: str
    tooltip: str | None = None
    safety_label: str | None = None
    risk_indicator: str | None = None
    color_semantics: str | None = Field(default=None, description="primary|secondary|warning|danger|success|ghost")
    icon_semantics: str | None = Field(default=None, description="Lucide icon name")


class ActionRegistryResponse(BaseModel):
    version: int = 1
    generated_at: datetime = Field(default_factory=datetime.utcnow)
    actions: list[ActionMetadata] = Field(default_factory=list)


class ActionAuditOutcome(str, enum.Enum):
    SUCCESS = "success"
    FAILURE = "failure"
    REJECTED = "rejected"
    ABORTED = "aborted"


class ActionAuditEvent(BaseModel):
    action_id: str
    outcome: ActionAuditOutcome
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    org_id: str | None = None
    user_id: str | None = None
    vehicle_id: str | None = None
    mission_id: str | None = None
    request_id: str | None = None
    message: str | None = None
    payload: dict | None = None
