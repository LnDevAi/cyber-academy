"""B2B company accounts and bulk enrollment endpoints."""
import uuid
from typing import Any, Dict, List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin_or_b2b_admin
from app.core.database import get_db
from app.models.company import Company, CompanyPlan
from app.models.course import Course
from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.payment import Payment, PaymentCurrency, PaymentMethod, PaymentStatus
from app.models.user import User, UserRole
from app.schemas.auth import CompanyResponse

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/b2b", tags=["B2B Entreprises"])


class CompanyCreate:
    pass


@router.post("/companies", response_model=CompanyResponse, status_code=status.HTTP_201_CREATED)
async def create_company(
    company_data: Dict[str, Any],
    admin: User = Depends(require_admin_or_b2b_admin),
    db: AsyncSession = Depends(get_db),
) -> Company:
    """Créer un compte entreprise B2B."""
    # Check uniqueness
    existing = await db.execute(
        select(Company).where(Company.contact_email == company_data.get("contact_email", "").lower())
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Une entreprise avec cet email existe déjà",
        )

    plan_str = company_data.get("plan", "STARTER").upper()
    try:
        plan = CompanyPlan(plan_str)
    except ValueError:
        plan = CompanyPlan.STARTER

    company = Company(
        name=company_data.get("name", ""),
        contact_email=company_data.get("contact_email", "").lower(),
        contact_phone=company_data.get("contact_phone"),
        country=company_data.get("country", "BF").upper(),
        plan=plan,
        seats_total=company_data.get("seats_total", 5),
        seats_used=0,
    )
    db.add(company)
    await db.flush()
    await db.refresh(company)

    logger.info("Entreprise B2B créée", company_id=str(company.id), name=company.name)
    return company


