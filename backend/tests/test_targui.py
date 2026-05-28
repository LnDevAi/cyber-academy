"""Tests for TARGUI AI tutor endpoints."""
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import AsyncClient

from app.models.user import User


@pytest.mark.asyncio
async def test_targui_chat_success(client: AsyncClient, test_student: User, student_token: str):
    """Test TARGUI chat endpoint with mocked Claude API."""
    session_id = str(uuid.uuid4())

    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.chat = AsyncMock(return_value={
            "response": (
                "Bonjour! Le phishing est une technique d'ingénierie sociale où un attaquant "
                "se fait passer pour une entité de confiance pour voler des informations. "
                "En zone UEMOA, nous observons de nombreux cas de phishing Mobile Money, "
                "notamment des SMS frauduleux imitant Orange Money. "
                "Pouvez-vous me dire quel aspect du phishing vous souhaitez approfondir?"
            ),
            "model": "claude-sonnet-4-6",
            "input_tokens": 450,
            "output_tokens": 120,
            "sources": ["CACP", "context"],
        })

        response = await client.post(
            "/api/v1/targui/chat",
            json={
                "message": "Qu'est-ce que le phishing? Donne moi un exemple en Afrique de l'Ouest.",
                "session_id": session_id,
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert data["session_id"] == session_id
    assert "message_id" in data
    assert data["model"] == "claude-sonnet-4-6"
    assert len(data["response"]) > 50
    assert "created_at" in data


@pytest.mark.asyncio
async def test_targui_chat_with_enrollment_context(
    client: AsyncClient,
    test_student: User,
    student_token: str,
    test_active_enrollment,
):
    """Test TARGUI chat with enrollment context provides relevant response."""
    session_id = str(uuid.uuid4())

    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.chat = AsyncMock(return_value={
            "response": (
                "Dans le cadre de votre formation CACP, les labs pratiques vous aideront "
                "à identifier les tentatives de phishing. Pour le Lab 1, concentrez-vous sur "
                "l'analyse des en-têtes d'email. Quelle partie du lab vous pose problème?"
            ),
            "model": "claude-sonnet-4-6",
            "input_tokens": 520,
            "output_tokens": 95,
            "sources": ["CACP"],
        })

        response = await client.post(
            "/api/v1/targui/chat",
            json={
                "message": "Comment détecter un email de phishing dans mes labs?",
                "session_id": session_id,
                "enrollment_id": str(test_active_enrollment.id),
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert len(data["response"]) > 20


@pytest.mark.asyncio
async def test_targui_chat_requires_auth(client: AsyncClient):
    """Test that TARGUI chat requires authentication."""
    response = await client.post(
        "/api/v1/targui/chat",
        json={"message": "Hello", "session_id": "test"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_targui_list_sessions_empty(client: AsyncClient, test_student: User, student_token: str):
    """Test listing chat sessions when none exist."""
    response = await client.get(
        "/api/v1/targui/sessions",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    assert response.json() == []


@pytest.mark.asyncio
async def test_targui_list_sessions_after_chat(client: AsyncClient, test_student: User, student_token: str):
    """Test that chat session appears in session list after chatting."""
    session_id = str(uuid.uuid4())

    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.chat = AsyncMock(return_value={
            "response": "Voici une explication du concept demandé...",
            "model": "claude-sonnet-4-6",
            "input_tokens": 100,
            "output_tokens": 50,
            "sources": [],
        })

        await client.post(
            "/api/v1/targui/chat",
            json={"message": "Question test", "session_id": session_id},
            headers={"Authorization": f"Bearer {student_token}"},
        )

    response = await client.get(
        "/api/v1/targui/sessions",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    sessions = response.json()
    session_ids = [s["session_id"] for s in sessions]
    assert session_id in session_ids


@pytest.mark.asyncio
async def test_targui_delete_session(client: AsyncClient, test_student: User, student_token: str):
    """Test deleting a TARGUI chat session."""
    session_id = str(uuid.uuid4())

    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.chat = AsyncMock(return_value={
            "response": "Message de test",
            "model": "claude-sonnet-4-6",
            "input_tokens": 50,
            "output_tokens": 20,
            "sources": [],
        })

        await client.post(
            "/api/v1/targui/chat",
            json={"message": "Message à supprimer", "session_id": session_id},
            headers={"Authorization": f"Bearer {student_token}"},
        )

    # Delete the session
    delete_response = await client.delete(
        f"/api/v1/targui/sessions/{session_id}",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert delete_response.status_code == 204

    # Verify it's gone
    sessions_response = await client.get(
        "/api/v1/targui/sessions",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    session_ids = [s["session_id"] for s in sessions_response.json()]
    assert session_id not in session_ids


@pytest.mark.asyncio
async def test_targui_delete_nonexistent_session(client: AsyncClient, student_token: str):
    """Test deleting a non-existent session returns 404."""
    response = await client.delete(
        "/api/v1/targui/sessions/nonexistent-session-id",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 404


@pytest.mark.asyncio
async def test_targui_hint_endpoint(client: AsyncClient, student_token: str):
    """Test TARGUI hint endpoint for lab guidance."""
    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.get_hint = AsyncMock(return_value={
            "hint": "Avez-vous essayé d'analyser les en-têtes HTTP de la réponse? Regardez le champ 'X-Powered-By'.",
            "confidence": 0.85,
            "related_concepts": ["HTTP headers", "Information disclosure", "Reconnaissance"],
        })

        response = await client.post(
            "/api/v1/targui/hint",
            json={
                "lab_id": "waso-lab-01",
                "user_action": "J'ai essayé de faire une requête GET sur /admin mais j'obtiens 403",
                "session_id": str(uuid.uuid4()),
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "hint" in data
    assert len(data["hint"]) > 10
    assert "confidence" in data


@pytest.mark.asyncio
async def test_targui_quiz_generation(client: AsyncClient, student_token: str):
    """Test TARGUI quiz generation endpoint."""
    with patch("app.api.v1.targui.targui_service") as mock_targui:
        mock_targui.generate_quiz = AsyncMock(return_value=[
            {
                "question": "Qu'est-ce que le phishing?",
                "options": [
                    "A: Une technique de pêche sportive",
                    "B: Une attaque d'ingénierie sociale par email frauduleux",
                    "C: Un logiciel antivirus",
                    "D: Un protocole réseau",
                ],
                "correct_answer": 1,
                "explanation": "Le phishing est une technique d'ingénierie sociale...",
            }
        ])

        response = await client.get(
            "/api/v1/targui/quiz/CACP?topic=Phishing&n=1",
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert data["course_code"] == "CACP"
    assert data["topic"] == "Phishing"
    assert len(data["questions"]) == 1
    q = data["questions"][0]
    assert "question" in q
    assert "options" in q
    assert "correct_answer" in q
    assert "explanation" in q
