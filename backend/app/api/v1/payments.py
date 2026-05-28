"""Payment endpoints — CinetPay and Stripe."""
import hashlib
import hmac
import uuid
from datetime import datetime, timedelta, timezone
from typing import List, Optional

import stripe
import structlog
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, require_admin
from app.core.config import settings
from app.core.database import get_db
from app.models.course import Course
from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.payment import Payment, PaymentCurrency, PaymentMethod, PaymentStatus
from app.models.user import User, UserRole
from app.schemas.payment import (
    CinetPayInitiateRequest,
    CinetPayInitiateResponse,
    PaymentResponse,
    PaymentWebhookCinetPay,
    StripeIntentRequest,
    StripeIntentResponse,
)
from app.services.payment.cinetpay import cinetpay_service
from app.services.payment.stripe_service import stripe_service
from app.tasks.payment_tasks import confirm_payment_and_provision

logger = structlog.get_logger(__name__)

router = APIRouter(prefix="/payments", tags=["Paiements"])

# FCFA to EUR conversion rate (approximate)
FCFA_TO_EUR_RATE = 655.957


@router.post("/cinetpay/initiate", response_model=CinetPayInitiateResponse)
async def initiate_cinetpay(
    request: CinetPayInitiateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Initier un paiement Mobile Money via CinetPay.
    Supporte Orange Money, Moov Money, Wave en 1x, 2x ou 3x.
    """
    # Validate method
    valid_mobile_methods = {
        PaymentMethod.ORANGE_MONEY,
        PaymentMethod.MOOV_MONEY,
        PaymentMethod.WAVE,
    }
    if request.method not in valid_mobile_methods:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Méthode non supportée par CinetPay. Utilisez: ORANGE_MONEY, MOOV_MONEY, WAVE",
        )

    # Load enrollment
    enrollment = await db.get(Enrollment, request.enrollment_id)
    if not enrollment or enrollment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inscription introuvable",
        )

    if enrollment.status not in (EnrollmentStatus.PENDING_PAYMENT,):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cette inscription n'est pas en attente de paiement (statut: {enrollment.status.value})",
        )

    # Load course for amount
    course = await db.get(Course, enrollment.course_id)
    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Formation introuvable",
        )

    # Calculate installment amount
    total_price = course.price_fcfa
    installment_amount = total_price // request.installment
    # Adjust last installment for rounding
    remaining = total_price - (installment_amount * (request.installment - 1))

    # Transaction ID must be unique
    transaction_id = f"CA-{str(uuid.uuid4()).replace('-', '')[:16].upper()}"

    # Create payment record for first installment
    payment = Payment(
        user_id=current_user.id,
        enrollment_id=enrollment.id,
        amount_fcfa=installment_amount,
        currency=PaymentCurrency.XOF,
        method=request.method,
        provider_ref=transaction_id,
        status=PaymentStatus.PENDING,
        installment_number=1,
        installment_total=request.installment,
    )
    db.add(payment)
    await db.flush()

    # Create future installment payment records (if échelonné)
    for i in range(2, request.installment + 1):
        amount = remaining if i == request.installment else installment_amount
        due_date = datetime.now(timezone.utc) + timedelta(days=30 * (i - 1))
        future_payment = Payment(
            user_id=current_user.id,
            enrollment_id=enrollment.id,
            amount_fcfa=amount,
            currency=PaymentCurrency.XOF,
            method=request.method,
            provider_ref=None,  # Will be assigned when installment is paid
            status=PaymentStatus.PENDING,
            installment_number=i,
            installment_total=request.installment,
            due_date=due_date,
        )
        db.add(future_payment)

    await db.flush()

    # Call CinetPay API
    try:
        customer = {
            "id": str(current_user.id),
            "name": current_user.full_name.split()[0] if current_user.full_name else "",
            "surname": " ".join(current_user.full_name.split()[1:]) if len(current_user.full_name.split()) > 1 else "",
            "email": current_user.email,
            "phone_number": current_user.phone or "",
            "country": current_user.country or "BF",
        }

        return_url = f"{settings.FRONTEND_URL}/payment/success?payment_id={payment.id}"
        notify_url = f"{settings.CINETPAY_NOTIFY_URL}"

        cinetpay_result = await cinetpay_service.initiate_payment(
            amount_fcfa=installment_amount,
            currency="XOF",
            transaction_id=transaction_id,
            customer=customer,
            method=request.method.value,
            return_url=return_url,
            notify_url=notify_url,
            description=f"Formation {course.code} — Versement 1/{request.installment}",
        )

        payment_url = cinetpay_result.get("payment_url", "")
        payment.payment_url = payment_url
        await db.flush()

        logger.info(
            "Paiement CinetPay initié",
            payment_id=str(payment.id),
            transaction_id=transaction_id,
            amount=installment_amount,
        )

        return {
            "payment_url": payment_url,
            "payment_id": payment.id,
            "transaction_id": transaction_id,
            "amount_fcfa": installment_amount,
            "installment_number": 1,
            "installment_total": request.installment,
            "message": f"Paiement initié — Versement 1/{request.installment}. Redirigez l'utilisateur vers le lien de paiement.",
        }

    except Exception as exc:
        logger.error("Erreur initiation CinetPay", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Erreur CinetPay: {str(exc)}",
        )


@router.post("/cinetpay/webhook", status_code=status.HTTP_200_OK)
async def cinetpay_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Webhook CinetPay — notification de paiement (HMAC vérifié).
    CinetPay envoie une requête POST quand un paiement est confirmé ou échoué.
    """
    try:
        body = await request.form()
        payload = dict(body)
    except Exception:
        body_bytes = await request.body()
        import json
        try:
            payload = json.loads(body_bytes)
        except Exception:
            payload = {}

    logger.info("Webhook CinetPay reçu", transaction_id=payload.get("cpm_trans_id"))

    # Verify webhook signature
    signature = payload.get("signature", "")
    if not cinetpay_service.verify_webhook(payload, signature):
        logger.warning("Signature webhook CinetPay invalide", payload=payload)
        # Return 200 anyway to avoid CinetPay retries with invalid payloads
        # but don't process
        return {"message": "Signature invalide — ignoré"}

    transaction_id = payload.get("cpm_trans_id")
    if not transaction_id:
        return {"message": "transaction_id manquant"}

    # Find payment by provider_ref
    result = await db.execute(
        select(Payment).where(Payment.provider_ref == transaction_id)
    )
    payment = result.scalar_one_or_none()

    if not payment:
        logger.warning("Paiement introuvable pour transaction", transaction_id=transaction_id)
        return {"message": "Paiement introuvable"}

    # Parse CinetPay result
    cpm_result = payload.get("cpm_result", "")
    if cpm_result == "00":
        payment.status = PaymentStatus.CONFIRMED
        payment.confirmed_at = datetime.now(timezone.utc)
        payment.webhook_payload = payload
        await db.flush()

        logger.info(
            "Paiement CinetPay confirmé",
            payment_id=str(payment.id),
            transaction_id=transaction_id,
        )

        # Trigger async provisioning
        confirm_payment_and_provision.delay(str(payment.id))

    else:
        payment.status = PaymentStatus.FAILED
        payment.webhook_payload = payload
        await db.flush()

        logger.warning(
            "Paiement CinetPay échoué",
            transaction_id=transaction_id,
            cpm_result=cpm_result,
            error=payload.get("cpm_error_message", ""),
        )

    await db.commit()
    return {"message": "OK"}


@router.post("/stripe/intent", response_model=StripeIntentResponse)
async def create_stripe_intent(
    request: StripeIntentRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Créer un Stripe PaymentIntent pour paiement par carte bancaire internationale."""
    enrollment = await db.get(Enrollment, request.enrollment_id)
    if not enrollment or enrollment.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Inscription introuvable",
        )

    if enrollment.status != EnrollmentStatus.PENDING_PAYMENT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cette inscription n'est pas en attente de paiement",
        )

    course = await db.get(Course, enrollment.course_id)
    if not course:
        raise HTTPException(status_code=404, detail="Formation introuvable")

    # Convert FCFA to the requested currency
    currency = request.currency.lower()
    if currency == "eur":
        amount_cents = int(course.price_fcfa / FCFA_TO_EUR_RATE * 100)
    elif currency == "usd":
        amount_cents = int(course.price_fcfa / 600 * 100)  # Approximate
    else:
        raise HTTPException(status_code=400, detail="Devise non supportée. Utilisez eur ou usd.")

    metadata = {
        "enrollment_id": str(enrollment.id),
        "user_id": str(current_user.id),
        "course_code": course.code,
        "source": "cyber_academy",
    }

    try:
        intent_data = await stripe_service.create_payment_intent(
            amount_cents=amount_cents,
            currency=currency,
            metadata=metadata,
            description=f"Cyber Academy E-DEFENCE — {course.title}",
            customer_email=current_user.email,
        )

        # Create payment record
        payment = Payment(
            user_id=current_user.id,
            enrollment_id=enrollment.id,
            amount_fcfa=course.price_fcfa,
            currency=PaymentCurrency.EUR if currency == "eur" else PaymentCurrency.USD,
            method=PaymentMethod.CARD_STRIPE,
            provider_ref=intent_data["payment_intent_id"],
            status=PaymentStatus.PENDING,
            installment_number=1,
            installment_total=1,
        )
        db.add(payment)
        await db.flush()

        return {
            "client_secret": intent_data["client_secret"],
            "payment_intent_id": intent_data["payment_intent_id"],
            "amount_cents": amount_cents,
            "currency": currency,
            "payment_id": payment.id,
        }

    except Exception as exc:
        logger.error("Erreur Stripe", error=str(exc))
        raise HTTPException(status_code=502, detail=f"Erreur Stripe: {str(exc)}")


@router.post("/stripe/webhook", status_code=status.HTTP_200_OK)
async def stripe_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Webhook Stripe — confirmation de paiement par carte."""
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature", "")

    try:
        event = stripe_service.verify_webhook(payload, sig_header)
    except ValueError as exc:
        logger.error("Webhook Stripe invalide", error=str(exc))
        raise HTTPException(status_code=400, detail="Payload invalide")
    except stripe.error.SignatureVerificationError as exc:
        logger.error("Signature Stripe invalide", error=str(exc))
        raise HTTPException(status_code=400, detail="Signature Stripe invalide")

    event_type = event.get("type", "")
    logger.info("Webhook Stripe reçu", event_type=event_type)

    if event_type == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        payment_intent_id = payment_intent["id"]

        # Find payment
        result = await db.execute(
            select(Payment).where(Payment.provider_ref == payment_intent_id)
        )
        payment = result.scalar_one_or_none()

        if payment:
            payment.status = PaymentStatus.CONFIRMED
            payment.confirmed_at = datetime.now(timezone.utc)
            payment.webhook_payload = payment_intent
            await db.flush()

            # Trigger provisioning
            confirm_payment_and_provision.delay(str(payment.id))

            logger.info(
                "Paiement Stripe confirmé",
                payment_id=str(payment.id),
                payment_intent_id=payment_intent_id,
            )

    elif event_type == "payment_intent.payment_failed":
        payment_intent = event["data"]["object"]
        payment_intent_id = payment_intent["id"]

        result = await db.execute(
            select(Payment).where(Payment.provider_ref == payment_intent_id)
        )
        payment = result.scalar_one_or_none()
        if payment:
            payment.status = PaymentStatus.FAILED
            payment.webhook_payload = payment_intent
            await db.flush()

    await db.commit()
    return {"received": True}


@router.get("", response_model=List[PaymentResponse])
async def list_payments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> List[Payment]:
    """Historique des paiements (étudiant: les siens; admin: tous)."""
    query = select(Payment)
    if current_user.role != UserRole.ADMIN:
        query = query.where(Payment.user_id == current_user.id)

    query = query.order_by(Payment.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()
