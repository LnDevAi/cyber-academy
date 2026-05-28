"""Initial migration — create all Cyber Academy E-DEFENCE tables.

Revision ID: 001
Revises:
Create Date: 2026-05-28 00:00:00.000000
"""
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from alembic import op

# revision identifiers
revision: str = "001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create schema
    op.execute("CREATE SCHEMA IF NOT EXISTS cyber_academy")

    # ── ENUM types ─────────────────────────────────────────────────────────────
    op.execute(
        "CREATE TYPE cyber_academy.userrole AS ENUM ('STUDENT', 'MENTOR', 'ADMIN', 'B2B_ADMIN')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.companyplan AS ENUM ('STARTER', 'PRO', 'ENTERPRISE')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.coursetype AS ENUM ('ECERT', 'INTERNATIONAL')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.coursepartner AS ENUM ('EDEFENCE', 'PECB', 'CISCO', 'FORTINET', 'EC_COUNCIL', 'ISC2', 'COMPTIA')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.courselevel AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.enrollmentstatus AS ENUM ('PENDING_PAYMENT', 'ACTIVE', 'COMPLETED', 'EXPIRED', 'REFUNDED')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.paymentcurrency AS ENUM ('XOF', 'EUR', 'USD')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.paymentmethod AS ENUM ('ORANGE_MONEY', 'MOOV_MONEY', 'WAVE', 'CARD_STRIPE', 'BANK_TRANSFER')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.paymentstatus AS ENUM ('PENDING', 'CONFIRMED', 'FAILED', 'REFUNDED')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.cyberrangestatus AS ENUM ('PROVISIONING', 'ACTIVE', 'SUSPENDED', 'TERMINATED')"
    )
    op.execute(
        "CREATE TYPE cyber_academy.mentorsessionstatus AS ENUM ('SCHEDULED', 'COMPLETED', 'CANCELLED')"
    )

    # ── companies table ─────────────────────────────────────────────────────────
    op.create_table(
        "companies",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("contact_email", sa.String(255), nullable=False, unique=True),
        sa.Column("contact_phone", sa.String(30), nullable=True),
        sa.Column("country", sa.String(3), nullable=False, server_default="BF"),
        sa.Column(
            "plan",
            sa.Enum("STARTER", "PRO", "ENTERPRISE", name="companyplan", schema="cyber_academy"),
            nullable=False,
            server_default="STARTER",
        ),
        sa.Column("seats_total", sa.Integer(), nullable=False, server_default="5"),
        sa.Column("seats_used", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )

    # ── users table ─────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("full_name", sa.String(255), nullable=False),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("country", sa.String(3), nullable=False, server_default="BF"),
        sa.Column(
            "role",
            sa.Enum("STUDENT", "MENTOR", "ADMIN", "B2B_ADMIN", name="userrole", schema="cyber_academy"),
            nullable=False,
            server_default="STUDENT",
        ),
        sa.Column("totp_secret", sa.String(64), nullable=True),
        sa.Column("is_2fa_enabled", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column(
            "company_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.companies.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("moodle_user_id", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        schema="cyber_academy",
    )
    op.create_index("ix_users_email", "users", ["email"], schema="cyber_academy")
    op.create_index("ix_users_company_id", "users", ["company_id"], schema="cyber_academy")

    # ── courses table ────────────────────────────────────────────────────────────
    op.create_table(
        "courses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column("code", sa.String(50), nullable=False, unique=True),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("short_description", sa.String(500), nullable=True),
        sa.Column(
            "type",
            sa.Enum("ECERT", "INTERNATIONAL", name="coursetype", schema="cyber_academy"),
            nullable=False,
        ),
        sa.Column(
            "partner",
            sa.Enum("EDEFENCE", "PECB", "CISCO", "FORTINET", "EC_COUNCIL", "ISC2", "COMPTIA",
                    name="coursepartner", schema="cyber_academy"),
            nullable=False,
        ),
        sa.Column(
            "level",
            sa.Enum("BEGINNER", "INTERMEDIATE", "ADVANCED", "EXPERT", name="courselevel", schema="cyber_academy"),
            nullable=False,
        ),
        sa.Column("hours_total", sa.Integer(), nullable=False),
        sa.Column("price_fcfa", sa.Integer(), nullable=False),
        sa.Column("price_eur", sa.Numeric(10, 2), nullable=True),
        sa.Column("prerequisites", sa.Text(), nullable=True),
        sa.Column("objectives", sa.Text(), nullable=True),
        sa.Column("target_audience", sa.Text(), nullable=True),
        sa.Column("moodle_course_id", sa.Integer(), nullable=True),
        sa.Column("thumbnail_url", sa.String(1000), nullable=True),
        sa.Column("syllabus_url", sa.String(1000), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_courses_code", "courses", ["code"], schema="cyber_academy")

    # ── labs table ───────────────────────────────────────────────────────────────
    op.create_table(
        "labs",
        sa.Column("id", sa.String(100), primary_key=True, nullable=False),
        sa.Column("course_code", sa.String(50), nullable=False),
        sa.Column("title", sa.String(500), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("difficulty", sa.Integer(), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False, server_default="60"),
        sa.Column("docker_image", sa.String(500), nullable=False),
        sa.Column("k8s_manifest", postgresql.JSONB(), nullable=True),
        sa.Column("objectives", postgresql.JSONB(), nullable=True),
        sa.Column("auto_grading_script", sa.Text(), nullable=True),
        sa.Column("order_in_course", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_labs_course_code", "labs", ["course_code"], schema="cyber_academy")

    # ── enrollments table ────────────────────────────────────────────────────────
    op.create_table(
        "enrollments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "course_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.courses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.Enum("PENDING_PAYMENT", "ACTIVE", "COMPLETED", "EXPIRED", "REFUNDED",
                    name="enrollmentstatus", schema="cyber_academy"),
            nullable=False,
            server_default="PENDING_PAYMENT",
        ),
        sa.Column("progress_pct", sa.Float(), nullable=False, server_default="0.0"),
        sa.Column("moodle_enrollment_id", sa.Integer(), nullable=True),
        sa.Column("moodle_user_id", sa.Integer(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_enrollments_user_id", "enrollments", ["user_id"], schema="cyber_academy")
    op.create_index("ix_enrollments_course_id", "enrollments", ["course_id"], schema="cyber_academy")

    # ── payments table ───────────────────────────────────────────────────────────
    op.create_table(
        "payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "enrollment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.enrollments.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("amount_fcfa", sa.Integer(), nullable=False),
        sa.Column(
            "currency",
            sa.Enum("XOF", "EUR", "USD", name="paymentcurrency", schema="cyber_academy"),
            nullable=False,
            server_default="XOF",
        ),
        sa.Column(
            "method",
            sa.Enum("ORANGE_MONEY", "MOOV_MONEY", "WAVE", "CARD_STRIPE", "BANK_TRANSFER",
                    name="paymentmethod", schema="cyber_academy"),
            nullable=False,
        ),
        sa.Column("provider_ref", sa.String(255), nullable=True),
        sa.Column(
            "status",
            sa.Enum("PENDING", "CONFIRMED", "FAILED", "REFUNDED",
                    name="paymentstatus", schema="cyber_academy"),
            nullable=False,
            server_default="PENDING",
        ),
        sa.Column("installment_number", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("installment_total", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("due_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("webhook_payload", postgresql.JSONB(), nullable=True),
        sa.Column("payment_url", sa.String(2000), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_payments_user_id", "payments", ["user_id"], schema="cyber_academy")
    op.create_index("ix_payments_enrollment_id", "payments", ["enrollment_id"], schema="cyber_academy")
    op.create_index("ix_payments_provider_ref", "payments", ["provider_ref"], schema="cyber_academy")

    # ── badges table ─────────────────────────────────────────────────────────────
    op.create_table(
        "badges",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "enrollment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.enrollments.id", ondelete="CASCADE"),
            nullable=False,
            unique=True,
        ),
        sa.Column("course_code", sa.String(50), nullable=False),
        sa.Column("token_id", sa.Integer(), nullable=True),
        sa.Column("tx_hash", sa.String(100), nullable=True, unique=True),
        sa.Column("metadata_uri", sa.String(2000), nullable=True),
        sa.Column("is_valid", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("blockchain_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("issued_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_badges_user_id", "badges", ["user_id"], schema="cyber_academy")
    op.create_index("ix_badges_enrollment_id", "badges", ["enrollment_id"], schema="cyber_academy")
    op.create_index("ix_badges_course_code", "badges", ["course_code"], schema="cyber_academy")

    # ── cyber_range_sessions table ────────────────────────────────────────────────
    op.create_table(
        "cyber_range_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("lab_id", sa.String(100), nullable=False),
        sa.Column(
            "enrollment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.enrollments.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("k8s_namespace", sa.String(255), nullable=True, unique=True),
        sa.Column("guacamole_connection_id", sa.String(255), nullable=True),
        sa.Column("guacamole_url", sa.String(2000), nullable=True),
        sa.Column(
            "status",
            sa.Enum("PROVISIONING", "ACTIVE", "SUSPENDED", "TERMINATED",
                    name="cyberrangestatus", schema="cyber_academy"),
            nullable=False,
            server_default="PROVISIONING",
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ended_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("duration_minutes", sa.Integer(), nullable=True),
        sa.Column("cpu_used", sa.Float(), nullable=True),
        sa.Column("memory_used_mb", sa.Float(), nullable=True),
        sa.Column("score", sa.Float(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_cyber_range_sessions_user_id", "cyber_range_sessions", ["user_id"], schema="cyber_academy")
    op.create_index("ix_cyber_range_sessions_lab_id", "cyber_range_sessions", ["lab_id"], schema="cyber_academy")
    op.create_index("ix_cyber_range_sessions_enrollment_id", "cyber_range_sessions", ["enrollment_id"], schema="cyber_academy")

    # ── mentor_sessions table ────────────────────────────────────────────────────
    op.create_table(
        "mentor_sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "mentor_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "student_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "enrollment_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.enrollments.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("duration_minutes", sa.Integer(), nullable=False, server_default="60"),
        sa.Column(
            "status",
            sa.Enum("SCHEDULED", "COMPLETED", "CANCELLED",
                    name="mentorsessionstatus", schema="cyber_academy"),
            nullable=False,
            server_default="SCHEDULED",
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("zoom_link", sa.String(1000), nullable=True),
        sa.Column("zoom_meeting_id", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_mentor_sessions_mentor_id", "mentor_sessions", ["mentor_id"], schema="cyber_academy")
    op.create_index("ix_mentor_sessions_student_id", "mentor_sessions", ["student_id"], schema="cyber_academy")

    # ── chat_messages table ──────────────────────────────────────────────────────
    op.create_table(
        "chat_messages",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("cyber_academy.users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("session_id", sa.String(100), nullable=False),
        sa.Column("role", sa.String(20), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("enrollment_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("lab_id", sa.String(100), nullable=True),
        sa.Column("course_code", sa.String(50), nullable=True),
        sa.Column("input_tokens", sa.Integer(), nullable=True),
        sa.Column("output_tokens", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        schema="cyber_academy",
    )
    op.create_index("ix_chat_messages_user_id", "chat_messages", ["user_id"], schema="cyber_academy")
    op.create_index("ix_chat_messages_session_id", "chat_messages", ["session_id"], schema="cyber_academy")

    # ── Alembic version table in cyber_academy schema ──────────────────────────
    op.execute("CREATE TABLE IF NOT EXISTS cyber_academy.alembic_version (version_num VARCHAR(32) NOT NULL)")


def downgrade() -> None:
    op.execute("DROP SCHEMA cyber_academy CASCADE")
