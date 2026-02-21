"""Mission graph schemas used by the mission planner.

The mission graph represents a mission as a set of typed nodes and edges.
It is stored as JSON inside Mission.settings["mission_graph"].
"""

from __future__ import annotations

import enum
from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

__all__ = [
    "MissionSeverity",
    "ValidationIssue",
    "ValidationResult",
    "MissionNodeType",
    "MissionEdgeType",
    "GeoPosition",
    "MissionGraphMeta",
    "MissionGraphNode",
    "MissionGraphEdge",
    "MissionGraph",
    "CompiledWaypoint",
    "CompileResult",
]


class MissionSeverity(str, enum.Enum):
    INFO = "info"
    WARNING = "warning"
    ERROR = "error"


class ValidationIssue(BaseModel):
    severity: MissionSeverity
    code: str
    message: str
    node_id: str | None = None
    edge_id: str | None = None


class ValidationResult(BaseModel):
    ok: bool
    issues: list[ValidationIssue] = Field(default_factory=list)


class MissionNodeType(str, enum.Enum):
    START = "START"
    WAYPOINT = "WAYPOINT"
    PATH_POINT = "PATH_POINT"
    ACTION = "ACTION"
    END = "END"


class MissionEdgeType(str, enum.Enum):
    SEQUENCE = "SEQUENCE"
    CONDITIONAL = "CONDITIONAL"


class GeoPosition(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    alt: float = Field(default=0, description="Altitude in meters")


class MissionGraphMeta(BaseModel):
    graph_version: int = Field(default=1, ge=1)
    created_at: datetime | None = None
    updated_at: datetime | None = None
    created_by: str | None = None
    updated_by: str | None = None


class MissionGraphNode(BaseModel):
    id: str = Field(min_length=1)
    type: MissionNodeType = MissionNodeType.WAYPOINT
    seq: int = Field(default=0, ge=0)
    label: str | None = None
    position: GeoPosition | None = None
    data: dict | None = None


class MissionGraphEdge(BaseModel):
    id: str = Field(min_length=1)
    from_node: str = Field(min_length=1)
    to_node: str = Field(min_length=1)
    type: MissionEdgeType = MissionEdgeType.SEQUENCE
    condition: str | None = None
    label: str | None = None
    data: dict | None = None


class MissionGraph(BaseModel):
    meta: MissionGraphMeta = Field(default_factory=MissionGraphMeta)
    nodes: list[MissionGraphNode] = Field(default_factory=list)
    edges: list[MissionGraphEdge] = Field(default_factory=list)


class CompiledWaypoint(BaseModel):
    seq: int = Field(ge=0)
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    alt: float = Field(description="Altitude in meters")
    command: str = "NAV_WAYPOINT"
    frame: int = 3


class CompileResult(BaseModel):
    mission_id: UUID
    graph_version: int = Field(default=1, ge=1)
    waypoints: list[CompiledWaypoint] = Field(default_factory=list)
