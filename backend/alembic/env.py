"""Alembic environment configuration for async SQLAlchemy."""
import asyncio
from logging.config import fileConfig

from sqlalchemy import pool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# Import all models so Alembic can detect them
from app.models.user import User  # noqa: F401
from app.models.company import Company  # noqa: F401
from app.models.course import Course  # noqa: F401
from app.models.enrollment import Enrollment  # noqa: F401
from app.models.payment import Payment  # noqa: F401
from app.models.badge import Badge  # noqa: F401
from app.models.cyber_range_session import CyberRangeSession  # noqa: F401
from app.models.lab import Lab  # noqa: F401
from app.models.mentor_session import MentorSession  # noqa: F401
from app.models.chat_message import ChatMessage  # noqa: F401
from app.core.database import Base
from app.core.config import settings

# this is the Alembic Config object
config = context.config

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Use the sync URL for Alembic migrations
target_metadata = Base.metadata

# Override sqlalchemy.url from settings
config.set_main_option("sqlalchemy.url", settings.DATABASE_SYNC_URL)


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_schemas=True,
        version_table_schema="cyber_academy",
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        include_schemas=True,
        version_table_schema="cyber_academy",
    )

    with context.begin_transaction():
        context.run_migrations()


async def run_async_migrations() -> None:
    """Run migrations in async mode."""
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

    await connectable.dispose()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    asyncio.run(run_async_migrations())


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
