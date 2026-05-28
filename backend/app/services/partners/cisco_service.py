"""Cisco NetAcad Partner Service — CCNA CyberOps certification."""
from typing import Any, Dict, Optional

import httpx
import structlog

from app.core.config import settings
from app.services.partners.base_partner import PartnerService

logger = structlog.get_logger(__name__)


class CiscoNetAcadService(PartnerService):
    """
    Service d'intégration avec l'API Cisco Network Academy (NetAcad).
    Gère la certification CCNA CyberOps (200-201 CBROPS).
    """

    CCNA_CYBEROPS_COURSE_ID = "CCNA-CBROPS-v1.0"
    CCNA_CYBEROPS_EXAM_CODE = "200-201"

    def __init__(self):
        self.api_url = settings.CISCO_NETACAD_API_URL
        self.api_key = settings.CISCO_NETACAD_API_KEY

    def _get_headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    async def _get(self, endpoint: str, params: Optional[Dict] = None) -> Dict:
        """Async GET request to Cisco NetAcad API."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{self.api_url}/{endpoint}",
                headers=self._get_headers(),
                params=params or {},
            )
            response.raise_for_status()
            return response.json()

    async def _post(self, endpoint: str, data: Dict) -> Dict:
        """Async POST request to Cisco NetAcad API."""
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                f"{self.api_url}/{endpoint}",
                headers=self._get_headers(),
                json=data,
            )
            response.raise_for_status()
            return response.json()

    async def create_candidate_account(self, user: Any) -> str:
        """
        Create a Cisco NetAcad account for a student.

        Returns:
            candidate_id: Cisco NetAcad user identifier
        """
        logger.info("Création compte NetAcad Cisco", user_email=user.email)

        name_parts = user.full_name.split(" ", 1)

        payload = {
            "email": user.email,
            "firstName": name_parts[0],
            "lastName": name_parts[1] if len(name_parts) > 1 else "",
            "phone": user.phone or "",
            "country": user.country or "BF",
            "language": "fr_FR",
            "partnerInstitutionId": "EDEFENCE-BF",
        }

        result = await self._post("users/register", payload)
        candidate_id = str(result.get("userId", ""))

        logger.info("Compte NetAcad créé", candidate_id=candidate_id)
        return candidate_id

    async def enroll_student(self, user: Any, course_id: str) -> str:
        """
        Enroll a student in a Cisco NetAcad course.

        Args:
            user: User model instance
            course_id: Cisco course identifier

        Returns:
            enrollment_id: NetAcad enrollment identifier
        """
        logger.info(
            "Inscription NetAcad Cisco",
            user_email=user.email,
            course_id=course_id,
        )

        payload = {
            "email": user.email,
            "courseId": course_id or self.CCNA_CYBEROPS_COURSE_ID,
            "sectionId": f"EDEFENCE-{course_id}-001",
            "partnerInstitutionId": "EDEFENCE-BF",
        }

        result = await self._post("enrollments", payload)
        enrollment_id = str(result.get("enrollmentId", ""))

        logger.info("Inscription NetAcad créée", enrollment_id=enrollment_id)
        return enrollment_id

    async def get_progress(self, enrollment_id: str) -> Dict[str, Any]:
        """
        Get a student's progress in a NetAcad course.

        Returns:
            Dict with progress_pct, completed_modules, total_modules, grade, last_activity
        """
        logger.info("Récupération progression NetAcad", enrollment_id=enrollment_id)

        result = await self._get(f"enrollments/{enrollment_id}/progress")

        return {
            "progress_pct": float(result.get("completionPercentage", 0)),
            "completed_modules": result.get("completedActivities", 0),
            "total_modules": result.get("totalActivities", 0),
            "grade": float(result.get("currentGrade", 0)),
            "last_activity": result.get("lastAccessedAt"),
            "status": result.get("status", "active"),
        }

    async def provision_voucher(self, candidate_id: str, exam_code: str) -> str:
        """
        Provision a Cisco exam voucher (Pearson VUE).

        Returns:
            voucher_code: Cisco/Pearson VUE exam voucher code
        """
        logger.info(
            "Provisionnement voucher Cisco",
            candidate_id=candidate_id,
            exam_code=exam_code,
        )

        payload = {
            "userId": candidate_id,
            "examCode": exam_code or self.CCNA_CYBEROPS_EXAM_CODE,
            "partnerInstitutionId": "EDEFENCE-BF",
            "voucherType": "FULL",
        }

        result = await self._post("vouchers/provision", payload)
        voucher_code = result.get("voucherCode", "")

        logger.info("Voucher Cisco provisionné", exam_code=exam_code)
        return voucher_code

    async def get_exam_results(self, candidate_id: str) -> Dict[str, Any]:
        """
        Get Cisco certification exam results (via Pearson VUE).

        Returns:
            Dict with: passed (bool), score (float), date (str), certificate_url (str)
        """
        logger.info("Récupération résultats examen Cisco", candidate_id=candidate_id)

        result = await self._get(f"users/{candidate_id}/certifications")

        certs = result.get("certifications", [])
        latest = certs[0] if certs else {}

        return {
            "passed": latest.get("status", "").upper() == "ACTIVE",
            "score": float(latest.get("score", 0)),
            "date": latest.get("expirationDate", ""),
            "certificate_url": latest.get("certificateUrl", ""),
            "certification_name": latest.get("name", "CCNA CyberOps"),
        }

    async def generate_exam_link(self, candidate_id: str, exam_code: str) -> str:
        """
        Generate link to Cisco/Pearson VUE exam scheduling.

        Returns:
            URL to schedule/access Cisco exam
        """
        return f"https://home.pearsonvue.com/cisco/online?exam={exam_code}&candidateId={candidate_id}"

    async def get_exam_voucher(self, user: Any) -> str:
        """
        Get or provision a CCNA CyberOps exam voucher for a user.
        Convenience method combining create_candidate_account + provision_voucher.
        """
        candidate_id = await self.create_candidate_account(user)
        return await self.provision_voucher(candidate_id, self.CCNA_CYBEROPS_EXAM_CODE)


# Singleton
cisco_service = CiscoNetAcadService()
