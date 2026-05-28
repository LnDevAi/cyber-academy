"""Kubernetes Cyber Range provisioning service — k3s namespace management."""
import json
import os
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import structlog
from kubernetes import client as k8s_client
from kubernetes import config as k8s_config
from kubernetes.client.rest import ApiException

from app.core.config import settings

logger = structlog.get_logger(__name__)


class K8sRangeService:
    """
    Service de provisionnement des namespaces Kubernetes pour le Cyber Range.
    Compatible avec k3s (k8s lightweight).
    """

    def __init__(self):
        self._initialized = False
        self._core_v1: Optional[k8s_client.CoreV1Api] = None
        self._apps_v1: Optional[k8s_client.AppsV1Api] = None
        self._networking_v1: Optional[k8s_client.NetworkingV1Api] = None

    def _initialize(self) -> None:
        """Lazy-initialize Kubernetes client."""
        if self._initialized:
            return

        try:
            if settings.K8S_IN_CLUSTER:
                k8s_config.load_incluster_config()
                logger.info("Kubernetes: configuration in-cluster chargée")
            elif settings.KUBECONFIG:
                k8s_config.load_kube_config(config_file=settings.KUBECONFIG)
                logger.info("Kubernetes: KUBECONFIG chargé", path=settings.KUBECONFIG)
            else:
                k8s_config.load_kube_config()
                logger.info("Kubernetes: config par défaut (~/.kube/config)")

            self._core_v1 = k8s_client.CoreV1Api()
            self._apps_v1 = k8s_client.AppsV1Api()
            self._networking_v1 = k8s_client.NetworkingV1Api()
            self._initialized = True

        except Exception as exc:
            logger.error("Erreur initialisation Kubernetes", error=str(exc))
            raise RuntimeError(f"Kubernetes non disponible: {str(exc)}")

    @property
    def core_v1(self) -> k8s_client.CoreV1Api:
        self._initialize()
        return self._core_v1

    @property
    def apps_v1(self) -> k8s_client.AppsV1Api:
        self._initialize()
        return self._apps_v1

    def _build_namespace_name(self, user_id: str, lab_id: str) -> str:
        """Generate a unique k8s namespace name."""
        short_id = str(user_id).replace("-", "")[:8]
        short_lab = lab_id.replace("_", "-").lower()[:20]
        return f"{settings.K8S_NAMESPACE_PREFIX}-{short_lab}-{short_id}"

    async def provision_namespace(self, user_id: str, lab_id: str) -> str:
        """
        Create a dedicated k8s namespace for a user's lab session.

        Args:
            user_id: User UUID string
            lab_id: Lab identifier slug

        Returns:
            namespace_name: Created Kubernetes namespace name
        """
        namespace_name = self._build_namespace_name(user_id, lab_id)

        logger.info(
            "Provisionnement namespace Cyber Range",
            namespace=namespace_name,
            user_id=user_id,
            lab_id=lab_id,
        )

        # Namespace spec with resource quotas
        namespace_body = k8s_client.V1Namespace(
            metadata=k8s_client.V1ObjectMeta(
                name=namespace_name,
                labels={
                    "app": "cyber-range",
                    "user-id": str(user_id)[:63],
                    "lab-id": lab_id[:63],
                    "managed-by": "edefence-academy",
                },
                annotations={
                    "edefence.tech/user-id": str(user_id),
                    "edefence.tech/lab-id": lab_id,
                    "edefence.tech/created-at": datetime.now(timezone.utc).isoformat(),
                },
            )
        )

        try:
            self.core_v1.create_namespace(namespace_body)
            logger.info("Namespace créé", namespace=namespace_name)
        except ApiException as exc:
            if exc.status == 409:
                logger.warning("Namespace déjà existant", namespace=namespace_name)
            else:
                raise

        # Create ResourceQuota to limit resources
        quota_body = k8s_client.V1ResourceQuota(
            metadata=k8s_client.V1ObjectMeta(
                name="range-quota",
                namespace=namespace_name,
            ),
            spec=k8s_client.V1ResourceQuotaSpec(
                hard={
                    "cpu": settings.K8S_CPU_LIMIT,
                    "memory": settings.K8S_MEMORY_LIMIT,
                    "pods": "10",
                    "services": "5",
                }
            ),
        )

        try:
            self.core_v1.create_namespaced_resource_quota(namespace_name, quota_body)
        except ApiException as exc:
            if exc.status != 409:
                logger.warning("Erreur création ResourceQuota", error=str(exc))

        # Create NetworkPolicy to isolate namespace
        await self._create_network_policy(namespace_name)

        return namespace_name

    async def _create_network_policy(self, namespace: str) -> None:
        """Create a NetworkPolicy to isolate the Cyber Range namespace."""
        # Allow ingress only from Guacamole gateway
        policy_body = {
            "apiVersion": "networking.k8s.io/v1",
            "kind": "NetworkPolicy",
            "metadata": {
                "name": "range-isolation",
                "namespace": namespace,
            },
            "spec": {
                "podSelector": {},
                "policyTypes": ["Ingress", "Egress"],
                "ingress": [
                    {
                        "from": [
                            {"namespaceSelector": {"matchLabels": {"app": "guacamole"}}}
                        ]
                    }
                ],
                "egress": [
                    {"to": [], "ports": [{"port": 53, "protocol": "UDP"}]},  # DNS
                    {"to": [{"ipBlock": {"cidr": "10.0.0.0/8"}}]},  # Internal range
                ],
            },
        }

        try:
            self._networking_v1.create_namespaced_network_policy(
                namespace,
                k8s_client.V1NetworkPolicy(**policy_body),
            )
        except Exception as exc:
            logger.warning("NetworkPolicy non créée (non critique)", error=str(exc))

    async def deploy_lab(self, namespace: str, lab: Any) -> Dict[str, Any]:
        """
        Deploy lab workloads into the namespace.

        Args:
            namespace: Kubernetes namespace name
            lab: Lab model instance with k8s_manifest

        Returns:
            Dict with deployment status
        """
        logger.info("Déploiement lab Cyber Range", namespace=namespace, lab_id=lab.id)

        manifest = lab.k8s_manifest or self._get_default_manifest(lab)

        # Create Deployment
        deployment_spec = manifest.get("deployment", {})
        deployment_name = f"lab-{lab.id}"

        deployment_body = k8s_client.V1Deployment(
            metadata=k8s_client.V1ObjectMeta(
                name=deployment_name,
                namespace=namespace,
                labels={"app": "lab", "lab-id": lab.id},
            ),
            spec=k8s_client.V1DeploymentSpec(
                replicas=1,
                selector=k8s_client.V1LabelSelector(
                    match_labels={"app": "lab", "lab-id": lab.id}
                ),
                template=k8s_client.V1PodTemplateSpec(
                    metadata=k8s_client.V1ObjectMeta(
                        labels={"app": "lab", "lab-id": lab.id}
                    ),
                    spec=k8s_client.V1PodSpec(
                        containers=[
                            k8s_client.V1Container(
                                name="lab-container",
                                image=lab.docker_image,
                                resources=k8s_client.V1ResourceRequirements(
                                    requests={"cpu": "500m", "memory": "512Mi"},
                                    limits={"cpu": "1", "memory": "1Gi"},
                                ),
                                ports=[k8s_client.V1ContainerPort(container_port=22)],  # SSH
                            )
                        ],
                        restart_policy="Always",
                    ),
                ),
            ),
        )

        try:
            self.apps_v1.create_namespaced_deployment(namespace, deployment_body)
            logger.info("Deployment créé", deployment=deployment_name)
        except ApiException as exc:
            if exc.status == 409:
                logger.info("Deployment déjà existant", deployment=deployment_name)
            else:
                raise

        # Create Service for SSH/RDP access
        service_body = k8s_client.V1Service(
            metadata=k8s_client.V1ObjectMeta(
                name=f"svc-{lab.id}",
                namespace=namespace,
            ),
            spec=k8s_client.V1ServiceSpec(
                selector={"app": "lab", "lab-id": lab.id},
                ports=[
                    k8s_client.V1ServicePort(
                        port=22,
                        target_port=22,
                        name="ssh",
                    )
                ],
                type="ClusterIP",
            ),
        )

        try:
            self.core_v1.create_namespaced_service(namespace, service_body)
        except ApiException as exc:
            if exc.status != 409:
                logger.warning("Erreur création Service", error=str(exc))

        return {
            "namespace": namespace,
            "deployment": deployment_name,
            "status": "deployed",
            "lab_id": lab.id,
        }

    async def get_guacamole_connection(
        self, namespace: str, lab: Any
    ) -> Dict[str, Any]:
        """
        Register a Guacamole connection for the lab and return the connection URL.

        Args:
            namespace: Kubernetes namespace
            lab: Lab model instance

        Returns:
            Dict with connection_id and connection_url
        """
        import httpx

        # Get the service ClusterIP for the lab
        service_name = f"svc-{lab.id}"
        try:
            service = self.core_v1.read_namespaced_service(service_name, namespace)
            cluster_ip = service.spec.cluster_ip
        except Exception:
            cluster_ip = f"{namespace}.lab.svc.cluster.local"

        # Register connection in Guacamole REST API
        connection_id = str(uuid.uuid4())[:8]
        auth_token = None

        try:
            async with httpx.AsyncClient(timeout=10.0) as http:
                # Get Guacamole auth token
                auth_response = await http.post(
                    f"{settings.GUACAMOLE_URL}/api/tokens",
                    data={
                        "username": settings.GUACAMOLE_USER,
                        "password": settings.GUACAMOLE_PASS,
                    },
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                )
                if auth_response.status_code == 200:
                    auth_token = auth_response.json().get("authToken")

            if auth_token:
                # Create SSH connection in Guacamole
                connection_body = {
                    "name": f"Lab {lab.id} — {namespace}",
                    "protocol": "ssh",
                    "parameters": {
                        "hostname": cluster_ip,
                        "port": "22",
                        "username": "student",
                        "password": "cyberrange",
                    },
                    "attributes": {
                        "max-connections": "1",
                        "max-connections-per-user": "1",
                    },
                }
                async with httpx.AsyncClient(timeout=10.0) as http:
                    conn_response = await http.post(
                        f"{settings.GUACAMOLE_URL}/api/session/data/mysql/connections",
                        json=connection_body,
                        headers={
                            "Guacamole-Token": auth_token,
                            "Content-Type": "application/json",
                        },
                    )
                    if conn_response.status_code in (200, 201):
                        connection_id = str(conn_response.json().get("identifier", connection_id))

        except Exception as exc:
            logger.warning("Guacamole non disponible, URL simulée", error=str(exc))

        connection_url = f"{settings.GUACAMOLE_URL}/#/client/{connection_id}"

        return {
            "connection_id": connection_id,
            "connection_url": connection_url,
            "cluster_ip": cluster_ip,
            "namespace": namespace,
        }

    async def terminate_namespace(self, namespace: str) -> bool:
        """
        Terminate a Cyber Range session by deleting the namespace.

        Args:
            namespace: Kubernetes namespace to delete

        Returns:
            bool: True if successful
        """
        logger.info("Terminaison namespace Cyber Range", namespace=namespace)

        try:
            self.core_v1.delete_namespace(
                namespace,
                body=k8s_client.V1DeleteOptions(
                    propagation_policy="Foreground",
                    grace_period_seconds=10,
                ),
            )
            logger.info("Namespace supprimé", namespace=namespace)
            return True
        except ApiException as exc:
            if exc.status == 404:
                logger.warning("Namespace déjà supprimé", namespace=namespace)
                return True
            logger.error("Erreur suppression namespace", namespace=namespace, error=str(exc))
            return False

    async def get_resource_usage(self, namespace: str) -> Dict[str, Any]:
        """
        Get resource usage for a namespace.

        Returns:
            Dict with cpu_cores, memory_mb, uptime_minutes, pod_count, status
        """
        try:
            pods = self.core_v1.list_namespaced_pod(namespace)

            running_pods = [
                p for p in pods.items
                if p.status and p.status.phase == "Running"
            ]

            # Calculate uptime from creation timestamp
            uptime_minutes = 0
            if pods.items and pods.items[0].metadata.creation_timestamp:
                created = pods.items[0].metadata.creation_timestamp
                if created.tzinfo is None:
                    created = created.replace(tzinfo=timezone.utc)
                uptime_minutes = int(
                    (datetime.now(timezone.utc) - created).total_seconds() / 60
                )

            return {
                "namespace": namespace,
                "cpu_cores": len(running_pods) * 0.5,  # Estimate
                "memory_mb": len(running_pods) * 512,  # Estimate
                "uptime_minutes": uptime_minutes,
                "pod_count": len(pods.items),
                "running_pods": len(running_pods),
                "status": "active" if running_pods else "idle",
            }

        except Exception as exc:
            logger.error("Erreur lecture ressources namespace", namespace=namespace, error=str(exc))
            return {
                "namespace": namespace,
                "cpu_cores": 0,
                "memory_mb": 0,
                "uptime_minutes": 0,
                "pod_count": 0,
                "status": "error",
            }

    def _get_default_manifest(self, lab: Any) -> Dict:
        """Return a default k8s manifest for labs without custom manifests."""
        return {
            "deployment": {
                "replicas": 1,
                "image": lab.docker_image,
                "resources": {
                    "requests": {"cpu": "500m", "memory": "512Mi"},
                    "limits": {"cpu": "1", "memory": "1Gi"},
                },
            }
        }

    async def list_active_namespaces(self) -> list:
        """List all active Cyber Range namespaces."""
        try:
            namespaces = self.core_v1.list_namespace(
                label_selector=f"managed-by=edefence-academy"
            )
            return [
                {
                    "name": ns.metadata.name,
                    "created_at": ns.metadata.creation_timestamp,
                    "labels": dict(ns.metadata.labels or {}),
                }
                for ns in namespaces.items
            ]
        except Exception as exc:
            logger.error("Erreur liste namespaces", error=str(exc))
            return []


# Singleton
k8s_service = K8sRangeService()
