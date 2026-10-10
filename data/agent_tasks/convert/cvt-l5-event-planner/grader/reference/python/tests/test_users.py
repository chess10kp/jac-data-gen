import httpx
import pytest

# ---------- Sign up tests ----------


@pytest.mark.asyncio
async def test_sign_up_user(client: httpx.AsyncClient) -> None:
    payload = {
        "email": "testuser@example.com",
        "password": "testpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
    }

    test_response = {
        "message": "User created successfully",
    }

    response = await client.post("/user/signup", json=payload, headers=headers)

    assert response.status_code == 200
    assert response.json() == test_response


@pytest.mark.asyncio
async def test_sign_up_user_already_exists(client: httpx.AsyncClient) -> None:
    payload = {
        "email": "duplicate@example.com",
        "password": "testpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
    }

    await client.post("/user/signup", json=payload, headers=headers)

    response = await client.post("/user/signup", json=payload, headers=headers)

    assert response.status_code == 409
    assert response.json()["detail"] == "User with supplied email already exists"


# ---------- Sign in tests ----------


@pytest.mark.asyncio
async def test_sign_in_user(client: httpx.AsyncClient) -> None:
    # Sign up
    signup_payload = {
        "email": "testuser@example.com",
        "password": "testpassword",
    }
    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
    }
    await client.post("/user/signup", json=signup_payload, headers=headers)

    # Sign in
    signin_payload = {
        "username": "testuser@example.com",
        "password": "testpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    response = await client.post("/user/signin", data=signin_payload, headers=headers)
    print(response.json())
    assert response.status_code == 200
    assert response.json()["token_type"] == "Bearer"


@pytest.mark.asyncio
async def test_sign_in_user_not_exists(client: httpx.AsyncClient) -> None:
    signin_payload = {
        "username": "nonexistent@example.com",
        "password": "testpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    response = await client.post("/user/signin", data=signin_payload, headers=headers)

    assert response.status_code == 404
    assert response.json()["detail"] == "User does not exist"


@pytest.mark.asyncio
async def test_sign_in_user_invalid_credentials(client: httpx.AsyncClient) -> None:
    signup_payload = {
        "email": "validuser@example.com",
        "password": "correctpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
    }

    await client.post("/user/signup", json=signup_payload, headers=headers)

    signin_payload = {
        "username": "validuser@example.com",
        "password": "wrongpassword",
    }

    headers = {
        "accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    response = await client.post("/user/signin", data=signin_payload, headers=headers)

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"
