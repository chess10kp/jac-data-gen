import asyncio  # This module will be used to create an active loop session to ensure the tests run on a single thread to avoid conflicts.
import httpx  # This module will act as the asynchronous client for conducting HTTP CRUD operations.
import os
import pytest

from main import app
from database.connection import Settings
from models.events import Event
from models.users import User


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


async def init_db():
    test_settings = Settings()
    test_settings.DATABASE_URL = os.environ.get(
        "TEST_DATABASE_URL", "mongodb://localhost:27017/test_db"
    )

    await test_settings.init_db()


@pytest.fixture(scope="function")
async def client():
    await init_db()
    # The application spun as an AsyncClient, which is kept alive until the end of the test session.
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://app") as client:
        yield client
        # After the tests are done, the database is cleaned up by deleting all events and users.
        await Event.find_all().delete()
        await User.find_all().delete()
