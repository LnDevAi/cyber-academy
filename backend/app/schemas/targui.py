"""TARGUI AI tutor schemas."""
import uuid
from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    session_id: str = Field(description="Identifiant de session de conversation (UUID v4)")
    enrollment_id: Optional[uuid.UUID] = Field(
        default=None, description="Contexte de formation en cours"
    )
    lab_id: Optional[str] = Field(
        default=None, description="Contexte du lab Cyber Range en cours"
    )


class ChatResponse(BaseModel):
    session_id: str
    message_id: uuid.UUID
    response: str
    model: str
    sources: List[str] = Field(default_factory=list, description="Documents sources RAG utilisés")
    input_tokens: Optional[int] = None
    output_tokens: Optional[int] = None
    created_at: datetime


class QuizQuestion(BaseModel):
    question: str
    options: List[str]
    correct_answer: int  # index in options list
    explanation: str


class QuizResponse(BaseModel):
    course_code: str
    topic: str
    questions: List[QuizQuestion]
    generated_at: datetime


class HintRequest(BaseModel):
    lab_id: str
    user_action: str = Field(
        max_length=1000, description="Ce que l'apprenant vient de faire ou d'essayer"
    )
    session_id: str


class HintResponse(BaseModel):
    hint: str
    confidence: float
    related_concepts: List[str]


class ConceptExplainRequest(BaseModel):
    concept: str = Field(max_length=500)
    course_code: Optional[str] = None
    detail_level: str = Field(default="intermediate", pattern=r"^(beginner|intermediate|advanced)$")


class ConceptExplainResponse(BaseModel):
    concept: str
    explanation: str
    examples: List[str]
    related_topics: List[str]
    references: List[str]


class ChatSessionSummary(BaseModel):
    session_id: str
    message_count: int
    first_message_at: datetime
    last_message_at: datetime
    course_code: Optional[str]
    lab_id: Optional[str]
