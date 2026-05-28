"""Celery tasks for blockchain badge minting."""
import asyncio
import uuid
from datetime import datetime, timezone

import structlog

from app.tasks.celery_app import celery_app

logger = structlog.get_logger(__name__)


def _run_async(coro):
    """Run an async coroutine in a Celery sync task."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@celery_app.task(
    bind=True,
    name="app.tasks.badge_tasks.mint_completion_badge",
    max_retries=5,
    default_retry_delay=120,
    queue="blockchain",
)
def mint_completion_badge(self, enrollment_id: str) -> dict:
    """
    Mint a blockchain badge when an enrollment is completed.

    Triggered by:
    - Enrollment status set to COMPLETED
    - Progress reaches 100% (checked by periodic task)

    Args:
        enrollment_id: UUID string of the completed Enrollment

    Returns:
        Dict with badge minting results
    """
    logger.info("Début minting badge blockchain", enrollment_id=enrollment_id)

    async def _mint():
        from app.core.database import AsyncSessionLocal
        from app.models.enrollment import Enrollment, EnrollmentStatus
        from app.models.badge import Badge
        from app.models.user import User
        from app.models.course import Course
        from app.services.blockchain.badge_service import badge_service
        from sqlalchemy import select

        async with AsyncSessionLocal() as db:
            # Load enrollment
            enrollment = await db.get(Enrollment, uuid.UUID(enrollment_id))
            if not enrollment:
                raise ValueError(f"Inscription {enrollment_id} introuvable")

            if enrollment.status != EnrollmentStatus.COMPLETED:
                logger.warning(
                    "Inscription non complétée, badge non minté",
                    enrollment_id=enrollment_id,
                    status=enrollment.status.value,
                )
                return {"status": "skipped", "reason": "enrollment_not_completed"}

            # Check if badge already exists
            existing = await db.execute(
                select(Badge).where(Badge.enrollment_id == enrollment.id)
            )
            if existing.scalar_one_or_none():
                logger.info("Badge déjà existant", enrollment_id=enrollment_id)
                return {"status": "skipped", "reason": "badge_already_exists"}

            # Load user and course
            user = await db.get(User, enrollment.user_id)
            course = await db.get(Course, enrollment.course_id)

            if not user or not course:
                raise ValueError("Utilisateur ou formation introuvable")

            # Mint badge on Polygon
            badge = await badge_service.mint_badge(
                user=user,
                course=course,
                enrollment_id=str(enrollment.id),
            )

            # Persist badge to DB
            db.add(badge)
            await db.commit()

            result = {
                "status": "minted" if badge.tx_hash else "pending",
                "badge_id": str(badge.id),
                "token_id": badge.token_id,
                "tx_hash": badge.tx_hash,
                "metadata_uri": badge.metadata_uri,
                "course_code": badge.course_code,
                "user_email": user.email,
            }

            logger.info(
                "Badge minté et persisté",
                badge_id=str(badge.id),
                token_id=badge.token_id,
                tx_hash=badge.tx_hash,
            )

            return result

    try:
        return _run_async(_mint())
    except Exception as exc:
        logger.error(
            "Erreur minting badge",
            enrollment_id=enrollment_id,
            error=str(exc),
        )
        raise self.retry(exc=exc)


@celery_app.task(
    bind=True,
    name="app.tasks.badge_tasks.verify_all_pending_badges",
    max_retries=3,
    queue="blockchain",
)
def verify_all_pending_badges(self) -> dict:
    """
    Periodic task: verify badges that haven't been blockchain-verified recently.
    Updates is_valid status and blockchain_verified_at timestamp.
    """
    logger.info("Vérification des badges blockchain")

    async def _verify():
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.badge import Badge
        from app.services.blockchain.badge_service import badge_service
        from datetime import timedelta

        verified_count = 0
        invalid_count = 0

        # Verify badges not checked in the last 7 days
        cutoff = datetime.now(timezone.utc) - timedelta(days=7)

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(Badge).where(
                    Badge.token_id.is_not(None),
                    Badge.blockchain_verified_at < cutoff,
                )
            )
            badges = result.scalars().all()

            for badge in badges:
                try:
                    verification = await badge_service.verify_badge(badge.token_id)
                    badge.is_valid = verification.get("is_valid", False)
                    badge.blockchain_verified_at = datetime.now(timezone.utc)

                    if badge.is_valid:
                        verified_count += 1
                    else:
                        invalid_count += 1

                except Exception as exc:
                    logger.error(
                        "Erreur vérification badge",
                        badge_id=str(badge.id),
                        error=str(exc),
                    )

            await db.commit()

        return {
            "verified": verified_count,
            "invalid": invalid_count,
            "total_checked": len(badges) if "badges" in dir() else 0,
        }

    try:
        return _run_async(_verify())
    except Exception as exc:
        logger.error("Erreur vérification badges", error=str(exc))
        raise self.retry(exc=exc)


@celery_app.task(
    bind=True,
    name="app.tasks.badge_tasks.retry_failed_badge_minting",
    max_retries=3,
    queue="blockchain",
)
def retry_failed_badge_minting(self) -> dict:
    """
    Periodic task: retry minting for badges that failed (no tx_hash but enrollment completed).
    """
    logger.info("Retry minting des badges échoués")

    async def _retry_failed():
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.badge import Badge
        from app.models.enrollment import EnrollmentStatus

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(Badge).where(
                    Badge.tx_hash.is_(None),
                    Badge.token_id.is_(None),
                )
            )
            failed_badges = result.scalars().all()

            for badge in failed_badges:
                # Trigger re-mint
                mint_completion_badge.delay(str(badge.enrollment_id))
                logger.info("Re-minting déclenché", badge_id=str(badge.id))

        return {"retried": len(failed_badges)}

    try:
        return _run_async(_retry_failed())
    except Exception as exc:
        logger.error("Erreur retry minting", error=str(exc))
        raise self.retry(exc=exc)
