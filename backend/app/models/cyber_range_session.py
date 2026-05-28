"""CyberRangeSession model — k3s lab provisioning sessions."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Float, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CyberRangeStatus(str, enum.Enum):
    PROVISIONING = "PROVISIONING"
    ACTIVE = "ACTIVE"
    SUSPENDED = "SUSPENDED"
    TERMINATED = "TERMINATED"


class CyberRangeSession(Base):
    __tablename__ = "cyber_range_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    lab_id: Mapped[str] = mapped_column(
        String(100),
        # FK to labs.id
        nullable=False,
        index=True,
    )
    enrollment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.enrollments.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    k8s_namespace: Mapped[str | None] = mapped_column(String(255), nullable=True, unique=True)
    guacamole_connection_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    guacamole_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    status: Mapped[CyberRangeStatus] = mapped_column(
        Enum(CyberRangeStatus, schema="cyber_academy"),
        default=CyberRangeStatus.PROVISIONING,
        nullable=False,
    )
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    duration_minutes: Mapped[int | None] = mapped_column(Integer, nullable=True)
    cpu_used: Mapped[float | None] = mapped_column(Float, nullable=True)
    memory_used_mb: Mapped[float | None] = mapped_column(Float, nullable=True)
    score: Mapped[float | None] = mapped_column(Float, nullable=True)  # auto-grading score 0-100
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="cyber_range_sessions")
    enrollment: Mapped["Enrollment"] = relationship("Enrollment", back_populates="cyber_range_sessions")
    lab: Mapped["Lab | None"] = relationship(
        "Lab",
        back_populates="cyber_range_sessions",
        primaryjoin="CyberRangeSession.lab_id == Lab.id",
        foreign_keys="[CyberRangeSession.lab_id]",
    )

    def __repr__(self) -> str:
        return f"<CyberRangeSession id={self.id} lab={self.lab_id} status={self.status}>"
