"""PECB Partner Service — ISO 27001, DPO UEMOA certifications."""
from typing import Any, Dict, Optional

import httpx
import structlog

from app.core.config import settings
from app.services.partners.base_partner import PartnerService

logger = structlog.get_logger(__name__)


class PECBPartnerService(PartnerService):
    """
    Service d'intégration avec le portail partenaire PECB.
    Gère les certifications: CDPO_UEMOA, ISO27001_LI, CLEH_SAHEL.
    """

    PECB_EXAM_CODES = {
        "CDPO_UEMOA": "PECB-DPO",
        "ISO27001_LI": "PECB-ISO27001-LI",
        "CLEH_SAHEL": "PECB-LEAD-ETHICAL-HACKER",
    }

    def __init__(self):
        self.api_base_url = settings.PECB_API_BASE_URL
        self.api_key = settings.PECB_API_KEY

    def _get_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Partner-Source": "EDEFENCE-CYBER-ACADEMY",
        }

    async def _get(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Async GET request to PECB Partner API."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{self.api_base_url}/{endpoint}",
                headers=self._get_headers(),
                params=params or {},
            )
            response.raise_for_status()
            return response.json()

    async def _post(self, endpoint: str, data: Dict) -> Dict:
        """Async POST request to PECB Partner API."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.api_base_url}/{endpoint}",
                headers=self._get_headers(),
                json=data,
            )
            response.raise_for_status()
            return response.json()

    async def create_candidate_account(self, user: Any) -> str:
        """
        Create a PECB candidate account for a student.

        Args:
            user: User model instance

        Returns:
            candidate_id: PECB candidate identifier string
        """
        logger.info(
            "Création compte candidat PECB",
            user_email=user.email,
        )

        name_parts = user.full_name.split(" ", 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else ""

        payload = {
            "first_name": first_name,
            "last_name": last_name,
            "email": user.email,
            "phone": user.phone or "",
            "country": user.country or "BF",
            "language": "fr",
            "partner_candidate_id": str(user.id),
        }

        result = await self._post("candidates", payload)
        candidate_id = str(result.get("candidate_id", ""))

        logger.info("Compte candidat PECB créé", candidate_id=candidate_id)
        return candidate_id

    async def enroll_student(self, user: Any, course_id: str) -> str:
        """
        Enroll a student in a PECB training program.

        Args:
            user: User model instance
            course_id: PECB course code (e.g., PECB-ISO27001-LI)

        Returns:
            enrollment_id: PECB enrollment identifier
        """
        logger.info(
            "Inscription PECB",
            user_email=user.email,
            course_id=course_id,
        )

        payload = {
            "candidate_email": user.email,
            "course_code": course_id,
            "partner_id": "EDEFENCE",
            "delivery_method": "online",
            "language": "fr",
        }

        result = await self._post("enrollments", payload)
        enrollment_id = str(result.get("enrollment_id", ""))

        logger.info("Inscription PECB créée", enrollment_id=enrollment_id)
        return enrollment_id

    async def provision_voucher(self, candidate_id: str, exam_code: str) -> str:
        """
        Provision a PECB exam voucher for a candidate.

        Args:
            candidate_id: PECB candidate ID
            exam_code: PECB exam code

        Returns:
            voucher_code: Exam access voucher
        """
        logger.info(
            "Provisionnement voucher PECB",
            candidate_id=candidate_id,
            exam_code=exam_code,
        )

        payload = {
            "candidate_id": candidate_id,
            "exam_code": exam_code,
            "partner_id": "EDEFENCE",
            "delivery": "online",
        }

        result = await self._post("vouchers/provision", payload)
        voucher_code = result.get("voucher_code", "")

        logger.info("Voucher PECB provisionné", voucher_code=voucher_code[:4] + "****")
        return voucher_code

    async def get_exam_results(self, candidate_id: str) -> Dict[str, Any]:
        """
        Retrieve PECB exam results for a candidate.

        Returns:
            Dict with: passed (bool), score (float), grade (str), date (str)
        """
        logger.info("Récupération résultats PECB", candidate_id=candidate_id)

        result = await self._get(f"candidates/{candidate_id}/results")

        latest = result.get("results", [{}])[0] if result.get("results") else {}
        return {
            "passed": latest.get("result", "").upper() == "PASS",
            "score": float(latest.get("score", 0)),
            "grade": latest.get("grade", ""),
            "date": latest.get("exam_date", ""),
            "certificate_url": latest.get("certificate_url", ""),
            "exam_code": latest.get("exam_code", ""),
        }

    async def generate_exam_link(self, candidate_id: str, exam_code: str) -> str:
        """
        Generate a PECB online exam access link.

        Returns:
            exam_url: Proctored exam URL
        """
        logger.info(
            "Génération lien examen PECB",
            candidate_id=candidate_id,
            exam_code=exam_code,
        )

        result = await self._post("exams/generate-link", {
            "candidate_id": candidate_id,
            "exam_code": exam_code,
            "partner_id": "EDEFENCE",
        })

        return result.get("exam_url", f"{self.api_base_url}/exam/{exam_code}/{candidate_id}")

    def get_exam_code_for_course(self, course_code: str) -> str:
        """Return the PECB exam code for a given course code."""
        return self.PECB_EXAM_CODES.get(course_code, f"PECB-{course_code}")


# Singleton
pecb_service = PECBPartnerService()
