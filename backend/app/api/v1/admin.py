"""Admin dashboard endpoints."""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.database import get_db
from app.models.badge import Badge
from app.models.course import Course
from app.models.cyber_range_session import CyberRangeSession, CyberRangeStatus
from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.lab import Lab
from app.models.payment import Payment, PaymentStatus
from app.models.user import User, UserRole
from app.schemas.auth import UserResponse
from app.schemas.badge import BadgeResponse
from app.schemas.course import CourseCreate
from app.schemas.payment import PaymentResponse

router = APIRouter(prefix="/admin", tags=["Administration"])


@router.get("/stats")
async def get_dashboard_stats(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """
    Statistiques globales du tableau de bord admin:
    inscriptions/jour, revenus, sessions Cyber Range actives, taux de complétion.
    """
    now = datetime.now(timezone.utc)
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=7)
    month_start = today_start - timedelta(days=30)

    # Total users
    total_users = await db.scalar(select(func.count(User.id)))

    # Users by role
    students_count = await db.scalar(
        select(func.count(User.id)).where(User.role == UserRole.STUDENT)
    )

    # Enrollments today
    enrollments_today = await db.scalar(
        select(func.count(Enrollment.id)).where(Enrollment.created_at >= today_start)
    )

    # Active enrollments
    active_enrollments = await db.scalar(
        select(func.count(Enrollment.id)).where(Enrollment.status == EnrollmentStatus.ACTIVE)
    )

    # Completed enrollments
    completed_enrollments = await db.scalar(
        select(func.count(Enrollment.id)).where(Enrollment.status == EnrollmentStatus.COMPLETED)
    )

    # Total revenue (confirmed payments, this month)
    revenue_month = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount_fcfa), 0)).where(
            Payment.status == PaymentStatus.CONFIRMED,
            Payment.confirmed_at >= month_start,
        )
    )

    # Revenue all-time
    revenue_total = await db.scalar(
        select(func.coalesce(func.sum(Payment.amount_fcfa), 0)).where(
            Payment.status == PaymentStatus.CONFIRMED,
        )
    )

    # Active Cyber Range sessions
    active_range_sessions = await db.scalar(
        select(func.count(CyberRangeSession.id)).where(
            CyberRangeSession.status == CyberRangeStatus.ACTIVE,
        )
    )

    # Completion rate
    total_enroll = (active_enrollments or 0) + (completed_enrollments or 0)
    completion_rate = (
        round((completed_enrollments or 0) / total_enroll * 100, 1)
        if total_enroll > 0 else 0.0
    )

    # Badges issued
    badges_count = await db.scalar(select(func.count(Badge.id)))

    # Top courses by enrollment
    top_courses_result = await db.execute(
        select(
            Course.code,
            Course.title,
            func.count(Enrollment.id).label("enrollments"),
        )
        .join(Enrollment, Enrollment.course_id == Course.id)
        .group_by(Course.code, Course.title)
        .order_by(func.count(Enrollment.id).desc())
        .limit(5)
    )
    top_courses = [
        {"code": row.code, "title": row.title, "enrollments": row.enrollments}
        for row in top_courses_result.all()
    ]

    # Enrollments per day last 7 days
    enrollments_per_day = []
    for i in range(7):
        day = today_start - timedelta(days=i)
        day_end = day + timedelta(days=1)
        count = await db.scalar(
            select(func.count(Enrollment.id)).where(
                Enrollment.created_at >= day,
                Enrollment.created_at < day_end,
            )
        )
        enrollments_per_day.append({
            "date": day.strftime("%Y-%m-%d"),
            "count": count or 0,
        })

    return {
        "total_users": total_users or 0,
        "students": students_count or 0,
        "enrollments_today": enrollments_today or 0,
        "active_enrollments": active_enrollments or 0,
        "completed_enrollments": completed_enrollments or 0,
        "completion_rate_pct": completion_rate,
        "revenue_month_fcfa": revenue_month or 0,
        "revenue_total_fcfa": revenue_total or 0,
        "active_range_sessions": active_range_sessions or 0,
        "badges_issued": badges_count or 0,
        "top_courses": top_courses,
        "enrollments_last_7_days": list(reversed(enrollments_per_day)),
        "generated_at": now.isoformat(),
    }


@router.get("/users", response_model=List[UserResponse])
async def list_users(
    role: Optional[str] = Query(default=None),
    search: Optional[str] = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> List[User]:
    """Liste des utilisateurs avec filtres (admin uniquement)."""
    query = select(User)

    if role:
        query = query.where(User.role == role.upper())

    if search:
        search_term = f"%{search}%"
        query = query.where(
            (User.email.ilike(search_term)) |
            (User.full_name.ilike(search_term))
        )

    query = query.order_by(User.created_at.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/payments", response_model=List[PaymentResponse])
async def list_all_payments(
    status_filter: Optional[str] = Query(default=None, alias="status"),
    limit: int = Query(default=100, ge=1, le=500),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> List[Payment]:
    """Liste de tous les paiements (admin uniquement)."""
    query = select(Payment)
    if status_filter:
        query = query.where(Payment.status == status_filter.upper())
    query = query.order_by(Payment.created_at.desc()).limit(limit)
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/courses/{code}/labs", status_code=status.HTTP_201_CREATED)
async def add_lab_to_course(
    code: str,
    lab_data: Dict[str, Any],
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Ajouter un lab à une formation (admin uniquement)."""
    # Verify course exists
    result = await db.execute(
        select(Course).where(Course.code == code.upper())
    )
    course = result.scalar_one_or_none()
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Formation '{code}' introuvable",
        )

    lab_id = lab_data.get("id")
    if not lab_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le champ 'id' (slug) est requis pour le lab",
        )

    lab = Lab(
        id=lab_id,
        course_code=code.upper(),
        title=lab_data.get("title", ""),
        description=lab_data.get("description", ""),
        difficulty=lab_data.get("difficulty", 1),
        duration_minutes=lab_data.get("duration_minutes", 60),
        docker_image=lab_data.get("docker_image", "ubuntu:22.04"),
        k8s_manifest=lab_data.get("k8s_manifest"),
        objectives=lab_data.get("objectives", []),
        auto_grading_script=lab_data.get("auto_grading_script"),
        order_in_course=lab_data.get("order_in_course", 1),
        is_active=lab_data.get("is_active", True),
    )
    db.add(lab)
    await db.flush()

    return {"message": f"Lab '{lab_id}' ajouté à la formation {code.upper()}", "lab_id": lab_id}


@router.get("/badges", response_model=List[BadgeResponse])
async def list_all_badges(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> List[Badge]:
    """Liste de tous les badges émis (admin uniquement)."""
    result = await db.execute(
        select(Badge).order_by(Badge.issued_at.desc())
    )
    return result.scalars().all()


@router.post("/users/{user_id}/activate")
async def activate_user(
    user_id: str,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Activer ou désactiver un compte utilisateur."""
    import uuid as _uuid
    user = await db.get(User, _uuid.UUID(user_id))
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    user.is_active = not user.is_active
    await db.flush()

    action = "activé" if user.is_active else "désactivé"
    return {"message": f"Compte {action}", "user_id": user_id, "is_active": user.is_active}
