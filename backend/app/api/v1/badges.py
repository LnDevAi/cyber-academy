"""Badge endpoints — Polygon blockchain certificates."""
import uuid
from datetime import datetime, timezone
from typing import List

import structlog
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.database import get_db
from app.models.badge import Badge
from app.models.user import User, UserRole
from app.schemas.badge import BadgeMetadataResponse, BadgeResponse, BadgeVerificationResponse

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/badges", tags=["Badges Blockchain"])


@router.get("", response_model=List[BadgeResponse])
async def list_badges(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[Badge]:
    """Lister mes badges blockchain."""
    query = select(Badge)

    if current_user.role != UserRole.ADMIN:
        query = query.where(Badge.user_id == current_user.id)

    query = query.order_by(Badge.issued_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.get("/{badge_id}", response_model=BadgeResponse)
async def get_badge(
    badge_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> Badge:
    """Détail d'un badge avec information de vérification blockchain."""
    badge = await db.get(Badge, badge_id)
    if not badge:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Badge introuvable")

    if current_user.role != UserRole.ADMIN and badge.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    return badge


@router.post("/{badge_id}/verify", response_model=BadgeVerificationResponse)
async def verify_badge(
    badge_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Déclencher une vérification blockchain fraîche du badge."""
    badge = await db.get(Badge, badge_id)
    if not badge:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Badge introuvable")

    if current_user.role != UserRole.ADMIN and badge.user_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès refusé")

    if badge.token_id is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ce badge n'a pas encore été minté sur la blockchain",
        )

    try:
        from app.services.blockchain.badge_service import badge_service
        verification = await badge_service.verify_badge(badge.token_id)

        badge.is_valid = verification.get("is_valid", False)
        badge.blockchain_verified_at = datetime.now(timezone.utc)
        await db.flush()

        return {
            "token_id": badge.token_id,
            "is_valid": badge.is_valid,
            "owner_address": verification.get("owner_address"),
            "metadata_uri": verification.get("metadata_uri"),
            "verified_at": badge.blockchain_verified_at,
            "blockchain_network": "Polygon",
        }

    except Exception as exc:
        logger.error("Erreur vérification badge blockchain", badge_id=str(badge_id), error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Erreur vérification blockchain: {str(exc)}",
        )


@router.get("/{badge_id}/metadata")
async def get_badge_metadata(
    badge_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Metadata Open Badges 3.0 JSON publique — accessible sans authentification
    (pour les vérificateurs externes, LinkedIn, etc.)
    """
    badge = await db.get(Badge, badge_id)
    if not badge:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Badge introuvable")

    if not badge.metadata_uri:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Metadata de badge non disponible",
        )

    # Try to download metadata from MinIO
    try:
        from app.core.minio_client import minio_client
        metadata_data = minio_client.download_file(f"badges/metadata/{badge_id}.json")
        import json
        return json.loads(metadata_data)
    except Exception as exc:
        logger.warning("Metadata MinIO non disponible", badge_id=str(badge_id), error=str(exc))
        # Return minimal metadata
        return {
            "@context": "https://purl.imsglobal.org/spec/ob/v3p0/context-3.0.3.json",
            "type": "OpenBadgeCredential",
            "id": badge.metadata_uri,
            "name": f"Badge E-DEFENCE — {badge.course_code}",
            "issued_at": badge.issued_at.isoformat(),
            "is_valid": badge.is_valid,
            "blockchain": {
                "network": "Polygon",
                "token_id": badge.token_id,
                "tx_hash": badge.tx_hash,
                "contract": badge.metadata_uri,
            }
        }
