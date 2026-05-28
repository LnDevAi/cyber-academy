"""User model."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class UserRole(str, enum.Enum):
    STUDENT = "STUDENT"
    MENTOR = "MENTOR"
    ADMIN = "ADMIN"
    B2B_ADMIN = "B2B_ADMIN"


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    country: Mapped[str] = mapped_column(String(3), default="BF")  # ISO 3166 code
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, schema="cyber_academy"),
        default=UserRole.STUDENT,
        nullable=False,
    )
    # 2FA
    totp_secret: Mapped[str | None] = mapped_column(String(64), nullable=True)
    is_2fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    # B2B
    company_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.companies.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    # Moodle integration
    moodle_user_id: Mapped[int | None] = mapped_column(nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Relationships
    company: Mapped["Company | None"] = relationship("Company", back_populates="users")
    enrollments: Mapped[list["Enrollment"]] = relationship("Enrollment", back_populates="user", foreign_keys="Enrollment.user_id")
    payments: Mapped[list["Payment"]] = relationship("Payment", back_populates="user")
    badges: Mapped[list["Badge"]] = relationship("Badge", back_populates="user")
    cyber_range_sessions: Mapped[list["CyberRangeSession"]] = relationship("CyberRangeSession", back_populates="user")
    chat_messages: Mapped[list["ChatMessage"]] = relationship("ChatMessage", back_populates="user")
    mentor_sessions_as_student: Mapped[list["MentorSession"]] = relationship(
        "MentorSession", foreign_keys="MentorSession.student_id", back_populates="student"
    )
    mentor_sessions_as_mentor: Mapped[list["MentorSession"]] = relationship(
        "MentorSession", foreign_keys="MentorSession.mentor_id", back_populates="mentor"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email} role={self.role}>"
