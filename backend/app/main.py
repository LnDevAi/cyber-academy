"""Cyber Academy E-DEFENCE — FastAPI Application Entry Point."""
import structlog
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.v1 import api_v1_router
from app.api.v1.health import router as health_router
from app.core.config import settings

logger = structlog.get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: startup and shutdown events."""
    # Startup
    logger.info(
        "Cyber Academy E-DEFENCE démarrage",
        version=settings.VERSION,
        environment=settings.ENVIRONMENT,
        debug=settings.DEBUG,
    )

    # Initialize MinIO bucket on startup
    try:
        from app.core.minio_client import minio_client
        logger.info("MinIO initialisé", bucket=settings.MINIO_BUCKET)
    except Exception as exc:
        logger.warning("MinIO non disponible au démarrage", error=str(exc))

    yield

    # Shutdown
    logger.info("Cyber Academy E-DEFENCE arrêt")


# Create FastAPI application
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="""
# Cyber Academy E-DEFENCE API

Plateforme phygitale de formation en cybersécurité pour l'espace UEMOA.

## Fonctionnalités

- **Authentification** — JWT + TOTP 2FA
- **Catalogue de formations** — 10 programmes certifiants
- **Inscriptions & Paiements** — CinetPay (Mobile Money) + Stripe
- **Cyber Range** — Labs pratiques sur k3s
- **TARGUI** — Tuteur IA RAG (Claude Sonnet)
- **Badges Blockchain** — Certificats ERC-721 sur Polygon
- **B2B** — Comptes entreprise avec inscription en masse

## Partenaires

E-DEFENCE | PECB | Cisco | Fortinet | EC-Council

## Support

**Email:** support@edefence.tech
**Site:** https://academy.edefence.tech
    """,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
    lifespan=lifespan,
    redirect_slashes=False,
)

# ── CORS Middleware ──────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["X-Total-Count", "X-Page", "X-Per-Page"],
)

# ── Global Exception Handlers ────────────────────────────────────────────────

@app.exception_handler(404)
async def not_found_handler(request: Request, exc) -> JSONResponse:
    return JSONResponse(
        status_code=status.HTTP_404_NOT_FOUND,
        content={"detail": "Ressource introuvable", "path": str(request.url.path)},
    )


@app.exception_handler(500)
async def internal_error_handler(request: Request, exc) -> JSONResponse:
    logger.error("Erreur interne serveur", path=str(request.url.path), error=str(exc))
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "Erreur interne du serveur. Veuillez contacter le support."},
    )


# ── Routers ──────────────────────────────────────────────────────────────────

# Health check at /api/health (outside versioned prefix)
app.include_router(health_router, prefix="/api")

# All v1 API routes at /api/v1/
app.include_router(api_v1_router)


# ── Root redirect ────────────────────────────────────────────────────────────

@app.get("/", include_in_schema=False)
async def root() -> dict:
    return {
        "service": settings.APP_NAME,
        "version": settings.VERSION,
        "docs": "/api/docs",
        "health": "/api/health",
        "status": "operational",
    }
