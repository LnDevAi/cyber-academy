"""Test fixtures and configuration for Cyber Academy E-DEFENCE backend tests."""
import asyncio
import uuid
from typing import AsyncGenerator, Generator

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy import MetaData, event
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.security import create_access_token, hash_password

# Use SQLite for testing (in-memory, no schema prefix)
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Create a test-specific Base without schema
test_metadata = MetaData()  # No schema for SQLite

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    echo=False,
)

TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


def get_test_base():
    """Get a test base with no schema (for SQLite compatibility)."""
    from app.core.database import Base
    # Temporarily remove schema for testing
    for table in Base.metadata.sorted_tables:
        table.schema = None
    return Base


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an event loop for the test session."""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="function")
async def db() -> AsyncGenerator[AsyncSession, None]:
    """Create a fresh database for each test function."""
    from app.core.database import Base

    # Patch all table schemas to None for SQLite compatibility
    for table in Base.metadata.sorted_tables:
        table.schema = None

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with TestSessionLocal() as session:
        yield session
        await session.rollback()

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture(scope="function")
async def client(db: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Create a test HTTP client with database session override."""
    from app.core.database import get_db
    from app.main import app

    async def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


# ── Test Data Factories ──────────────────────────────────────────────────────

@pytest_asyncio.fixture
async def test_student(db: AsyncSession):
    """Create a standard student user."""
    from app.models.user import User, UserRole
    user = User(
        id=uuid.uuid4(),
        email="etudiant@test.com",
        hashed_password=hash_password("Test1234!"),
        full_name="Moussa Diallo",
        phone="+22670000001",
        country="BF",
        role=UserRole.STUDENT,
        is_active=True,
        is_2fa_enabled=False,
    )
    db.add(user)
    await db.flush()
    return user


@pytest_asyncio.fixture
async def test_admin(db: AsyncSession):
    """Create an admin user."""
    from app.models.user import User, UserRole
    user = User(
        id=uuid.uuid4(),
        email="admin@edefence.tech",
        hashed_password=hash_password("Admin1234!"),
        full_name="Admin Système",
        country="BF",
        role=UserRole.ADMIN,
        is_active=True,
        is_2fa_enabled=False,
    )
    db.add(user)
    await db.flush()
    return user


@pytest_asyncio.fixture
async def test_mentor(db: AsyncSession):
    """Create a mentor user."""
    from app.models.user import User, UserRole
    user = User(
        id=uuid.uuid4(),
        email="mentor@edefence.tech",
        hashed_password=hash_password("Mentor1234!"),
        full_name="Aminata Coulibaly",
        country="CI",
        role=UserRole.MENTOR,
        is_active=True,
        is_2fa_enabled=False,
    )
    db.add(user)
    await db.flush()
    return user


@pytest_asyncio.fixture
async def test_course(db: AsyncSession):
    """Create a test course (CACP)."""
    from app.models.course import Course, CourseLevel, CoursePartner, CourseType
    course = Course(
        id=uuid.uuid4(),
        code="CACP",
        title="Certified Associate in Cybersecurity Practice",
        description="Formation de base en cybersécurité pour l'espace UEMOA.",
        type=CourseType.ECERT,
        partner=CoursePartner.EDEFENCE,
        level=CourseLevel.BEGINNER,
        hours_total=40,
        price_fcfa=75000,
        is_active=True,
    )
    db.add(course)
    await db.flush()
    return course


@pytest_asyncio.fixture
async def test_course_pecb(db: AsyncSession):
    """Create a test PECB course (ISO27001_LI)."""
    from app.models.course import Course, CourseLevel, CoursePartner, CourseType
    course = Course(
        id=uuid.uuid4(),
        code="ISO27001_LI",
        title="ISO 27001 Lead Implementer",
        description="Certification PECB ISO 27001.",
        type=CourseType.INTERNATIONAL,
        partner=CoursePartner.PECB,
        level=CourseLevel.ADVANCED,
        hours_total=100,
        price_fcfa=650000,
        moodle_course_id=42,
        is_active=True,
    )
    db.add(course)
    await db.flush()
    return course


@pytest_asyncio.fixture
async def test_enrollment(db: AsyncSession, test_student, test_course):
    """Create a test enrollment (PENDING_PAYMENT)."""
    from app.models.enrollment import Enrollment, EnrollmentStatus
    enrollment = Enrollment(
        id=uuid.uuid4(),
        user_id=test_student.id,
        course_id=test_course.id,
        status=EnrollmentStatus.PENDING_PAYMENT,
        progress_pct=0.0,
    )
    db.add(enrollment)
    await db.flush()
    return enrollment


@pytest_asyncio.fixture
async def test_active_enrollment(db: AsyncSession, test_student, test_course):
    """Create a test enrollment (ACTIVE)."""
    from datetime import datetime, timezone, timedelta
    from app.models.enrollment import Enrollment, EnrollmentStatus
    enrollment = Enrollment(
        id=uuid.uuid4(),
        user_id=test_student.id,
        course_id=test_course.id,
        status=EnrollmentStatus.ACTIVE,
        progress_pct=45.5,
        started_at=datetime.now(timezone.utc),
        expires_at=datetime.now(timezone.utc) + timedelta(days=365),
    )
    db.add(enrollment)
    await db.flush()
    return enrollment


@pytest_asyncio.fixture
async def test_company(db: AsyncSession):
    """Create a test B2B company."""
    from app.models.company import Company, CompanyPlan
    company = Company(
        id=uuid.uuid4(),
        name="TechSarl Ouagadougou",
        contact_email="contact@techsarl.bf",
        contact_phone="+22670000100",
        country="BF",
        plan=CompanyPlan.PRO,
        seats_total=20,
        seats_used=3,
    )
    db.add(company)
    await db.flush()
    return company


@pytest_asyncio.fixture
async def student_token(test_student) -> str:
    """Generate a valid JWT access token for the test student."""
    from app.models.user import UserRole
    return create_access_token(
        str(test_student.id),
        extra_claims={"role": test_student.role.value, "email": test_student.email},
    )


@pytest_asyncio.fixture
async def admin_token(test_admin) -> str:
    """Generate a valid JWT access token for the test admin."""
    return create_access_token(
        str(test_admin.id),
        extra_claims={"role": test_admin.role.value, "email": test_admin.email},
    )


@pytest_asyncio.fixture
async def mentor_token(test_mentor) -> str:
    """Generate a valid JWT access token for the test mentor."""
    return create_access_token(
        str(test_mentor.id),
        extra_claims={"role": test_mentor.role.value, "email": test_mentor.email},
    )