@router.get("/companies/{company_id}", response_model=CompanyResponse)
async def get_company(
    company_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Company:
    """Détail d'une entreprise B2B."""
    company = await db.get(Company, company_id)
    if not company:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Entreprise introuvable")

    # B2B admin can only see their own company
    if current_user.role == UserRole.B2B_ADMIN and current_user.company_id != company_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    return company


@router.post("/companies/{company_id}/enroll")
async def bulk_enroll_employees(
    company_id: uuid.UUID,
    enrollment_data: Dict[str, Any],
    current_user: User = Depends(require_admin_or_b2b_admin),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Inscrire en masse les employés d'une entreprise à une formation.
    Body: {course_id: UUID, employee_user_ids: [UUID...]}
    """
    company = await db.get(Company, company_id)
    if not company:
        raise HTTPException(status_code=404, detail="Entreprise introuvable")

    if current_user.role == UserRole.B2B_ADMIN and current_user.company_id != company_id:
        raise HTTPException(status_code=403, detail="Accès refusé")

    course_id_str = enrollment_data.get("course_id")
    employee_ids = enrollment_data.get("employee_user_ids", [])

    if not course_id_str or not employee_ids:
        raise HTTPException(
            status_code=400,
            detail="course_id et employee_user_ids sont requis",
        )

    try:
        course_id = uuid.UUID(course_id_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="course_id invalide")

    course = await db.get(Course, course_id)
    if not course or not course.is_active:
        raise HTTPException(status_code=404, detail="Formation introuvable")

    # Check seat availability
    available_seats = company.seats_total - company.seats_used
    if len(employee_ids) > available_seats:
        raise HTTPException(
            status_code=400,
            detail=f"Sièges insuffisants: {available_seats} disponibles, {len(employee_ids)} demandés",
        )

    created_enrollments = []
    errors = []

    for user_id_str in employee_ids:
        try:
            user_id = uuid.UUID(str(user_id_str))
            user = await db.get(User, user_id)

            if not user:
                errors.append({"user_id": user_id_str, "error": "Utilisateur introuvable"})
                continue

            if user.company_id != company_id:
                errors.append({"user_id": user_id_str, "error": "Utilisateur n'appartient pas à cette entreprise"})
                continue

            # Check not already enrolled
            existing = await db.execute(
                select(Enrollment).where(
                    Enrollment.user_id == user_id,
                    Enrollment.course_id == course_id,
                    Enrollment.status.in_([
                        EnrollmentStatus.PENDING_PAYMENT,
                        EnrollmentStatus.ACTIVE,
                    ]),
                )
            )
            if existing.scalar_one_or_none():
                errors.append({"user_id": user_id_str, "error": "Déjà inscrit"})
                continue

            # Create enrollment (B2B = direct ACTIVE)
            enrollment = Enrollment(
                user_id=user_id,
                course_id=course_id,
                status=EnrollmentStatus.ACTIVE,
                progress_pct=0.0,
            )
            db.add(enrollment)
            created_enrollments.append(user_id_str)

            # Create B2B payment record (company pays)
            payment = Payment(
                user_id=user_id,
                enrollment_id=enrollment.id,
                amount_fcfa=course.price_fcfa,
                currency=PaymentCurrency.XOF,
                method=PaymentMethod.BANK_TRANSFER,
                provider_ref=f"B2B-{company_id}-{user_id}",
                status=PaymentStatus.CONFIRMED,
                installment_number=1,
                installment_total=1,
            )
            db.add(payment)

        except Exception as exc:
            errors.append({"user_id": user_id_str, "error": str(exc)})

    # Update seats used
    company.seats_used += len(created_enrollments)
    await db.flush()

    logger.info(
        "Inscriptions B2B bulk créées",
        company_id=str(company_id),
        course_code=course.code,
        created=len(created_enrollments),
        errors=len(errors),
    )

    return {
        "message": f"{len(created_enrollments)} inscriptions créées",
        "created": created_enrollments,
        "errors": errors,
        "seats_remaining": company.seats_total - company.seats_used,
    }


@router.get("/companies/{company_id}/report")
async def company_training_report(
    company_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Dict[str, Any]:
    """Rapport de complétion de formation pour une entreprise B2B."""
    company = await db.get(Company, company_id)
    if not company:
        raise HTTPException(status_code=404, detail="Entreprise introuvable")

    if current_user.role == UserRole.B2B_ADMIN and current_user.company_id != company_id:
        raise HTTPException(status_code=403, detail="Accès refusé")

    # Get all employees
    employees_result = await db.execute(
        select(User).where(User.company_id == company_id)
    )
    employees = employees_result.scalars().all()

    employee_ids = [e.id for e in employees]

    if not employee_ids:
        return {
            "company": {"id": str(company_id), "name": company.name},
            "summary": {"total_employees": 0, "enrolled": 0, "completed": 0, "active": 0},
            "employees": [],
        }

    # Get all enrollments for this company's employees
    enrollments_result = await db.execute(
        select(Enrollment, Course, User)
        .join(Course, Course.id == Enrollment.course_id)
        .join(User, User.id == Enrollment.user_id)
        .where(Enrollment.user_id.in_(employee_ids))
        .order_by(User.full_name, Course.code)
    )

    rows = enrollments_result.all()

    # Build report
    employee_reports = {}
    for enrollment, course, user in rows:
        emp_id = str(user.id)
        if emp_id not in employee_reports:
            employee_reports[emp_id] = {
                "user_id": emp_id,
                "full_name": user.full_name,
                "email": user.email,
                "enrollments": [],
            }
        employee_reports[emp_id]["enrollments"].append({
            "course_code": course.code,
            "course_title": course.title,
            "status": enrollment.status.value,
            "progress_pct": enrollment.progress_pct,
            "started_at": enrollment.started_at.isoformat() if enrollment.started_at else None,
            "completed_at": enrollment.completed_at.isoformat() if enrollment.completed_at else None,
        })

    total_enrollments = len(rows)
    completed = sum(1 for e, _, _ in rows if e.status.value == "COMPLETED")
    active = sum(1 for e, _, _ in rows if e.status.value == "ACTIVE")

    return {
        "company": {
            "id": str(company_id),
            "name": company.name,
            "plan": company.plan.value,
            "seats_total": company.seats_total,
            "seats_used": company.seats_used,
        },
        "summary": {
            "total_employees": len(employees),
            "enrolled": len(employee_reports),
            "total_enrollments": total_enrollments,
            "completed": completed,
            "active": active,
            "completion_rate_pct": round(completed / total_enrollments * 100, 1) if total_enrollments > 0 else 0.0,
        },
        "employees": list(employee_reports.values()),
        "generated_at": __import__("datetime").datetime.now(__import__("datetime").timezone.utc).isoformat(),
    }
