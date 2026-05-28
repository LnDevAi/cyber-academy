"""Blockchain badge minting service — Polygon ERC-721."""
import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import structlog
from web3 import Web3
from web3.middleware import geth_poa_middleware

from app.core.config import settings
from app.core.minio_client import minio_client

logger = structlog.get_logger(__name__)

# Standard ERC-721 ABI with mintBadge function for E-DEFENCE badges
ERC721_ABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "to", "type": "address"},
            {"internalType": "string", "name": "metadataURI", "type": "string"}
        ],
        "name": "mintBadge",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "tokenId", "type": "uint256"}
        ],
        "name": "ownerOf",
        "outputs": [
            {"internalType": "address", "name": "", "type": "address"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "tokenId", "type": "uint256"}
        ],
        "name": "tokenURI",
        "outputs": [
            {"internalType": "string", "name": "", "type": "string"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "owner", "type": "address"}
        ],
        "name": "balanceOf",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "tokenId", "type": "uint256"},
            {"internalType": "bool", "name": "valid", "type": "bool"}
        ],
        "name": "setValidity",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "tokenId", "type": "uint256"}
        ],
        "name": "isValid",
        "outputs": [
            {"internalType": "bool", "name": "", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "internalType": "address", "name": "from", "type": "address"},
            {"indexed": True, "internalType": "address", "name": "to", "type": "address"},
            {"indexed": True, "internalType": "uint256", "name": "tokenId", "type": "uint256"}
        ],
        "name": "Transfer",
        "type": "event"
    },
    {
        "anonymous": False,
        "inputs": [
            {"indexed": True, "internalType": "uint256", "name": "tokenId", "type": "uint256"},
            {"indexed": True, "internalType": "address", "name": "recipient", "type": "address"},
            {"indexed": False, "internalType": "string", "name": "courseCode", "type": "string"}
        ],
        "name": "BadgeMinted",
        "type": "event"
    }
]

COURSE_BADGE_NAMES = {
    "CACP": "Certified Associate in Cybersecurity Practice",
    "CSA": "Certified Security Analyst",
    "CDPO_UEMOA": "Certified Data Protection Officer UEMOA",
    "ISO27001_LI": "ISO 27001 Lead Implementer",
    "CLEH_SAHEL": "Certified Lead Ethical Hacker SAHEL",
    "WASO": "Web Application Security Operator",
    "CCNA_CYBEROPS": "Cisco CCNA CyberOps",
    "NSE4": "Fortinet NSE 4 Network Security Professional",
    "CDFIR": "Certified Digital Forensics & Incident Response",
    "CMSP": "Certified Malware & Security Professional",
}


