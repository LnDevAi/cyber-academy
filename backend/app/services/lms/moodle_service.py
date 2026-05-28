"""Moodle LMS integration service."""
from typing import Any, Dict, List, Optional

import httpx
import structlog

from app.core.config import settings

logger = structlog.get_logger(__name__)


class MoodleService:
    """
    Service d'intégration avec Moodle 4.x via REST API.
    Documentation: https://docs.moodle.org/dev/Web_service_API_functions
    """

    def __init__(self):
        self.base_url = settings.MOODLE_URL
        self.token = settings.MOODLE_TOKEN
        self.rest_endpoint = f"{self.base_url}/webservice/rest/server.php"

    async def _call(
        self,
        wsfunction: str,
        params: Optional[Dict] = None,
        method: str = "GET",
    ) -> Any:
        """
        Make a Moodle REST API call.

        Args:
            wsfunction: Moodle web service function name
            params: Additional parameters
            method: HTTP method (GET or POST)

        Returns:
            Parsed JSON response
        """
        base_params = {
            "wstoken": self.token,
            "wsfunction": wsfunction,
            "moodlewsrestformat": "json",
        }
        if params:
            base_params.update(params)

        async with httpx.AsyncClient(timeout=30.0) as client:
            if method.upper() == "POST":
                response = await client.post(self.rest_endpoint, data=base_params)
            else:
                response = await client.get(self.rest_endpoint, params=base_params)

            response.raise_for_status()
            data = response.json()

            if isinstance(data, dict) and "exception" in data:
                raise RuntimeError(
                    f"Erreur Moodle ({data.get('errorcode', 'unknown')}): {data.get('message', 'Inconnue')}"
                )

            return data

    async def get_user_progress(
        self, moodle_user_id: int, course_id: int
    ) -> Dict[str, Any]:
        """
        Get detailed progress for a user in a Moodle course.

        Args:
            moodle_user_id: Moodle internal user ID
            course_id: Moodle course ID

        Returns:
            Dict with progress_pct, completed_activities, total_activities, grade
        """
        logger.info(
            "Récupération progression Moodle",
            user_id=moodle_user_id,
            course_id=course_id,
        )

        # Get course completion status
        completion_data = await self._call(
            "core_completion_get_course_completion_status",
            {
                "courseid": course_id,
                "userid": moodle_user_id,
            },
        )

        # Get course activities completion
        activities_data = await self._call(
            "core_completion_get_activities_completion_status",
            {
                "courseid": course_id,
                "userid": moodle_user_id,
            },
        )

        # Get grades
        grades_data = await self._call(
            "gradereport_overview_get_course_grades",
            {"userid": moodle_user_id},
        )

        # Parse activities
        activities = activities_data.get("statuses", [])
        total = len(activities)
        completed = sum(1 for a in activities if a.get("state") == 1)

        # Parse grade
        grade_value = None
        if isinstance(grades_data, dict):
            for g in grades_data.get("grades", []):
                if g.get("courseid") == course_id:
                    grade_value = g.get("grade")
                    break

        progress_pct = (completed / total * 100) if total > 0 else 0.0

        return {
            "progress_pct": round(progress_pct, 1),
            "completed_activities": completed,
            "total_activities": total,
            "grade": float(grade_value) if grade_value is not None else None,
            "activities": [
                {
                    "module_id": str(a.get("cmid")),
                    "module_name": a.get("modname", ""),
                    "completed": a.get("state") == 1,
                    "completion_date": a.get("timecompleted"),
                }
                for a in activities
            ],
            "course_completed": completion_data.get("completionstatus", {}).get("completed", False),
        }

    async def enroll_user(self, moodle_user_id: int, course_id: int) -> int:
        """
        Enroll a user in a Moodle course.

        Args:
            moodle_user_id: Moodle internal user ID
            course_id: Moodle course ID

        Returns:
            enrollment_id (not directly available in Moodle — returns 1 if success)
        """
        logger.info(
            "Inscription utilisateur Moodle",
            user_id=moodle_user_id,
            course_id=course_id,
        )

        # Moodle enroll_users format
        params = {
            "enrolments[0][roleid]": 5,  # student role
            "enrolments[0][userid]": moodle_user_id,
            "enrolments[0][courseid]": course_id,
        }

        await self._call(
            "enrol_manual_enrol_users",
            params,
            method="POST",
        )

        logger.info("Inscription Moodle créée", user_id=moodle_user_id, course_id=course_id)
        return moodle_user_id  # Moodle doesn't return enrollment ID directly

    async def get_completion_status(
        self, moodle_user_id: int, course_id: int
    ) -> Dict[str, Any]:
        """
        Get simple completion status for a Moodle course.

        Returns:
            Dict with completed (bool) and grade (float)
        """
        logger.info(
            "Vérification complétion Moodle",
            user_id=moodle_user_id,
            course_id=course_id,
        )

        data = await self._call(
            "core_completion_get_course_completion_status",
            {
                "courseid": course_id,
                "userid": moodle_user_id,
            },
        )

        status = data.get("completionstatus", {})

        return {
            "completed": status.get("completed", False),
            "completiontime": status.get("completiontime"),
        }

    async def create_user(self, user: Any) -> int:
        """
        Create a Moodle user account.

        Args:
            user: User model instance

        Returns:
            moodle_user_id: Moodle internal user ID
        """
        logger.info("Création compte utilisateur Moodle", email=user.email)

        name_parts = user.full_name.split(" ", 1)
        first_name = name_parts[0]
        last_name = name_parts[1] if len(name_parts) > 1 else name_parts[0]

        params = {
            "users[0][username]": user.email.split("@")[0].replace(".", "_") + str(abs(hash(user.email)))[:4],
            "users[0][password]": f"Academy@{str(user.id)[:8]}!",  # Temporary password
            "users[0][firstname]": first_name,
            "users[0][lastname]": last_name,
            "users[0][email]": user.email,
            "users[0][phone1]": user.phone or "",
            "users[0][country]": user.country or "BF",
            "users[0][lang]": "fr",
        }

        result = await self._call("core_user_create_users", params, method="POST")

        if isinstance(result, list) and result:
            moodle_user_id = result[0].get("id")
            logger.info("Utilisateur Moodle créé", moodle_user_id=moodle_user_id)
            return int(moodle_user_id)

        raise RuntimeError("Erreur création compte Moodle")

    async def get_course_modules(self, course_id: int) -> List[Dict[str, Any]]:
        """Get all modules/activities in a Moodle course."""
        data = await self._call(
            "core_course_get_contents",
            {"courseid": course_id},
        )

        modules = []
        for section in data:
            for module in section.get("modules", []):
                modules.append({
                    "module_id": str(module.get("id")),
                    "module_name": module.get("name", ""),
                    "module_type": module.get("modname", ""),
                    "section": section.get("name", ""),
                    "visible": module.get("visible", 1) == 1,
                })

        return modules

    async def get_user_grades(self, moodle_user_id: int, course_id: int) -> Dict[str, Any]:
        """Get a user's grades for a specific course."""
        data = await self._call(
            "gradereport_user_get_grade_items",
            {
                "userid": moodle_user_id,
                "courseid": course_id,
            },
        )

        items = data.get("usergrades", [{}])[0].get("gradeitems", [])
        grade_items = [
            {
                "item_name": item.get("itemname", ""),
                "grade": item.get("graderaw"),
                "grade_max": item.get("grademax"),
                "grade_pct": item.get("percentageformatted", ""),
                "feedback": item.get("feedback", ""),
            }
            for item in items
        ]

        overall_grade = None
        for item in items:
            if item.get("itemtype") == "course":
                overall_grade = item.get("graderaw")
                break

        return {
            "overall_grade": overall_grade,
            "grade_items": grade_items,
        }


# Singleton
moodle_service = MoodleService()
