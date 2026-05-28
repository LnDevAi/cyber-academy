"""Authentication endpoints."""
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.core.database import get_db
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_totp_qr_base64,
    generate_totp_secret,
    get_totp_uri,
    hash_password,
    verify_password,
    verify_refresh_token,
    verify_totp,
)
from app.models.user import User, UserRole
from app.schemas.auth import (
    RefreshRequest,
    TokenResponse,
    TwoFASetupResponse,
    TwoFAVerifyRequest,
    UserCreate,
    UserLogin,
    UserResponse,
    UserUpdate,
)
from app.core.config import settings

router = APIRouter(prefix="/auth", tags=["Authentification"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(
    user_data: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> User:
    """Créer un nouveau compte étudiant."""
    # Check email uniqueness
    existing = await db.execute(
        select(User).where(User.email == user_data.email.lower())
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Un compte avec cet email existe déjà",
        )

    user = User(
        email=user_data.email.lower(),
        hashed_password=hash_password(user_data.password),
        full_name=user_data.full_name,
        phone=user_data.phone,
        country=user_data.country.upper(),
        role=UserRole.STUDENT,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)

    return user


@router.post("/login", response_model=TokenResponse)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Connexion utilisateur — retourne un access token JWT."""
    result = await db.execute(
        select(User).where(User.email == credentials.email.lower())
    )
    user: User | None = result.scalar_one_or_none()

    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou mot de passe incorrect",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Compte désactivé. Contactez le support.",
        )

    # 2FA check
    if user.is_2fa_enabled:
        if not credentials.totp_code:
            return {
                "access_token": "",
                "refresh_token": "",
                "token_type": "bearer",
                "expires_in": 0,
                "requires_2fa": True,
            }
        if not verify_totp(user.totp_secret, credentials.totp_code):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Code d'authentification 2FA invalide",
            )

    # Update last login
    user.last_login_at = datetime.now(timezone.utc)
    await db.flush()

    # Create tokens
    extra_claims = {"role": user.role.value, "email": user.email}
    access_token = create_access_token(str(user.id), extra_claims=extra_claims)
    refresh_token = create_refresh_token(str(user.id))

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "requires_2fa": False,
    }


@router.post("/2fa/setup", response_model=TwoFASetupResponse)
async def setup_2fa(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Initialiser la configuration 2FA TOTP — retourne le QR code."""
    if current_user.is_2fa_enabled:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="L'authentification 2FA est déjà activée",
        )

    # Generate a new TOTP secret
    secret = generate_totp_secret()
    current_user.totp_secret = secret
    await db.flush()

    qr_base64 = generate_totp_qr_base64(secret, current_user.email)
    otp_uri = get_totp_uri(secret, current_user.email)

    return {
        "secret": secret,
        "qr_code_base64": qr_base64,
        "otp_uri": otp_uri,
        "message": "Scannez ce QR code avec votre application d'authentification (Google Authenticator, Authy)",
    }


@router.post("/2fa/verify", status_code=status.HTTP_200_OK)
async def verify_2fa(
    request: TwoFAVerifyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Vérifier le code TOTP et activer le 2FA pour le compte."""
    if not current_user.totp_secret:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Configurez d'abord le 2FA via POST /auth/2fa/setup",
        )

    if not verify_totp(current_user.totp_secret, request.totp_code):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Code TOTP invalide. Vérifiez l'heure de votre appareil.",
        )

    current_user.is_2fa_enabled = True
    await db.flush()

    return {
        "message": "Authentification à deux facteurs activée avec succès",
        "is_2fa_enabled": True,
    }


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshRequest,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Renouveler l'access token via un refresh token valide."""
    import uuid

    user_id_str = verify_refresh_token(request.refresh_token)
    if not user_id_str:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token invalide ou expiré",
        )

    try:
        user_id = uuid.UUID(user_id_str)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalide",
        )

    user = await db.get(User, user_id)
    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Utilisateur introuvable ou inactif",
        )

    extra_claims = {"role": user.role.value, "email": user.email}
    access_token = create_access_token(str(user.id), extra_claims=extra_claims)
    new_refresh_token = create_refresh_token(str(user.id))

    return {
        "access_token": access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "requires_2fa": False,
    }


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
) -> User:
    """Récupérer le profil de l'utilisateur connecté."""
    return current_user


@router.patch("/me", response_model=UserResponse)
async def update_profile(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> User:
    """Mettre à jour le profil de l'utilisateur connecté."""
    if update_data.full_name is not None:
        current_user.full_name = update_data.full_name
    if update_data.phone is not None:
        current_user.phone = update_data.phone
    if update_data.country is not None:
        current_user.country = update_data.country.upper()

    await db.flush()
    return current_user
