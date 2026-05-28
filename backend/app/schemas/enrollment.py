"""Enrollment schemas."""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel

from app.models.enrollment import EnrollmentStatus
from app.schemas.course import CourseListResponse


class EnrollmentCreate(BaseModel):
    course_id: uuid.UUID


class EnrollmentResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    user_id: uuid.UUID
    course_id: uuid.UUID
    status: EnrollmentStatus
    progress_pct: float
    moodle_enrollment_id: Optional[int]
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    expires_at: Optional[datetime]
    created_at: datetime


class EnrollmentWithCourseResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    user_id: uuid.UUID
    course_id: uuid.UUID
    status: EnrollmentStatus
    progress_pct: float
    started_at: Optional[datetime]
    completed_at: Optional[datetime]
    expires_at: Optional[datetime]
    created_at: datetime
    course: Optional[CourseListResponse] = None


class ModuleProgress(BaseModel):
    module_id: str
    module_name: str
    completed: bool
    grade: Optional[float]
    completion_date: Optional[datetime]
    time_spent_minutes: Optional[int]


class EnrollmentProgressResponse(BaseModel):
    enrollment_id: uuid.UUID
    course_code: str
    overall_progress_pct: float
    modules: List[ModuleProgress]
    total_modules: int
    completed_modules: int
    grade_average: Optional[float]
    last_activity_at: Optional[datetime]
