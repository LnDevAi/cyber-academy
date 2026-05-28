"""Lab model — Cyber Range exercises."""
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, Integer, JSON, String, Text, func
from sqlalchemy.dialects.postgresql import JSONB

_JSON = JSONB().with_variant(JSON(), "sqlite")
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Lab(Base):
    __tablename__ = "labs"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)  # slug like cacp-lab-01
    course_code: Mapped[str] = mapped_column(
        String(50),
        # No FK constraint — course_code references Course.code (string)
        nullable=False,
        index=True,
    )
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    difficulty: Mapped[int] = mapped_column(Integer, nullable=False)  # 1-5
    duration_minutes: Mapped[int] = mapped_column(Integer, default=60, nullable=False)
    docker_image: Mapped[str] = mapped_column(String(500), nullable=False)
    k8s_manifest: Mapped[dict | None] = mapped_column(_JSON, nullable=True)
    objectives: Mapped[list | None] = mapped_column(_JSON, nullable=True)  # list of strings
    auto_grading_script: Mapped[str | None] = mapped_column(Text, nullable=True)
    order_in_course: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship to course (string-based join)
    course: Mapped["Course | None"] = relationship(
        "Course",
        back_populates="labs",
        primaryjoin="Lab.course_code == Course.code",
        foreign_keys="[Lab.course_code]",
    )

    # Relationship to cyber range sessions
    cyber_range_sessions: Mapped[list["CyberRangeSession"]] = relationship(
        "CyberRangeSession",
        back_populates="lab",
        primaryjoin="Lab.id == CyberRangeSession.lab_id",
        foreign_keys="[CyberRangeSession.lab_id]",
    )

    def __repr__(self) -> str:
        return f"<Lab id={self.id} course={self.course_code} difficulty={self.difficulty}>"
