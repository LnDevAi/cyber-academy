"""Course schemas."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field

from app.models.course import CourseLevel, CoursePartner, CourseType


class CourseCreate(BaseModel):
    code: str = Field(max_length=50)
    title: str = Field(max_length=500)
    description: str
    short_description: Optional[str] = Field(default=None, max_length=500)
    type: CourseType
    partner: CoursePartner
    level: CourseLevel
    hours_total: int = Field(gt=0)
    price_fcfa: int = Field(gt=0)
    price_eur: Optional[float] = None
    prerequisites: Optional[str] = None
    objectives: Optional[str] = None
    target_audience: Optional[str] = None
    moodle_course_id: Optional[int] = None
    thumbnail_url: Optional[str] = None
    syllabus_url: Optional[str] = None
    is_active: bool = True


class CourseUpdate(BaseModel):
    title: Optional[str] = Field(default=None, max_length=500)
    description: Optional[str] = None
    short_description: Optional[str] = Field(default=None, max_length=500)
    hours_total: Optional[int] = Field(default=None, gt=0)
    price_fcfa: Optional[int] = Field(default=None, gt=0)
    price_eur: Optional[float] = None
    prerequisites: Optional[str] = None
    objectives: Optional[str] = None
    moodle_course_id: Optional[int] = None
    thumbnail_url: Optional[str] = None
    syllabus_url: Optional[str] = None
    is_active: Optional[bool] = None


class CourseResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    code: str
    title: str
    description: str
    short_description: Optional[str]
    type: CourseType
    partner: CoursePartner
    level: CourseLevel
    hours_total: int
    price_fcfa: int
    price_eur: Optional[float]
    prerequisites: Optional[str]
    objectives: Optional[str]
    target_audience: Optional[str]
    moodle_course_id: Optional[int]
    thumbnail_url: Optional[str]
    syllabus_url: Optional[str]
    is_active: bool
    created_at: datetime


class CourseListResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    code: str
    title: str
    short_description: Optional[str]
    type: CourseType
    partner: CoursePartner
    level: CourseLevel
    hours_total: int
    price_fcfa: int
    thumbnail_url: Optional[str]
    is_active: bool
