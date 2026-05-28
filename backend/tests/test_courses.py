"""Tests for course catalog endpoints."""
import uuid
import pytest
from httpx import AsyncClient

from app.models.course import Course, CourseLevel, CoursePartner, CourseType
from app.models.user import User


@pytest.mark.asyncio
async def test_list_courses_public(client: AsyncClient, test_course: Course):
    """Test that the course catalog is publicly accessible."""
    response = await client.get("/api/v1/courses")
    assert response.status_code == 200
    courses = response.json()
    assert isinstance(courses, list)
    assert len(courses) >= 1
    # Verify CACP is in the list
    codes = [c["code"] for c in courses]
    assert "CACP" in codes


@pytest.mark.asyncio
async def test_list_courses_filter_by_partner(client: AsyncClient, test_course: Course, test_course_pecb: Course):
    """Test filtering courses by partner."""
    response = await client.get("/api/v1/courses?partner=EDEFENCE")
    assert response.status_code == 200
    courses = response.json()
    for c in courses:
        assert c["partner"] == "EDEFENCE"


@pytest.mark.asyncio
async def test_list_courses_filter_by_level(client: AsyncClient, test_course: Course):
    """Test filtering courses by level."""
    response = await client.get("/api/v1/courses?level=BEGINNER")
    assert response.status_code == 200
    courses = response.json()
    for c in courses:
        assert c["level"] == "BEGINNER"


@pytest.mark.asyncio
async def test_get_course_detail(client: AsyncClient, test_course: Course):
    """Test retrieving a single course by code."""
    response = await client.get("/api/v1/courses/CACP")
    assert response.status_code == 200
    data = response.json()
    assert data["code"] == "CACP"
    assert data["title"] == "Certified Associate in Cybersecurity Practice"
    assert data["price_fcfa"] == 75000
    assert data["hours_total"] == 40
    assert data["partner"] == "EDEFENCE"
    assert data["level"] == "BEGINNER"


@pytest.mark.asyncio
async def test_get_course_not_found(client: AsyncClient):
    """Test that requesting a non-existent course returns 404."""
    response = await client.get("/api/v1/courses/NONEXISTENT")
    assert response.status_code == 404
    assert "introuvable" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_get_course_case_insensitive(client: AsyncClient, test_course: Course):
    """Test that course code lookup is case-insensitive."""
    response = await client.get("/api/v1/courses/cacp")
    assert response.status_code == 200
    assert response.json()["code"] == "CACP"


@pytest.mark.asyncio
async def test_create_course_admin(client: AsyncClient, test_admin: User, admin_token: str):
    """Test that an admin can create a new course."""
    response = await client.post(
        "/api/v1/courses",
        json={
            "code": "TEST101",
            "title": "Formation Test",
            "description": "Description de la formation test",
            "type": "ECERT",
            "partner": "EDEFENCE",
            "level": "BEGINNER",
            "hours_total": 20,
            "price_fcfa": 50000,
        },
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 201
    data = response.json()
    assert data["code"] == "TEST101"
    assert data["price_fcfa"] == 50000


@pytest.mark.asyncio
async def test_create_course_forbidden_student(client: AsyncClient, student_token: str):
    """Test that a student cannot create a course."""
    response = await client.post(
        "/api/v1/courses",
        json={
            "code": "TEST102",
            "title": "Formation Non Autorisée",
            "description": "...",
            "type": "ECERT",
            "partner": "EDEFENCE",
            "level": "BEGINNER",
            "hours_total": 10,
            "price_fcfa": 10000,
        },
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_update_course_admin(client: AsyncClient, test_course: Course, admin_token: str):
    """Test that an admin can update a course."""
    response = await client.patch(
        "/api/v1/courses/CACP",
        json={"price_fcfa": 80000},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == 200
    assert response.json()["price_fcfa"] == 80000


@pytest.mark.asyncio
async def test_inactive_course_hidden(client: AsyncClient, db, test_admin: User, admin_token: str):
    """Test that inactive courses are not shown in the catalog."""
    # Create an inactive course
    inactive_course = Course(
        id=uuid.uuid4(),
        code="INACTIVE",
        title="Formation Inactive",
        description="...",
        type=CourseType.ECERT,
        partner=CoursePartner.EDEFENCE,
        level=CourseLevel.BEGINNER,
        hours_total=10,
        price_fcfa=10000,
        is_active=False,
    )
    db.add(inactive_course)
    await db.flush()

    response = await client.get("/api/v1/courses")
    codes = [c["code"] for c in response.json()]
    assert "INACTIVE" not in codes
