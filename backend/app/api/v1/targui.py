"""TARGUI AI tutor endpoints."""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.models.chat_message import ChatMessage
from app.models.user import User
from app.schemas.targui import (
    ChatRequest,
    ChatResponse,
    ChatSessionSummary,
    ConceptExplainRequest,
    ConceptExplainResponse,
    HintRequest,
    HintResponse,
    QuizResponse,
)
from app.services.ai.targui import targui_service

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/targui", tags=["TARGUI — Tuteur IA"])


@router.post("/chat", response_model=ChatResponse)
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Envoyer un message à TARGUI, le tuteur IA RAG de Cyber Academy.
    Retourne une réponse contextualisée basée sur le cours et le lab en cours.
    """
    # Save user message to DB
    user_message = ChatMessage(
        user_id=current_user.id,
        session_id=request.session_id,
        role="user",
        content=request.message,
        enrollment_id=request.enrollment_id,
        lab_id=request.lab_id,
    )
    db.add(user_message)
    await db.flush()

    # Get course context if enrollment provided
    context = {}
    if request.enrollment_id:
        from app.models.enrollment import Enrollment
        from app.models.course import Course
        enrollment = await db.get(Enrollment, request.enrollment_id)
        if enrollment:
            course = await db.get(Course, enrollment.course_id)
            if course:
                context["course_code"] = course.code
                user_message.course_code = course.code

    if request.lab_id:
        context["lab_id"] = request.lab_id

    # Call TARGUI service
    try:
        result = await targui_service.chat(
            user_message=request.message,
            session_id=request.session_id,
            context=context,
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        )

    # Save assistant response
    message_id = uuid.uuid4()
    assistant_message = ChatMessage(
        id=message_id,
        user_id=current_user.id,
        session_id=request.session_id,
        role="assistant",
        content=result["response"],
        enrollment_id=request.enrollment_id,
        lab_id=request.lab_id,
        course_code=context.get("course_code"),
        input_tokens=result.get("input_tokens"),
        output_tokens=result.get("output_tokens"),
    )
    db.add(assistant_message)
    await db.flush()

    return {
        "session_id": request.session_id,
        "message_id": message_id,
        "response": result["response"],
        "model": result["model"],
        "sources": result.get("sources", []),
        "input_tokens": result.get("input_tokens"),
        "output_tokens": result.get("output_tokens"),
        "created_at": assistant_message.created_at,
    }


@router.get("/sessions", response_model=List[ChatSessionSummary])
async def list_sessions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[dict]:
    """Lister les sessions de conversation TARGUI."""
    result = await db.execute(
        select(
            ChatMessage.session_id,
            func.count(ChatMessage.id).label("message_count"),
            func.min(ChatMessage.created_at).label("first_message_at"),
            func.max(ChatMessage.created_at).label("last_message_at"),
            func.max(ChatMessage.course_code).label("course_code"),
            func.max(ChatMessage.lab_id).label("lab_id"),
        )
        .where(ChatMessage.user_id == current_user.id)
        .group_by(ChatMessage.session_id)
        .order_by(func.max(ChatMessage.created_at).desc())
    )

    rows = result.all()
    return [
        {
            "session_id": row.session_id,
            "message_count": row.message_count,
            "first_message_at": row.first_message_at,
            "last_message_at": row.last_message_at,
            "course_code": row.course_code,
            "lab_id": row.lab_id,
        }
        for row in rows
    ]


@router.delete("/sessions/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def clear_session(
    session_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Effacer l'historique d'une session de conversation TARGUI."""
    result = await db.execute(
        select(ChatMessage).where(
            ChatMessage.session_id == session_id,
            ChatMessage.user_id == current_user.id,
        )
    )
    messages = result.scalars().all()

    if not messages:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session introuvable",
        )

    for message in messages:
        await db.delete(message)

    await db.flush()
    logger.info("Session TARGUI effacée", session_id=session_id)


@router.post("/hint", response_model=HintResponse)
async def get_hint(
    request: HintRequest,
    current_user: User = Depends(get_current_user),
) -> dict:
    """Obtenir un indice contextuel pour un lab sans recevoir la solution."""
    try:
        result = await targui_service.get_hint(request.lab_id, request.user_action)
        return result
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Erreur TARGUI: {str(exc)}")


@router.get("/quiz/{course_code}")
async def generate_quiz(
    course_code: str,
    topic: str = "Concepts fondamentaux",
    n: int = 5,
    current_user: User = Depends(get_current_user),
) -> dict:
    """Générer un QCM de révision pour une formation et un thème donnés."""
    try:
        questions = await targui_service.generate_quiz(
            course_code=course_code.upper(),
            topic=topic,
            n_questions=min(n, 10),
        )
        return {
            "course_code": course_code.upper(),
            "topic": topic,
            "questions": questions,
            "generated_at": datetime.now(timezone.utc),
        }
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Erreur génération quiz: {str(exc)}")


@router.post("/explain")
async def explain_concept(
    request: ConceptExplainRequest,
    current_user: User = Depends(get_current_user),
) -> dict:
    """Demander à TARGUI une explication approfondie d'un concept de cybersécurité."""
    try:
        result = await targui_service.explain_concept(request.concept, request.course_code)
        return {
            "concept": request.concept,
            "explanation": result.get("explanation", ""),
            "examples": result.get("examples", []),
            "related_topics": result.get("related_topics", []),
            "references": result.get("references", []),
        }
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"Erreur TARGUI: {str(exc)}")
