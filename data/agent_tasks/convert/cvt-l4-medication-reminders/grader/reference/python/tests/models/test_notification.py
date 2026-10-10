import random
from datetime import datetime, timedelta

import pytest
from beanie.operators import Set, In
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.helpers import dt_time_min
from app.models import Medication, User, Notification


@pytest.mark.asyncio
async def test_new_notification(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `Notification` document is being created properly.
    """

    medication = await Medication.find({}).first_or_none()
    sent_at = datetime.now() + timedelta(days=1)

    inserted_notification = await Notification(medication=medication, sent_at=sent_at).insert()

    expected_notification = await Notification.get(inserted_notification.id, fetch_links=True)

    assert expected_notification.medication.name == medication.name
    # Python saves microseconds while mongodb saves milliseconds.
    # When we save '2023-09-02 01:51:01.749493' only 3 first digits of microseconds will be saved.
    # So from mongodb we will get '2023-09-02 01:51:01.749000'.
    assert str(expected_notification.sent_at)[:-3] == str(sent_at)[:-3]
    assert expected_notification.was_taken is False
    assert expected_notification.tg_original_notification_id is None
    assert expected_notification.tg_original_notification_updated is False
    assert expected_notification.tg_followup_notification_id is None
    assert expected_notification.tg_followup_notification_updated is False


@pytest.mark.asyncio
async def test_get_taken_notifications_for_time_period(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_notifications: list[Notification],
):
    """
    Checking that `Notification.get_taken_notifications_for_time_period()` returns
    right result when some notifications for specified time period have `was_taken=True`.
    """
    user = await User.find({}).first_or_none()

    end_dt = datetime.now()
    start_dt = dt_time_min(end_dt - timedelta(days=2))

    notifications_for_user = list(filter(lambda n: n.medication.user.username == user.username, inserted_notifications))

    # Setting `was_taken=True` to random 6 notifications.
    taken_notification_amount = 6
    ids = random.sample([n.id for n in notifications_for_user if n.sent_at <= end_dt], taken_notification_amount)
    result = await Notification.find(
        In(Notification.id, ids),
    ).update(Set({Notification.was_taken: True}))

    assert result.modified_count == taken_notification_amount

    expected_notifications = await Notification.get_taken_notifications_for_time_period(
        tg_user_id=user.tg_user_id, start_dt=start_dt, end_dt=end_dt,
    )

    assert len(expected_notifications) == taken_notification_amount


@pytest.mark.asyncio
async def test_get_taken_notifications_for_time_period_empty(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `Notification.get_taken_notifications_for_time_period()` returns
    empty list when all notifications for specified time period have `was_taken=False`.
    """
    user = await User.find({}).first_or_none()

    end_dt = datetime.now()
    start_dt = dt_time_min(end_dt - timedelta(days=1))

    expected_notifications = await Notification.get_taken_notifications_for_time_period(
        tg_user_id=user.tg_user_id, start_dt=start_dt, end_dt=end_dt,
    )

    assert expected_notifications == []


@pytest.mark.asyncio
async def test_get_notification_for_current_day(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `Notification.get_notification_for_current_day()` returns one notification for today's date.
    """
    medication = await Medication.find({}, fetch_links=True).first_or_none()

    dt = datetime.now()
    expected_notification = await Notification.get_notification_for_current_day(medication=medication, dt=dt)

    assert expected_notification
    assert expected_notification.medication == medication
    assert expected_notification.sent_at.date() == dt.date()


@pytest.mark.asyncio
async def test_get_notification_for_current_day_none(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `Notification.get_notification_for_current_day()` returns None for tomorrow's date.
    """
    medication = await Medication.find({}).first_or_none()

    dt = datetime.now() + timedelta(days=1)
    expected_notification = await Notification.get_notification_for_current_day(medication=medication, dt=dt)

    assert expected_notification is None


@pytest.mark.asyncio
async def test_get_not_taken_notifications_for_current_day(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_notifications: list[Notification],
):
    """
    Checking that `Notification.get_not_taken_notifications_for_current_day()` returns
    right result when some notifications for specified date have `was_taken=False`.
    """
    dt = datetime.now()
    today_notifications = list(filter(lambda n: n.sent_at.date() == dt.date(), inserted_notifications))

    expected_notification = await Notification.get_not_taken_notifications_for_current_day(dt=dt)

    assert len(today_notifications) == len(expected_notification)


@pytest.mark.asyncio
async def test_get_not_taken_notifications_for_current_day_empty(
        mongodb_db: AsyncIOMotorDatabase,
        inserted_notifications: list[Notification],
):
    """
    Checking that `Notification.get_not_taken_notifications_for_current_day()` returns
    empty list when all notifications for specified date have `was_taken=True`.
    """
    dt = datetime.now()
    today_notifications = list(filter(lambda n: n.sent_at.date() == dt.date(), inserted_notifications))

    await Notification.find(
        In(Notification.id, [n.id for n in today_notifications]),
    ).update(Set({Notification.was_taken: True}))

    expected_notification = await Notification.get_not_taken_notifications_for_current_day(dt=dt)

    assert expected_notification == []
