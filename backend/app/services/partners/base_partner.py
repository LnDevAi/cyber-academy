"""Abstract base class for partner service integrations."""
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional


class PartnerService(ABC):
    """Interface que tous les services partenaires doivent implémenter."""

    @abstractmethod
    async def create_candidate_account(self, user: Any) -> str:
        """
        Create a candidate account in the partner's system.

        Args:
            user: User model instance

        Returns:
            candidate_id: Partner-assigned candidate identifier
        """
        raise NotImplementedError

    @abstractmethod
    async def enroll_student(self, user: Any, course_id: str) -> str:
        """
        Enroll a student in a partner course/program.

        Args:
            user: User model instance
            course_id: Partner course identifier

        Returns:
            enrollment_id: Partner enrollment identifier
        """
        raise NotImplementedError

    @abstractmethod
    async def get_exam_results(self, candidate_id: str) -> Dict[str, Any]:
        """
        Retrieve exam results for a candidate.

        Args:
            candidate_id: Partner candidate identifier

        Returns:
            Dict with keys: passed (bool), score (float), grade (str), date (str)
        """
        raise NotImplementedError

    @abstractmethod
    async def generate_exam_link(self, candidate_id: str, exam_code: str) -> str:
        """
        Generate a link to the partner's exam portal.

        Args:
            candidate_id: Partner candidate identifier
            exam_code: Exam/certification code

        Returns:
            exam_url: URL to access the exam
        """
        raise NotImplementedError

    @abstractmethod
    async def provision_voucher(self, candidate_id: str, exam_code: str) -> str:
        """
        Provision an exam voucher/access code.

        Args:
            candidate_id: Partner candidate identifier
            exam_code: Exam/certification code

        Returns:
            voucher_code: Exam access voucher code
        """
        raise NotImplementedError

    async def get_progress(self, enrollment_id: str) -> Dict[str, Any]:
        """
        Get student progress in a partner course. Optional implementation.

        Returns:
            Dict with keys: progress_pct (float), completed_modules (int),
                           total_modules (int), last_activity (str)
        """
        return {
            "progress_pct": 0.0,
            "completed_modules": 0,
            "total_modules": 0,
            "last_activity": None,
        }
