"""CinetPay payment service — Mobile Money UEMOA (Orange Money, Moov Money, Wave)."""
import hashlib
import hmac
import json
import uuid
from typing import Any, Dict, Optional

import httpx
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)

CINETPAY_BASE_URL = "https://api-checkout.cinetpay.com/v2"

# CinetPay channel codes
CHANNEL_MAP = {
    "ORANGE_MONEY": "OM",
    "MOOV_MONEY": "FLOOZ",
    "WAVE": "WAVE",
}


class CinetPayService:
    """Service d'intégration CinetPay pour les paiements Mobile Money en zone UEMOA."""

    def __init__(self):
        self.api_key = settings.CINETPAY_API_KEY
        self.site_id = settings.CINETPAY_SITE_ID
        self.base_url = CINETPAY_BASE_URL

    async def _post(self, endpoint: str, payload: Dict) -> Dict:
        """Make an async POST request to the CinetPay API."""
        url = f"{self.base_url}/{endpoint}"
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                url,
                json=payload,
                headers={
                    "Content-Type": "application/json",
                    "Accept": "application/json",
                },
            )
            response.raise_for_status()
            return response.json()

    async def initiate_payment(
        self,
        amount_fcfa: int,
        currency: str,
        transaction_id: str,
        customer: Dict[str, str],
        method: str,
        return_url: str,
        notify_url: str,
        description: str = "Formation Cyber Academy E-DEFENCE",
    ) -> Dict[str, Any]:
        """
        Initiate a CinetPay payment.

        Args:
            amount_fcfa: Amount in FCFA (XOF)
            currency: Currency code (XOF)
            transaction_id: Unique transaction identifier
            customer: Dict with name, email, phone_number, address, city, country, zip_code
            method: ORANGE_MONEY | MOOV_MONEY | WAVE
            return_url: URL to redirect after payment
            notify_url: Webhook URL for payment notification
            description: Payment description

        Returns:
            Dict with payment_url and transaction details
        """
        channel = CHANNEL_MAP.get(method, "")

        payload = {
            "apikey": self.api_key,
            "site_id": self.site_id,
            "transaction_id": transaction_id,
            "amount": amount_fcfa,
            "currency": currency,
            "alternative_currency": "",
            "description": description,
            "customer_id": customer.get("id", transaction_id),
            "customer_name": customer.get("name", ""),
            "customer_surname": customer.get("surname", ""),
            "customer_email": customer.get("email", ""),
            "customer_phone_number": customer.get("phone_number", ""),
            "customer_address": customer.get("address", "Ouagadougou"),
            "customer_city": customer.get("city", "Ouagadougou"),
            "customer_country": customer.get("country", "BF"),
            "customer_state": customer.get("state", "BF"),
            "customer_zip_code": customer.get("zip_code", "00000"),
            "notify_url": notify_url,
            "return_url": return_url,
            "channels": channel if channel else "ALL",
            "metadata": json.dumps({"source": "cyber_academy", "method": method}),
            "lang": "FR",
            "invoice_data": {},
        }

        logger.info(
            "Initiation paiement CinetPay",
            transaction_id=transaction_id,
            amount=amount_fcfa,
            method=method,
        )

        result = await self._post("payment", payload)

        if result.get("code") != "201":
            logger.error(
                "Erreur CinetPay initiation",
                code=result.get("code"),
                message=result.get("message"),
            )
            raise ValueError(
                f"Erreur CinetPay: {result.get('message', 'Erreur inconnue')} (code: {result.get('code')})"
            )

        payment_url = result.get("data", {}).get("payment_url", "")
        logger.info("Paiement CinetPay initié", payment_url=payment_url[:50])

        return {
            "payment_url": payment_url,
            "transaction_id": transaction_id,
            "payment_token": result.get("data", {}).get("payment_token", ""),
            "code": result.get("code"),
            "message": result.get("message"),
        }

    def verify_webhook(self, payload: Dict, signature: Optional[str] = None) -> bool:
        """
        Verify CinetPay webhook authenticity using HMAC signature.

        CinetPay sends: cpm_site_id, cpm_trans_id, cpm_trans_date,
        cpm_amount, cpm_currency, signature (SHA256 HMAC)
        """
        if not signature and payload.get("signature"):
            signature = payload["signature"]

        if not signature:
            logger.warning("Webhook CinetPay sans signature")
            return False

        # Build the string to sign: sorted key=value pairs
        sign_fields = [
            "cpm_amount",
            "cpm_currency",
            "cpm_page_action",
            "cpm_site_id",
            "cpm_trans_date",
            "cpm_trans_id",
            "cpm_version",
            "site_id",
        ]

        data_to_sign = "".join(
            str(payload.get(field, ""))
            for field in sign_fields
            if field in payload
        )

        # CinetPay uses SHA256 HMAC with API key
        expected_signature = hmac.new(
            key=self.api_key.encode("utf-8"),
            msg=data_to_sign.encode("utf-8"),
            digestmod=hashlib.sha256,
        ).hexdigest()

        is_valid = hmac.compare_digest(expected_signature.lower(), signature.lower())

        if not is_valid:
            logger.warning(
                "Signature webhook CinetPay invalide",
                transaction_id=payload.get("cpm_trans_id"),
            )

        return is_valid

    async def check_payment_status(self, transaction_id: str) -> Dict[str, Any]:
        """
        Check the status of a CinetPay transaction.

        Returns:
            Dict with keys: status (ACCEPTED/REFUSED/PENDING), amount, currency, payment_method
        """
        payload = {
            "apikey": self.api_key,
            "site_id": self.site_id,
            "transaction_id": transaction_id,
        }

        logger.info("Vérification statut paiement CinetPay", transaction_id=transaction_id)

        result = await self._post("payment/check", payload)

        if result.get("code") == "00":
            data = result.get("data", {})
            raw_status = data.get("cpm_result", "")

            # Normalize status
            if raw_status == "00":
                status = "ACCEPTED"
            elif raw_status in ("", "PENDING"):
                status = "PENDING"
            else:
                status = "REFUSED"

            return {
                "status": status,
                "transaction_id": transaction_id,
                "amount": data.get("cpm_amount"),
                "currency": data.get("cpm_currency"),
                "payment_method": data.get("payment_method", ""),
                "phone_number": data.get("cel_phone_num", ""),
                "raw_result": raw_status,
                "message": data.get("cpm_error_message", ""),
            }

        logger.error(
            "Erreur vérification CinetPay",
            code=result.get("code"),
            message=result.get("message"),
        )
        raise ValueError(f"Erreur vérification paiement: {result.get('message', 'Inconnue')}")


# Singleton
cinetpay_service = CinetPayService()
