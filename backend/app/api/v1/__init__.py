"""API v1 router aggregation."""
from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.courses import router as courses_router
from app.api.v1.enrollments import router as enrollments_router
from app.api.v1.payments import router as payments_router
from app.api.v1.cyber_range import router as cyber_range_router
from app.api.v1.badges import router as badges_router
from app.api.v1.targui import router as targui_router
from app.api.v1.mentors import router as mentors_router
from app.api.v1.admin import router as admin_router
from app.api.v1.b2b import router as b2b_router

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(auth_router)
api_v1_router.include_router(courses_router)
api_v1_router.include_router(enrollments_router)
api_v1_router.include_router(payments_router)
api_v1_router.include_router(cyber_range_router)
api_v1_router.include_router(badges_router)
api_v1_router.include_router(targui_router)
api_v1_router.include_router(mentors_router)
api_v1_router.include_router(admin_router)
api_v1_router.include_router(b2b_router)

__all__ = ["api_v1_router"]
