"""MentorSession model — 1:1 mentor/student sessions."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class MentorSessionStatus(str, enum.Enum):
    SCHEDULED = "SCHEDULED"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"


class MentorSession(Base):
    __tablename__ = "mentor_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    mentor_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    student_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    enrollment_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.enrollments.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    scheduled_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    duration_minutes: Mapped[int] = mapped_column(Integer, default=60, nullable=False)
    status: Mapped[MentorSessionStatus] = mapped_column(
        Enum(MentorSessionStatus, schema="cyber_academy"),
        default=MentorSessionStatus.SCHEDULED,
        nullable=False,
    )
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    zoom_link: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    zoom_meeting_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    mentor: Mapped["User"] = relationship(
        "User", foreign_keys=[mentor_id], back_populates="mentor_sessions_as_mentor"
    )
    student: Mapped["User"] = relationship(
        "User", foreign_keys=[student_id], back_populates="mentor_sessions_as_student"
    )
    enrollment: Mapped["Enrollment | None"] = relationship(
        "Enrollment", back_populates="mentor_sessions"
    )

    def __repr__(self) -> str:
        return f"<MentorSession id={self.id} mentor={self.mentor_id} student={self.student_id} status={self.status}>"
