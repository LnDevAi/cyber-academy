"""Health check endpoint."""
from fastapi import APIRouter
from app.core.config import settings

router = APIRouter(tags=["Santé"])


@router.get("/health")
async def health_check() -> dict:
    """Health check endpoint — vérifie que l'API est opérationnelle."""
    return {
        "status": "ok",
        "version": settings.VERSION,
        "service": settings.APP_NAME,
        "environment": settings.ENVIRONMENT,
    }
