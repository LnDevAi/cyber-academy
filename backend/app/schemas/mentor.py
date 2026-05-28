"""Mentor session schemas."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.mentor_session import MentorSessionStatus
from app.schemas.auth import UserResponse


class MentorSessionCreate(BaseModel):
    mentor_id: uuid.UUID
    enrollment_id: Optional[uuid.UUID] = None
    scheduled_at: datetime
    duration_minutes: int = Field(default=60, ge=30, le=240)
    notes: Optional[str] = Field(default=None, max_length=2000)


class MentorSessionUpdate(BaseModel):
    status: Optional[MentorSessionStatus] = None
    notes: Optional[str] = Field(default=None, max_length=2000)
    zoom_link: Optional[str] = Field(default=None, max_length=1000)
    duration_minutes: Optional[int] = Field(default=None, ge=30, le=240)


class MentorSessionResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    mentor_id: uuid.UUID
    student_id: uuid.UUID
    enrollment_id: Optional[uuid.UUID]
    scheduled_at: datetime
    duration_minutes: int
    status: MentorSessionStatus
    notes: Optional[str]
    zoom_link: Optional[str]
    created_at: datetime
    updated_at: datetime


class MentorProfileResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    full_name: str
    email: str
    country: str
    specializations: Optional[list] = None
    bio: Optional[str] = None
    available_slots: Optional[list] = None
