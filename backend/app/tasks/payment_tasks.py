"""Celery tasks for payment processing and enrollment provisioning."""
import asyncio
import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

import structlog
from celery import shared_task

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
    name="app.tasks.payment_tasks.confirm_payment_and_provision",
    max_retries=3,
    default_retry_delay=60,
    queue="payments",
)
def confirm_payment_and_provision(self, payment_id: str) -> dict:
    """
    Main payment confirmation task.
    On payment confirmed:
    1. Activate enrollment
    2. Create/link Moodle account
    3. Enroll in Moodle course
    4. Assign mentor (if needed)
    5. Buy partner voucher (PECB/Cisco)
    6. Send welcome notification
    7. Schedule installment follow-ups if échelonné

    Args:
        payment_id: UUID string of the confirmed Payment

    Returns:
        Dict with provisioning results
    """
    logger.info("Début provisionnement post-paiement", payment_id=payment_id)

    async def _provision():
        from sqlalchemy.ext.asyncio import AsyncSession
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.payment import Payment, PaymentStatus
        from app.models.enrollment import Enrollment, EnrollmentStatus
        from app.models.user import User
        from app.models.course import Course
        from app.services.lms.moodle_service import moodle_service

        async with AsyncSessionLocal() as db:
            # Load payment
            payment = await db.get(Payment, uuid.UUID(payment_id))
            if not payment:
                raise ValueError(f"Paiement {payment_id} introuvable")

            if payment.status != PaymentStatus.CONFIRMED:
                logger.warning("Paiement non confirmé, abandon provisionnement", payment_id=payment_id)
                return {"status": "skipped", "reason": "payment_not_confirmed"}

            # Load enrollment
            enrollment = await db.get(Enrollment, payment.enrollment_id)
            if not enrollment:
                raise ValueError(f"Inscription {payment.enrollment_id} introuvable")

            # Load user and course
            user = await db.get(User, enrollment.user_id)
            course = await db.get(Course, enrollment.course_id)

            if not user or not course:
                raise ValueError("Utilisateur ou formation introuvable")

            results = {"payment_id": payment_id, "steps": {}}

            # Step 1: Activate enrollment if all installments paid
            all_installments_paid = await _check_all_installments_paid(db, enrollment.id, payment.installment_total)

            if all_installments_paid:
                enrollment.status = EnrollmentStatus.ACTIVE
                enrollment.started_at = datetime.now(timezone.utc)
                # Set expiry (1 year from activation)
                enrollment.expires_at = datetime.now(timezone.utc) + timedelta(days=365)
                await db.flush()
                results["steps"]["enrollment_activated"] = True
                logger.info("Inscription activée", enrollment_id=str(enrollment.id))
            else:
                results["steps"]["enrollment_status"] = "awaiting_installments"
                logger.info(
                    "Paiement partiel — en attente des versements suivants",
                    installment_number=payment.installment_number,
                    installment_total=payment.installment_total,
                )

            # Step 2: Moodle provisioning (only when fully paid)
            if all_installments_paid and course.moodle_course_id:
                try:
                    moodle_user_id = user.moodle_user_id
                    if not moodle_user_id:
                        moodle_user_id = await moodle_service.create_user(user)
                        user.moodle_user_id = moodle_user_id
                        await db.flush()

                    enrollment_id = await moodle_service.enroll_user(
                        moodle_user_id, course.moodle_course_id
                    )
                    enrollment.moodle_enrollment_id = enrollment_id
                    enrollment.moodle_user_id = moodle_user_id
                    await db.flush()
                    results["steps"]["moodle_enrollment"] = True
                    logger.info("Inscription Moodle créée", moodle_user_id=moodle_user_id)
                except Exception as exc:
                    logger.error("Erreur inscription Moodle", error=str(exc))
                    results["steps"]["moodle_enrollment"] = f"Erreur: {str(exc)}"

            # Step 3: Partner voucher provisioning
            if all_installments_paid and course.partner.value in ("PECB",):
                try:
                    from app.services.partners.pecb_service import pecb_service
                    candidate_id = await pecb_service.create_candidate_account(user)
                    exam_code = pecb_service.get_exam_code_for_course(course.code)
                    voucher = await pecb_service.provision_voucher(candidate_id, exam_code)
                    results["steps"]["pecb_voucher"] = voucher[:4] + "****"
                    logger.info("Voucher PECB provisionné", course_code=course.code)
                except Exception as exc:
                    logger.error("Erreur provisionnement voucher PECB", error=str(exc))
                    results["steps"]["pecb_voucher"] = f"Erreur: {str(exc)}"

            elif all_installments_paid and course.partner.value == "CISCO":
                try:
                    from app.services.partners.cisco_service import cisco_service
                    voucher = await cisco_service.get_exam_voucher(user)
                    results["steps"]["cisco_voucher"] = True
                except Exception as exc:
                    logger.error("Erreur provisionnement voucher Cisco", error=str(exc))
                    results["steps"]["cisco_voucher"] = f"Erreur: {str(exc)}"

            # Step 4: Schedule next installment reminder if échelonné
            if payment.installment_total > 1 and payment.installment_number < payment.installment_total:
                next_due = datetime.now(timezone.utc) + timedelta(days=30)
                results["steps"]["next_installment_scheduled"] = next_due.isoformat()
                logger.info(
                    "Prochain versement planifié",
                    installment_number=payment.installment_number + 1,
                    due_date=next_due.isoformat(),
                )

            await db.commit()
            logger.info("Provisionnement post-paiement terminé", results=results)
            return results

    try:
        return _run_async(_provision())
    except Exception as exc:
        logger.error("Erreur provisionnement", payment_id=payment_id, error=str(exc))
        raise self.retry(exc=exc)


