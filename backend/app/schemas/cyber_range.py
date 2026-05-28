"""Cyber Range schemas."""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel

from app.models.cyber_range_session import CyberRangeStatus


class CyberRangeStartRequest(BaseModel):
    lab_id: str
    enrollment_id: uuid.UUID


class CyberRangeSessionResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    user_id: uuid.UUID
    lab_id: str
    enrollment_id: uuid.UUID
    k8s_namespace: Optional[str]
    guacamole_connection_id: Optional[str]
    guacamole_url: Optional[str]
    status: CyberRangeStatus
    started_at: Optional[datetime]
    ended_at: Optional[datetime]
    duration_minutes: Optional[int]
    cpu_used: Optional[float]
    memory_used_mb: Optional[float]
    score: Optional[float]
    created_at: datetime


class LabResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: str
    course_code: str
    title: str
    description: str
    difficulty: int
    duration_minutes: int
    docker_image: str
    objectives: Optional[List[str]]
    order_in_course: int
    is_active: bool


class ResourceUsageResponse(BaseModel):
    namespace: str
    cpu_cores: float
    memory_mb: float
    uptime_minutes: int
    pod_count: int
    status: str
