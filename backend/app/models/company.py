"""Company model — B2B accounts."""
import uuid
from datetime import datetime, timezone

from sqlalchemy import DateTime, Enum, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base
import enum


class CompanyPlan(str, enum.Enum):
    STARTER = "STARTER"
    PRO = "PRO"
    ENTERPRISE = "ENTERPRISE"


class Company(Base):
    __tablename__ = "companies"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    contact_email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    contact_phone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    country: Mapped[str] = mapped_column(String(3), default="BF")  # ISO country code
    plan: Mapped[CompanyPlan] = mapped_column(
        Enum(CompanyPlan, schema="cyber_academy"),
        default=CompanyPlan.STARTER,
        nullable=False,
    )
    seats_total: Mapped[int] = mapped_column(Integer, default=5, nullable=False)
    seats_used: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
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
    users: Mapped[list["User"]] = relationship("User", back_populates="company")

    def __repr__(self) -> str:
        return f"<Company id={self.id} name={self.name} plan={self.plan}>"
