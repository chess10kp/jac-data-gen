import asyncio
import random
from datetime import datetime, timedelta
from typing import Iterator

import pytest
import pytest_asyncio
from beanie import init_beanie
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from pytest import FixtureRequest

from app.config import settings
from app.helpers import generate_notification_time, generate_random_string
from app.models import __beanie_models__, User, Medication, Notification


@pytest.fixture(scope="session")
def event_loop(request: FixtureRequest) -> Iterator[asyncio.AbstractEventLoop]:
    """Create an instance of the default event loop for each test case."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def mongodb_client() -> Iterator[AsyncIOMotorClient]:
    async_client: AsyncIOMotorClient = AsyncIOMotorClient(settings.database_url)

    yield async_client

    async_client.close()


@pytest_asyncio.fixture(scope="function")
async def mongodb_empty_db(mongodb_client: AsyncIOMotorClient) -> Iterator[AsyncIOMotorDatabase]:
    await init_beanie(database=mongodb_client[settings.mongo_db_name_test], document_models=__beanie_models__)

    yield mongodb_client[settings.mongo_db_name_test]

    await mongodb_client.drop_database(settings.mongo_db_name_test)


@pytest_asyncio.fixture(scope="function")
async def mongodb_db(
        mongodb_empty_db: AsyncIOMotorClient,
        inserted_users: list[User],
        inserted_medications: list[Medication],
        inserted_notifications: list[Notification],
) -> Iterator[AsyncIOMotorDatabase]:
    yield mongodb_empty_db


@pytest_asyncio.fixture(scope="function")
async def inserted_users(mongodb_empty_db: AsyncIOMotorClient) -> list[User]:
    """
    Inserts 3 users into mongodb.
    """
    data = [
        User(username="ahsoka", tg_user_id=11111111, tg_chat_id=11111111),
        User(username="darth_vader", tg_user_id=22222222, tg_chat_id=22222222),
        User(username="grogu", tg_user_id=33333333, tg_chat_id=33333333),
    ]

    await User.insert_many(data)
    return await User.find({}).to_list()


@pytest_asyncio.fixture(scope="function")
async def inserted_medications(inserted_users: list[User]) -> list[Medication]:
    """
    Inserts 9 medications (3 for each user) into mongodb.
    """
    data = []

    for user in inserted_users:
        # For each user there will be 3 medications.
        for _ in range(3):
            data.append(Medication(user=user, name=generate_random_string(),
                                   notification_time=generate_notification_time()))

    await Medication.insert_many(data)
    return await Medication.find({}, fetch_links=True).to_list()


@pytest_asyncio.fixture(scope="function")
async def inserted_notifications(inserted_medications: list[Medication]) -> list[Notification]:
    """
    Inserts 27 notifications (3 for each medication) into mongodb.
    """
    data = []

    for medication in inserted_medications:
        hour, minute = medication.notification_time.split(":")
        # For each medication there will be 3 notifications.
        sent_at = datetime.now().replace(hour=int(hour), minute=int(minute))
        data.append(Notification(medication=medication, sent_at=sent_at))
        data.append(Notification(medication=medication,
                                 sent_at=sent_at.replace(second=random.randint(0, 59)) - timedelta(days=1)))
        data.append(Notification(medication=medication,
                                 sent_at=sent_at.replace(second=random.randint(0, 59)) - timedelta(days=2)))

    await Notification.insert_many(data)
    return await Notification.find({}, fetch_links=True).to_list()
