"""Course model — 10 certification programs."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Integer, Numeric, String, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class CourseType(str, enum.Enum):
    ECERT = "ECERT"           # E-DEFENCE proprietary
    INTERNATIONAL = "INTERNATIONAL"  # PECB, Cisco, Fortinet, etc.


class CoursePartner(str, enum.Enum):
    EDEFENCE = "EDEFENCE"
    PECB = "PECB"
    CISCO = "CISCO"
    FORTINET = "FORTINET"
    EC_COUNCIL = "EC_COUNCIL"
    ISC2 = "ISC2"
    COMPTIA = "COMPTIA"


class CourseLevel(str, enum.Enum):
    BEGINNER = "BEGINNER"
    INTERMEDIATE = "INTERMEDIATE"
    ADVANCED = "ADVANCED"
    EXPERT = "EXPERT"


class Course(Base):
    __tablename__ = "courses"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    code: Mapped[str] = mapped_column(String(50), unique=True, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    short_description: Mapped[str | None] = mapped_column(String(500), nullable=True)
    type: Mapped[CourseType] = mapped_column(
        Enum(CourseType, schema="cyber_academy"), nullable=False
    )
    partner: Mapped[CoursePartner] = mapped_column(
        Enum(CoursePartner, schema="cyber_academy"), nullable=False
    )
    level: Mapped[CourseLevel] = mapped_column(
        Enum(CourseLevel, schema="cyber_academy"), nullable=False
    )
    hours_total: Mapped[int] = mapped_column(Integer, nullable=False)
    price_fcfa: Mapped[int] = mapped_column(Integer, nullable=False)
    price_eur: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    prerequisites: Mapped[str | None] = mapped_column(Text, nullable=True)
    objectives: Mapped[str | None] = mapped_column(Text, nullable=True)
    target_audience: Mapped[str | None] = mapped_column(Text, nullable=True)
    # Moodle integration
    moodle_course_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    thumbnail_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    syllabus_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)
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

    # Relationships
    enrollments: Mapped[list["Enrollment"]] = relationship("Enrollment", back_populates="course")
    labs: Mapped[list["Lab"]] = relationship(
        "Lab", back_populates="course",
        primaryjoin="Course.code == Lab.course_code",
        foreign_keys="Lab.course_code",
    )

    def __repr__(self) -> str:
        return f"<Course code={self.code} title={self.title[:50]}>"
