"""Payment model — CinetPay and Stripe transactions."""
import uuid
import enum
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, JSON, String, Text, func
from sqlalchemy.dialects.postgresql import UUID, JSONB

_JSON = JSONB().with_variant(JSON(), "sqlite")
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class PaymentCurrency(str, enum.Enum):
    XOF = "XOF"   # FCFA
    EUR = "EUR"
    USD = "USD"


class PaymentMethod(str, enum.Enum):
    ORANGE_MONEY = "ORANGE_MONEY"
    MOOV_MONEY = "MOOV_MONEY"
    WAVE = "WAVE"
    CARD_STRIPE = "CARD_STRIPE"
    BANK_TRANSFER = "BANK_TRANSFER"


class PaymentStatus(str, enum.Enum):
    PENDING = "PENDING"
    CONFIRMED = "CONFIRMED"
    FAILED = "FAILED"
    REFUNDED = "REFUNDED"


class Payment(Base):
    __tablename__ = "payments"

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
        index=True,
    )
    amount_fcfa: Mapped[int] = mapped_column(Integer, nullable=False)
    currency: Mapped[PaymentCurrency] = mapped_column(
        Enum(PaymentCurrency, schema="cyber_academy"),
        default=PaymentCurrency.XOF,
        nullable=False,
    )
    method: Mapped[PaymentMethod] = mapped_column(
        Enum(PaymentMethod, schema="cyber_academy"), nullable=False
    )
    provider_ref: Mapped[str | None] = mapped_column(String(255), nullable=True, index=True)
    status: Mapped[PaymentStatus] = mapped_column(
        Enum(PaymentStatus, schema="cyber_academy"),
        default=PaymentStatus.PENDING,
        nullable=False,
    )
    # Installment support (échelonné)
    installment_number: Mapped[int] = mapped_column(Integer, default=1, nullable=False)  # 1, 2, or 3
    installment_total: Mapped[int] = mapped_column(Integer, default=1, nullable=False)   # total installments
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Provider webhook data
    webhook_payload: Mapped[dict | None] = mapped_column(_JSON, nullable=True)
    # Payment URL (for redirect)
    payment_url: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="payments")
    enrollment: Mapped["Enrollment"] = relationship("Enrollment", back_populates="payments")

    def __repr__(self) -> str:
        return f"<Payment id={self.id} amount={self.amount_fcfa} XOF status={self.status}>"
