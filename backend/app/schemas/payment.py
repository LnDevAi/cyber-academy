"""Payment schemas."""
import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel, Field

from app.models.payment import PaymentCurrency, PaymentMethod, PaymentStatus


class PaymentCreate(BaseModel):
    enrollment_id: uuid.UUID
    method: PaymentMethod
    installment_total: int = Field(default=1, ge=1, le=3)


class CinetPayInitiateRequest(BaseModel):
    enrollment_id: uuid.UUID
    method: PaymentMethod = Field(
        description="ORANGE_MONEY, MOOV_MONEY ou WAVE"
    )
    installment: int = Field(default=1, ge=1, le=3, description="Nombre de versements: 1, 2 ou 3")


class CinetPayInitiateResponse(BaseModel):
    payment_url: str
    payment_id: uuid.UUID
    transaction_id: str
    amount_fcfa: int
    installment_number: int
    installment_total: int
    message: str


class PaymentWebhookCinetPay(BaseModel):
    """CinetPay webhook payload structure."""
    cpm_site_id: Optional[str] = None
    cpm_trans_id: Optional[str] = None
    cpm_trans_date: Optional[str] = None
    cpm_amount: Optional[str] = None
    cpm_currency: Optional[str] = None
    signature: Optional[str] = None
    payment_method: Optional[str] = None
    cel_phone_num: Optional[str] = None
    cpm_phone_prefixe: Optional[str] = None
    cpm_language: Optional[str] = None
    cpm_version: Optional[str] = None
    cpm_payment_config: Optional[str] = None
    cpm_page_action: Optional[str] = None
    cpm_custom: Optional[str] = None
    cpm_designation: Optional[str] = None
    cpm_error_message: Optional[str] = None

    class Config:
        extra = "allow"


class StripeIntentRequest(BaseModel):
    enrollment_id: uuid.UUID
    currency: str = Field(default="eur", pattern=r"^[a-z]{3}$")


class StripeIntentResponse(BaseModel):
    client_secret: str
    payment_intent_id: str
    amount_cents: int
    currency: str
    payment_id: uuid.UUID


class PaymentResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    user_id: uuid.UUID
    enrollment_id: uuid.UUID
    amount_fcfa: int
    currency: PaymentCurrency
    method: PaymentMethod
    provider_ref: Optional[str]
    status: PaymentStatus
    installment_number: int
    installment_total: int
    payment_url: Optional[str]
    created_at: datetime
    confirmed_at: Optional[datetime]
