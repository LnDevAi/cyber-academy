"""Tests for authentication endpoints."""
import pytest
from httpx import AsyncClient

from app.models.user import User, UserRole


@pytest.mark.asyncio
async def test_register_success(client: AsyncClient):
    """Test successful user registration."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "nouveau@test.com",
            "password": "Secure1234!",
            "full_name": "Nouveau Utilisateur",
            "phone": "+22670000002",
            "country": "BF",
        },
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "nouveau@test.com"
    assert data["full_name"] == "Nouveau Utilisateur"
    assert data["role"] == "STUDENT"
    assert data["country"] == "BF"
    assert "hashed_password" not in data


@pytest.mark.asyncio
async def test_register_duplicate_email(client: AsyncClient, test_student: User):
    """Test that registering with a duplicate email fails."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "etudiant@test.com",  # Already exists
            "password": "Secure1234!",
            "full_name": "Doublon Test",
        },
    )
    assert response.status_code == 409
    assert "existe déjà" in response.json()["detail"]


@pytest.mark.asyncio
async def test_register_weak_password(client: AsyncClient):
    """Test that a weak password is rejected."""
    response = await client.post(
        "/api/v1/auth/register",
        json={
            "email": "test2@test.com",
            "password": "weak",
            "full_name": "Test User",
        },
    )
    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_login_success(client: AsyncClient, test_student: User):
    """Test successful login returns JWT tokens."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "etudiant@test.com",
            "password": "Test1234!",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["token_type"] == "bearer"
    assert data["requires_2fa"] == False
    assert data["expires_in"] > 0


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, test_student: User):
    """Test login with wrong password fails."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "etudiant@test.com",
            "password": "WrongPassword!",
        },
    )
    assert response.status_code == 401
    assert "incorrect" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_nonexistent_user(client: AsyncClient):
    """Test login with non-existent email fails."""
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "email": "inexistant@test.com",
            "password": "Test1234!",
        },
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_get_me_authenticated(client: AsyncClient, test_student: User, student_token: str):
    """Test getting current user profile with valid token."""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "etudiant@test.com"
    assert data["full_name"] == "Moussa Diallo"
    assert data["role"] == "STUDENT"


@pytest.mark.asyncio
async def test_get_me_unauthenticated(client: AsyncClient):
    """Test that /me endpoint requires authentication."""
    response = await client.get("/api/v1/auth/me")
    assert response.status_code == 403  # Missing credentials


@pytest.mark.asyncio
async def test_get_me_invalid_token(client: AsyncClient):
    """Test that /me endpoint rejects invalid tokens."""
    response = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer invalid_token_here"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_refresh_token_success(client: AsyncClient, test_student: User):
    """Test that a valid refresh token generates new tokens."""
    from app.core.security import create_refresh_token

    refresh_token = create_refresh_token(str(test_student.id))

    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data


@pytest.mark.asyncio
async def test_refresh_token_invalid(client: AsyncClient):
    """Test that an invalid refresh token is rejected."""
    response = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": "invalid.refresh.token"},
    )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_2fa_setup(client: AsyncClient, test_student: User, student_token: str):
    """Test TOTP 2FA setup returns QR code."""
    response = await client.post(
        "/api/v1/auth/2fa/setup",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "secret" in data
    assert "qr_code_base64" in data
    assert "otp_uri" in data
    assert len(data["secret"]) > 10
    assert data["otp_uri"].startswith("otpauth://totp/")


@pytest.mark.asyncio
async def test_update_profile(client: AsyncClient, test_student: User, student_token: str):
    """Test updating user profile."""
    response = await client.patch(
        "/api/v1/auth/me",
        json={"full_name": "Moussa Ouédraogo", "phone": "+22670999999"},
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["full_name"] == "Moussa Ouédraogo"
    assert data["phone"] == "+22670999999"
