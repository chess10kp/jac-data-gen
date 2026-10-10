import httpx
import pytest

from auth.jwt_handler import create_access_token
from models.events import Event

# ---------- Fixtures ----------


@pytest.fixture(scope="module")
async def access_token() -> str:
    return create_access_token("testuser@example.com")


@pytest.fixture(scope="function")
async def mock_event() -> Event:
    event = Event(
        creator="testuser@example.com",
        title="Test event",
        image="https://example.com/image.jpg",
        description="This is a test event",
        tags=["test", "event"],
        location="Test location",
    )

    await Event.insert_one(event)
    yield event


# ---------- Get events tests ----------


@pytest.mark.asyncio
async def test_get_events(client: httpx.AsyncClient, mock_event: Event) -> None:
    response = await client.get("/event/")

    assert response.status_code == 200
    assert response.json()[0]["_id"] == str(mock_event.id)


@pytest.mark.asyncio
async def test_get_events_count(client: httpx.AsyncClient, access_token: str) -> None:
    payload_1 = {
        "title": "Test event 1",
        "image": "https://example.com/image1.jpg",
        "description": "This is test event 1",
        "tags": ["test", "event"],
        "location": "Test location 1",
    }

    payload_2 = {
        "title": "Test event 2",
        "image": "https://example.com/image2.jpg",
        "description": "This is test event 2",
        "tags": ["test", "event"],
        "location": "Test location 2",
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    await client.post("/event/new", json=payload_1, headers=headers)
    await client.post("/event/new", json=payload_2, headers=headers)

    response = await client.get("/event/")

    events = response.json()

    assert response.status_code == 200
    assert len(events) == 2


# ---------- Get event by ID tests ----------


@pytest.mark.asyncio
async def test_get_event_by_id(client: httpx.AsyncClient, mock_event: Event) -> None:
    response = await client.get(f"/event/{mock_event.id}")

    assert response.status_code == 200
    assert response.json()["creator"] == mock_event.creator
    assert response.json()["_id"] == str(mock_event.id)


@pytest.mark.asyncio
async def test_get_event_by_id_not_exist(client: httpx.AsyncClient) -> None:
    fake_id = "507f1f77bcf86cd799439011"

    response = await client.get(f"/event/{fake_id}")

    assert response.status_code == 404
    assert response.json()["detail"] == "Event with supplied ID does not exist"


# ---------- Post event tests ----------


@pytest.mark.asyncio
async def test_post_event(client: httpx.AsyncClient, access_token: str) -> None:
    payload = {
        "title": "New test event",
        "image": "https://example.com/new_image.jpg",
        "description": "This is a new test event",
        "tags": ["new", "test", "event"],
        "location": "New test location",
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    response_message = "Event created successfully"

    response = await client.post("/event/new", json=payload, headers=headers)

    assert response.status_code == 200
    assert response.json()["message"] == response_message
    assert "id" in response.json()


# ---------- Update event tests ----------


@pytest.mark.asyncio
async def test_update_event(
    client: httpx.AsyncClient, mock_event: Event, access_token: str
) -> None:
    payload = {"title": "Updated test event"}

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    response = await client.put(
        f"/event/edit/{mock_event.id}", json=payload, headers=headers
    )

    assert response.status_code == 200
    assert response.json()["title"] == payload["title"]


@pytest.mark.asyncio
async def test_update_event_not_exist(
    client: httpx.AsyncClient, access_token: str
) -> None:
    fake_id = "507f1f77bcf86cd799439011"

    payload = {"title": "Updated title"}

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    response = await client.put(f"/event/edit/{fake_id}", json=payload, headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Event with supplied ID does not exist"


@pytest.mark.asyncio
async def test_update_event_not_allowed(
    client: httpx.AsyncClient, mock_event: Event
) -> None:
    different_user_token = create_access_token("differentuser@example.com")

    payload = {"title": "Unauthorized update"}

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {different_user_token}",
    }

    response = await client.put(
        f"/event/edit/{mock_event.id}", json=payload, headers=headers
    )

    assert response.status_code == 400
    assert response.json()["detail"] == "Operation not allowed"
    assert mock_event.title != payload["title"]


# ---------- Delete event tests ----------


@pytest.mark.asyncio
async def test_delete_event(
    client: httpx.AsyncClient, mock_event: Event, access_token: str
) -> None:
    payload = {
        "title": "Test event",
        "image": "https://example.com/image1.jpg",
        "description": "This is test event",
        "tags": ["test", "event"],
        "location": "Test location",
    }

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    await client.post("/event/new", json=payload, headers=headers)

    response_message = "Event deleted successfully"

    response = await client.delete(f"/event/{mock_event.id}", headers=headers)

    assert response.status_code == 200
    assert response.json()["message"] == response_message


@pytest.mark.asyncio
async def test_delete_event_not_exist(
    client: httpx.AsyncClient, access_token: str
) -> None:
    fake_id = "507f1f77bcf86cd799439011"

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }

    response = await client.delete(f"/event/{fake_id}", headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "Event with supplied ID does not exist"


@pytest.mark.asyncio
async def test_delete_event_not_allowed(
    client: httpx.AsyncClient, mock_event: Event
) -> None:
    different_user_token = create_access_token("differentuser@example.com")

    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {different_user_token}",
    }

    response = await client.delete(f"/event/{mock_event.id}", headers=headers)

    assert response.status_code == 400
    assert response.json()["detail"] == "Operation not allowed"
