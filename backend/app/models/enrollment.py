"""Enrollment model — student course registrations."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class EnrollmentStatus(str, enum.Enum):
    PENDING_PAYMENT = "PENDING_PAYMENT"
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    EXPIRED = "EXPIRED"
    REFUNDED = "REFUNDED"


class Enrollment(Base):
    __tablename__ = "enrollments"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    course_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.courses.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    status: Mapped[EnrollmentStatus] = mapped_column(
        Enum(EnrollmentStatus, schema="cyber_academy"),
        default=EnrollmentStatus.PENDING_PAYMENT,
        nullable=False,
    )
    progress_pct: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    # Moodle integration
    moodle_enrollment_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    moodle_user_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Dates
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
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
    user: Mapped["User"] = relationship("User", back_populates="enrollments", foreign_keys=[user_id])
    course: Mapped["Course"] = relationship("Course", back_populates="enrollments")
    payments: Mapped[list["Payment"]] = relationship("Payment", back_populates="enrollment")
    badge: Mapped["Badge | None"] = relationship("Badge", back_populates="enrollment", uselist=False)
    cyber_range_sessions: Mapped[list["CyberRangeSession"]] = relationship(
        "CyberRangeSession", back_populates="enrollment"
    )
    mentor_sessions: Mapped[list["MentorSession"]] = relationship(
        "MentorSession", back_populates="enrollment"
    )

    def __repr__(self) -> str:
        return f"<Enrollment id={self.id} user={self.user_id} course={self.course_id} status={self.status}>"
