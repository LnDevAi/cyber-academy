"""Authentication and user schemas."""
import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.models.user import UserRole


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str = Field(min_length=2, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=30)
    country: str = Field(default="BF", max_length=3)

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Le mot de passe doit contenir au moins 8 caractères")
        if not any(c.isupper() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins une majuscule")
        if not any(c.isdigit() for c in v):
            raise ValueError("Le mot de passe doit contenir au moins un chiffre")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str
    totp_code: Optional[str] = Field(default=None, description="Code TOTP 6 chiffres si 2FA activé")


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    requires_2fa: bool = False


class RefreshRequest(BaseModel):
    refresh_token: str


class TwoFASetupResponse(BaseModel):
    secret: str
    qr_code_base64: str
    otp_uri: str
    message: str = "Scannez ce QR code avec votre application d'authentification"


class TwoFAVerifyRequest(BaseModel):
    totp_code: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")


class UserUpdate(BaseModel):
    full_name: Optional[str] = Field(default=None, max_length=255)
    phone: Optional[str] = Field(default=None, max_length=30)
    country: Optional[str] = Field(default=None, max_length=3)


class UserResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    email: str
    full_name: str
    phone: Optional[str]
    country: str
    role: UserRole
    is_2fa_enabled: bool
    is_active: bool
    company_id: Optional[uuid.UUID]
    moodle_user_id: Optional[int]
    created_at: datetime
    last_login_at: Optional[datetime]


class CompanyResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    name: str
    contact_email: str
    plan: str
    seats_total: int
    seats_used: int
    is_active: bool
    created_at: datetime
