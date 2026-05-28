"""Mentor session endpoints."""
import uuid
from typing import List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_mentor_or_admin
from app.core.database import get_db
from app.models.mentor_session import MentorSession, MentorSessionStatus
from app.models.user import User, UserRole
from app.schemas.mentor import (
    MentorProfileResponse,
    MentorSessionCreate,
    MentorSessionResponse,
    MentorSessionUpdate,
)

logger = structlog.get_logger(__name__)

router = APIRouter(tags=["Mentors"])


@router.get("/mentors", response_model=List[MentorProfileResponse])
async def list_mentors(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[User]:
    """Lister les mentors disponibles."""
    result = await db.execute(
        select(User).where(
            User.role == UserRole.MENTOR,
            User.is_active == True,
        ).order_by(User.full_name)
    )
    return result.scalars().all()


@router.post("/mentor-sessions", response_model=MentorSessionResponse, status_code=status.HTTP_201_CREATED)
async def schedule_session(
    session_data: MentorSessionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MentorSession:
    """Planifier une session avec un mentor."""
    # Verify mentor exists and has MENTOR role
    mentor = await db.get(User, session_data.mentor_id)
    if not mentor or mentor.role != UserRole.MENTOR:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Mentor introuvable",
        )

    if not mentor.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce mentor n'est pas disponible actuellement",
        )

    # Verify enrollment if provided
    if session_data.enrollment_id:
        from app.models.enrollment import Enrollment, EnrollmentStatus
        enrollment = await db.get(Enrollment, session_data.enrollment_id)
        if not enrollment or enrollment.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Inscription introuvable",
            )

    mentor_session = MentorSession(
        mentor_id=session_data.mentor_id,
        student_id=current_user.id,
        enrollment_id=session_data.enrollment_id,
        scheduled_at=session_data.scheduled_at,
        duration_minutes=session_data.duration_minutes,
        notes=session_data.notes,
        status=MentorSessionStatus.SCHEDULED,
    )
    db.add(mentor_session)
    await db.flush()
    await db.refresh(mentor_session)

    logger.info(
        "Session mentor planifiée",
        session_id=str(mentor_session.id),
        mentor_id=str(session_data.mentor_id),
        student_id=str(current_user.id),
    )

    return mentor_session


@router.get("/mentor-sessions", response_model=List[MentorSessionResponse])
async def list_mentor_sessions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[MentorSession]:
    """Lister mes sessions mentor (étudiant: en tant qu'étudiant; mentor: sessions assignées)."""
    if current_user.role == UserRole.ADMIN:
        query = select(MentorSession)
    elif current_user.role == UserRole.MENTOR:
        query = select(MentorSession).where(MentorSession.mentor_id == current_user.id)
    else:
        query = select(MentorSession).where(MentorSession.student_id == current_user.id)

    query = query.order_by(MentorSession.scheduled_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.patch("/mentor-sessions/{session_id}", response_model=MentorSessionResponse)
async def update_mentor_session(
    session_id: uuid.UUID,
    update: MentorSessionUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MentorSession:
    """Mettre à jour le statut ou les notes d'une session mentor (mentor ou admin)."""
    session = await db.get(MentorSession, session_id)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session introuvable",
        )

    # Only mentor or admin can update
    if current_user.role not in (UserRole.MENTOR, UserRole.ADMIN):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Seuls les mentors peuvent mettre à jour les sessions",
        )

    if current_user.role == UserRole.MENTOR and session.mentor_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Vous ne pouvez modifier que vos propres sessions",
        )

    if update.status is not None:
        session.status = update.status
    if update.notes is not None:
        session.notes = update.notes
    if update.zoom_link is not None:
        session.zoom_link = update.zoom_link
    if update.duration_minutes is not None:
        session.duration_minutes = update.duration_minutes

    await db.flush()
    return session
