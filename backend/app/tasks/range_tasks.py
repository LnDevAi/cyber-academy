"""Celery tasks for Cyber Range session management."""
import asyncio
import uuid
from datetime import datetime, timedelta, timezone

import structlog

from app.tasks.celery_app import celery_app
from app.core.config import settings

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
    name="app.tasks.range_tasks.auto_terminate_idle_sessions",
    queue="periodic",
)
def auto_terminate_idle_sessions() -> dict:
    """
    Periodic task: auto-terminate Cyber Range sessions idle for more than 4 hours.
    Runs every 30 minutes.

    Returns:
        Dict with count of terminated sessions
    """
    logger.info("Vérification des sessions Cyber Range inactives")

    async def _terminate_idle():
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.cyber_range_session import CyberRangeSession, CyberRangeStatus
        from app.services.cyber_range.k8s_service import k8s_service

        idle_threshold = datetime.now(timezone.utc) - timedelta(
            hours=settings.K8S_SESSION_TIMEOUT_HOURS
        )
        terminated_count = 0

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(CyberRangeSession).where(
                    CyberRangeSession.status == CyberRangeStatus.ACTIVE,
                    CyberRangeSession.started_at < idle_threshold,
                )
            )
            idle_sessions = result.scalars().all()

            for session in idle_sessions:
                try:
                    logger.info(
                        "Terminaison session Cyber Range inactive",
                        session_id=str(session.id),
                        namespace=session.k8s_namespace,
                        started_at=session.started_at.isoformat() if session.started_at else None,
                    )

                    # Terminate k8s namespace
                    if session.k8s_namespace:
                        success = await k8s_service.terminate_namespace(session.k8s_namespace)
                    else:
                        success = True

                    if success:
                        session.status = CyberRangeStatus.TERMINATED
                        session.ended_at = datetime.now(timezone.utc)

                        if session.started_at:
                            duration = (session.ended_at - session.started_at).total_seconds() / 60
                            session.duration_minutes = int(duration)

                        terminated_count += 1

                except Exception as exc:
                    logger.error(
                        "Erreur terminaison session",
                        session_id=str(session.id),
                        error=str(exc),
                    )

            await db.commit()

        logger.info("Sessions Cyber Range terminées", count=terminated_count)
        return {"terminated": terminated_count}

    return _run_async(_terminate_idle())


@celery_app.task(
    bind=True,
    name="app.tasks.range_tasks.provision_range_session",
    max_retries=3,
    default_retry_delay=30,
    queue="range",
)
def provision_range_session(self, session_id: str) -> dict:
    """
    Async lab provisioning task.
    Provisions k8s namespace and Guacamole connection, then updates session status.

    Args:
        session_id: UUID string of the CyberRangeSession to provision

    Returns:
        Dict with provisioning results including guacamole_url
    """
    logger.info("Provisionnement session Cyber Range", session_id=session_id)

    async def _provision():
        from app.core.database import AsyncSessionLocal
        from app.models.cyber_range_session import CyberRangeSession, CyberRangeStatus
        from app.models.lab import Lab
        from app.services.cyber_range.k8s_service import k8s_service

        async with AsyncSessionLocal() as db:
            session = await db.get(CyberRangeSession, uuid.UUID(session_id))
            if not session:
                raise ValueError(f"Session {session_id} introuvable")

            if session.status != CyberRangeStatus.PROVISIONING:
                logger.warning(
                    "Session pas en état PROVISIONING",
                    session_id=session_id,
                    status=session.status.value,
                )
                return {"status": "skipped"}

            # Load lab
            lab = await db.get(Lab, session.lab_id)
            if not lab:
                session.status = CyberRangeStatus.TERMINATED
                await db.commit()
                raise ValueError(f"Lab {session.lab_id} introuvable")

            try:
                # Step 1: Create namespace
                namespace = await k8s_service.provision_namespace(
                    str(session.user_id), session.lab_id
                )
                session.k8s_namespace = namespace

                # Step 2: Deploy lab workloads
                await k8s_service.deploy_lab(namespace, lab)

                # Step 3: Get Guacamole connection
                guac_data = await k8s_service.get_guacamole_connection(namespace, lab)
                session.guacamole_connection_id = guac_data["connection_id"]
                session.guacamole_url = guac_data["connection_url"]

                # Step 4: Mark session as ACTIVE
                session.status = CyberRangeStatus.ACTIVE
                session.started_at = datetime.now(timezone.utc)

                await db.commit()

                logger.info(
                    "Session Cyber Range provisionnée",
                    session_id=session_id,
                    namespace=namespace,
                    guacamole_url=guac_data["connection_url"],
                )

                return {
                    "status": "active",
                    "session_id": session_id,
                    "namespace": namespace,
                    "guacamole_url": guac_data["connection_url"],
                }

            except Exception as exc:
                session.status = CyberRangeStatus.TERMINATED
                await db.commit()
                logger.error(
                    "Erreur provisionnement Cyber Range",
                    session_id=session_id,
                    error=str(exc),
                )
                raise

    try:
        return _run_async(_provision())
    except Exception as exc:
        logger.error("Erreur tâche provisionnement", session_id=session_id, error=str(exc))
        raise self.retry(exc=exc)


@celery_app.task(
    bind=True,
    name="app.tasks.range_tasks.collect_session_metrics",
    max_retries=2,
    queue="range",
)
def collect_session_metrics(self, session_id: str) -> dict:
    """
    Collect resource usage metrics for an active Cyber Range session.

    Args:
        session_id: UUID string of the CyberRangeSession

    Returns:
        Dict with resource usage metrics
    """
    logger.info("Collecte métriques session", session_id=session_id)

    async def _collect():
        from app.core.database import AsyncSessionLocal
        from app.models.cyber_range_session import CyberRangeSession, CyberRangeStatus
        from app.services.cyber_range.k8s_service import k8s_service

        async with AsyncSessionLocal() as db:
            session = await db.get(CyberRangeSession, uuid.UUID(session_id))
            if not session or session.status != CyberRangeStatus.ACTIVE:
                return {"status": "skipped"}

            if not session.k8s_namespace:
                return {"status": "no_namespace"}

            metrics = await k8s_service.get_resource_usage(session.k8s_namespace)

            session.cpu_used = metrics.get("cpu_cores", 0)
            session.memory_used_mb = metrics.get("memory_mb", 0)

            await db.commit()

            return {
                "session_id": session_id,
                "cpu_cores": session.cpu_used,
                "memory_mb": session.memory_used_mb,
                "uptime_minutes": metrics.get("uptime_minutes", 0),
            }

    try:
        return _run_async(_collect())
    except Exception as exc:
        logger.error("Erreur collecte métriques", session_id=session_id, error=str(exc))
        raise self.retry(exc=exc)
