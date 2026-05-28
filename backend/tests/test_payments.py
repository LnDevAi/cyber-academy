"""Tests for payment endpoints — CinetPay and Stripe."""
import json
import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from httpx import AsyncClient

from app.models.enrollment import Enrollment, EnrollmentStatus
from app.models.payment import Payment, PaymentStatus
from app.models.user import User


@pytest.mark.asyncio
async def test_list_payments_student(client: AsyncClient, test_student: User, student_token: str, db):
    """Test that a student can list only their own payments."""
    # Create a payment
    from app.models.course import Course, CourseLevel, CoursePartner, CourseType
    course = Course(
        id=uuid.uuid4(),
        code="CACP_P",
        title="Test Course",
        description="...",
        type=CourseType.ECERT,
        partner=CoursePartner.EDEFENCE,
        level=CourseLevel.BEGINNER,
        hours_total=40,
        price_fcfa=75000,
    )
    db.add(course)
    await db.flush()

    enrollment = Enrollment(
        id=uuid.uuid4(),
        user_id=test_student.id,
        course_id=course.id,
        status=EnrollmentStatus.PENDING_PAYMENT,
    )
    db.add(enrollment)
    await db.flush()

    payment = Payment(
        id=uuid.uuid4(),
        user_id=test_student.id,
        enrollment_id=enrollment.id,
        amount_fcfa=75000,
        method="ORANGE_MONEY",
        currency="XOF",
        status=PaymentStatus.PENDING,
        installment_number=1,
        installment_total=1,
    )
    db.add(payment)
    await db.flush()

    response = await client.get(
        "/api/v1/payments",
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 200
    payments = response.json()
    assert isinstance(payments, list)
    # Student only sees their own payments
    for p in payments:
        assert p["user_id"] == str(test_student.id)


@pytest.mark.asyncio
async def test_initiate_cinetpay_payment(
    client: AsyncClient,
    test_student: User,
    student_token: str,
    test_enrollment: Enrollment,
):
    """Test CinetPay payment initiation with mock."""
    with patch("app.api.v1.payments.cinetpay_service") as mock_cinetpay:
        mock_cinetpay.initiate_payment = AsyncMock(return_value={
            "payment_url": "https://pay.cinetpay.com/test123",
            "transaction_id": "CA-TEST123",
            "payment_token": "tok_test",
            "code": "201",
            "message": "Payment initiated",
        })

        response = await client.post(
            "/api/v1/payments/cinetpay/initiate",
            json={
                "enrollment_id": str(test_enrollment.id),
                "method": "ORANGE_MONEY",
                "installment": 1,
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "payment_url" in data
    assert data["installment_number"] == 1
    assert data["installment_total"] == 1
    assert data["amount_fcfa"] == 75000


@pytest.mark.asyncio
async def test_initiate_cinetpay_installment_3x(
    client: AsyncClient,
    test_student: User,
    student_token: str,
    test_enrollment: Enrollment,
):
    """Test CinetPay 3-installment payment creates 3 payment records."""
    with patch("app.api.v1.payments.cinetpay_service") as mock_cinetpay:
        mock_cinetpay.initiate_payment = AsyncMock(return_value={
            "payment_url": "https://pay.cinetpay.com/test456",
            "transaction_id": "CA-TEST456",
            "payment_token": "tok_test2",
            "code": "201",
            "message": "Payment initiated",
        })

        response = await client.post(
            "/api/v1/payments/cinetpay/initiate",
            json={
                "enrollment_id": str(test_enrollment.id),
                "method": "WAVE",
                "installment": 3,
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert data["installment_total"] == 3
    assert data["installment_number"] == 1
    # First installment is 75000 // 3 = 25000
    assert data["amount_fcfa"] == 25000


@pytest.mark.asyncio
async def test_initiate_cinetpay_invalid_method(
    client: AsyncClient,
    test_student: User,
    student_token: str,
    test_enrollment: Enrollment,
):
    """Test that non-Mobile Money methods are rejected by CinetPay endpoint."""
    response = await client.post(
        "/api/v1/payments/cinetpay/initiate",
        json={
            "enrollment_id": str(test_enrollment.id),
            "method": "CARD_STRIPE",  # Not valid for CinetPay
            "installment": 1,
        },
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 400
    assert "CinetPay" in response.json()["detail"]


@pytest.mark.asyncio
async def test_cinetpay_webhook_confirmed(client: AsyncClient, test_enrollment: Enrollment, db):
    """Test CinetPay webhook confirms a payment."""
    # Create a pending payment
    transaction_id = f"CA-WEBHOOK-{uuid.uuid4().hex[:8].upper()}"
    payment = Payment(
        id=uuid.uuid4(),
        user_id=test_enrollment.user_id,
        enrollment_id=test_enrollment.id,
        amount_fcfa=75000,
        method="ORANGE_MONEY",
        currency="XOF",
        status=PaymentStatus.PENDING,
        provider_ref=transaction_id,
        installment_number=1,
        installment_total=1,
    )
    db.add(payment)
    await db.flush()

    with patch("app.api.v1.payments.cinetpay_service") as mock_cinetpay:
        mock_cinetpay.verify_webhook = MagicMock(return_value=True)

        with patch("app.api.v1.payments.confirm_payment_and_provision") as mock_task:
            mock_task.delay = MagicMock()

            response = await client.post(
                "/api/v1/payments/cinetpay/webhook",
                data={
                    "cpm_trans_id": transaction_id,
                    "cpm_result": "00",
                    "cpm_amount": "75000",
                    "cpm_currency": "XOF",
                    "signature": "test_signature",
                },
            )

    assert response.status_code == 200
    assert response.json()["message"] == "OK"


@pytest.mark.asyncio
async def test_stripe_intent_creation(
    client: AsyncClient,
    test_student: User,
    student_token: str,
    test_enrollment: Enrollment,
):
    """Test Stripe PaymentIntent creation."""
    with patch("app.api.v1.payments.stripe_service") as mock_stripe:
        mock_stripe.create_payment_intent = AsyncMock(return_value={
            "client_secret": "pi_test_secret",
            "payment_intent_id": "pi_test123",
            "amount_cents": 11436,  # 75000 FCFA ≈ 114.36 EUR
            "currency": "eur",
            "status": "requires_payment_method",
        })

        response = await client.post(
            "/api/v1/payments/stripe/intent",
            json={
                "enrollment_id": str(test_enrollment.id),
                "currency": "eur",
            },
            headers={"Authorization": f"Bearer {student_token}"},
        )

    assert response.status_code == 200
    data = response.json()
    assert "client_secret" in data
    assert "payment_intent_id" in data
    assert "payment_id" in data


@pytest.mark.asyncio
async def test_payment_requires_auth(client: AsyncClient):
    """Test that payment endpoints require authentication."""
    response = await client.get("/api/v1/payments")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_cinetpay_enrollment_not_found(
    client: AsyncClient,
    student_token: str,
):
    """Test that CinetPay initiation fails for non-existent enrollment."""
    response = await client.post(
        "/api/v1/payments/cinetpay/initiate",
        json={
            "enrollment_id": str(uuid.uuid4()),
            "method": "ORANGE_MONEY",
            "installment": 1,
        },
        headers={"Authorization": f"Bearer {student_token}"},
    )
    assert response.status_code == 404
