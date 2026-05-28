"""Celery application configuration."""
from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

# Create Celery app
celery_app = Celery(
    "cyber_academy",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=[
        "app.tasks.payment_tasks",
        "app.tasks.badge_tasks",
        "app.tasks.range_tasks",
    ],
)

# Celery configuration
celery_app.conf.update(
    # Serialization
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    # Timezone
    timezone="Africa/Abidjan",
    enable_utc=True,
    # Task behavior
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
    # Result expiry
    result_expires=86400,  # 24 hours
    # Retry defaults
    task_max_retries=3,
    task_default_retry_delay=60,  # 60 seconds
    # Rate limiting
    task_annotations={
        "app.tasks.badge_tasks.mint_completion_badge": {"rate_limit": "10/m"},
        "app.tasks.payment_tasks.confirm_payment_and_provision": {"rate_limit": "30/m"},
    },
    # Beat schedule — periodic tasks
    beat_schedule={
        "check-pending-payments": {
            "task": "app.tasks.payment_tasks.check_pending_payments",
            "schedule": crontab(minute="*/15"),  # Every 15 minutes
            "options": {"queue": "periodic"},
        },
        "auto-terminate-idle-range-sessions": {
            "task": "app.tasks.range_tasks.auto_terminate_idle_sessions",
            "schedule": crontab(minute="*/30"),  # Every 30 minutes
            "options": {"queue": "periodic"},
        },
        "check-installment-due-payments": {
            "task": "app.tasks.payment_tasks.check_installment_due_payments",
            "schedule": crontab(hour="8", minute="0"),  # Daily at 08:00 WAT
            "options": {"queue": "periodic"},
        },
    },
    # Queues
    task_queues={
        "default": {"exchange": "default", "routing_key": "default"},
        "payments": {"exchange": "payments", "routing_key": "payments"},
        "blockchain": {"exchange": "blockchain", "routing_key": "blockchain"},
        "range": {"exchange": "range", "routing_key": "range"},
        "periodic": {"exchange": "periodic", "routing_key": "periodic"},
    },
    task_default_queue="default",
    task_routes={
        "app.tasks.payment_tasks.*": {"queue": "payments"},
        "app.tasks.badge_tasks.*": {"queue": "blockchain"},
        "app.tasks.range_tasks.*": {"queue": "range"},
    },
)


if __name__ == "__main__":
    celery_app.start()
