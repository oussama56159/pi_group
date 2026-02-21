"""Backend action registry.

This provides a server-side action registry for clients that want to fetch
action semantics from the API rather than bundling them at build time.

Keep this registry small and versioned; the dashboard can still maintain a
superset locally.
"""

from __future__ import annotations

from backend.shared.schemas.action_semantics import (
    ActionCategory,
    ActionEffectLevel,
    ActionLogging,
    ActionMetadata,
    ActionRegistryResponse,
    ActionRiskLevel,
    ActionSafetyImpact,
    ActionVisualPriority,
    ActionConfirmation,
    ActionReversibility,
)
from backend.shared.schemas.auth import Role


def get_action_registry() -> ActionRegistryResponse:
    """Return the server-side action registry.

    Note: This is intentionally a minimal baseline set; the frontend may ship
    additional action definitions.
    """

    actions: list[ActionMetadata] = [
        ActionMetadata(
            action_id="nav.goto.dashboard",
            name="Open Dashboard",
            description="Navigate to the operations dashboard view.",
            purpose="Access high-level fleet overview and KPIs.",
            functional_impact="No vehicle-side effect; changes operator context only.",
            technical_impact="Client-side route change; may trigger data queries.",
            safety_impact="None (informational navigation).",
            risk_level=ActionRiskLevel.LOW,
            safety_class=ActionSafetyImpact.NONE,
            visual_priority=ActionVisualPriority.NORMAL,
            preconditions=[],
            postconditions=[],
            failure_scenarios=["Route load fails or API queries fail."],
            emergency_behavior=None,
            dependencies=["Dashboard route"],
            permissions_required=[Role.VIEWER, Role.OPERATOR, Role.PILOT, Role.ADMIN, Role.SUPER_ADMIN],
            reversible=ActionReversibility.REVERSIBLE,
            confirmation=ActionConfirmation(required=False),
            logging=ActionLogging(required=False, audit_trail=False),
            realtime_effect=ActionEffectLevel.LOCAL,
            mission_effect=ActionEffectLevel.NONE,
            fleet_effect=ActionEffectLevel.NONE,
            operator_responsibility="Ensure you are viewing the correct operational context.",
            tooltip="Go to Dashboard",
            safety_label=None,
            risk_indicator=None,
            color_semantics="ghost",
            icon_semantics=None,
        ),
        ActionMetadata(
            action_id="control.command.emergency_stop",
            name="Emergency Stop",
            description="Immediately stop vehicle actuation (failsafe / kill).",
            purpose="Mitigate imminent hazard to life/property.",
            functional_impact="Vehicle may drop or stop abruptly depending on platform.",
            technical_impact="Highest-priority command; may bypass normal control logic.",
            safety_impact="Critical: may prevent harm but can also cause crash.",
            risk_level=ActionRiskLevel.CRITICAL,
            safety_class=ActionSafetyImpact.LIFE_SAFETY,
            visual_priority=ActionVisualPriority.URGENT,
            preconditions=[],
            postconditions=[],
            failure_scenarios=["Command not received", "Actuator failure"],
            emergency_behavior="This action is the emergency behavior.",
            dependencies=["Emergency channel availability"],
            permissions_required=[Role.PILOT, Role.ADMIN, Role.SUPER_ADMIN],
            reversible=ActionReversibility.IRREVERSIBLE,
            confirmation=ActionConfirmation(
                required=True,
                style="danger",
                prompt="EMERGENCY STOP? Use only to prevent harm.",
                typed_phrase=None,
            ),
            logging=ActionLogging(required=True, level="error", audit_trail=True, include_payload=True),
            realtime_effect=ActionEffectLevel.VEHICLE,
            mission_effect=ActionEffectLevel.MISSION,
            fleet_effect=ActionEffectLevel.NONE,
            operator_responsibility="Only use to prevent harm; report and document incident.",
            tooltip="Emergency Stop (kill)",
            safety_label="Life Safety",
            risk_indicator="CRITICAL",
            color_semantics="danger",
            icon_semantics=None,
        ),
    ]

    return ActionRegistryResponse(actions=actions)
