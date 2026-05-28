"""Stripe payment service — international card payments."""
from typing import Any, Dict, Optional

import stripe
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

stripe.api_key = settings.STRIPE_SECRET_KEY


class StripeService:
    """Service d'intégration Stripe pour les paiements par carte bancaire internationale."""

    def __init__(self):
        stripe.api_key = settings.STRIPE_SECRET_KEY
        self.webhook_secret = settings.STRIPE_WEBHOOK_SECRET

    async def create_payment_intent(
        self,
        amount_cents: int,
        currency: str = "eur",
        metadata: Optional[Dict[str, str]] = None,
        description: str = "Formation Cyber Academy E-DEFENCE",
        customer_email: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Create a Stripe PaymentIntent for card payment.

        Args:
            amount_cents: Amount in smallest currency unit (cents for EUR)
            currency: ISO currency code (eur, usd)
            metadata: Additional metadata dict (enrollment_id, user_id, etc.)
            description: Payment description
            customer_email: Optional customer email for receipt

        Returns:
            Dict with client_secret, payment_intent_id, amount, currency
        """
        intent_params: Dict[str, Any] = {
            "amount": amount_cents,
            "currency": currency.lower(),
            "description": description,
            "payment_method_types": ["card"],
            "metadata": metadata or {},
            "statement_descriptor": "EDEFENCE ACADEMY",
        }

        if customer_email:
            intent_params["receipt_email"] = customer_email

        logger.info(
            "Création Stripe PaymentIntent",
            amount_cents=amount_cents,
            currency=currency,
        )

        intent = stripe.PaymentIntent.create(**intent_params)

        logger.info(
            "Stripe PaymentIntent créé",
            payment_intent_id=intent.id,
            status=intent.status,
        )

        return {
            "client_secret": intent.client_secret,
            "payment_intent_id": intent.id,
            "amount_cents": intent.amount,
            "currency": intent.currency,
            "status": intent.status,
        }

    def verify_webhook(self, payload: bytes, signature: str) -> Dict[str, Any]:
        """
        Verify and parse a Stripe webhook event.

        Args:
            payload: Raw request body bytes
            signature: Stripe-Signature header value

        Returns:
            Stripe Event dict

        Raises:
            stripe.error.SignatureVerificationError if invalid
            ValueError if webhook secret not configured
        """
        if not self.webhook_secret or self.webhook_secret == "whsec_changeme":
            raise ValueError("STRIPE_WEBHOOK_SECRET non configuré")

        event = stripe.Webhook.construct_event(
            payload, signature, self.webhook_secret
        )

        logger.info(
            "Webhook Stripe vérifié",
            event_type=event["type"],
            event_id=event["id"],
        )

        return dict(event)

    async def retrieve_payment_intent(self, payment_intent_id: str) -> Dict[str, Any]:
        """Retrieve a PaymentIntent by ID."""
        intent = stripe.PaymentIntent.retrieve(payment_intent_id)
        return {
            "payment_intent_id": intent.id,
            "amount_cents": intent.amount,
            "currency": intent.currency,
            "status": intent.status,
            "metadata": dict(intent.metadata),
        }

    async def create_refund(
        self,
        payment_intent_id: str,
        amount_cents: Optional[int] = None,
        reason: str = "requested_by_customer",
    ) -> Dict[str, Any]:
        """
        Create a Stripe refund.

        Args:
            payment_intent_id: Stripe PaymentIntent ID to refund
            amount_cents: Partial refund amount in cents (None = full refund)
            reason: Refund reason

        Returns:
            Dict with refund details
        """
        refund_params: Dict[str, Any] = {
            "payment_intent": payment_intent_id,
            "reason": reason,
        }
        if amount_cents:
            refund_params["amount"] = amount_cents

        refund = stripe.Refund.create(**refund_params)

        logger.info(
            "Remboursement Stripe créé",
            refund_id=refund.id,
            payment_intent_id=payment_intent_id,
            amount=refund.amount,
        )

        return {
            "refund_id": refund.id,
            "payment_intent_id": payment_intent_id,
            "amount_cents": refund.amount,
            "currency": refund.currency,
            "status": refund.status,
        }


# Singleton
stripe_service = StripeService()
