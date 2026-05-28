"""Badge schemas."""
import uuid
from datetime import datetime
from typing import Any, Dict, Optional

from pydantic import BaseModel


class BadgeResponse(BaseModel):
    model_config = {"from_attributes": True}

    id: uuid.UUID
    user_id: uuid.UUID
    enrollment_id: uuid.UUID
    course_code: str
    token_id: Optional[int]
    tx_hash: Optional[str]
    metadata_uri: Optional[str]
    is_valid: bool
    blockchain_verified_at: Optional[datetime]
    issued_at: datetime
    created_at: datetime


class BadgeMetadataResponse(BaseModel):
    """Open Badges 3.0 format."""
    context: str
    type: str
    id: str
    name: str
    description: str
    image: str
    criteria: Dict[str, Any]
    issuer: Dict[str, Any]
    issuedOn: str
    recipient: Dict[str, Any]
    evidence: Optional[Dict[str, Any]]
    blockchain: Dict[str, Any]


class BadgeVerificationResponse(BaseModel):
    token_id: int
    is_valid: bool
    owner_address: Optional[str]
    metadata_uri: Optional[str]
    verified_at: datetime
    blockchain_network: str = "Polygon"
