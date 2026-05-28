"""Cyber Range endpoints — lab provisioning and session management."""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.database import get_db
from app.models.cyber_range_session import CyberRangeSession, CyberRangeStatus
from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.lab import Lab
from app.models.user import User, UserRole
from app.schemas.cyber_range import CyberRangeSessionResponse, CyberRangeStartRequest, LabResponse

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/cyber-range", tags=["Cyber Range"])


@router.post("/start", response_model=CyberRangeSessionResponse, status_code=status.HTTP_202_ACCEPTED)
async def start_lab(
    request: CyberRangeStartRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CyberRangeSession:
    """
    Démarrer un lab Cyber Range.
    Provisionne un namespace k3s et retourne l'URL Guacamole.
    """
    # Verify enrollment is active
    enrollment = await db.get(Enrollment, request.enrollment_id)
    if not enrollment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inscription introuvable",
        )

    if enrollment.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    if enrollment.status != EnrollmentStatus.ACTIVE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Inscription non active (statut: {enrollment.status.value}). Vous devez payer pour accéder aux labs.",
        )

    # Verify lab exists
    lab = await db.get(Lab, request.lab_id)
    if not lab or not lab.is_active:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lab '{request.lab_id}' introuvable ou inactif",
        )

    # Check if student already has an active session for this lab
    existing = await db.execute(
        select(CyberRangeSession).where(
            CyberRangeSession.user_id == current_user.id,
            CyberRangeSession.lab_id == request.lab_id,
            CyberRangeSession.status == CyberRangeStatus.ACTIVE,
        )
    )
    active_session = existing.scalar_one_or_none()
    if active_session:
        # Return existing session
        return active_session

    # Create new session record
    session = CyberRangeSession(
        user_id=current_user.id,
        lab_id=request.lab_id,
        enrollment_id=request.enrollment_id,
        status=CyberRangeStatus.PROVISIONING,
    )
    db.add(session)
    await db.flush()
    await db.refresh(session)

    # Trigger async provisioning via Celery
    from app.tasks.range_tasks import provision_range_session
    provision_range_session.delay(str(session.id))

    logger.info(
        "Session Cyber Range créée — provisionnement en cours",
        session_id=str(session.id),
        lab_id=request.lab_id,
    )

    return session


@router.get("/sessions", response_model=List[CyberRangeSessionResponse])
async def list_sessions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[CyberRangeSession]:
    """Lister mes sessions Cyber Range."""
    query = select(CyberRangeSession)

    if current_user.role != UserRole.ADMIN:
        query = query.where(CyberRangeSession.user_id == current_user.id)

    query = query.order_by(CyberRangeSession.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/sessions/{session_id}", response_model=CyberRangeSessionResponse)
async def get_session(
    session_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CyberRangeSession:
    """Détail d'une session Cyber Range — inclut l'URL Guacamole quand active."""
    session = await db.get(CyberRangeSession, session_id)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session introuvable")

    if current_user.role != UserRole.ADMIN and session.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    return session


@router.post("/sessions/{session_id}/stop", response_model=CyberRangeSessionResponse)
async def stop_session(
    session_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> CyberRangeSession:
    """Arrêter une session Cyber Range et supprimer le namespace k8s."""
    session = await db.get(CyberRangeSession, session_id)
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session introuvable")

    if current_user.role != UserRole.ADMIN and session.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    if session.status in (CyberRangeStatus.TERMINATED,):
        raise HTTPException(status_code=400, detail="Session déjà terminée")

    # Terminate k8s namespace
    if session.k8s_namespace:
        try:
            from app.services.cyber_range.k8s_service import k8s_service
            await k8s_service.terminate_namespace(session.k8s_namespace)
        except Exception as exc:
            logger.warning("Erreur terminaison namespace", error=str(exc))

    # Update session status
    session.status = CyberRangeStatus.TERMINATED
    session.ended_at = datetime.now(timezone.utc)
    if session.started_at:
        duration = (session.ended_at - session.started_at).total_seconds() / 60
        session.duration_minutes = int(duration)

    await db.flush()

    logger.info("Session Cyber Range terminée", session_id=str(session_id))
    return session


@router.get("/labs", response_model=List[LabResponse])
async def list_labs(
    course_code: Optional[str] = Query(default=None, description="Filtrer par code de formation"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[Lab]:
    """Lister les labs disponibles pour une formation."""
    query = select(Lab).where(Lab.is_active == True)
    if course_code:
        query = query.where(Lab.course_code == course_code.upper())
    query = query.order_by(Lab.course_code, Lab.order_in_course)

    result = await db.execute(query)
    return result.scalars().all()


@router.get("/labs/{lab_id}", response_model=LabResponse)
async def get_lab(
    lab_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Lab:
    """Détail d'un lab — objectifs, durée, difficulté."""
    lab = await db.get(Lab, lab_id)
    if not lab or not lab.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Lab introuvable")
    return lab
