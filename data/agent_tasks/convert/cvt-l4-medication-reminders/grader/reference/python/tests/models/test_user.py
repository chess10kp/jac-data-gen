import pytest
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.models import User


@pytest.mark.asyncio
async def test_new_user(mongodb_db: AsyncIOMotorDatabase):
    """
    Checking that `User` document is being created properly.
    """
    username = "boba_fett"
    tg_user_id = 44444444
    tg_chat_id = 44444444

    inserted_user = await User(username=username, tg_user_id=tg_user_id, tg_chat_id=tg_chat_id).insert()

    expected_user = await User.get(inserted_user.id)

    assert expected_user.username == username
    assert expected_user.tg_user_id == tg_user_id
    assert expected_user.tg_chat_id == tg_chat_id