class BlockchainBadgeService:
    """
    Service de minting de badges blockchain sur Polygon (ERC-721).
    Utilise web3.py pour interagir avec le smart contract E-DEFENCE.
    """

    def __init__(self):
        self._w3: Optional[Web3] = None
        self._contract = None

    def _get_web3(self) -> Web3:
        """Initialize and return Web3 connection to Polygon."""
        if self._w3 is not None and self._w3.is_connected():
            return self._w3

        self._w3 = Web3(Web3.HTTPProvider(settings.POLYGON_RPC_URL))
        # Polygon uses PoA consensus — add middleware
        self._w3.middleware_onion.inject(geth_poa_middleware, layer=0)

        if not self._w3.is_connected():
            raise ConnectionError("Impossible de se connecter au réseau Polygon")

        return self._w3

    def _get_contract(self):
        """Get or initialize the ERC-721 contract instance."""
        if self._contract is not None:
            return self._contract

        w3 = self._get_web3()
        checksum_address = Web3.to_checksum_address(settings.CONTRACT_ADDRESS)
        self._contract = w3.eth.contract(
            address=checksum_address,
            abi=ERC721_ABI,
        )
        return self._contract

    def generate_metadata(
        self,
        user: Any,
        course: Any,
        badge_id: str,
        metadata_url: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Generate Open Badges 3.0 compliant metadata JSON.

        Args:
            user: User model instance
            course: Course model instance
            badge_id: UUID of the badge
            metadata_url: URL where this metadata will be stored

        Returns:
            Open Badges 3.0 JSON dict
        """
        issued_on = datetime.now(timezone.utc).isoformat()
        badge_name = COURSE_BADGE_NAMES.get(course.code, course.title)

        metadata = {
            "@context": [
                "https://www.w3.org/2018/credentials/v1",
                "https://purl.imsglobal.org/spec/ob/v3p0/context-3.0.3.json"
            ],
            "type": ["VerifiableCredential", "OpenBadgeCredential"],
            "id": metadata_url or f"https://academy.edefence.tech/api/v1/badges/{badge_id}/metadata",
            "name": badge_name,
            "description": (
                f"Ce badge certifie que {user.full_name} a réussi avec succès "
                f"la formation {course.title} ({course.code}) proposée par "
                f"Cyber Academy E-DEFENCE. "
                f"Formation de {course.hours_total} heures, niveau {course.level.value}."
            ),
            "image": {
                "id": f"https://academy.edefence.tech/static/badges/{course.code.lower()}.png",
                "type": "Image",
                "caption": f"Badge {badge_name}"
            },
            "criteria": {
                "narrative": (
                    f"Pour obtenir ce badge, l'apprenant doit avoir: "
                    f"(1) complété l'intégralité des modules du programme {course.code} "
                    f"({course.hours_total}h), (2) réussi tous les labs pratiques Cyber Range, "
                    f"(3) obtenu une note de passage aux évaluations. "
                    f"Partenaire: {course.partner.value}."
                )
            },
            "issuer": {
                "id": "https://academy.edefence.tech",
                "type": "Profile",
                "name": "Cyber Academy E-DEFENCE",
                "url": "https://academy.edefence.tech",
                "email": "certifications@edefence.tech",
                "description": (
                    "Cyber Academy E-DEFENCE est la plateforme de formation en cybersécurité "
                    "de référence pour l'espace UEMOA (Afrique de l'Ouest)."
                ),
                "image": "https://academy.edefence.tech/static/logo.png",
            },
            "issuedOn": issued_on,
            "validFrom": issued_on,
            "recipient": {
                "type": "email",
                "identity": user.email,
                "hashed": False,
            },
            "evidence": [
                {
                    "type": "Evidence",
                    "id": f"https://academy.edefence.tech/certificates/{badge_id}",
                    "name": f"Certificat de complétion — {course.code}",
                    "description": f"Preuve de completion de la formation {course.title}",
                    "genre": "Completion Certificate",
                    "audience": "Employeurs, recruteurs, partenaires UEMOA",
                }
            ],
            "blockchain": {
                "network": "Polygon",
                "contract_address": settings.CONTRACT_ADDRESS,
                "standard": "ERC-721",
                "rpc_url": "https://polygon-rpc.com",
                "badge_id": badge_id,
            },
            "course": {
                "code": course.code,
                "title": course.title,
                "hours": course.hours_total,
                "level": course.level.value,
                "partner": course.partner.value,
                "type": course.type.value,
            }
        }

        return metadata

    async def mint_badge(
        self,
        user: Any,
        course: Any,
        enrollment_id: str,
    ) -> "Badge":
        """
        Mint an ERC-721 badge on Polygon for a completed course.

        Args:
            user: User model instance (must have an Ethereum-compatible address or derive one)
            course: Course model instance
            enrollment_id: UUID of the completed enrollment

        Returns:
            Badge model dict (not yet persisted — caller must save to DB)
        """
        from app.models.badge import Badge as BadgeModel

        badge_id = str(uuid.uuid4())

        # Generate and store metadata in MinIO first
        metadata = self.generate_metadata(user, course, badge_id)
        metadata_url = minio_client.upload_badge_metadata(badge_id, metadata)

        # Update metadata with the actual URL
        metadata["id"] = metadata_url
        minio_client.upload_badge_metadata(badge_id, metadata)

        logger.info(
            "Minting badge blockchain",
            badge_id=badge_id,
            user_email=user.email,
            course_code=course.code,
        )

        try:
            w3 = self._get_web3()
            contract = self._get_contract()

            # Derive wallet address from private key
            private_key = settings.WALLET_PRIVATE_KEY
            if private_key.startswith("0x"):
                private_key = private_key[2:]

            wallet_account = w3.eth.account.from_key(private_key)
            wallet_address = wallet_account.address

            # Derive recipient address from user's wallet
            # For simplicity, we mint to the platform wallet first
            # In production, integrate with MetaMask connect on the frontend
            recipient_address = wallet_address  # TODO: use user.wallet_address when available

            # Get nonce
            nonce = w3.eth.get_transaction_count(wallet_address)

            # Build transaction
            txn = contract.functions.mintBadge(
                recipient_address,
                metadata_url,
            ).build_transaction({
                "from": wallet_address,
                "nonce": nonce,
                "gas": 300000,
                "gasPrice": w3.eth.gas_price,
                "chainId": 137,  # Polygon mainnet
            })

            # Sign and send transaction
            signed_txn = w3.eth.account.sign_transaction(txn, private_key)
            tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
            tx_hash_hex = tx_hash.hex()

            logger.info("Transaction blockchain envoyée", tx_hash=tx_hash_hex)

            # Wait for receipt (with timeout)
            receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=120)

            if receipt.status != 1:
                raise RuntimeError(f"Transaction blockchain échouée: {tx_hash_hex}")

            # Extract token_id from Transfer event logs
            token_id = None
            try:
                transfer_events = contract.events.Transfer().process_receipt(receipt)
                if transfer_events:
                    token_id = int(transfer_events[0]["args"]["tokenId"])
            except Exception as exc:
                logger.warning("Impossible d'extraire token_id des logs", error=str(exc))

            logger.info(
                "Badge minté avec succès",
                token_id=token_id,
                tx_hash=tx_hash_hex,
            )

            badge = BadgeModel(
                id=uuid.UUID(badge_id),
                user_id=user.id,
                enrollment_id=uuid.UUID(str(enrollment_id)),
                course_code=course.code,
                token_id=token_id,
                tx_hash=tx_hash_hex,
                metadata_uri=metadata_url,
                is_valid=True,
                issued_at=datetime.now(timezone.utc),
                blockchain_verified_at=datetime.now(timezone.utc),
            )
            return badge

        except Exception as exc:
            logger.error(
                "Erreur minting badge blockchain",
                badge_id=badge_id,
                error=str(exc),
                course_code=course.code,
            )
            # Return badge without blockchain data — can retry later
            from app.models.badge import Badge as BadgeModel
            badge = BadgeModel(
                id=uuid.UUID(badge_id),
                user_id=user.id,
                enrollment_id=uuid.UUID(str(enrollment_id)),
                course_code=course.code,
                token_id=None,
                tx_hash=None,
                metadata_uri=metadata_url,
                is_valid=False,
                issued_at=datetime.now(timezone.utc),
            )
            return badge

    async def verify_badge(self, token_id: int) -> Dict[str, Any]:
        """
        Verify a badge on the Polygon blockchain.

        Args:
            token_id: ERC-721 token ID

        Returns:
            Dict with is_valid, owner_address, metadata_uri
        """
        try:
            w3 = self._get_web3()
            contract = self._get_contract()

            owner = contract.functions.ownerOf(token_id).call()
            metadata_uri = contract.functions.tokenURI(token_id).call()

            # Check validity if contract supports it
            is_valid = True
            try:
                is_valid = contract.functions.isValid(token_id).call()
            except Exception:
                pass  # Contract might not implement isValid

            return {
                "token_id": token_id,
                "is_valid": is_valid,
                "owner_address": owner,
                "metadata_uri": metadata_uri,
                "verified_at": datetime.now(timezone.utc),
                "blockchain_network": "Polygon",
                "contract_address": settings.CONTRACT_ADDRESS,
            }

        except Exception as exc:
            logger.error("Erreur vérification badge blockchain", token_id=token_id, error=str(exc))
            return {
                "token_id": token_id,
                "is_valid": False,
                "owner_address": None,
                "metadata_uri": None,
                "verified_at": datetime.now(timezone.utc),
                "error": str(exc),
            }


# Singleton
badge_service = BlockchainBadgeService()
