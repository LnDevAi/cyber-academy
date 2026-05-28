"""MinIO client singleton for object storage."""
import json
import uuid
from io import BytesIO
from typing import Optional

from minio import Minio
from minio.error import S3Error

from app.core.config import settings

import structlog

logger = structlog.get_logger(__name__)


class MinIOClient:
    """Singleton MinIO client wrapper."""

    _instance: Optional["MinIOClient"] = None
    _client: Optional[Minio] = None

    def __new__(cls) -> "MinIOClient":
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self):
        if self._client is None:
            self._client = Minio(
                endpoint=settings.MINIO_ENDPOINT,
                access_key=settings.MINIO_ACCESS_KEY,
                secret_key=settings.MINIO_SECRET_KEY,
                secure=settings.MINIO_SECURE,
            )
            self._ensure_bucket()

    def _ensure_bucket(self) -> None:
        """Create the default bucket if it does not exist."""
        try:
            if not self._client.bucket_exists(settings.MINIO_BUCKET):
                self._client.make_bucket(settings.MINIO_BUCKET)
                logger.info("MinIO bucket créé", bucket=settings.MINIO_BUCKET)
        except S3Error as exc:
            logger.error("Erreur MinIO lors de la création du bucket", error=str(exc))

    @property
    def client(self) -> Minio:
        return self._client

    def upload_file(
        self,
        object_name: str,
        data: bytes,
        content_type: str = "application/octet-stream",
        bucket: Optional[str] = None,
    ) -> str:
        """Upload bytes to MinIO and return the object URL."""
        bucket = bucket or settings.MINIO_BUCKET
        data_stream = BytesIO(data)
        self._client.put_object(
            bucket_name=bucket,
            object_name=object_name,
            data=data_stream,
            length=len(data),
            content_type=content_type,
        )
        return self.get_url(object_name, bucket)

    def upload_json(self, object_name: str, data: dict, bucket: Optional[str] = None) -> str:
        """Upload a JSON dict as a file and return its URL."""
        payload = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        return self.upload_file(object_name, payload, "application/json", bucket)

    def download_file(self, object_name: str, bucket: Optional[str] = None) -> bytes:
        """Download an object from MinIO as bytes."""
        bucket = bucket or settings.MINIO_BUCKET
        response = self._client.get_object(bucket, object_name)
        try:
            return response.read()
        finally:
            response.close()
            response.release_conn()

    def get_presigned_url(
        self,
        object_name: str,
        expires_seconds: int = 3600,
        bucket: Optional[str] = None,
    ) -> str:
        """Generate a presigned URL for temporary access."""
        from datetime import timedelta

        bucket = bucket or settings.MINIO_BUCKET
        return self._client.presigned_get_object(
            bucket_name=bucket,
            object_name=object_name,
            expires=timedelta(seconds=expires_seconds),
        )

    def get_url(self, object_name: str, bucket: Optional[str] = None) -> str:
        """Return the public URL for an object."""
        bucket = bucket or settings.MINIO_BUCKET
        protocol = "https" if settings.MINIO_SECURE else "http"
        return f"{protocol}://{settings.MINIO_ENDPOINT}/{bucket}/{object_name}"

    def delete_file(self, object_name: str, bucket: Optional[str] = None) -> bool:
        """Delete an object from MinIO."""
        bucket = bucket or settings.MINIO_BUCKET
        try:
            self._client.remove_object(bucket, object_name)
            return True
        except S3Error:
            return False

    def upload_badge_metadata(self, badge_id: str, metadata: dict) -> str:
        """Upload badge Open Badges metadata JSON and return its URL."""
        object_name = f"badges/metadata/{badge_id}.json"
        return self.upload_json(object_name, metadata)

    def upload_badge_image(self, badge_id: str, image_data: bytes) -> str:
        """Upload badge PNG image and return its URL."""
        object_name = f"badges/images/{badge_id}.png"
        return self.upload_file(object_name, image_data, "image/png")


# Singleton instance
minio_client = MinIOClient()