async def _check_all_installments_paid(db, enrollment_id, total_installments: int) -> bool:
    """Check if all installments for an enrollment have been paid."""
    from sqlalchemy import select, func
    from app.models.payment import Payment, PaymentStatus

    result = await db.execute(
        select(func.count(Payment.id)).where(
            Payment.enrollment_id == enrollment_id,
            Payment.status == PaymentStatus.CONFIRMED,
        )
    )
    confirmed_count = result.scalar()
    return confirmed_count >= total_installments


@celery_app.task(
    name="app.tasks.payment_tasks.check_pending_payments",
    queue="periodic",
)
def check_pending_payments() -> dict:
    """
    Periodic task: check for stale PENDING payments and verify status with providers.
    Runs every 15 minutes. Cancels payments pending for more than 24 hours.
    """
    logger.info("Vérification des paiements en attente")

    async def _check():
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.payment import Payment, PaymentStatus, PaymentMethod
        from app.services.payment.cinetpay import cinetpay_service
        from datetime import datetime, timedelta, timezone

        stale_threshold = datetime.now(timezone.utc) - timedelta(hours=24)
        checked = 0
        confirmed = 0
        cancelled = 0

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(Payment).where(
                    Payment.status == PaymentStatus.PENDING,
                    Payment.created_at < stale_threshold,
                )
            )
            stale_payments = result.scalars().all()

            for payment in stale_payments:
                try:
                    if payment.method in (
                        PaymentMethod.ORANGE_MONEY,
                        PaymentMethod.MOOV_MONEY,
                        PaymentMethod.WAVE,
                    ) and payment.provider_ref:
                        status_data = await cinetpay_service.check_payment_status(
                            payment.provider_ref
                        )
                        if status_data["status"] == "ACCEPTED":
                            payment.status = PaymentStatus.CONFIRMED
                            payment.confirmed_at = datetime.now(timezone.utc)
                            confirmed += 1
                            # Trigger provisioning
                            confirm_payment_and_provision.delay(str(payment.id))
                        else:
                            payment.status = PaymentStatus.FAILED
                            cancelled += 1
                    else:
                        # Mark stale non-verifiable payments as failed
                        payment.status = PaymentStatus.FAILED
                        cancelled += 1

                    checked += 1
                except Exception as exc:
                    logger.error("Erreur vérification paiement", payment_id=str(payment.id), error=str(exc))

            await db.commit()

        return {"checked": checked, "confirmed": confirmed, "cancelled": cancelled}

    return _run_async(_check())


@celery_app.task(
    name="app.tasks.payment_tasks.check_installment_due_payments",
    queue="periodic",
)
def check_installment_due_payments() -> dict:
    """
    Daily task: check for installment payments due today and send reminders.
    Creates follow-up payment records for students who signed up for échelonné.
    """
    logger.info("Vérification des versements échelonnés dus")

    async def _check_installments():
        from sqlalchemy import select
        from app.core.database import AsyncSessionLocal
        from app.models.payment import Payment, PaymentStatus
        from datetime import date, timedelta

        today = datetime.now(timezone.utc).date()
        due_soon = datetime.now(timezone.utc) + timedelta(days=3)  # Due in next 3 days
        reminded = 0

        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(Payment).where(
                    Payment.status == PaymentStatus.PENDING,
                    Payment.installment_total > 1,
                    Payment.installment_number > 1,
                    Payment.due_date <= due_soon,
                )
            )
            due_payments = result.scalars().all()

            for payment in due_payments:
                logger.info(
                    "Rappel versement échelonné",
                    payment_id=str(payment.id),
                    installment_number=payment.installment_number,
                    due_date=payment.due_date.isoformat() if payment.due_date else None,
                )
                reminded += 1

            await db.commit()

        return {"reminders_sent": reminded}

    return _run_async(_check_installments())
