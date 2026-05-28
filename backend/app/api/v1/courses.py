"""Course catalog endpoints."""
import uuid
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, require_admin
from app.core.database import get_db
from app.models.course import Course
from app.models.user import User
from app.schemas.course import CourseCreate, CourseListResponse, CourseResponse, CourseUpdate

router = APIRouter(prefix="/courses", tags=["Catalogue de formations"])


@router.get("", response_model=List[CourseListResponse])
async def list_courses(
    partner: Optional[str] = Query(default=None, description="Filtrer par partenaire"),
    level: Optional[str] = Query(default=None, description="Filtrer par niveau"),
    type: Optional[str] = Query(default=None, description="ECERT ou INTERNATIONAL"),
    db: AsyncSession = Depends(get_db),
) -> List[Course]:
    """Catalogue public des formations — toutes les formations actives."""
    query = select(Course).where(Course.is_active == True)

    if partner:
        query = query.where(Course.partner == partner.upper())
    if level:
        query = query.where(Course.level == level.upper())
    if type:
        query = query.where(Course.type == type.upper())

    query = query.order_by(Course.level, Course.price_fcfa)
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{code}", response_model=CourseResponse)
async def get_course(
    code: str,
    db: AsyncSession = Depends(get_db),
) -> Course:
    """Détail d'une formation — programme, prérequis, labs, prix, partenaire."""
    result = await db.execute(
        select(Course).where(
            Course.code == code.upper(),
            Course.is_active == True,
        ).options(selectinload(Course.labs))
    )
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Formation '{code}' introuvable",
        )

    return course


@router.post("", response_model=CourseResponse, status_code=status.HTTP_201_CREATED)
async def create_or_update_course(
    course_data: CourseCreate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Course:
    """Créer ou mettre à jour une formation (admin uniquement)."""
    # Check if course with code already exists
    existing = await db.execute(
        select(Course).where(Course.code == course_data.code.upper())
    )
    course = existing.scalar_one_or_none()

    if course:
        # Update existing
        for field, value in course_data.model_dump(exclude_none=True).items():
            setattr(course, field, value)
        course.code = course.code.upper()
    else:
        # Create new
        course = Course(
            **{**course_data.model_dump(), "code": course_data.code.upper()}
        )
        db.add(course)

    await db.flush()
    await db.refresh(course)
    return course


@router.patch("/{code}", response_model=CourseResponse)
async def update_course(
    code: str,
    update_data: CourseUpdate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
) -> Course:
    """Mettre à jour une formation existante (admin uniquement)."""
    result = await db.execute(
        select(Course).where(Course.code == code.upper())
    )
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Formation '{code}' introuvable",
        )

    for field, value in update_data.model_dump(exclude_none=True).items():
        setattr(course, field, value)

    await db.flush()
    await db.refresh(course)
    return course
