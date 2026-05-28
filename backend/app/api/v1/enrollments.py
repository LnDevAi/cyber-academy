"""Enrollment management endpoints."""
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, require_admin
from app.core.database import get_db
from app.models.course import Course
from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.user import User, UserRole
from app.schemas.enrollment import (
    EnrollmentCreate,
    EnrollmentProgressResponse,
    EnrollmentResponse,
    EnrollmentWithCourseResponse,
    ModuleProgress,
)

router = APIRouter(prefix="/enrollments", tags=["Inscriptions"])


@router.post("", response_model=EnrollmentResponse, status_code=status.HTTP_201_CREATED)
async def create_enrollment(
    enrollment_data: EnrollmentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Enrollment:
    """Initier une inscription (création d'un dossier PENDING_PAYMENT)."""
    # Check course exists and is active
    course = await db.get(Course, enrollment_data.course_id)
    if not course or not course.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Formation introuvable ou inactive",
        )

    # Check not already enrolled
    existing = await db.execute(
        select(Enrollment).where(
            Enrollment.user_id == current_user.id,
            Enrollment.course_id == enrollment_data.course_id,
            Enrollment.status.in_([
                EnrollmentStatus.PENDING_PAYMENT,
                EnrollmentStatus.ACTIVE,
            ]),
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Vous avez déjà une inscription active ou en attente de paiement pour cette formation",
        )

    enrollment = Enrollment(
        user_id=current_user.id,
        course_id=enrollment_data.course_id,
        status=EnrollmentStatus.PENDING_PAYMENT,
        progress_pct=0.0,
    )
    db.add(enrollment)
    await db.flush()
    await db.refresh(enrollment)

    return enrollment


@router.get("", response_model=List[EnrollmentWithCourseResponse])
async def list_enrollments(
    status_filter: Optional[str] = Query(default=None, alias="status"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[Enrollment]:
    """Lister mes inscriptions (étudiant) ou toutes les inscriptions (admin)."""
    query = select(Enrollment).options(selectinload(Enrollment.course))

    if current_user.role == UserRole.ADMIN:
        # Admin sees all enrollments
        if status_filter:
            query = query.where(Enrollment.status == status_filter.upper())
    else:
        # Students see only their own enrollments
        query = query.where(Enrollment.user_id == current_user.id)
        if status_filter:
            query = query.where(Enrollment.status == status_filter.upper())

    query = query.order_by(Enrollment.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{enrollment_id}", response_model=EnrollmentWithCourseResponse)
async def get_enrollment(
    enrollment_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Enrollment:
    """Détail d'une inscription avec progression."""
    result = await db.execute(
        select(Enrollment)
        .where(Enrollment.id == enrollment_id)
        .options(selectinload(Enrollment.course))
    )
    enrollment = result.scalar_one_or_none()

    if not enrollment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inscription introuvable",
        )

    # Students can only see their own enrollments
    if current_user.role not in (UserRole.ADMIN, UserRole.B2B_ADMIN):
        if enrollment.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès refusé",
            )

    return enrollment


@router.get("/{enrollment_id}/progress", response_model=EnrollmentProgressResponse)
async def get_enrollment_progress(
    enrollment_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Progression détaillée module par module depuis Moodle."""
    result = await db.execute(
        select(Enrollment)
        .where(Enrollment.id == enrollment_id)
        .options(selectinload(Enrollment.course))
    )
    enrollment = result.scalar_one_or_none()

    if not enrollment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inscription introuvable",
        )

    if current_user.role not in (UserRole.ADMIN,) and enrollment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès refusé",
        )

    # Fetch from Moodle if linked
    modules_progress = []
    grade_average = None
    last_activity_at = None

    if enrollment.moodle_enrollment_id and enrollment.moodle_user_id and enrollment.course.moodle_course_id:
        try:
            from app.services.lms.moodle_service import moodle_service
            progress_data = await moodle_service.get_user_progress(
                enrollment.moodle_user_id,
                enrollment.course.moodle_course_id,
            )

            modules_progress = [
                ModuleProgress(
                    module_id=m["module_id"],
                    module_name=m["module_name"],
                    completed=m["completed"],
                    grade=None,
                    completion_date=None,
                    time_spent_minutes=None,
                )
                for m in progress_data.get("activities", [])
            ]

            grade_average = progress_data.get("grade")
            enrollment.progress_pct = progress_data.get("progress_pct", enrollment.progress_pct)
            await db.flush()

        except Exception as exc:
            # Return local data if Moodle unavailable
            pass

    completed_modules = sum(1 for m in modules_progress if m.completed)

    return {
        "enrollment_id": enrollment_id,
        "course_code": enrollment.course.code if enrollment.course else "",
        "overall_progress_pct": enrollment.progress_pct,
        "modules": modules_progress,
        "total_modules": len(modules_progress),
        "completed_modules": completed_modules,
        "grade_average": grade_average,
        "last_activity_at": last_activity_at,
    }
