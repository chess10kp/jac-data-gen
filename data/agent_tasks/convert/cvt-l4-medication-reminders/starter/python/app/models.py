from __future__ import annotations

from datetime import datetime
from typing import Optional

from beanie import Document, Indexed, Link
from beanie.operators import GTE, LTE, In

from app.helpers import TIME_FORMAT, dt_time_min, dt_time_max


class Medication(Document):
    user: Link[User]
    name: Indexed(str)
    notification_time: str
    deleted: bool = False

    class Settings:
        name = "medications"

    @classmethod
    async def get_medications(cls, tg_user_id: int) -> list[Medication]:
        return await cls.find(
            cls.user.tg_user_id == tg_user_id,
            In(cls.deleted, [False, None]),
            fetch_links=True
        ).sort("notification_time").to_list()

    @classmethod
    async def get_medications_ready_for_notifications(cls, tg_user_id: int, dt: datetime) -> list[Medication]:
        return await cls.find(
            cls.user.tg_user_id == tg_user_id,
            In(cls.deleted, [False, None]),
            cls.notification_time <= dt.strftime(TIME_FORMAT),
            fetch_links=True
        ).sort("notification_time").to_list()


class Notification(Document):
    medication: Link[Medication]
    sent_at: datetime

    # `True` - means that notification was confirmed and medication was taken,
    #          no need to send follow-up notification at 23:00.
    # `False` - notification was not confirmed and medication was not taken,
    #           need to send follow-up notification at 23:00.
    was_taken: bool = False

    tg_original_notification_id: Optional[int] = None  # `message_id` of message in telegram for notification
    tg_original_notification_updated: bool = False

    tg_followup_notification_id: Optional[int] = None  # `message_id` of followup message in telegram for notification
    tg_followup_notification_updated: bool = False

    @classmethod
    async def get_taken_notifications_for_time_period(
        cls,
        tg_user_id: int,
        start_dt: datetime,
        end_dt: datetime,
    ) -> list[Notification]:
        return await cls.find(
            cls.medication.user.tg_user_id == tg_user_id,
            cls.was_taken == True,  # noqa: E712
            GTE(cls.sent_at, start_dt),
            LTE(cls.sent_at, end_dt),
            fetch_links=True
        ).sort("+sent_at").to_list()

    @classmethod
    async def get_notification_for_current_day(cls, medication: Medication, dt: datetime) -> Optional[Notification]:
        return await cls.find(
            cls.medication.id == medication.id,
            GTE(cls.sent_at, dt_time_min(dt)),
            LTE(cls.sent_at, dt_time_max(dt)),
            fetch_links=True
        ).first_or_none()

    @classmethod
    async def get_not_taken_notifications_for_current_day(cls, dt: datetime) -> list[Notification]:
        return await cls.find(
            cls.was_taken == False,  # noqa: E712
            GTE(cls.sent_at, dt_time_min(dt)),
            LTE(cls.sent_at, dt_time_max(dt)),
            fetch_links=True
        ).to_list()

    class Settings:
        name = "notifications"


class User(Document):
    username: Indexed(str, unique=True)
    tg_user_id: int
    tg_chat_id: int

    class Settings:
        name = "users"


# All models to instantiate on load
__beanie_models__ = [Medication, User, Notification]
