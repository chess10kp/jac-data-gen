from datetime import datetime

import pytest
from beanie.operators import Set, In
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.models import Medication, User


@pytest.mark.asyncio
async def test_new_medication(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `Medication` document is being created properly.
    """
    user = await User.find({}).first_or_none()

    name = "omega-3"
    notification_time = "14:55"

    inserted_medication = await Medication(user=user, name=name, notification_time=notification_time).insert()

    expected_medication = await Medication.get(inserted_medication.id)

    assert expected_medication.user.username == user.username
    assert expected_medication.name == name
    assert expected_medication.notification_time == notification_time


@pytest.mark.asyncio
async def test_get_medications(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_users: list[User]
):
    """
    Checking that `Medication.get_medications()` returns right result when all medications have `deleted=True`.
    """
    for user in inserted_users:
        expected_medications = await Medication.get_medications(tg_user_id=user.tg_user_id)

        assert len(expected_medications) == 3

        for medication in expected_medications:
            assert medication.user.tg_user_id == user.tg_user_id


@pytest.mark.asyncio
async def test_get_medications_with_deleted(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_medications: list[Medication],
):
    """
    Checking that `Medication.get_medications()` returns right result when some medications have `deleted=False`.
    """
    user = await User.find({}).first_or_none()

    user_medications = list(filter(lambda m: m.user.username == user.username, inserted_medications))

    medication = await Medication.find(
        Medication.user.tg_user_id == user.tg_user_id,
        fetch_links=True,
    ).first_or_none()
    await medication.set({Medication.deleted: True})  # Marking as deleted one out of three medications.

    expected_medications = await Medication.get_medications(tg_user_id=user.tg_user_id)

    assert len(expected_medications) == len(user_medications) - 1


@pytest.mark.asyncio
async def test_get_medications_ready_for_notifications(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_medications: list[Medication],
):
    """
    Checking that `Medication.get_medications_ready_for_notifications()` returns right result when some
    notifications have `deleted=False` and check time is greater than `Medication.notification_time`.
    """
    user = await User.find({}).first_or_none()

    user_medications = list(filter(lambda m: m.user.username == user.username, inserted_medications))

    max_notification_time = max([m.notification_time for m in user_medications])
    hour, minute = max_notification_time.split(":")
    dt = datetime.now().replace(hour=int(hour), minute=int(minute))

    expected_medications = await Medication.get_medications_ready_for_notifications(tg_user_id=user.tg_user_id, dt=dt)

    assert len(expected_medications) == len(user_medications)


@pytest.mark.asyncio
async def test_get_medications_ready_for_notifications_empty(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_medications: list[Medication],
):
    """
    Checking that `Medication.get_medications_ready_for_notifications()` returns
    empty list when all notifications have `deleted=True`.
    """
    user = await User.find({}).first_or_none()

    user_medications = list(filter(lambda m: m.user.username == user.username, inserted_medications))

    await Medication.find(
        In(Medication.id, [n.id for n in user_medications]),
    ).update(Set({Medication.deleted: True}))

    expected_medications = await Medication.get_medications_ready_for_notifications(
        tg_user_id=user.tg_user_id, dt=datetime.now(),
    )

    assert expected_medications == []
