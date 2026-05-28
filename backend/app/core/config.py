"""Application configuration using Pydantic Settings."""
import json
from typing import List, Optional

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Application
    APP_NAME: str = "Cyber Academy E-DEFENCE"
    VERSION: str = "1.0.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"

    # Security
    SECRET_KEY: str = "changeme-super-secret-key-64-hex-characters-minimum-length"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://cyberacademy:password@localhost:5432/cyberacademy"
    DATABASE_SYNC_URL: str = "postgresql://cyberacademy:password@localhost:5432/cyberacademy"
    DB_PASSWORD: str = "password"
    DB_POOL_SIZE: int = 20
    DB_MAX_OVERFLOW: int = 40

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    REDIS_PASSWORD: str = ""

    # MinIO
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "cyberacademy"
    MINIO_SECRET_KEY: str = "changeme"
    MINIO_BUCKET: str = "cyberacademy"
    MINIO_SECURE: bool = False

    # Anthropic / TARGUI
    ANTHROPIC_API_KEY: str = "sk-ant-changeme"
    TARGUI_MODEL: str = "claude-sonnet-4-6"

    # Moodle LMS
    MOODLE_URL: str = "http://moodle"
    MOODLE_TOKEN: str = "changeme-moodle-token"

    # CinetPay (Mobile Money UEMOA)
    CINETPAY_API_KEY: str = "changeme-cinetpay-key"
    CINETPAY_SITE_ID: str = "changeme-site-id"
    CINETPAY_BASE_URL: str = "https://api-checkout.cinetpay.com/v2"
    CINETPAY_NOTIFY_URL: str = "https://academy.edefence.tech/api/v1/payments/cinetpay/webhook"

    # Stripe
    STRIPE_SECRET_KEY: str = "sk_test_changeme"
    STRIPE_WEBHOOK_SECRET: str = "whsec_changeme"

    # Polygon / Blockchain
    POLYGON_RPC_URL: str = "https://polygon-rpc.com"
    CONTRACT_ADDRESS: str = "0x0000000000000000000000000000000000000000"
    WALLET_PRIVATE_KEY: str = "changeme-private-key"
    IPFS_GATEWAY: str = "https://ipfs.io/ipfs/"

    # Kubernetes / Cyber Range
    K8S_NAMESPACE_PREFIX: str = "cyber-range"
    K8S_IN_CLUSTER: bool = False
    KUBECONFIG: Optional[str] = None
    K8S_CPU_LIMIT: str = "2"
    K8S_MEMORY_LIMIT: str = "2Gi"
    K8S_SESSION_TIMEOUT_HOURS: int = 4

    # Guacamole
    GUACAMOLE_URL: str = "http://guacamole:8080/guacamole"
    GUACAMOLE_USER: str = "guacadmin"
    GUACAMOLE_PASS: str = "changeme"

    # PECB Partner
    PECB_API_BASE_URL: str = "https://partners.pecb.com/api"
    PECB_API_KEY: str = "changeme-pecb-key"

    # Cisco NetAcad Partner
    CISCO_NETACAD_API_URL: str = "https://api.netacad.com"
    CISCO_NETACAD_API_KEY: str = "changeme-cisco-key"

    # Frontend / CORS
    FRONTEND_URL: str = "https://academy.edefence.tech"
    ALLOWED_ORIGINS: List[str] = ["https://academy.edefence.tech", "http://localhost:3000"]

    @field_validator("ALLOWED_ORIGINS", mode="before")
    @classmethod
    def parse_allowed_origins(cls, v):
        if isinstance(v, str):
            try:
                return json.loads(v)
            except (json.JSONDecodeError, ValueError):
                return [origin.strip() for origin in v.split(",")]
        return v

    # Email (optional)
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    EMAILS_FROM: str = "noreply@edefence.tech"


settings = Settings()
