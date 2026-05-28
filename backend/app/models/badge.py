"""Badge model — Polygon ERC-721 blockchain certificates."""
import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Badge(Base):
    __tablename__ = "badges"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    enrollment_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("cyber_academy.enrollments.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    course_code: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    # Blockchain data
    token_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    tx_hash: Mapped[str | None] = mapped_column(String(100), nullable=True, unique=True)
    metadata_uri: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    # Status
    is_valid: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    blockchain_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    issued_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="badges")
    enrollment: Mapped["Enrollment"] = relationship("Enrollment", back_populates="badge")

    def __repr__(self) -> str:
        return f"<Badge id={self.id} course={self.course_code} token_id={self.token_id}>"
